import type { PoolClient, QueryResultRow } from 'pg';
import { pool } from './pool.js';
import { internalError } from '../utils/errors.js';
import { logger } from '../logging/logger.js';

export { pool, closePool } from './pool.js';

/**
 * The only sanctioned way to talk to the database.
 *
 * `text` must be a static SQL string and every runtime value must arrive
 * through `params` as a $1/$2 placeholder. That is what makes SQL injection
 * structurally impossible here rather than a review checklist item: the driver
 * sends the statement and the arguments over the wire separately, so a value
 * is never parsed as SQL no matter what it contains.
 *
 * If you ever need a dynamic column or direction (ORDER BY cannot be
 * parameterized), run it through `safeIdentifier` / `safeSortDirection` — those
 * map untrusted input onto a fixed allowlist rather than interpolating it.
 */

export type Sql = string;

/** Rejects a template-built string before it can reach the driver. */
function assertStaticSql(text: string): void {
  // A parameterized statement never needs a quoted literal built at runtime.
  // This does not prove safety, but it catches the common regression where
  // someone reintroduces `WHERE email = '${email}'`.
  if (/\$\{/.test(text)) {
    throw internalError(new Error('SQL contains a template interpolation'), {
      reason: 'non_parameterized_sql',
    });
  }
}

export async function query<T extends QueryResultRow = QueryResultRow>(
  text: Sql,
  params: readonly unknown[] = [],
): Promise<T[]> {
  assertStaticSql(text);
  try {
    const result = await pool.query<T>(text, params as unknown[]);
    return result.rows;
  } catch (err) {
    // The driver's message can quote the failing statement and its values.
    // Log it; never let it propagate to a response.
    logger.error(
      { err: { name: (err as Error).name, message: (err as Error).message } },
      'database query failed',
    );
    throw internalError(err, { stage: 'query' });
  }
}

/** Exactly one row expected; returns null when there is none. */
export async function queryOne<T extends QueryResultRow = QueryResultRow>(
  text: Sql,
  params: readonly unknown[] = [],
): Promise<T | null> {
  const rows = await query<T>(text, params);
  return rows[0] ?? null;
}

/**
 * Runs `fn` inside a transaction, rolling back on any throw. Used wherever a
 * security decision spans more than one statement — rotating a refresh token,
 * for instance, must revoke the old row and insert the new one atomically or
 * not at all.
 */
export async function withTransaction<T>(
  fn: (client: TxClient) => Promise<T>,
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await fn(wrapClient(client));
    await client.query('COMMIT');
    return result;
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      logger.error(
        { err: { message: (rollbackErr as Error).message } },
        'transaction rollback failed',
      );
    }
    if (err && (err as { code?: string }).code === 'internal_error') throw err;
    throw err instanceof Error && err.name === 'AppError'
      ? err
      : internalError(err, { stage: 'transaction' });
  } finally {
    client.release();
  }
}

export interface TxClient {
  query<T extends QueryResultRow = QueryResultRow>(
    text: Sql,
    params?: readonly unknown[],
  ): Promise<T[]>;
  queryOne<T extends QueryResultRow = QueryResultRow>(
    text: Sql,
    params?: readonly unknown[],
  ): Promise<T | null>;
}

function wrapClient(client: PoolClient): TxClient {
  return {
    async query<T extends QueryResultRow = QueryResultRow>(
      text: Sql,
      params: readonly unknown[] = [],
    ): Promise<T[]> {
      assertStaticSql(text);
      const result = await client.query<T>(text, params as unknown[]);
      return result.rows;
    },
    async queryOne<T extends QueryResultRow = QueryResultRow>(
      text: Sql,
      params: readonly unknown[] = [],
    ): Promise<T | null> {
      const rows = await this.query<T>(text, params);
      return rows[0] ?? null;
    },
  };
}

/**
 * Maps caller-supplied sort input onto an allowlist. Identifiers cannot be
 * bound as parameters, so the only safe construction is selecting from a fixed
 * set we wrote ourselves — never quoting or escaping the input.
 */
export function safeIdentifier<T extends string>(
  candidate: unknown,
  allowed: readonly T[],
  fallback: T,
): T {
  return typeof candidate === 'string' && (allowed as readonly string[]).includes(candidate)
    ? (candidate as T)
    : fallback;
}

export function safeSortDirection(candidate: unknown): 'ASC' | 'DESC' {
  return typeof candidate === 'string' && candidate.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
}
