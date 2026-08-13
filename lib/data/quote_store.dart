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
  // Set from NeedHelpScreen's urgency selection — see _urgencyInfo there.
  final String durationLabel;
  final int surcharge;
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
    this.durationLabel = 'Completed within 10 days',
    this.surcharge = 0,
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
///    only then is a winner picked. Multiple Normal/Urgent jobs can be
///    accepted and worked simultaneously by the same mechanic — they stack.
///  - Emergency: the request goes out to every mechanic as "Accept" only.
///    The FIRST mechanic to call [mechanicAcceptEmergency] is immediately
///    and irreversibly matched. A mechanic can only have ONE active
///    emergency job at a time — see [mechanicHasActiveEmergency] — they
///    must complete it before accepting another.
///
/// In a real backend this would be replaced by Firestore / REST + push
/// notifications, but the shape of this API is what both sides talk to, so
/// swapping the implementation later shouldn't require touching the UI.
class QuoteNotificationStore extends ChangeNotifier {
  QuoteNotificationStore._internal();
  static final QuoteNotificationStore instance = QuoteNotificationStore._internal();

  // Todo: replace with real auth-derived identities once login exists.
  // Centralized here so every screen/store agrees on "who is the current
  // mechanic" instead of each file hardcoding its own 'You' string.
  static const currentMechanicName = 'You';

  final List<HelpRequest> _requests = [];
  final List<MechanicQuote> _allQuotes = [];
  int _unseenCount = 0;

  // ---------------------------------------------------------------------
  // Client-facing API (NeedHelpScreen / QuotesScreen / bell badge)
  // ---------------------------------------------------------------------

  /// The request currently shown on QuotesScreen / ActiveRequestScreen —
  /// the most recently submitted request that's still pending, falling back
  /// to the last request overall once everything's matched/completed.
  HelpRequest? get activeRequest {
    final pending = _requests.where((r) => r.status == RequestStatus.pending);
    if (pending.isNotEmpty) return pending.last;
    return _requests.isEmpty ? null : _requests.last;
  }

  /// Quotes for the active request only.
  List<MechanicQuote> get quotes {
    final req = activeRequest;
    if (req == null) return const [];
    return _allQuotes.where((q) => q.requestId == req.id).toList();
  }

  /// Quotes for any specific request (used internally, and available if a
  /// future screen wants to browse quotes across multiple open requests).
  List<MechanicQuote> quotesForRequest(String requestId) =>
      _allQuotes.where((q) => q.requestId == requestId).toList();

  int get unseenCount => _unseenCount;
  bool get hasAcceptedQuote => quotes.any((q) => q.accepted);

  int get mechanicNotificationCount => _allQuotes
      .where((q) => q.accepted && q.mechanicName == currentMechanicName)
      .length;

  List<MechanicQuote> get mechanicNotifications => _allQuotes
      .where((q) => q.accepted && q.mechanicName == currentMechanicName)
      .toList();

  HelpRequest? requestFor(String requestId) {
    try {
      return _requests.firstWhere((r) => r.id == requestId);
    } catch (_) {
      return null;
    }
  }

  MechanicQuote? quoteById(String quoteId) {
    try {
      return _allQuotes.firstWhere((q) => q.id == quoteId);
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

  /// Client picks a quote — on QuotesScreen or anywhere else. Resolves the
  /// quote's OWN request via [quote.requestId] rather than assuming it
  /// belongs to [activeRequest], so accepting quotes across several
  /// different open requests all work correctly and independently.
  void clientAcceptQuote(String quoteId) {
    final quote = quoteById(quoteId);
    if (quote == null) return;
    final req = requestFor(quote.requestId);
    if (req == null) return;

    for (final q in quotesForRequest(quote.requestId)) {
      q.accepted = q.id == quoteId;
    }
    req.status = RequestStatus.matched;
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
      id: '${DateTime.now().microsecondsSinceEpoch}_${_allQuotes.length}',
      requestId: requestId,
      mechanicName: mechanicName,
      price: price,
      eta: eta,
      rating: rating,
    ));
    if (activeRequest?.id == requestId) _unseenCount++;
    notifyListeners();
  }

  /// True while [mechanicName] has an emergency job that's been accepted
  /// but not yet marked complete. A mechanic can only ride one emergency at
  /// a time — Normal/Urgent jobs are unaffected and can stack freely.
  bool mechanicHasActiveEmergency(String mechanicName) {
    return _requests.any((r) =>
        r.isEmergency &&
        r.status == RequestStatus.matched &&
        acceptedQuoteFor(r.id)?.mechanicName == mechanicName);
  }

  /// Emergency only: first mechanic to call this wins. Returns false if the
  /// job was already grabbed by someone else, OR if this mechanic already
  /// has an active emergency job — check [mechanicHasActiveEmergency]
  /// beforehand if you want to show a more specific message than a generic
  /// failure.
  bool mechanicAcceptEmergency(
    String requestId, {
    required String mechanicName,
    required String price,
    required String eta,
    required double rating,
  }) {
    final req = _requests.firstWhere((r) => r.id == requestId);
    if (req.status != RequestStatus.pending) return false;
    if (mechanicHasActiveEmergency(mechanicName)) return false;

    _allQuotes.add(MechanicQuote(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_allQuotes.length}',
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

  /// Jobs a specific mechanic has won and is currently working. Normal and
  /// Urgent jobs stack here freely; Emergency is capped to one by
  /// [mechanicAcceptEmergency] refusing further accepts while one is active.
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