import { SignJWT, jwtVerify, type JWTPayload } from 'jose';
import { z } from 'zod';
import { loadConfig } from '../config/env.js';
import { AppError } from '../utils/errors.js';
import { newUuid } from '../utils/crypto.js';

/**
 * Access tokens.
 *
 * Signed JWTs, HS256, deliberately short-lived (10 minutes by default; the
 * config refuses anything over 15 in production). They are *bearer* tokens, so
 * the only real mitigation for theft is that the window is small — continuity
 * comes from the refresh token, which is revocable server-side.
 *
 * What is deliberately NOT here:
 *   - No permissions in the token. Only `sub`, `role` and the session id. Rights
 *     are read from the database at request time, so revoking a moderator's
 *     approve permission takes effect on the next request rather than whenever
 *     their token happens to expire.
 *   - No `alg` flexibility. The verifier pins HS256, which closes the classic
 *     `alg: none` and RS256->HS256 confusion attacks.
 *
 * HS256 (symmetric) is the right fit while this is one service verifying its
 * own tokens. If a second service ever needs to verify without being able to
 * mint, move to EdDSA and publish a JWKS — the shape below does not change.
 */

const ALG = 'HS256';

export type TokenRole = 'client' | 'mechanic' | 'moderator' | 'admin';

export interface AccessTokenClaims {
  /** User id. */
  sub: string;
  /** Role at issue time. Re-checked against the database on every request. */
  role: TokenRole;
  /** Session family this token belongs to, so it can be revoked with it. */
  sid: string;
  /** Unique token id — lets a single token be denylisted if that is ever needed. */
  jti: string;
  iat: number;
  exp: number;
}

const claimsSchema = z.object({
  sub: z.string().uuid(),
  role: z.enum(['client', 'mechanic', 'moderator', 'admin']),
  sid: z.string().uuid(),
  jti: z.string().min(1),
  iat: z.number().int(),
  exp: z.number().int(),
});

function keyFrom(secret: string): Uint8Array {
  return new TextEncoder().encode(secret);
}

function signingKey(): Uint8Array {
  return keyFrom(loadConfig().JWT_SIGNING_KEY);
}

/** Current key first, then the previous one — supports zero-downtime rotation. */
function verificationKeys(): Uint8Array[] {
  const config = loadConfig();
  const keys = [keyFrom(config.JWT_SIGNING_KEY)];
  if (config.JWT_PREVIOUS_SIGNING_KEY) {
    keys.push(keyFrom(config.JWT_PREVIOUS_SIGNING_KEY));
  }
  return keys;
}

export async function issueAccessToken(input: {
  userId: string;
  role: TokenRole;
  sessionFamilyId: string;
}): Promise<{ token: string; expiresIn: number }> {
  const config = loadConfig();
  const now = Math.floor(Date.now() / 1000);
  const expiresIn = config.ACCESS_TOKEN_TTL_SECONDS;

  const token = await new SignJWT({
    role: input.role,
    sid: input.sessionFamilyId,
  })
    .setProtectedHeader({ alg: ALG, typ: 'JWT' })
    .setSubject(input.userId)
    .setIssuer(config.JWT_ISSUER)
    .setAudience(config.JWT_AUDIENCE)
    .setIssuedAt(now)
    .setExpirationTime(now + expiresIn)
    .setJti(newUuid())
    .sign(signingKey());

  return { token, expiresIn };
}

/**
 * Verifies signature, algorithm, issuer, audience and expiry, then validates
 * the claim shape. Throws `token_expired` separately from `token_invalid` so
 * the client knows to refresh rather than to send the user back to sign-in.
 */
export async function verifyAccessToken(token: string): Promise<AccessTokenClaims> {
  const config = loadConfig();
  let lastError: unknown;

  for (const key of verificationKeys()) {
    try {
      const { payload } = await jwtVerify(token, key, {
        algorithms: [ALG],
        issuer: config.JWT_ISSUER,
        audience: config.JWT_AUDIENCE,
        // Tight tolerance: enough for ordinary NTP drift, not enough to
        // meaningfully extend a token's life.
        clockTolerance: 5,
      });
      return parseClaims(payload);
    } catch (err) {
      lastError = err;
      if (isExpired(err)) {
        throw new AppError('token_expired', 'Your session has expired. Please refresh.');
      }
      // Otherwise fall through and try the previous key.
    }
  }

  throw new AppError('token_invalid', 'Invalid authentication token.', {
    logContext: { reason: (lastError as Error | undefined)?.name },
  });
}

function isExpired(err: unknown): boolean {
  return (
    typeof err === 'object' &&
    err !== null &&
    (err as { code?: string }).code === 'ERR_JWT_EXPIRED'
  );
}

function parseClaims(payload: JWTPayload): AccessTokenClaims {
  const parsed = claimsSchema.safeParse(payload);
  if (!parsed.success) {
    // A validly-signed token with the wrong shape means our own issuer and
    // verifier disagree — never a client's fault, and never trusted.
    throw new AppError('token_invalid', 'Invalid authentication token.', {
      logContext: { reason: 'claim_shape' },
    });
  }
  return parsed.data;
}

/**
 * Pulls the bearer token out of an Authorization header.
 *
 * Tokens are accepted ONLY from this header — never from a query string, where
 * they would end up in ALB access logs, CloudFront logs, and browser history.
 */
export function extractBearerToken(header: string | undefined): string | null {
  if (!header) return null;
  const match = /^Bearer ([A-Za-z0-9._~+/-]+=*)$/.exec(header.trim());
  return match?.[1] ?? null;
}
