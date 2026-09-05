import 'package:flutter/foundation.dart';
import 'admin_data.dart';
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

/// Dispatch order for urgency — Emergency first, then Urgent, then Normal.
/// The one ordering rule; anything that sorts by urgency goes through this.
int urgencyPriority(String urgency) {
  switch (urgency) {
    case 'Emergency':
      return 0;
    case 'Urgent':
      return 1;
    default:
      return 2;
  }
}

/// How long a mechanic has to COMPLETE a job, counted from the moment they
/// accepted it. These are the job's actual deadlines — there is no separate
/// "start" timer — and they are the single source of truth for the Accepted
/// tab's countdown, the "Time Remaining" sort and the auto-expiry sweep.
/// Change a window here and all three follow.
const Map<String, Duration> jobCompletionWindows = {
  'Emergency': Duration(hours: 12),
  'Urgent': Duration(days: 3),
  'Normal': Duration(days: 5),
};

/// The completion promise for an urgency, in words — "Completed within 12
/// hours" / "3 days" / "5 days". Read straight off [jobCompletionWindows], so
/// the Urgency Level picker the client chooses from and the deadline their
/// job is actually held to can never drift apart.
String completionWindowLabel(String urgency) {
  final window = jobCompletionWindows[urgency] ?? jobCompletionWindows['Normal']!;
  if (window.inHours < 24) {
    return 'Completed within ${window.inHours} hour${window.inHours == 1 ? '' : 's'}';
  }
  final days = window.inDays;
  return 'Completed within $days day${days == 1 ? '' : 's'}';
}

