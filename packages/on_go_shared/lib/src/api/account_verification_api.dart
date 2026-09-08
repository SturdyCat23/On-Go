import '../models/account_verification_request.dart';
import '../models/enums.dart';

/// The account-verification queue — the busiest crossing between the two apps.
///
/// * The MOBILE app calls [submit] when someone finishes registration, and
///   [watchRequest] / [findRequest] to learn what was decided.
/// * The CONSOLE calls [listRequests] to fill the moderator queue and
///   [decide] to rule on one.
///
/// Everything returns a Future because every one of these becomes a network
/// call. Writing the interface that way now means the screens are already
/// shaped for latency and failure, and swapping the local implementation for
/// an HTTP one changes no call site.
abstract interface class AccountVerificationApi {
  /// Files a new pending request and returns it, complete with the id and
  /// user number the queue assigned. Mobile → console.
  Future<AccountVerificationRequest> submit(SubmitVerificationRequest request);

  /// Every request this caller is allowed to see, newest first.
  ///
  /// [status] and [escalatedOnly] narrow it server-side rather than making the
  /// console pull the whole queue to filter it locally.
  Future<List<AccountVerificationRequest>> listRequests({
    ApprovalStatus? status,
    bool escalatedOnly = false,
    String? search,
  });

  /// One request by id, or null when it no longer exists.
  Future<AccountVerificationRequest?> findRequest(String requestId);

  /// Approves, rejects or escalates [requestId] and returns the updated
  /// record. Console → mobile.
  ///
  /// Throws [ApiException] with [ApiErrorKind.forbidden] when the actor lacks
  /// the permission for [ModerationDecision.action], and with
  /// [ApiErrorKind.rejected] when the request has already been decided.
  Future<AccountVerificationRequest> decide(
    String requestId,
    ModerationDecision decision,
  );

  /// The console's activity feed, newest first — one entry per decision.
  Future<List<ModerationActivity>> listActivity({int limit = 50});

  /// A live view of one request's status.
  ///
  /// This is the mobile app's half of the round trip: a mechanic sits on their
  /// Jobs screen while a moderator, in another application, rules on their
  /// account. The local implementation emits on every local change; a
  /// networked one polls, or opens a socket, without any screen changing.
  Stream<AccountVerificationRequest?> watchRequest(String requestId);

  /// A live view of the whole queue, for the console's moderator screens.
  Stream<List<AccountVerificationRequest>> watchRequests();
}
