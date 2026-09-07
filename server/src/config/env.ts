import { z } from 'zod';

/**
 * The single source of truth for configuration.
 *
 * Every value is validated at boot; the process refuses to start on a bad or
 * missing setting rather than discovering it at the first request. Production
 * additionally forbids the permissive defaults that are convenient locally
 * (wildcard CORS, unverified database TLS, short signing keys).
 */

const csv = (value: string): string[] =>
  value
    .split(',')
    .map((part) => part.trim())
    .filter((part) => part.length > 0);

const durationSeconds = (fallback: number) =>
  z.coerce.number().int().positive().max(60 * 60 * 24 * 365).default(fallback);

const schema = z
  .object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: z.coerce.number().int().min(1).max(65535).default(8080),
    HOST: z.string().default('0.0.0.0'),
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),

    /** Number of proxy hops in front of the app (ALB = 1). Controls whose
     *  X-Forwarded-For we are willing to believe when rate limiting by IP. */
    TRUST_PROXY_HOPS: z.coerce.number().int().min(0).max(10).default(0),

    // ── CORS ────────────────────────────────────────────────────────────────
    /** Exact origins allowed to call the API. Never a wildcard in production. */
    CORS_ALLOWED_ORIGINS: z.string().default('').transform(csv),

    // ── Tokens ──────────────────────────────────────────────────────────────
    /** HS256 signing key, base64. Must be >= 32 bytes of real entropy. */
    JWT_SIGNING_KEY: z.string().min(32),
    /** Optional previous key, kept valid for verification during rotation. */
    JWT_PREVIOUS_SIGNING_KEY: z.string().min(32).optional(),
    JWT_ISSUER: z.string().min(1).default('ongo-api'),
    JWT_AUDIENCE: z.string().min(1).default('ongo-app'),

    /** Access tokens are deliberately short-lived — compromise window, not
     *  convenience, sets this number. Refresh handles continuity. */
    ACCESS_TOKEN_TTL_SECONDS: durationSeconds(600),
    /** Idle timeout: a refresh token unused for this long is dead. */
    REFRESH_TOKEN_TTL_SECONDS: durationSeconds(60 * 60 * 24 * 14),
    /** Hard ceiling on a session regardless of activity — forces re-auth. */
    SESSION_ABSOLUTE_TTL_SECONDS: durationSeconds(60 * 60 * 24 * 60),

    // ── Password hashing ────────────────────────────────────────────────────
    /** Server-side secret mixed into every hash. Sits in Secrets Manager, not
     *  the database, so a stolen table dump alone cannot be cracked offline. */
    PASSWORD_PEPPER: z.string().min(16),
    ARGON2_MEMORY_KIB: z.coerce.number().int().min(19456).default(65536),
    ARGON2_TIME_COST: z.coerce.number().int().min(2).default(3),
    ARGON2_PARALLELISM: z.coerce.number().int().min(1).max(16).default(1),

    // ── Database ────────────────────────────────────────────────────────────
    PGHOST: z.string().min(1),
    PGPORT: z.coerce.number().int().min(1).max(65535).default(5432),
    PGDATABASE: z.string().min(1),
    PGUSER: z.string().min(1),
    PGPASSWORD: z.string().min(1),
    /** verify-full is the only mode that actually stops an active MITM. */
    PGSSLMODE: z.enum(['disable', 'require', 'verify-ca', 'verify-full']).default('verify-full'),
    /** PEM bundle for the RDS CA. Path or inline PEM. */
    PG_CA_CERT: z.string().optional(),
    PG_POOL_MAX: z.coerce.number().int().min(1).max(100).default(10),
    PG_STATEMENT_TIMEOUT_MS: z.coerce.number().int().min(100).default(10_000),

    // ── Rate limiting / lockout ─────────────────────────────────────────────
    RATE_LIMIT_GLOBAL_MAX: z.coerce.number().int().min(1).default(300),
    RATE_LIMIT_GLOBAL_WINDOW_SECONDS: durationSeconds(60),
    RATE_LIMIT_AUTH_MAX: z.coerce.number().int().min(1).default(10),
    RATE_LIMIT_AUTH_WINDOW_SECONDS: durationSeconds(300),
    /** Failed logins before the account itself is temporarily locked. */
    LOGIN_MAX_FAILED_ATTEMPTS: z.coerce.number().int().min(3).default(8),
    LOGIN_LOCKOUT_SECONDS: durationSeconds(900),

    // ── Body limits ─────────────────────────────────────────────────────────
    MAX_REQUEST_BODY_BYTES: z.coerce.number().int().min(1024).default(256 * 1024),
  })
  .superRefine((env, ctx) => {
    if (env.NODE_ENV !== 'production') return;

    if (env.CORS_ALLOWED_ORIGINS.length === 0) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['CORS_ALLOWED_ORIGINS'],
        message: 'must list explicit origins in production',
      });
    }
    if (env.CORS_ALLOWED_ORIGINS.includes('*')) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['CORS_ALLOWED_ORIGINS'],
        message: 'wildcard origin is not allowed in production',
      });
    }
    if (env.CORS_ALLOWED_ORIGINS.some((o) => o.startsWith('http://'))) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['CORS_ALLOWED_ORIGINS'],
        message: 'plaintext http origins are not allowed in production',
      });
    }
    if (env.PGSSLMODE !== 'verify-full') {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['PGSSLMODE'],
        message: 'database connections must use verify-full in production',
      });
    }
    if (!env.PG_CA_CERT) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['PG_CA_CERT'],
        message: 'a CA bundle is required to verify the database certificate',
      });
    }
    if (env.ACCESS_TOKEN_TTL_SECONDS > 900) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['ACCESS_TOKEN_TTL_SECONDS'],
        message: 'access tokens must live at most 15 minutes in production',
      });
    }
  });

export type AppConfig = z.infer<typeof schema>;

let cached: AppConfig | null = null;

/**
 * Validates and returns configuration. On failure the reported message names
 * only the offending KEYS — never the values, which are secrets.
 */
export function loadConfig(): AppConfig {
  if (cached) return cached;

  const parsed = schema.safeParse(process.env);
  if (!parsed.success) {
    const keys = [...new Set(parsed.error.issues.map((i) => i.path.join('.')))];
    const detail = parsed.error.issues
      .map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`)
      .join('; ');
    throw new Error(
      `Invalid configuration for ${keys.length} setting(s) — ${detail}`,
    );
  }

  cached = parsed.data;
  return cached;
}

export function isProduction(): boolean {
  return loadConfig().NODE_ENV === 'production';
}
