import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../data/mechanic_account_store.dart';
import '../../../../data/mechanic_settings_store.dart';
import '../../../../services/backend/mobile_backend.dart';
import '../../../../data/quote_store.dart';
import '../../../../data/review_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/chat_icon_button.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../shared/job_chat_screen.dart';
import 'send_quote_sheet.dart';
import 'mechanic_active_job_screen.dart';
import '../../../../widgets/job_photo_preview.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _tabIndex = 0;
  bool? _wasApproved;
  Timer? _ticker;

  String get _mechanicName => QuoteNotificationStore.currentMechanicName;

  @override
  void initState() {
    super.initState();
    MechanicAccountStore.instance.addListener(_onAccountChange);
    _wasApproved = MechanicAccountStore.instance.canPerformJobActions;
    // Drives the Accepted tab's live countdown and hands back any job that
    // ran past its completion deadline. Both read that deadline off the
    // request itself, so the clock is unaffected by this timer starting,
    // stopping or restarting.
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    MechanicAccountStore.instance.removeListener(_onAccountChange);
    super.dispose();
  }

  void _onTick(Timer _) {
    final store = QuoteNotificationStore.instance;
    // Notifies (and so rebuilds) by itself only when something actually
    // expired; the setState below is just for the ticking numbers.
    store.expireOverdueJobs();
    if (!mounted) return;
    final counting = store.matchedJobsFor(_mechanicName).any((r) => r.timeRemaining() != null);
    if (counting) setState(() {});
  }

  /// Opening the Emergency tab is what "viewing the Emergency Jobs list"
  /// means, so that is where the pulse stops.
  void _onTabChanged(int index) {
    if (index == _JobTabBar.emergencyIndex) {
      QuoteNotificationStore.instance.markEmergencyJobsSeen();
    }
    setState(() => _tabIndex = index);
  }

  void _onAccountChange() {
    final account = MechanicAccountStore.instance;
    final nowApproved = account.canPerformJobActions;
    if (nowApproved && _wasApproved == false && !account.isDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your mechanic account has been approved. You can now send quotes and accept jobs.'), duration: AppDurations.snackBar),
        );
      });
    }
    _wasApproved = nowApproved;
  }

  Future<void> _sendQuote(HelpRequest request) async {
    if (!MechanicAccountStore.instance.canPerformJobActions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account must be approved before you can send quotes.'), duration: AppDurations.snackBar),
      );
      return;
    }

    final input = await showModalBottomSheet<QuoteInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SendQuoteSheet(request: request),
    );
    if (input == null) return;

    try {
      QuoteNotificationStore.instance.mechanicSendQuote(
        request.id,
        mechanicName: _mechanicName,
        price: '₱${input.total.toStringAsFixed(0)}',
        eta: input.estimatedTime,
        rating: ReviewStore.instance.averageRatingFor(_mechanicName),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), duration: AppDurations.snackBar));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote sent — the client will compare offers and choose.'), duration: AppDurations.snackBar),
    );
  }

  Future<void> _acceptEmergency(HelpRequest request) async {
    if (!MechanicAccountStore.instance.canPerformJobActions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account must be approved before you can accept jobs.'), duration: AppDurations.snackBar),
      );
      return;
    }

    final store = QuoteNotificationStore.instance;

    if (store.mechanicHasActiveEmergency(_mechanicName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish your current emergency job before accepting another.'), duration: AppDurations.snackBar),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('Emergency Job')),
          ],
        ),
        content: const Text(
          'This is an emergency request. Once accepted, you must head to the client\'s location right away — there\'s no time to spare. Are you ready to respond ASAP?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not Now')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept & Go ASAP'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final won = store.mechanicAcceptEmergency(
      request.id,
      mechanicName: _mechanicName,
      // No price on purpose — an emergency's amount is agreed with the client
      // in person and set via Set Payment Amount, so there is nothing to
      // record here yet.
      eta: '15 mins',
      rating: ReviewStore.instance.averageRatingFor(_mechanicName),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(won
            ? 'Job accepted! Head to the client now.'
            : 'Too late — another mechanic already took this emergency.'),
        duration: AppDurations.snackBar,
      ),
    );
  }

  Future<void> _openActiveJob(HelpRequest request) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MechanicActiveJobScreen(requestId: request.id)),
    );
  }

  Future<void> _cancelAccepted(HelpRequest request) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Cancel this job?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Let ${request.clientName} know why you can\'t continue with this job.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                autofocus: true,
                onChanged: (_) => setDialogState(() {}),
                decoration: const InputDecoration(hintText: 'Reason for cancelling (required)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Job')),
            TextButton(
              onPressed: controller.text.trim().isEmpty ? null : () => Navigator.pop(ctx, controller.text.trim()),
              child: Text('Cancel Job', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;

    try {
      final ok = QuoteNotificationStore.instance.mechanicCancelJob(request.id, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Job cancelled — the client has been notified.' : 'Could not cancel this job.'), duration: AppDurations.snackBar),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), duration: AppDurations.snackBar));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        QuoteNotificationStore.instance,
        MechanicAccountStore.instance,
        MechanicSettingsStore.instance,
      ]),
      builder: (context, _) {
        final store = QuoteNotificationStore.instance;
        final account = MechanicAccountStore.instance;
        final canAct = account.canPerformJobActions;

        // Sitting on the Emergency tab counts as viewing the list, so a job
        // that arrives while it is open is already seen and never pulses.
        // Deferred to after the frame — this notifies, and we are in build.
        if (_tabIndex == _JobTabBar.emergencyIndex && store.hasUnseenEmergencyJobs) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) QuoteNotificationStore.instance.markEmergencyJobsSeen();
          });
        }

        // The toggle wins outright: off means never pulse.
        final pulseEmergency = MechanicSettingsStore.instance.emergencyPulseEnabled &&
            _tabIndex != _JobTabBar.emergencyIndex &&
            store.hasUnseenEmergencyJobs;

        final allAvailable = store.availableJobs;
        final available = allAvailable.where((r) => !r.isEmergency).toList();
        final emergency = allAvailable.where((r) => r.isEmergency).toList();
        final accepted = store.matchedJobsFor(_mechanicName);
        final hasActiveEmergency = store.mechanicHasActiveEmergency(_mechanicName);

        return Column(
          children: [
            if (account.isDemo) const _DemoModeBanner(),
            if (account.isRegistered && account.status != ApprovalStatus.approved)
              _ApprovalBanner(status: account.status),
            _JobTabBar(
              currentIndex: _tabIndex,
              onChanged: _onTabChanged,
              counts: [available.length, emergency.length, accepted.length],
              pulseEmergency: pulseEmergency,
            ),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _AvailableTab(
                    requests: available,
                    canAct: canAct,
                    onSendQuote: _sendQuote,
                  ),
                  _EmergencyTab(
                    requests: emergency,
                    onAccept: _acceptEmergency,
                    blocked: hasActiveEmergency,
                    canAct: canAct,
                  ),
                  _AcceptedTab(
                    requests: accepted,
                    store: store,
                    onOpen: _openActiveJob,
                    onCancel: (r) {
                      _cancelAccepted(r);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Approval / demo banners
// ---------------------------------------------------------------------

class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_outlined, size: 14, color: AppColors.info),
          SizedBox(width: 6),
          // Flexible so the banner shortens rather than overflowing on a
          // narrow screen or at a large system text scale.
          Flexible(
            child: Text(
              'DEMO MODE — for testing only',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalBanner extends StatelessWidget {
  final ApprovalStatus? status;
  const _ApprovalBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final rejected = status == ApprovalStatus.rejected;
    final color = rejected ? AppColors.primary : AppColors.warning;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (rejected ? AppColors.primary : AppColors.warning).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (rejected ? AppColors.primary : AppColors.warning).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(rejected ? Icons.cancel_outlined : Icons.hourglass_top, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rejected
                  ? 'Your mechanic account was rejected. You can browse jobs, but job actions remain locked.'
                  : 'Your mechanic account is awaiting approval. You can browse jobs, but job actions are locked until approval.',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Small display helpers
// ---------------------------------------------------------------------

Color _urgencyColor(String urgency) {
  switch (urgency) {
    case 'Emergency':
      return AppColors.primary;
    case 'Urgent':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}

String _paymentDisplay(HelpRequest request, MechanicQuote? quote) {
  // Once paid this is the recorded amount; before that it is the agreed
  // Emergency price or the accepted quote. Never a fixed fallback figure.
  final amount = settledPaymentAmount(request, quote);
  if (amount != null) return '₱${amount.toStringAsFixed(0)}';
  return request.isEmergency ? 'To be agreed' : 'To be quoted';
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
  if (diff.inHours < 24) return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
  return '${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}/${time.year}';
}

class _ProblemText {
  final String issue;
  final String description;
  const _ProblemText(this.issue, this.description);
}

_ProblemText _splitProblem(String problem) {
  final idx = problem.indexOf(':');
  if (idx == -1 || idx > 40) {
    return _ProblemText('Reported Issue', problem);
  }
  final rest = problem.substring(idx + 1).trim();
  return _ProblemText(problem.substring(0, idx).trim(), rest.isEmpty ? problem : rest);
}

// ---------------------------------------------------------------------
// Tab bar
// ---------------------------------------------------------------------

class _JobTabBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<int> counts;

  /// Whether the Emergency pill should be pulsing right now. The screen works
  /// this out from unviewed emergency jobs AND the mechanic's alert toggle, so
  /// this widget just plays or stops the animation.
  final bool pulseEmergency;

  const _JobTabBar({
    required this.currentIndex,
    required this.onChanged,
    required this.counts,
    this.pulseEmergency = false,
  });

  static const _labels = ['Available', 'Emergency', 'Accepted'];

  /// The index of the Emergency pill in [_labels].
  static const int emergencyIndex = 1;

  @override
  State<_JobTabBar> createState() => _JobTabBarState();
}

class _JobTabBarState extends State<_JobTabBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.pulseEmergency) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _JobTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulseEmergency == oldWidget.pulseEmergency) return;
    if (widget.pulseEmergency) {
      _pulse.repeat(reverse: true);
    } else {
      // Back to the pill's normal, unanimated look.
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// The pill exactly as it has always looked. [glow] is 0 when nothing is
  /// pulsing, which leaves the original decoration untouched.
  Widget _pill(int i, {double glow = 0}) {
    final selected = i == widget.currentIndex;
    return Container(
      margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: selected ? AppColors.primary : AppColors.textdark.withValues(alpha: 0.2)),
        boxShadow: glow == 0
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45 * glow),
                  blurRadius: 14 * glow,
                  spreadRadius: 2 * glow,
                ),
              ],
      ),
      child: Text('${_JobTabBar._labels[i]} ${widget.counts[i]}',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.textlight : AppColors.textmedium)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(3, (i) {
          final pulsing = widget.pulseEmergency && i == _JobTabBar.emergencyIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onChanged(i),
              child: pulsing
                  ? AnimatedBuilder(
                      // Present only while the pill is actually pulsing.
                      key: const ValueKey('emergencyPulse'),
                      animation: _pulse,
                      builder: (context, _) {
                        // Curved so the pill swells and settles rather than
                        // ticking linearly between the two extremes.
                        final t = Curves.easeInOut.transform(_pulse.value);
                        // Transform, not layout — the row never reflows, so
                        // the other two pills stay exactly where they are.
                        return Transform.scale(
                          scale: 1 + 0.05 * t,
                          child: _pill(i, glow: t),
                        );
                      },
                    )
                  : _pill(i),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Tip: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.info)),
            TextSpan(
              text: 'Send competitive quotes to win more jobs! Clients compare multiple mechanics before choosing.',
              style: TextStyle(color: AppColors.info),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  final String location;
  const _LocationBlock({required this.location});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: AppColors.textdark.withValues(alpha: 0.55)),
            const SizedBox(width: 4),
            Text('Location', style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
          ],
        ),
        const SizedBox(height: 2),
        Text(location, style: TextStyle(fontSize: 13, color: AppColors.textdark)),
      ],
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final HelpRequest request;
  const _DeadlineRow({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 13, color: AppColors.textdark.withValues(alpha: 0.55)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(request.durationLabel, style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Available tab (non-emergency, quote-based jobs)
// ---------------------------------------------------------------------

class _AvailableTab extends StatelessWidget {
  final List<HelpRequest> requests;
  final bool canAct;
  final void Function(HelpRequest) onSendQuote;

  const _AvailableTab({
    required this.requests,
    required this.canAct,
    required this.onSendQuote,
  });

  @override
  Widget build(BuildContext context) {
    final mechanicName = QuoteNotificationStore.currentMechanicName;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        const _TipCard(),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No available jobs right now', style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55))),
            ),
          ),
        ...requests.map((request) {
          final alreadyQuoted = QuoteNotificationStore.instance.mechanicHasQuoted(request.id, mechanicName);
          return Padding(
            padding: const EdgeInsets.only(bottom: jobCardSpacing),
            child: _JobCard(
              request: request,
              actionLabel: alreadyQuoted ? 'Quote Sent' : 'Send Quote',
              actionEnabled: canAct && !alreadyQuoted,
              onAction: () => onSendQuote(request),
            ),
          );
        }),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final HelpRequest request;
  final String actionLabel;
  final bool actionEnabled;
  final VoidCallback onAction;

  const _JobCard({
    required this.request,
    required this.actionLabel,
    required this.onAction,
    this.actionEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final problem = _splitProblem(request.problem);
    final urgencyColor = _urgencyColor(request.urgency);

    return AppCard(
      padding: jobCardPadding,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(_timeAgo(request.createdAt),
                        style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: urgencyColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(request.urgency,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: urgencyColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(problem.description, style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                    if (request.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            JobPhotoPreview(photoPaths: request.photoPaths),
          ],
          const SizedBox(height: 10),
          _LocationBlock(location: request.location),
          _DeadlineRow(request: request),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: actionEnabled ? onAction : null,
              style: ElevatedButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Emergency tab
// ---------------------------------------------------------------------

class _EmergencyTab extends StatelessWidget {
  final List<HelpRequest> requests;
  final void Function(HelpRequest) onAccept;
  final bool blocked;
  final bool canAct;

  const _EmergencyTab({required this.requests, required this.onAccept, required this.blocked, required this.canAct});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                    text: blocked ? 'You\'re on a job: ' : 'Heads up: ',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                TextSpan(
                  text: blocked
                      ? 'Finish your current emergency job before accepting another one.'
                      : 'Emergencies are first come, first served — once accepted there\'s no backing out, you\'ll need to respond ASAP.',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No emergency jobs right now', style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55))),
            ),
          ),
        ...requests.map((request) => Padding(
              padding: const EdgeInsets.only(bottom: jobCardSpacing),
              child: _JobCard(
                request: request,
                actionLabel: 'Accept',
                actionEnabled: canAct && !blocked,
                onAction: () => onAccept(request),
              ),
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Accepted tab
// ---------------------------------------------------------------------

/// Sort options for the Accepted list. [urgency] is the default — the order
/// dispatch actually cares about (Emergency → Urgent → Normal).
enum _AcceptedSort { urgency, dateAccepted, timeRemaining }

extension on _AcceptedSort {
  String get label => switch (this) {
        _AcceptedSort.urgency => 'Urgency Level',
        _AcceptedSort.dateAccepted => 'Date Accepted',
        _AcceptedSort.timeRemaining => 'Time Remaining',
      };
}

class _AcceptedTab extends StatefulWidget {
  final List<HelpRequest> requests;
  final QuoteNotificationStore store;
  final void Function(HelpRequest) onOpen;
  final void Function(HelpRequest) onCancel;

  const _AcceptedTab({required this.requests, required this.store, required this.onOpen, required this.onCancel});

  @override
  State<_AcceptedTab> createState() => _AcceptedTabState();
}

class _AcceptedTabState extends State<_AcceptedTab> {
  _AcceptedSort _sort = _AcceptedSort.urgency;
  bool _sortOpen = false;

  static DateTime _acceptedAt(HelpRequest r) => r.matchedAt ?? r.createdAt;

  List<HelpRequest> get _sorted {
    final list = [...widget.requests];
    switch (_sort) {
      case _AcceptedSort.urgency:
        list.sort((a, b) {
          final byUrgency = urgencyPriority(a.urgency).compareTo(urgencyPriority(b.urgency));
          return byUrgency != 0 ? byUrgency : _acceptedAt(b).compareTo(_acceptedAt(a));
        });
      case _AcceptedSort.dateAccepted:
        list.sort((a, b) => _acceptedAt(b).compareTo(_acceptedAt(a)));
      case _AcceptedSort.timeRemaining:
        list.sort((a, b) {
          final left = a.timeRemaining();
          final right = b.timeRemaining();
          // Jobs already under way have no clock left to run, so they sit
          // below the ones still waiting to be started.
          if (left == null && right == null) return _acceptedAt(b).compareTo(_acceptedAt(a));
          if (left == null) return 1;
          if (right == null) return -1;
          return left.compareTo(right);
        });
    }
    return list;
  }

  Widget _sortPill(_AcceptedSort value) {
    final selected = _sort == value;
    return GestureDetector(
      onTap: () => setState(() {
        _sort = value;
        _sortOpen = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.textdark.withValues(alpha: 0.2)),
        ),
        child: Text(value.label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.textmedium : AppColors.textdark)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requests.isEmpty) {
      return Center(child: Text('No active jobs', style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55))));
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Sorted by ${_sort.label}',
                      style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55), fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Sort accepted jobs',
                  onPressed: () => setState(() => _sortOpen = !_sortOpen),
                ),
              ],
            ),
            ..._sorted.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: jobCardSpacing),
                  child: _ActiveJobCard(
                    request: r,
                    quote: widget.store.acceptedQuoteFor(r.id),
                    onOpen: () => widget.onOpen(r),
                    onCancel: () => widget.onCancel(r),
                  ),
                )),
          ],
        ),
        if (_sortOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _sortOpen = false),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: 46,
            right: 16,
            width: 170,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  _sortPill(_AcceptedSort.urgency),
                  _sortPill(_AcceptedSort.dateAccepted),
                  _sortPill(_AcceptedSort.timeRemaining),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

String _mechanicStatusLabel(HelpRequest request) {
  if (!request.navigating) return 'Navigate';
  if (!request.arrived) return 'En Route';
  if (!request.workStarted) return 'Mechanic Arrived';
  if (!request.serviceCompleted) return 'Work in Progress';
  return 'Awaiting Payment';
}

class _ActiveJobCard extends StatelessWidget {
  final HelpRequest request;
  final MechanicQuote? quote;
  final VoidCallback onOpen;
  final VoidCallback onCancel;

  const _ActiveJobCard({required this.request, required this.quote, required this.onOpen, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final problem = _splitProblem(request.problem);
    final label = _mechanicStatusLabel(request);
    final statusColor = label == 'Awaiting Payment' ? AppColors.primary : AppColors.success;
    final showCancel = !request.isEmergency && !request.navigating;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: jobCardPadding,
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: request.isEmergency ? AppColors.primary : AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(request.isEmergency ? 'ACTIVE · EMERGENCY' : 'ACTIVE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: request.isEmergency ? AppColors.primary : AppColors.success,
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                _CircleIconButton(icon: Icons.call, color: AppColors.success, onTap: () {}),
                const SizedBox(width: 8),
                ChatIconButton(
                  requestId: request.id,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => JobChatScreen(requestId: request.id, otherPartyName: request.clientName)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(problem.description, style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _LocationBlock(location: request.location)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Payment', style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
                    const SizedBox(height: 2),
                    Text(_paymentDisplay(request, quote),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                  ],
                ),
              ],
            ),
            // No "Completed within …" line here: once the job is accepted the
            // live countdown below is the only deadline that matters.
            _TimeRemainingRow(request: request),
            const SizedBox(height: 14),
            showCancel
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onOpen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: AppColors.textlight,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(label),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textlight,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onOpen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: AppColors.textlight,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(label),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

/// Live "time left to finish this job" line. The value comes from the
/// request's own completion deadline ([HelpRequest.timeRemaining]) — accept
/// time plus the urgency's window — so it keeps counting down across
/// rebuilds, navigation and app reopens instead of restarting, and is never a
/// stored or hard-coded figure. Renders nothing once the mechanic has reached
/// Work in Progress — at that point [HelpRequest.timeRemaining] stops, which
/// stops the expiry too rather than just hiding it.
class _TimeRemainingRow extends StatelessWidget {
  final HelpRequest request;

  const _TimeRemainingRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final remaining = request.timeRemaining();
    if (remaining == null) return const SizedBox.shrink();

    // Runs hot in the final hour, so a job about to be handed back reads as
    // urgent rather than as just another grey line.
    final color = remaining <= const Duration(hours: 1) ? AppColors.primary : AppColors.textdark.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text('Time Remaining: ${formatTimeRemaining(remaining)}',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}