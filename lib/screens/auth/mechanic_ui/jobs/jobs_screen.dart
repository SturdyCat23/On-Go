import 'package:flutter/material.dart';
import '../../../../data/mechanic_account_store.dart';
import '../../../../data/moderator_data.dart';
import '../../../../data/quote_store.dart';
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

  String get _mechanicName => QuoteNotificationStore.currentMechanicName;

  @override
  void initState() {
    super.initState();
    MechanicAccountStore.instance.addListener(_onAccountChange);
    _wasApproved = MechanicAccountStore.instance.canPerformJobActions;
  }

  @override
  void dispose() {
    MechanicAccountStore.instance.removeListener(_onAccountChange);
    super.dispose();
  }

  void _onAccountChange() {
    final account = MechanicAccountStore.instance;
    final nowApproved = account.canPerformJobActions;
    if (nowApproved && _wasApproved == false && !account.isDemo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your mechanic account has been approved. You can now send quotes and accept jobs.')),
        );
      });
    }
    _wasApproved = nowApproved;
  }

  Future<void> _sendQuote(HelpRequest request) async {
    if (!MechanicAccountStore.instance.canPerformJobActions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account must be approved before you can send quotes.')),
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
        // Todo: pull this mechanic's real rating from their profile.
        rating: 4.8,
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote sent — the client will compare offers and choose.')),
    );
  }

  Future<void> _acceptEmergency(HelpRequest request) async {
    if (!MechanicAccountStore.instance.canPerformJobActions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account must be approved before you can accept jobs.')),
      );
      return;
    }

    final store = QuoteNotificationStore.instance;

    if (store.mechanicHasActiveEmergency(_mechanicName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish your current emergency job before accepting another.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
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
      // Todo: pull a real emergency callout rate from the mechanic's profile.
      price: '₱200',
      eta: '15 mins',
      rating: 4.8,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(won
            ? 'Job accepted! Head to the client now.'
            : 'Too late — another mechanic already took this emergency.'),
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
              child: const Text('Cancel Job', style: TextStyle(color: AppColors.primary)),
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
        SnackBar(content: Text(ok ? 'Job cancelled — the client has been notified.' : 'Could not cancel this job.')),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([QuoteNotificationStore.instance, MechanicAccountStore.instance]),
      builder: (context, _) {
        final store = QuoteNotificationStore.instance;
        final account = MechanicAccountStore.instance;
        final canAct = account.canPerformJobActions;

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
              onChanged: (i) => setState(() => _tabIndex = i),
              counts: [available.length, accepted.length, emergency.length],
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
                  _AcceptedTab(
                    requests: accepted,
                    store: store,
                    onOpen: _openActiveJob,
                    onCancel: (r) {
                      _cancelAccepted(r);
                    },
                  ),
                  _EmergencyTab(
                    requests: emergency,
                    onAccept: _acceptEmergency,
                    blocked: hasActiveEmergency,
                    canAct: canAct,
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
        color: AppColors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.science_outlined, size: 14, color: AppColors.blue),
          SizedBox(width: 6),
          Text('DEMO MODE — for testing only', style: TextStyle(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w700)),
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
    final color = rejected ? AppColors.primary : const Color(0xFFB07A00);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (rejected ? AppColors.primary : AppColors.yellow).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (rejected ? AppColors.primary : AppColors.yellow).withValues(alpha: 0.4)),
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
      return AppColors.yellow;
    default:
      return AppColors.green;
  }
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

class _JobTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<int> counts;

  const _JobTabBar({required this.currentIndex, required this.onChanged, required this.counts});

  static const _labels = ['Available', 'Accepted', 'Emergency'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(3, (i) {
          final selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('${_labels[i]} ${counts[i]}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.white : AppColors.textDark)),
              ),
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
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Tip: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.blue)),
            TextSpan(
              text: 'Send competitive quotes to win more jobs! Clients compare multiple mechanics before choosing.',
              style: TextStyle(color: AppColors.blue),
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
            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
            const SizedBox(width: 4),
            const Text('Location', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        ),
        const SizedBox(height: 2),
        Text(location, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
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
          const Icon(Icons.schedule, size: 13, color: AppColors.textGrey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(request.durationLabel, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ),
          if (request.surcharge > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Text('+₱${request.surcharge} rush', style: const TextStyle(fontSize: 10, color: Color(0xFFB07A00), fontWeight: FontWeight.w700)),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No available jobs right now', style: TextStyle(color: AppColors.textGrey)),
            ),
          ),
        ...requests.map((request) {
          final alreadyQuoted = QuoteNotificationStore.instance.mechanicHasQuoted(request.id, mechanicName);
          return _JobCard(
            request: request,
            actionLabel: alreadyQuoted ? 'Quote Sent' : 'Send Quote',
            actionEnabled: canAct && !alreadyQuoted,
            onAction: () => onSendQuote(request),
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
      padding: const EdgeInsets.all(14),
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
                        style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
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
          Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
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
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
                TextSpan(
                  text: blocked
                      ? 'Finish your current emergency job before accepting another one.'
                      : 'Emergencies are first come, first served — once accepted there\'s no backing out, you\'ll need to respond ASAP.',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No emergency jobs right now', style: TextStyle(color: AppColors.textGrey)),
            ),
          ),
        ...requests.map((request) => _JobCard(
              request: request,
              actionLabel: 'Accept',
              actionEnabled: canAct && !blocked,
              onAction: () => onAccept(request),
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Accepted tab
// ---------------------------------------------------------------------

class _AcceptedTab extends StatelessWidget {
  final List<HelpRequest> requests;
  final QuoteNotificationStore store;
  final void Function(HelpRequest) onOpen;
  final void Function(HelpRequest) onCancel;

  const _AcceptedTab({required this.requests, required this.store, required this.onOpen, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('No active jobs', style: TextStyle(color: AppColors.textGrey)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: requests
          .map((r) => _ActiveJobCard(
                request: r,
                quote: store.acceptedQuoteFor(r.id),
                onOpen: () => onOpen(r),
                onCancel: () => onCancel(r),
              ))
          .toList(),
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
    final statusColor = label == 'Awaiting Payment' ? AppColors.primary : AppColors.green;
    final showCancel = !request.isEmergency && !request.navigating;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: request.isEmergency ? AppColors.primary : AppColors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(request.isEmergency ? 'ACTIVE · EMERGENCY' : 'ACTIVE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: request.isEmergency ? AppColors.primary : AppColors.green,
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                _CircleIconButton(icon: Icons.call, color: AppColors.green, onTap: () {}),
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
            Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _LocationBlock(location: request.location)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Payment', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    const SizedBox(height: 2),
                    Text(quote?.price ?? '₱200',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
                  ],
                ),
              ],
            ),
            _DeadlineRow(request: request),
            const SizedBox(height: 14),
            showCancel
                ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onOpen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: AppColors.white,
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
                            foregroundColor: AppColors.white,
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
                        foregroundColor: AppColors.white,
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