/// How a remaining-time value reads on screen, switching format at the 24h
/// mark: 24h or more counts days, hours and minutes ("4d 23h 59m",
/// "2d 06h 15m", and "1d 00h 00m" at exactly a day); under 24h it ticks down
/// to the second ("23h 59m 59s" → "1h 5m 20s" → "0h 0m 0s"). Lives here, with
/// the deadlines themselves, so every screen shows one countdown format.
String formatTimeRemaining(Duration remaining) {
  if (remaining >= const Duration(hours: 24)) {
    final hours = (remaining.inHours % 24).toString().padLeft(2, '0');
    final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
    return '${remaining.inDays}d ${hours}h ${minutes}m';
  }
  return '${remaining.inHours}h ${remaining.inMinutes % 60}m ${remaining.inSeconds % 60}s';
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
  /// What this job's urgency promises the client, in words. Derived rather
  /// than stored so it always matches [completionWindow] — the deadline the
  /// job is really held to.
  String get durationLabel => completionWindowLabel(urgency);

  /// ONGO's priority fee for this job's urgency — 0 for Normal, 50 for
  /// Urgent, 100 for Emergency. This is PLATFORM revenue, not part of the
  /// job price: the client pays it on top of the mechanic's amount at
  /// checkout, and it never reaches the mechanic's payout. See
  /// [clientTotalPaymentAmount].
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

  /// Set when an accepted job was handed back to the pool because the
  /// mechanic didn't finish it inside [completionWindow] — see
  /// [QuoteNotificationStore.expireOverdueJobs]. This is what the client's
  /// Jobs screen reads to tell them the mechanic ran out of time.
  /// Cleared the moment the client accepts a new quote.
  DateTime? expiredAt;
  String? expiredByMechanic;

  /// EMERGENCY ONLY. Normal/Urgent jobs already have a firm price from the
  /// mechanic's quote (sent and accepted before the job started) — that
  /// price never changes and is never negotiated in-app, so this field
  /// stays null for them. Emergency jobs skip quoting entirely, so this is
  /// how the mechanic sets (and can update) the price once they and the
  /// client agree on one in person. See [effectivePaymentAmount] for the
  /// single rule both charging and display always follow.
  double? agreedPaymentAmount;
  DateTime? agreedPaymentAmountSetAt;

  /// The priority fee actually booked as ONGO revenue for this job. Stays
  /// null until the client pays — [QuoteNotificationStore.clientConfirmPayment]
  /// sets it at the same moment it hands the fee to
  /// [AdminStore.recordCompletedPayment], so it doubles as the record of
  /// "this job's fee has already been counted".
  double? platformFeeCharged;

  HelpRequest({
    required this.id,
    required this.problem,
    required this.location,
    required this.urgency,
    required this.photoPaths,
    required this.createdAt,
    this.clientName = 'Client',
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
    this.expiredAt,
    this.expiredByMechanic,
    this.agreedPaymentAmount,
    this.agreedPaymentAmountSetAt,
    this.platformFeeCharged,
  });

  bool get isEmergency => urgency == 'Emergency';
  bool get hasClientCoordinates => clientLat != null && clientLng != null;

  /// The ONGO priority fee for this job, as an amount. Charged to the client
  /// at checkout only — never added to what the mechanic is paid.
  double get platformFee => surcharge.toDouble();

  /// How long this job's mechanic has to finish it, from the urgency the
  /// client chose. See [jobCompletionWindows].
  Duration get completionWindow => jobCompletionWindows[urgency] ?? jobCompletionWindows['Normal']!;

  /// The moment this job must be finished by, anchored to [matchedAt] — the
  /// instant the mechanic accepted. Because it is derived from that stored
  /// timestamp rather than from when a widget was built, the countdown keeps
  /// running across rebuilds, navigation and reopening the app instead of
  /// restarting.
  DateTime? get completionDeadline => matchedAt?.add(completionWindow);

  /// Time left, never negative. Null when no deadline is running: the job
  /// isn't accepted, or the mechanic has reached Work in Progress — once they
  /// are actually working on it the clock stops for good, and with it the
  /// expiry, because [deadlinePassed] and every countdown on screen read this
  /// one method.
  Duration? timeRemaining([DateTime? now]) {
    final deadline = completionDeadline;
    if (deadline == null || workStarted || serviceCompleted || status != RequestStatus.matched) {
      return null;
    }
    final left = deadline.difference(now ?? DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Accepted, not yet under way, and out of time —
  /// [QuoteNotificationStore.expireOverdueJobs] is what acts on this.
  bool deadlinePassed([DateTime? now]) {
    final remaining = timeRemaining(now);
    return remaining != null && remaining == Duration.zero;
  }
}

/// THE single rule for "how much does this job actually cost" — every
/// screen and every calculation (QR generation, payment confirmation,
/// earnings totals, card displays) goes through this and NOTHING computes
/// its own version of this logic separately:
///   - Emergency: whatever the mechanic most recently set via
///     mechanicSetPaymentAmount — null until they set one.
///   - Normal/Urgent: the accepted quote's price, always. Never negotiable,
///     never overridden — the client already agreed to this exact number
///     when they accepted the quote.
double? effectivePaymentAmount(HelpRequest request, MechanicQuote? acceptedQuote) {
  if (request.isEmergency) return request.agreedPaymentAmount;
  return acceptedQuote == null ? null : parsePesoAmount(acceptedQuote.price);
}

/// What the CLIENT is charged at checkout: the mechanic's amount
/// ([effectivePaymentAmount]) plus ONGO's priority fee for the job's urgency
/// (+₱50 Urgent, +₱100 Emergency). The two halves stay apart on purpose — the
/// mechanic is paid [effectivePaymentAmount] and nothing more, while the fee
/// is booked as platform revenue by [QuoteNotificationStore.clientConfirmPayment].
/// Null whenever the mechanic's amount isn't known yet.
double? clientTotalPaymentAmount(HelpRequest request, MechanicQuote? acceptedQuote) {
  final mechanicAmount = effectivePaymentAmount(request, acceptedQuote);
  return mechanicAmount == null ? null : mechanicAmount + request.platformFee;
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
    // A fresh acceptance restarts the completion clock and clears any notice
    // about the previous mechanic running out of time.
    req.expiredAt = null;
    req.expiredByMechanic = null;
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
    req.expiredAt = null;
    req.expiredByMechanic = null;
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

  /// EMERGENCY-ONLY. Sets (or updates) the price the mechanic and client
  /// agreed on in person — refuses outright for Normal/Urgent jobs, which
  /// always use their quote price and never go through this negotiation
  /// step at all. See [effectivePaymentAmount] for the full rule.
  bool mechanicSetPaymentAmount(String requestId, double amount) {
    if (AppSession.instance.currentRole != AppRole.mechanic) {
      throw StateError('Only the Mechanic UI can set the payment amount.');
    }
    final req = requestFor(requestId);
    if (req == null || req.paymentCompleted) return false;
    if (!req.isEmergency) {
      throw StateError('Normal and Urgent jobs use their quoted price — only Emergency jobs need a payment amount set.');
    }
    if (amount <= 0) return false;
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

    // Chat intentionally NOT cleared — the job reverts to Pending (still
    // visible, still chattable there), not removed. See clientDeleteRequest
    // for the one action that actually clears chat.

    notifyListeners();
    return true;
  }

  /// AUTOMATIC — no role gate, because nobody performs this: it is the clock
  /// running out. Every job still unfinished at its
  /// [HelpRequest.completionDeadline] goes back to Pending, so it leaves the
  /// mechanic's Accepted list and is open to mechanics again, and is stamped
  /// [HelpRequest.expiredAt] / [HelpRequest.expiredByMechanic] so the client's
  /// Jobs screen can tell them the mechanic ran out of time. A job the
  /// mechanic has actually started (Work in Progress onwards) is never
  /// touched — the countdown that drives this stops the moment work begins,
  /// so there is no expiry running behind the hidden timer.
  ///
  /// Safe to call as often as you like — a job it has already dealt with is
  /// no longer `matched`, so it is skipped. Returns how many expired, and
  /// only notifies when something actually did.
  int expireOverdueJobs([DateTime? now]) {
    var expired = 0;
    for (final req in _requests) {
      if (_expireIfOverdue(req, now)) expired++;
    }
    if (expired > 0) notifyListeners();
    return expired;
  }

  bool _expireIfOverdue(HelpRequest req, [DateTime? now]) {
    if (!req.deadlinePassed(now)) return false;

    final mechanicName = acceptedQuoteFor(req.id)?.mechanicName;

    if (req.isEmergency) {
      // An emergency "quote" is just the accept record (there is no quoting
      // step), so it goes with the mechanic who let the window lapse —
      // otherwise the client would be offered it as a real quote to accept.
      _allQuotes.removeWhere((q) => q.requestId == req.id && q.mechanicName == mechanicName);
    } else {
      for (final q in quotesForRequest(req.id)) {
        q.accepted = false;
      }
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

    final at = now ?? DateTime.now();
    req.expiredAt = at;
    req.expiredByMechanic = mechanicName;
    req.lastCancelReason = 'Did not complete the job within the allowed time.';
    req.lastCancelledBy = mechanicName;
    req.lastCancelledAt = at;

    // Chat intentionally NOT cleared — the request is still alive and still
    // chattable, exactly as after mechanicCancelJob.
    return true;
  }

  /// CLIENT action only — the ONLY way payment (and therefore the job) can
  /// ever be marked complete. The client is charged
  /// [clientTotalPaymentAmount] — never anything parsed from a scanned or
  /// pasted code, which could be stale.
  ///
  /// The split is settled here and only here: the mechanic's
  /// [effectivePaymentAmount] drives their payout and the client's loyalty
  /// points exactly as before, and the job's priority fee goes to
  /// [AdminStore.recordCompletedPayment] as ONGO revenue. A job can only be
  /// paid once (the paymentCompleted guard below), so the payment can never
  /// be booked twice.
  int? clientConfirmPayment(String requestId) {
    if (AppSession.instance.currentRole != AppRole.client) {
      throw StateError('Only the Client UI can confirm a payment.');
    }
    final req = requestFor(requestId);
    if (req == null) return null;
    if (!req.serviceCompleted) return null;
    if (req.paymentCompleted) return null;

    final quote = acceptedQuoteFor(requestId);
    final amount = effectivePaymentAmount(req, quote);
    if (amount == null) return null;

    // Points stay based on the mechanic's amount — the priority fee is
    // ONGO's cut, not part of the service the client earns points on.
    final points = (amount * 0.05).round();

    req.paymentCompleted = true;
    req.paymentCompletedAt = DateTime.now();
    req.pointsAwarded = points;
    req.status = RequestStatus.completed;
    req.completedAt = req.paymentCompletedAt;

    final fee = req.platformFee;
    if (fee > 0) req.platformFeeCharged = fee;
    // Every successful payment is booked, fee or no fee: the fee is ONGO's
    // revenue, and the payment itself is one Admin transaction either way.
    AdminStore.instance.recordCompletedPayment(platformFee: fee, at: req.paymentCompletedAt);

    // Chat intentionally NOT cleared — see clientDeleteRequest.

    notifyListeners();
    return points;
  }

  // ---------------------------------------------------------------------
  // Mechanic financials
  // ---------------------------------------------------------------------

  /// The mechanic's payout — [effectivePaymentAmount] only. Priority fees are
  /// deliberately excluded: they are ONGO revenue and were never part of what
  /// the mechanic quoted or agreed to.
  double totalEarningsFor(String mechanicName) {
    double sum = 0;
    for (final req in completedJobsFor(mechanicName)) {
      final quote = acceptedQuoteFor(req.id);
      sum += effectivePaymentAmount(req, quote) ?? 0;
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