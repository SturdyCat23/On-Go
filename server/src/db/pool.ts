import { readFileSync } from 'node:fs';
import pg from 'pg';
import { loadConfig } from '../config/env.js';
import { logger } from '../logging/logger.js';

const { Pool } = pg;

/**
 * The PostgreSQL connection pool.
 *
 * TLS: `verify-full` is required in production (enforced in config), which
 * means we both verify the RDS certificate chain against the AWS CA bundle AND
 * check that the hostname matches. `require` alone encrypts but authenticates
 * nothing, so it does not stop an attacker who can answer for the host.
 *
 * The pool connects as the least-privileged application role, never as the RDS
 * master user — see migrations/002_roles_least_privilege.sql.
 */

function resolveCaCert(raw: string | undefined): string | undefined {
  if (!raw) return undefined;
  // Accept either an inline PEM (how Secrets Manager delivers it) or a path
  // (how a container mount delivers it).
  if (raw.includes('-----BEGIN CERTIFICATE-----')) return raw;
  return readFileSync(raw, 'utf8');
}

function buildSslConfig(): pg.PoolConfig['ssl'] {
  const config = loadConfig();
  const ca = resolveCaCert(config.PG_CA_CERT);

  switch (config.PGSSLMODE) {
    case 'disable':
      return false;
    case 'require':
      // Encrypted, but the server identity is not checked. Local use only.
      return { rejectUnauthorized: false };
    case 'verify-ca':
      return { ca, rejectUnauthorized: true, checkServerIdentity: () => undefined };
    case 'verify-full':
    default:
      return { ca, rejectUnauthorized: true };
  }
}

const config = loadConfig();

export const pool = new Pool({
  host: config.PGHOST,
  port: config.PGPORT,
  database: config.PGDATABASE,
  user: config.PGUSER,
  password: config.PGPASSWORD,
  ssl: buildSslConfig(),
  max: config.PG_POOL_MAX,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  application_name: 'ongo-api',
  // A runaway query holds a connection and a row lock; cap it server-side so a
  // single expensive or hostile request cannot exhaust the pool.
  statement_timeout: config.PG_STATEMENT_TIMEOUT_MS,
  query_timeout: config.PG_STATEMENT_TIMEOUT_MS,
});

// An idle client erroring (failover, RDS restart) must not take the process
// down; pg re-creates the connection on next use.
pool.on('error', (err) => {
  logger.error({ err: { name: err.name, message: err.message } }, 'idle database client error');
});

export async function closePool(): Promise<void> {
  await pool.end();
}
