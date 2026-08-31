import 'package:flutter/foundation.dart';
import 'app_session.dart';
import 'mechanic_account_store.dart';

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

/// Parses a peso-formatted string like '₱300' into a numeric value.
double parsePesoAmount(String price) {
  final digits = price.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(digits) ?? 0;
}

/// The payload a mechanic's "Waiting for Client Payment" QR encodes, and the
/// client's scanner decodes. Kept as a single shared format so both sides
/// can never drift out of sync with each other.
class PaymentQrPayload {
  final String requestId;
  final String mechanicName;
  final double amount;
  const PaymentQrPayload({required this.requestId, required this.mechanicName, required this.amount});
}

const _qrPrefix = 'ONGOPAY';

String buildPaymentQrData({required String requestId, required String mechanicName, required double amount}) {
  return '$_qrPrefix|$requestId|$mechanicName|${amount.toStringAsFixed(2)}';
}

PaymentQrPayload? parsePaymentQrData(String raw) {
  final parts = raw.split('|');
  if (parts.length != 4 || parts[0] != _qrPrefix) return null;
  final amount = double.tryParse(parts[3]);
  if (amount == null) return null;
  return PaymentQrPayload(requestId: parts[1], mechanicName: parts[2], amount: amount);
}

/// The problem report a client uploads from NeedHelpScreen.
class HelpRequest {
  final String id;
  final String problem;
  final String location;
  final String urgency; // 'Normal' | 'Urgent' | 'Emergency'
  final List<String> photoPaths;
  final DateTime createdAt;
  final String clientName;
  final String durationLabel;
  final int surcharge;

  /// GPS coordinates captured only if the client used "Use Current
  /// Location" — null if they typed a freeform address. Auto-detection of
  /// En Route / Arrived requires these; without them the mechanic falls
  /// back to a manual "Confirm Arrival" control.
  final double? clientLat;
  final double? clientLng;

  RequestStatus status;

  // Fine-grained workflow flags. Who's allowed to flip each one:
  //  - navigating: MECHANIC only (manual "Navigate" button tap — this is
  //    also what starts GPS tracking; nothing below happens automatically
  //    until this is true)
  //  - enRoute / arrived: SYSTEM only (GPS-driven, see mechanicMarkEnRoute/Arrived)
  //  - workStarted / serviceCompleted: MECHANIC only (manual button press)
  //  - paymentCompleted: CLIENT only, via clientConfirmPayment after a QR scan
  bool navigating;
  bool enRoute;
  bool arrived;
  bool workStarted;
  bool serviceCompleted;
  bool paymentCompleted;
  DateTime? navigatingAt;
  DateTime? enRouteAt;
  DateTime? arrivedAt;
  DateTime? workStartedAt;
  DateTime? serviceCompletedAt;
  DateTime? paymentCompletedAt;

  /// Points credited to the mechanic for this job — 5% of the paid amount,
  /// set exactly once by [QuoteNotificationStore.clientConfirmPayment].
  int? pointsAwarded;

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
    this.clientLat,
    this.clientLng,
    this.status = RequestStatus.pending,
    this.navigating = false,
    this.enRoute = false,
    this.arrived = false,
    this.workStarted = false,
    this.serviceCompleted = false,
    this.paymentCompleted = false,
    this.navigatingAt,
    this.enRouteAt,
    this.arrivedAt,
    this.workStartedAt,
    this.serviceCompletedAt,
    this.paymentCompletedAt,
    this.pointsAwarded,
    this.completedAt,
  });

  bool get isEmergency => urgency == 'Emergency';
  bool get hasClientCoordinates => clientLat != null && clientLng != null;
}

/// App-wide, in-memory store connecting the client's "Need Help" upload to
/// the mechanic's "Jobs" screen, and back to the client's notification bell.
///
/// THE CLIENT CONTROLS PAYMENT, THE MECHANIC CONTROLS THE SERVICE, THE
/// SYSTEM HANDLES AUTOMATIC STATUS DETECTION. See the per-method docs below
/// for exactly who's allowed to call what — several methods assert
/// [AppSession.instance.currentRole] and/or [MechanicAccountStore]'s
/// approval status and throw/refuse if the caller isn't allowed, so this
/// isn't just a UI convention.
class QuoteNotificationStore extends ChangeNotifier {
  QuoteNotificationStore._internal();
  static final QuoteNotificationStore instance = QuoteNotificationStore._internal();

