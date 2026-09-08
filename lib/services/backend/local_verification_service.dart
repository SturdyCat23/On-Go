import 'dart:async';

import 'package:on_go_shared/on_go_shared.dart';

/// The mobile app's own copy of the verification queue, for as long as there
/// is no backend to hold the real one.
///
/// It does exactly the half of [AccountVerificationApi] this app is entitled
/// to: a mechanic finishing registration files a request, and their Jobs and
/// Profile screens watch it for a verdict. Deciding is a console action, so
/// [decide] refuses here rather than quietly approving — a phone approving its
/// own owner would be the whole point of the split, undone.
///
/// Which means a request filed on this device stays Pending until the backend
/// exists to carry it to a moderator. That is the honest state of a
/// disconnected app; the `demo-mechanic` sign-in shortcut is what unlocks the
/// mechanic flows for local testing in the meantime.
///
/// Swapping this for an HTTP implementation changes no screen: every caller
/// already awaits a Future or listens to a Stream.
class LocalVerificationService implements AccountVerificationApi {
  final List<AccountVerificationRequest> _requests = [];
  final StreamController<List<AccountVerificationRequest>> _changes =
      StreamController<List<AccountVerificationRequest>>.broadcast();

  List<AccountVerificationRequest> get _snapshot =>
      List<AccountVerificationRequest>.unmodifiable(_requests.reversed);

  void _publish() {
    if (!_changes.isClosed) _changes.add(_snapshot);
  }

  @override
  Future<AccountVerificationRequest> submit(SubmitVerificationRequest request) async {
    final now = DateTime.now();
    final stored = AccountVerificationRequest(
      id: 'req_${now.millisecondsSinceEpoch}',
      userNumber: 'User - ${(_requests.length + 1).toString().padLeft(5, '0')}',
      name: request.name,
      email: request.email,
      role: request.role,
      submittedAt: now,
      documentNames: request.documentNames,
    );
    _requests.add(stored);
    _publish();
    return stored;
  }

  @override
  Future<List<AccountVerificationRequest>> listRequests({
    ApprovalStatus? status,
    bool escalatedOnly = false,
    String? search,
  }) async {
    return _snapshot.where((request) {
      if (status != null && request.status != status) return false;
      if (escalatedOnly && !request.escalated) return false;
      if (search != null && search.isNotEmpty) {
        return request.name.toLowerCase().contains(search.toLowerCase());
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Future<AccountVerificationRequest?> findRequest(String requestId) async =>
      _findSync(requestId);

  AccountVerificationRequest? _findSync(String requestId) {
    for (final request in _requests) {
      if (request.id == requestId) return request;
    }
    return null;
  }

  @override
  Future<AccountVerificationRequest> decide(
    String requestId,
    ModerationDecision decision,
  ) {
    throw const ApiException(
      ApiErrorKind.forbidden,
      'Account verification decisions are made in the On Go admin console, '
      'not in the mobile app.',
    );
  }

  @override
  Future<List<ModerationActivity>> listActivity({int limit = 50}) {
    throw const ApiException(
      ApiErrorKind.forbidden,
      'The moderation activity feed belongs to the admin console.',
    );
  }

  @override
  Stream<AccountVerificationRequest?> watchRequest(String requestId) async* {
    yield _findSync(requestId);
    yield* _changes.stream.map((_) => _findSync(requestId)).distinct();
  }

  @override
  Stream<List<AccountVerificationRequest>> watchRequests() async* {
    yield _snapshot;
    yield* _changes.stream;
  }
}
