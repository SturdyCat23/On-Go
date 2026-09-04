import 'package:flutter/foundation.dart';
import 'app_session.dart';
import 'chat_store.dart';
import 'mechanic_account_store.dart';

enum RequestStatus { pending, matched, completed }

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

double parsePesoAmount(String price) {
  final digits = price.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(digits) ?? 0;
}

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

const _accountQrPrefix = 'ONGOACCOUNT';

String buildMechanicAccountQrData(String mechanicName) => '$_accountQrPrefix|$mechanicName';

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

  final double? clientLat;
  final double? clientLng;

  RequestStatus status;
  DateTime? matchedAt;

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

  int? pointsAwarded;
  DateTime? completedAt;

  String? lastCancelReason;
  String? lastCancelledBy;
  DateTime? lastCancelledAt;

  /// The actual price the mechanic and client settled on, set by the
  /// mechanic via [QuoteNotificationStore.mechanicSetPaymentAmount] before
  /// a payment code can be shared. REQUIRED for Emergency jobs — those have
  /// no MechanicQuote price at all, since emergencies skip quoting
  /// entirely and the price is negotiated in person. For Normal/Urgent,
  /// this OVERRIDES the original quote price once set, covering cases
  /// where the final in-person price differs from the quote.
  double? agreedPaymentAmount;
  DateTime? agreedPaymentAmountSetAt;

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
    this.matchedAt,
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
    this.lastCancelReason,
    this.lastCancelledBy,
    this.lastCancelledAt,
    this.agreedPaymentAmount,
    this.agreedPaymentAmountSetAt,
  });

  bool get isEmergency => urgency == 'Emergency';
  bool get hasClientCoordinates => clientLat != null && clientLng != null;
}

class QuoteNotificationStore extends ChangeNotifier {
  QuoteNotificationStore._internal();
  static final QuoteNotificationStore instance = QuoteNotificationStore._internal();

  static String get currentMechanicName {
    final name = MechanicAccountStore.instance.name;
    return name.isEmpty ? 'You' : name;
  }

  final List<HelpRequest> _requests = [];
  final List<MechanicQuote> _allQuotes = [];
  int _unseenCount = 0;
  final Set<String> _seenMechanicQuoteIds = {};
  final Set<String> _seenClientQuoteIds = {};

  // ---------------------------------------------------------------------
  // Client-facing API
  // ---------------------------------------------------------------------

  List<HelpRequest> get myPendingRequests {
    final list = _requests.where((r) => r.status == RequestStatus.pending).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<HelpRequest> get myActiveJobs =>
      _requests.where((r) => r.status == RequestStatus.matched).toList();

  List<HelpRequest> get myCompletedJobs {
    final list = _requests.where((r) => r.status == RequestStatus.completed).toList();
    list.sort((a, b) =>
        (b.paymentCompletedAt ?? b.completedAt ?? b.createdAt).compareTo(a.paymentCompletedAt ?? a.completedAt ?? a.createdAt));
    return list;
  }

  HelpRequest? get activeRequest {
    final unfinished = _requests.where((r) => r.status != RequestStatus.completed).toList();
    if (unfinished.isNotEmpty) {
      unfinished.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return unfinished.last;
    }
    return _requests.isEmpty ? null : _requests.last;
  }

  List<MechanicQuote> get quotes {
    final req = activeRequest;
    if (req == null) return const [];
    return _allQuotes.where((q) => q.requestId == req.id).toList();
  }

  List<MechanicQuote> quotesForRequest(String requestId) =>
      _allQuotes.where((q) => q.requestId == requestId).toList();

  int get unseenCount => _unseenCount;
  bool get hasAcceptedQuote => quotes.any((q) => q.accepted);

  int unseenQuoteCountForRequest(String requestId) =>
      quotesForRequest(requestId).where((q) => !_seenClientQuoteIds.contains(q.id)).length;

  int get totalUnseenQuoteCountForClient =>
      myPendingRequests.fold(0, (sum, r) => sum + unseenQuoteCountForRequest(r.id));

  void markRequestQuotesSeen(String requestId) {
    _seenClientQuoteIds.addAll(quotesForRequest(requestId).map((q) => q.id));
    notifyListeners();
  }

  List<MechanicQuote> get mechanicNotifications => _allQuotes
      .where((q) => q.accepted && q.mechanicName == currentMechanicName)
      .toList();

  int get mechanicNotificationCount =>
      mechanicNotifications.where((q) => !_seenMechanicQuoteIds.contains(q.id)).length;

  void markMechanicNotificationsSeen() {
    _seenMechanicQuoteIds.addAll(mechanicNotifications.map((q) => q.id));
    notifyListeners();
  }

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
    req.matchedAt = DateTime.now();
    req.lastCancelReason = null;
    req.lastCancelledBy = null;
    req.lastCancelledAt = null;
    notifyListeners();
  }