  // Todo: replace with real auth-derived identities once login exists.
  static const currentMechanicName = 'You';

  final List<HelpRequest> _requests = [];
  final List<MechanicQuote> _allQuotes = [];
  int _unseenCount = 0;

  // ---------------------------------------------------------------------
  // Client-facing API (NeedHelpScreen / QuotesScreen / ActiveRequestScreen)
  // ---------------------------------------------------------------------

  /// Every one of this client's requests still awaiting a decision — the
  /// data behind QuotesScreen, which shows one comparison card per request
  /// rather than a single global list (a client can have several jobs out
  /// for quotes simultaneously).
  List<HelpRequest> get myPendingRequests {
    final list = _requests.where((r) => r.status == RequestStatus.pending).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Every one of this client's requests that has an accepted mechanic and
  /// isn't fully paid off yet — the data behind ClientJobsScreen's Pending
  /// and Active sub-tabs. There's no multi-client separation in this demo
  /// (single client session), so this is simply every matched request.
  List<HelpRequest> get myActiveJobs =>
      _requests.where((r) => r.status == RequestStatus.matched).toList();

  /// Every one of this client's requests that has been fully paid off — the
  /// data behind ServiceHistoryScreen. Same single-client-demo caveat as
  /// [myActiveJobs]: this is simply every completed request, most recently
  /// paid first.
  List<HelpRequest> get myCompletedJobs {
    final list = _requests.where((r) => r.status == RequestStatus.completed).toList();
    list.sort((a, b) =>
        (b.paymentCompletedAt ?? b.completedAt ?? b.createdAt).compareTo(a.paymentCompletedAt ?? a.completedAt ?? a.createdAt));
    return list;
  }

  /// Compatibility shim: the single most recently submitted unfinished
  /// request. Most screens now work off specific request ids (via
  /// [requestFor]) or [myPendingRequests]/[myActiveJobs]/[myCompletedJobs]
  /// instead.
  HelpRequest? get activeRequest {
    final unfinished = _requests.where((r) => r.status != RequestStatus.completed).toList();
    if (unfinished.isNotEmpty) {
      unfinished.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return unfinished.last;
    }
    return _requests.isEmpty ? null : _requests.last;
  }

  /// Compatibility shim — quotes for [activeRequest] only. Prefer
  /// [quotesForRequest] for a specific request.
  List<MechanicQuote> get quotes {
    final req = activeRequest;
    if (req == null) return const [];
    return _allQuotes.where((q) => q.requestId == req.id).toList();
  }

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

  void submitRequest(HelpRequest request) {
    _requests.add(request);
    notifyListeners();
  }

  void markSeen() {
    if (_unseenCount == 0) return;
    _unseenCount = 0;
    notifyListeners();
  }

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

  void acceptQuote(String quoteId) => clientAcceptQuote(quoteId);

  /// CLIENT action only. Reverts an already-matched request back to
  /// Pending and un-accepts its winning quote, so mechanics can quote/accept
  /// it again. Only reachable while the job is still in the Pending sub-tab
  /// (i.e. the mechanic hasn't tapped Navigate yet) — see ClientJobsScreen.
  bool clientRevertToPending(String requestId) {
    if (AppSession.instance.currentRole != AppRole.client) {
      throw StateError('Only the Client UI can cancel a request.');
    }
    final req = requestFor(requestId);
    if (req == null || req.status != RequestStatus.matched) return false;

    for (final q in quotesForRequest(requestId)) {
      q.accepted = false;
    }
    req.status = RequestStatus.pending;
    req.navigating = false;
    req.enRoute = false;
    req.arrived = false;
    req.workStarted = false;
    req.serviceCompleted = false;
    req.navigatingAt = null;
    req.enRouteAt = null;
    req.arrivedAt = null;
    req.workStartedAt = null;
    req.serviceCompletedAt = null;
    notifyListeners();
    return true;
  }

  /// CLIENT action only. Permanently removes a request and all its quotes.
  /// Refuses to delete a request that's already been paid — that's real
  /// history, not something to silently disappear.
  bool clientDeleteRequest(String requestId) {
    if (AppSession.instance.currentRole != AppRole.client) {
      throw StateError('Only the Client UI can delete a request.');
    }
    final req = requestFor(requestId);
    if (req == null || req.paymentCompleted) return false;
    _requests.removeWhere((r) => r.id == requestId);
    _allQuotes.removeWhere((q) => q.requestId == requestId);
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------
  // Mechanic-facing API — accept / quote (JobsScreen)
  // ---------------------------------------------------------------------

  List<HelpRequest> get availableJobs =>
      _requests.where((r) => r.status == RequestStatus.pending).toList();

  /// Normal/Urgent only: mechanic sends a quote. The job stays available to
  /// other mechanics until the client picks a winner.
  ///
  /// THE gate: refuses to run — throwing rather than silently no-op'ing —
  /// unless [MechanicAccountStore.canPerformJobActions] is true. This is
  /// checked here, not just in the UI, so no button/screen anywhere can
  /// bypass it.
  void mechanicSendQuote(
    String requestId, {
    required String mechanicName,
    required String price,
    required String eta,
    required double rating,
  }) {
    if (!MechanicAccountStore.instance.canPerformJobActions) {
      throw StateError('Your mechanic account must be approved before you can send quotes.');
    }
    _allQuotes.add(MechanicQuote(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_allQuotes.length}',
      requestId: requestId,
      mechanicName: mechanicName,
      price: price,
      eta: eta,
      rating: rating,
    ));
    _unseenCount++;
    notifyListeners();
  }

  bool mechanicHasActiveEmergency(String mechanicName) {
    return _requests.any((r) =>
        r.isEmergency &&
        r.status == RequestStatus.matched &&
        acceptedQuoteFor(r.id)?.mechanicName == mechanicName);
  }

  /// Emergency only: first mechanic to call this wins. Returns false if the
  /// job was already grabbed by someone else, if this mechanic already has
  /// an active emergency job, OR if the account isn't approved.
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
    if (!MechanicAccountStore.instance.canPerformJobActions) return false;

    _allQuotes.add(MechanicQuote(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_allQuotes.length}',
      requestId: requestId,
      mechanicName: mechanicName,
      price: price,
      eta: eta,
      rating: rating,
      accepted: true,
    ));
    req.status = RequestStatus.matched;
    _unseenCount++;
    notifyListeners();
    return true;
  }

  MechanicQuote? acceptedQuoteFor(String requestId) {
    for (final q in _allQuotes) {
      if (q.requestId == requestId && q.accepted) return q;
    }
    return null;
  }

  /// Jobs a mechanic has won and is actively working — includes every phase
  /// up to (but not including) payment. Normal/Urgent stack freely here;
  /// Emergency is capped to one active by [mechanicAcceptEmergency].
  List<HelpRequest> matchedJobsFor(String mechanicName) => _requests
      .where((r) =>
          r.status == RequestStatus.matched &&
          acceptedQuoteFor(r.id)?.mechanicName == mechanicName)
      .toList();

  /// Jobs a mechanic has finished AND been paid for. This is the only
  /// definition of "completed" — see [clientConfirmPayment].
  List<HelpRequest> completedJobsFor(String mechanicName) => _requests
      .where((r) =>
          r.status == RequestStatus.completed &&
          acceptedQuoteFor(r.id)?.mechanicName == mechanicName)
      .toList();

  // ---------------------------------------------------------------------
  // Service-status workflow
  // ---------------------------------------------------------------------

  /// MECHANIC action only — manual, and entirely at the mechanic's own
  /// pace ("when they're ready"). This is what unlocks GPS tracking on
  /// MechanicActiveJobScreen; nothing below this point in the workflow
  /// happens until it's true.
  void mechanicStartNavigating(String requestId) {
    if (AppSession.instance.currentRole != AppRole.mechanic) {
      throw StateError('Only the Mechanic UI can start navigating to a job.');
    }
    final req = requestFor(requestId);
    if (req == null || req.navigating) return;
    req.navigating = true;
    req.navigatingAt = DateTime.now();
    notifyListeners();
  }

  /// SYSTEM: called from GPS tracking in MechanicActiveJobScreen once the
  /// mechanic's position has moved measurably closer to the client since
  /// navigation started. Idempotent.
  void mechanicMarkEnRoute(String requestId) {
    final req = requestFor(requestId);
    if (req == null || req.enRoute || req.status != RequestStatus.matched) return;
    req.enRoute = true;
    req.enRouteAt = DateTime.now();
    notifyListeners();
  }

  /// SYSTEM: called from GPS tracking once the mechanic is within the
  /// arrival radius of the client's coordinates. Idempotent.
  void mechanicMarkArrived(String requestId) {
    final req = requestFor(requestId);
    if (req == null || req.arrived || req.status != RequestStatus.matched) return;
    req.arrived = true;
    req.arrivedAt = DateTime.now();
    if (!req.enRoute) {
      req.enRoute = true;
      req.enRouteAt = req.arrivedAt;
    }
    notifyListeners();
  }

  /// MECHANIC action only — manual, and only meaningful after arrival.
  void mechanicStartWork(String requestId) {
    if (AppSession.instance.currentRole != AppRole.mechanic) {
      throw StateError('Only the Mechanic UI can start work on a job.');
    }
    final req = requestFor(requestId);
    if (req == null || req.workStarted) return;
    req.workStarted = true;
    req.workStartedAt = DateTime.now();
    notifyListeners();
  }

  /// MECHANIC action only — manual. Does NOT complete the job; payment is
  /// still owed, and [RequestStatus] stays [RequestStatus.matched] until
  /// the client pays via [clientConfirmPayment].
  void mechanicCompleteService(String requestId) {
    if (AppSession.instance.currentRole != AppRole.mechanic) {
      throw StateError('Only the Mechanic UI can mark a service complete.');
    }
    final req = requestFor(requestId);
    if (req == null || req.serviceCompleted) return;
    req.serviceCompleted = true;
    req.serviceCompletedAt = DateTime.now();
    notifyListeners();
  }

  /// CLIENT action only — the ONLY way payment (and therefore the job) can
  /// ever be marked complete. Requires the service to actually be finished.
  /// Returns the points credited to the mechanic, or null if the payment
  /// couldn't go through (wrong request, already paid, or service not yet
  /// complete).
  int? clientConfirmPayment(String requestId) {
    if (AppSession.instance.currentRole != AppRole.client) {
      throw StateError('Only the Client UI can confirm a payment.');
    }
    final req = requestFor(requestId);
    if (req == null) return null;
    if (!req.serviceCompleted) return null;
    if (req.paymentCompleted) return null;

    final quote = acceptedQuoteFor(requestId);
    final amount = quote == null ? 0.0 : parsePesoAmount(quote.price);
    final points = (amount * 0.05).round();

    req.paymentCompleted = true;
    req.paymentCompletedAt = DateTime.now();
    req.pointsAwarded = points;
    req.status = RequestStatus.completed;
    req.completedAt = req.paymentCompletedAt;

    notifyListeners();
    return points;
  }

  // ---------------------------------------------------------------------
  // Mechanic financials — always DERIVED from real paid jobs, never stored
  // separately, so there's no way for a balance to drift out of sync or be
  // inflated before payment actually happens.
  // ---------------------------------------------------------------------

  double totalEarningsFor(String mechanicName) {
    double sum = 0;
    for (final req in completedJobsFor(mechanicName)) {
      final quote = acceptedQuoteFor(req.id);
      if (quote != null) sum += parsePesoAmount(quote.price);
    }
    return sum;
  }

  int totalPointsFor(String mechanicName) {
    int sum = 0;
    for (final req in completedJobsFor(mechanicName)) {
      sum += req.pointsAwarded ?? 0;
    }
    return sum;
  }

  void clear() {
    _requests.clear();
    _allQuotes.clear();
    _unseenCount = 0;
    notifyListeners();
  }
}