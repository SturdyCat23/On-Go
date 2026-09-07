/**
 * Error taxonomy.
 *
 * The split that matters: `publicMessage` is what the caller is allowed to
 * read, `cause`/`detail` is what only the logs get. Anything thrown that is
 * NOT an AppError is treated as an internal fault and reported to the caller
 * as a bare 500 — no message, no stack, no database text. That default is what
 * keeps driver errors ("duplicate key value violates unique constraint
 * users_email_key"), file paths, and query fragments out of responses.
 */

export type ErrorCode =
  | 'bad_request'
  | 'validation_failed'
  | 'unauthorized'
  | 'invalid_credentials'
  | 'account_locked'
  | 'token_expired'
  | 'token_invalid'
  | 'forbidden'
  | 'not_found'
  | 'conflict'
  | 'rate_limited'
  | 'payload_too_large'
  | 'internal_error';

const STATUS_BY_CODE: Record<ErrorCode, number> = {
  bad_request: 400,
  validation_failed: 400,
  unauthorized: 401,
  invalid_credentials: 401,
  account_locked: 423,
  token_expired: 401,
  token_invalid: 401,
  forbidden: 403,
  not_found: 404,
  conflict: 409,
  rate_limited: 429,
  payload_too_large: 413,
  internal_error: 500,
};

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly statusCode: number;
  /** Safe to return to the caller. */
  readonly publicMessage: string;
  /** Structured, non-sensitive extra returned to the caller (field errors). */
  readonly details?: unknown;
  /** Log-only context. Never serialized into a response. */
  readonly logContext?: Record<string, unknown>;

  constructor(
    code: ErrorCode,
    publicMessage: string,
    options: { details?: unknown; logContext?: Record<string, unknown>; cause?: unknown } = {},
  ) {
    super(publicMessage, { cause: options.cause });
    this.name = 'AppError';
    this.code = code;
    this.statusCode = STATUS_BY_CODE[code];
    this.publicMessage = publicMessage;
    this.details = options.details;
    this.logContext = options.logContext;
  }
}

/* Constructors for the cases used often enough to be worth naming. */

export const badRequest = (message = 'Malformed request.', details?: unknown) =>
  new AppError('bad_request', message, { details });

export const unauthorized = (message = 'Authentication required.') =>
  new AppError('unauthorized', message);

/**
 * Deliberately identical for "no such user" and "wrong password" — a caller
 * must not be able to enumerate which accounts exist by reading the error.
 */
export const invalidCredentials = (logContext?: Record<string, unknown>) =>
  new AppError('invalid_credentials', 'Incorrect username or password.', { logContext });

export const forbidden = (message = 'You do not have access to this resource.') =>
  new AppError('forbidden', message);

/**
 * Used for both "does not exist" and "exists but is not yours". Returning 404
 * rather than 403 on the second case stops an attacker from confirming that an
 * id is real — the core defence against IDOR probing.
 */
export const notFound = (message = 'Resource not found.') =>
  new AppError('not_found', message);

export const conflict = (message = 'That change conflicts with the current state.') =>
  new AppError('conflict', message);

export const internalError = (cause?: unknown, logContext?: Record<string, unknown>) =>
  new AppError('internal_error', 'Something went wrong. Please try again.', {
    cause,
    logContext,
  });