  void acceptQuote(String quoteId) => clientAcceptQuote(quoteId);

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
    req.matchedAt = null;
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
    req.agreedPaymentAmount = null;
    req.agreedPaymentAmountSetAt = null;
    notifyListeners();
    return true;
  }

  bool clientDeleteRequest(String requestId) {
    if (AppSession.instance.currentRole != AppRole.client) {
      throw StateError('Only the Client UI can delete a request.');
    }
    final req = requestFor(requestId);
    if (req == null || req.paymentCompleted) return false;
    _requests.removeWhere((r) => r.id == requestId);
    _allQuotes.removeWhere((q) => q.requestId == requestId);
    ChatStore.instance.clearChat(requestId);
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------
  // Mechanic-facing API — accept / quote
  // ---------------------------------------------------------------------

  List<HelpRequest> get availableJobs =>
      _requests.where((r) => r.status == RequestStatus.pending).toList();

  bool mechanicHasQuoted(String requestId, String mechanicName) =>
      _allQuotes.any((q) => q.requestId == requestId && q.mechanicName == mechanicName);

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
    if (mechanicHasQuoted(requestId, mechanicName)) {
      throw StateError('You have already sent a quote for this job.');
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

  /// Emergency only: first mechanic to call this wins. Note the [price]
  /// passed in is NOT shown to anyone as a final price anymore — Emergency
  /// jobs skip quoting entirely and the real price is set later via
  /// [mechanicSetPaymentAmount] once the mechanic and client agree in
  /// person. This kept-around price only exists for internal bookkeeping
  /// on the MechanicQuote record (eta/rating still matter for display).
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
    req.matchedAt = DateTime.now();
    req.lastCancelReason = null;
    req.lastCancelledBy = null;
    req.lastCancelledAt = null;
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

  List<HelpRequest> matchedJobsFor(String mechanicName) => _requests
      .where((r) =>
          r.status == RequestStatus.matched &&
          acceptedQuoteFor(r.id)?.mechanicName == mechanicName)
      .toList();

  List<HelpRequest> completedJobsFor(String mechanicName) => _requests
      .where((r) =>
          r.status == RequestStatus.completed &&
          acceptedQuoteFor(r.id)?.mechanicName == mechanicName)
      .toList();

  // ---------------------------------------------------------------------
  // Service-status workflow
  // ---------------------------------------------------------------------

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

  void mechanicMarkEnRoute(String requestId) {
    final req = requestFor(requestId);
    if (req == null || req.enRoute || req.status != RequestStatus.matched) return;
    req.enRoute = true;
    req.enRouteAt = DateTime.now();
    notifyListeners();
  }

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

  /// MECHANIC action only. Sets (or updates) the price the mechanic and
  /// client actually agreed on — REQUIRED before a payment code can be
  /// generated. Calling this again after a code was already shared is how
  /// the mechanic "asks for a new code" when the client disagrees with the
  /// first price: the QR/copy-code on MechanicActiveJobScreen always
  /// reflects whatever this was most recently set to.
  bool mechanicSetPaymentAmount(String requestId, double amount) {
    if (AppSession.instance.currentRole != AppRole.mechanic) {
      throw StateError('Only the Mechanic UI can set the payment amount.');
    }
    if (amount <= 0) return false;
    final req = requestFor(requestId);
    if (req == null || req.paymentCompleted) return false;
    req.agreedPaymentAmount = amount;
    req.agreedPaymentAmountSetAt = DateTime.now();
    notifyListeners();
    return true;
  }

  bool mechanicCancelJob(String requestId, String reason) {
    if (AppSession.instance.currentRole != AppRole.mechanic) {
      throw StateError('Only the Mechanic UI can cancel a job.');
    }
    final req = requestFor(requestId);
    if (req == null || req.status != RequestStatus.matched) return false;
    if (req.isEmergency || req.navigating) return false;

    final mechanicName = acceptedQuoteFor(requestId)?.mechanicName;

    for (final q in quotesForRequest(requestId)) {
      q.accepted = false;
    }
    req.status = RequestStatus.pending;
    req.matchedAt = null;
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
    req.agreedPaymentAmount = null;
    req.agreedPaymentAmountSetAt = null;
    req.lastCancelReason = reason;
    req.lastCancelledBy = mechanicName;
    req.lastCancelledAt = DateTime.now();

    ChatStore.instance.clearChat(requestId);

    notifyListeners();
    return true;
  }

  /// CLIENT action only — the ONLY way payment (and therefore the job) can
  /// ever be marked complete. The amount charged is whatever the mechanic
  /// most recently set via [mechanicSetPaymentAmount] — falling back to
  /// the original quote price only if that was somehow never set (should
  /// only happen for old data; the UI now requires it before any code
  /// exists to scan/enter in the first place).
  int? clientConfirmPayment(String requestId) {
    if (AppSession.instance.currentRole != AppRole.client) {
      throw StateError('Only the Client UI can confirm a payment.');
    }
    final req = requestFor(requestId);
    if (req == null) return null;
    if (!req.serviceCompleted) return null;
    if (req.paymentCompleted) return null;

    final quote = acceptedQuoteFor(requestId);
    final amount = req.agreedPaymentAmount ?? (quote == null ? 0.0 : parsePesoAmount(quote.price));
    final points = (amount * 0.05).round();

    req.paymentCompleted = true;
    req.paymentCompletedAt = DateTime.now();
    req.pointsAwarded = points;
    req.status = RequestStatus.completed;
    req.completedAt = req.paymentCompletedAt;

    ChatStore.instance.clearChat(requestId);

    notifyListeners();
    return points;
  }

  // ---------------------------------------------------------------------
  // Mechanic financials
  // ---------------------------------------------------------------------

  double totalEarningsFor(String mechanicName) {
    double sum = 0;
    for (final req in completedJobsFor(mechanicName)) {
      final quote = acceptedQuoteFor(req.id);
      sum += req.agreedPaymentAmount ?? (quote == null ? 0.0 : parsePesoAmount(quote.price));
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
    _seenMechanicQuoteIds.clear();
    _seenClientQuoteIds.clear();
    notifyListeners();
  }
}