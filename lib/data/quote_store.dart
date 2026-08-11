import 'package:flutter/foundation.dart';

enum RequestStatus { pending, matched, completed }

/// A quote sent by a mechanic in response to a client's help request.
///
/// For Normal/Urgent requests, several of these can exist for the same
/// [requestId] — the client compares them and picks one (`accepted` flips to
/// true only on the winner).
///
/// For Emergency requests there is only ever ONE MechanicQuote per request:
/// it's created already `accepted: true` the instant a mechanic taps Accept.
/// There is no comparison step — first mechanic to accept wins.
class MechanicQuote {
  final String id;
  final String requestId;
  final String mechanicName;
  final String price;
  final String eta;
  final double rating;
  bool accepted;

  MechanicQuote({
    required this.id,
    required this.requestId,
    required this.mechanicName,
    required this.price,
    required this.eta,
    required this.rating,
    this.accepted = false,
  });
}

/// The problem report a client uploads from NeedHelpScreen.
class HelpRequest {
  final String id;
  final String problem;
  final String location;
  final String urgency; // 'Normal' | 'Urgent' | 'Emergency'
  final List<String> photoPaths;
  final DateTime createdAt;
  // Todo: populate from the logged-in client's real profile once auth exists.
  final String clientName;
  RequestStatus status;
  DateTime? completedAt;

  HelpRequest({
    required this.id,
    required this.problem,
    required this.location,
    required this.urgency,
    required this.photoPaths,
    required this.createdAt,
    this.clientName = 'Client',
    this.status = RequestStatus.pending,
    this.completedAt,
  });

  bool get isEmergency => urgency == 'Emergency';
}

/// App-wide, in-memory store connecting the client's "Need Help" upload to
/// the mechanic's "Jobs" screen, and back to the client's notification bell.
///
/// Flow:
///  - Normal / Urgent: the request goes out to every mechanic as "Send
///    Quote". Any number of mechanics can call [mechanicSendQuote]. The
///    client compares them on QuotesScreen and calls [clientAcceptQuote] —
///    only then is a winner picked.
///  - Emergency: the request goes out to every mechanic as "Accept" only.
///    The FIRST mechanic to call [mechanicAcceptEmergency] is immediately
///    and irreversibly matched. There's nothing for the client to choose —
///    it's first come, first served.
///
/// In a real backend this would be replaced by Firestore / REST + push
/// notifications, but the shape of this API is what both sides talk to, so
/// swapping the implementation later shouldn't require touching the UI.
class QuoteNotificationStore extends ChangeNotifier {
  QuoteNotificationStore._internal();
  static final QuoteNotificationStore instance = QuoteNotificationStore._internal();

  final List<HelpRequest> _requests = [];
  final List<MechanicQuote> _allQuotes = [];
  int _unseenCount = 0;

  // ---------------------------------------------------------------------
  // Client-facing API (NeedHelpScreen / QuotesScreen / bell badge)
  // ---------------------------------------------------------------------

  /// The request currently shown on QuotesScreen / ActiveRequestScreen.
  HelpRequest? get activeRequest => _requests.isEmpty ? null : _requests.last;

  /// Quotes for the active request only.
  List<MechanicQuote> get quotes {
    final req = activeRequest;
    if (req == null) return const [];
    return _allQuotes.where((q) => q.requestId == req.id).toList();
  }

  int get unseenCount => _unseenCount;
  bool get hasAcceptedQuote => quotes.any((q) => q.accepted);

  int get mechanicNotificationCount =>
      _allQuotes.where((q) => q.accepted).length;

  List<MechanicQuote> get mechanicNotifications =>
      _allQuotes.where((q) => q.accepted).toList();

  HelpRequest? requestFor(String requestId) {
    try {
      return _requests.firstWhere((r) => r.id == requestId);
    } catch (_) {
      return null;
    }
  }

  /// Called when the client taps "Upload" on NeedHelpScreen.
  void submitRequest(HelpRequest request) {
    _requests.add(request);
    notifyListeners();
  }

  void markSeen() {
    if (_unseenCount == 0) return;
    _unseenCount = 0;
    notifyListeners();
  }

  /// Client picks a quote on QuotesScreen. Only reachable for Normal/Urgent
  /// requests — Emergency requests are already matched before this screen
  /// would show a choice.
  void clientAcceptQuote(String quoteId) {
    for (final q in quotes) {
      q.accepted = q.id == quoteId;
    }
    activeRequest?.status = RequestStatus.matched;
    notifyListeners();
  }

  // Back-compat alias — existing QuotesScreen code calls this name.
  void acceptQuote(String quoteId) => clientAcceptQuote(quoteId);

  // ---------------------------------------------------------------------
  // Mechanic-facing API (JobsScreen)
  // ---------------------------------------------------------------------

  /// Requests still open for a mechanic to act on (not yet matched).
  List<HelpRequest> get availableJobs =>
      _requests.where((r) => r.status == RequestStatus.pending).toList();

  /// Normal/Urgent only: mechanic sends a quote. The job stays available to
  /// other mechanics until the client picks a winner.
  void mechanicSendQuote(
    String requestId, {
    required String mechanicName,
    required String price,
    required String eta,
    required double rating,
  }) {
    _allQuotes.add(MechanicQuote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      requestId: requestId,
      mechanicName: mechanicName,
      price: price,
      eta: eta,
      rating: rating,
    ));
    if (activeRequest?.id == requestId) _unseenCount++;
    notifyListeners();
  }

  /// Emergency only: first mechanic to call this wins. Returns false if the
  /// job was already grabbed by someone else, so the UI can tell this
  /// mechanic they were too slow instead of silently double-booking it.
  bool mechanicAcceptEmergency(
    String requestId, {
    required String mechanicName,
    required String price,
    required String eta,
    required double rating,
  }) {
    final req = _requests.firstWhere((r) => r.id == requestId);
    if (req.status != RequestStatus.pending) return false;

    _allQuotes.add(MechanicQuote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      requestId: requestId,
      mechanicName: mechanicName,
      price: price,
      eta: eta,
      rating: rating,
      accepted: true, // no client comparison for emergencies
    ));
    req.status = RequestStatus.matched;
    if (activeRequest?.id == requestId) _unseenCount++;
    notifyListeners();
    return true;
  }

  /// The winning quote for a matched/completed request, if any.
  MechanicQuote? acceptedQuoteFor(String requestId) {
    for (final q in _allQuotes) {
      if (q.requestId == requestId && q.accepted) return q;
    }
    return null;
  }

  /// Jobs a specific mechanic has won and is currently working.
  List<HelpRequest> matchedJobsFor(String mechanicName) => _requests
      .where((r) =>
          r.status == RequestStatus.matched &&
          acceptedQuoteFor(r.id)?.mechanicName == mechanicName)
      .toList();

  /// Jobs a specific mechanic has finished.
  List<HelpRequest> completedJobsFor(String mechanicName) => _requests
      .where((r) =>
          r.status == RequestStatus.completed &&
          acceptedQuoteFor(r.id)?.mechanicName == mechanicName)
      .toList();

  void mechanicCompleteJob(String requestId) {
    final req = _requests.firstWhere((r) => r.id == requestId);
    req.status = RequestStatus.completed;
    req.completedAt = DateTime.now();
    notifyListeners();
  }

  void clear() {
    _requests.clear();
    _allQuotes.clear();
    _unseenCount = 0;
    notifyListeners();
  }
}