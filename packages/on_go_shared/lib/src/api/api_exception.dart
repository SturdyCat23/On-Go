/// Why a call across the app boundary failed.
///
/// Deliberately transport-neutral: an implementation backed by HTTP maps
/// status codes onto these, and the local pre-backend implementations throw
/// the same kinds, so callers never have to know which one they hold.
enum ApiErrorKind {
  /// No network, DNS failure, timeout — the request never got an answer.
  unreachable,

  /// The caller is not signed in, or the session expired.
  unauthenticated,

  /// Signed in, but not allowed to do this.
  forbidden,

  /// The thing being addressed does not exist.
  notFound,

  /// The request was well-formed but the server refused it (validation, a
  /// duplicate submission, a state that no longer allows the action).
  rejected,

  /// This surface cannot do this at all — the operation belongs to the other
  /// front end, or needs a backend that is not connected yet.
  unsupported,

  /// Anything else.
  unknown,
}

/// The single error type every API in this package throws.
class ApiException implements Exception {
  final ApiErrorKind kind;
  final String message;

  /// The underlying failure, when there was one.
  final Object? cause;

  const ApiException(this.kind, this.message, {this.cause});

  /// The operation is not available on this surface yet — thrown by the local
  /// implementations for the calls that genuinely need the backend.
  const ApiException.unsupported(String reason)
      : kind = ApiErrorKind.unsupported,
        message = reason,
        cause = null;

  @override
  String toString() => 'ApiException(${kind.name}): $message';
}
