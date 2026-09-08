import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/chat_icon_button.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../data/quote_store.dart';
import '../../../../data/review_store.dart';
import '../../../shared/job_chat_screen.dart';
import '../profile/mechanic_profile_view_screen.dart';
import 'qr_scan_screen.dart';

class ActiveRequestScreen extends StatefulWidget {
  final String requestId;
  const ActiveRequestScreen({super.key, required this.requestId});

  @override
  State<ActiveRequestScreen> createState() => _ActiveRequestScreenState();
}

class _ActiveRequestScreenState extends State<ActiveRequestScreen> {
  final _store = QuoteNotificationStore.instance;
  final _reviews = ReviewStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
    // Keeps the mechanic's rating on this screen live — a review submitted
    // from here (or anywhere else) moves the average immediately.
    _reviews.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    _reviews.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  /// The mechanic's CURRENT rating, read from ReviewStore — the same average
  /// their profile shows — not the snapshot frozen into the quote when it was
  /// sent. Shows '—' until they have a review, exactly as the profile does.
  String _ratingDisplay(String mechanicName) {
    if (_reviews.reviewsFor(mechanicName).isEmpty) return '—';
    return _reviews.averageRatingFor(mechanicName).toStringAsFixed(1);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: AppDurations.snackBar));
  }

  Future<void> _sendPayment(HelpRequest request, MechanicQuote? quote) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.qr_code_scanner, color: AppColors.primary),
              title: const Text('Scan QR Code'),
              subtitle: const Text('Use your camera to scan the mechanic\'s code'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Icon(Icons.content_paste, color: AppColors.primary),
              title: const Text('Paste Payment Code'),
              subtitle: const Text('Paste the code the mechanic sent you'),
              onTap: () => Navigator.pop(ctx, 'manual'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    String? raw;
    if (choice == 'camera') {
      raw = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScanScreen()));
    } else {
      final controller = TextEditingController();
      raw = await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Payment Code'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste the code the mechanic shared with you. It can\'t be typed or edited manually.',
                  style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  readOnly: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'No code pasted yet',
                    suffixIcon: controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setDialogState(() => controller.clear()),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      setDialogState(() => controller.text = data!.text!.trim());
                    }
                  },
                  icon: const Icon(Icons.paste, size: 16),
                  label: const Text('Paste from Clipboard'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: controller.text.trim().isEmpty ? null : () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      );
      if (raw == null || raw.isEmpty) return;
    }

    if (raw == null || !mounted) return;

    final payload = parsePaymentQrData(raw);
    if (payload == null || payload.requestId != request.id) {
      _showSnack("That code doesn't match this job.");
      return;
    }

    // The amount embedded in the scanned/pasted code is never trusted for
    // display or charging. effectivePaymentAmount is the single source of
    // truth for the mechanic's half: for Normal/Urgent it's the fixed quote
    // price; for Emergency it's whatever the mechanic most recently set. The
    // priority fee on top is ONGO's and is charged here, at checkout only.
    final currentRequest = _store.requestFor(request.id);
    final currentQuote = _store.acceptedQuoteFor(request.id);
    final mechanicAmount = currentRequest == null ? null : effectivePaymentAmount(currentRequest, currentQuote);
    if (currentRequest == null || mechanicAmount == null) {
      _showSnack('A payment amount isn\'t available for this job yet.');
      return;
    }
    final platformFee = currentRequest.platformFee;
    final totalAmount = clientTotalPaymentAmount(currentRequest, currentQuote)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay ${payload.mechanicName}', style: TextStyle(fontSize: 14, color: AppColors.textdark.withValues(alpha: 0.55))),
            const SizedBox(height: 8),
            Text('₱${totalAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary)),
            if (platformFee > 0) ...[
              const SizedBox(height: 12),
              _PaymentBreakdownRow(
                  label: 'Mechanic (${payload.mechanicName})', value: '₱${mechanicAmount.toStringAsFixed(0)}'),
              const SizedBox(height: 4),
              _PaymentBreakdownRow(
                  label: '${currentRequest.urgency} priority fee', value: '₱${platformFee.toStringAsFixed(0)}'),
              const SizedBox(height: 6),
              Text('The priority fee is an ONGO service charge and is not paid to the mechanic.',
                  style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm & Pay'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final points = _store.clientConfirmPayment(request.id);
    if (!mounted) return;
    if (points == null) {
      _showSnack('Payment could not be completed.');
    } else {
      _showSnack('Payment sent! ${payload.mechanicName} earned $points points.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _store.requestFor(widget.requestId);
    final quote = request == null ? null : _store.acceptedQuoteFor(request.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textmedium,
        title: const Text('Job Progress'),
      ),
      body: (request == null || quote == null)
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('This job is no longer active.', style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55))),
              ),
            )
          : _buildBody(request, quote),
    );
  }

  Widget _buildBody(HelpRequest request, MechanicQuote quote) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.info.withValues(alpha: 0.22), AppColors.info.withValues(alpha: 0.08)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, color: AppColors.primary, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      request.arrived ? 'Mechanic has arrived' : (request.enRoute ? 'Mechanic is on the way' : 'Mechanic is preparing'),
                      style: TextStyle(color: AppColors.textdark, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(request.durationLabel,
                        style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: -46,
                child: AppCard(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.background,
                            child: Icon(Icons.person, color: AppColors.textdark.withValues(alpha: 0.55)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(quote.mechanicName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(request.urgency, style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                              ],
                            ),
                          ),
                          _CircleIconButton(icon: Icons.call, color: AppColors.success, onTap: () {}),
                          const SizedBox(width: 8),
                          ChatIconButton(
                            requestId: request.id,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => JobChatScreen(requestId: request.id, otherPartyName: quote.mechanicName)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                        child: request.isEmergency
                            ? Row(
                                children: [
                                  _InfoColumn(label: 'ETA', value: quote.eta),
                                  const _VerticalDivider(),
                                  _InfoColumn(label: 'Rating', value: _ratingDisplay(quote.mechanicName)),
                                ],
                              )
                            : Row(
                                children: [
                                  _InfoColumn(label: 'ETA', value: quote.eta),
                                  const _VerticalDivider(),
                                  _InfoColumn(label: 'Rating', value: _ratingDisplay(quote.mechanicName)),
                                  const _VerticalDivider(),
                                  _InfoColumn(label: 'Quote', value: quote.price, valueColor: AppColors.success),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 62, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (request.isEmergency) ...[
                  _StatusStep(title: 'Navigate', done: request.navigating, isFirst: true),
                  _StatusStep(title: 'Mechanic En Route', done: request.enRoute),
                  _StatusStep(title: 'Work in Progress', done: request.workStarted),
                  _StatusStep(title: 'Service Complete', done: request.serviceCompleted),
                  _StatusStep(title: 'Payment Complete', done: request.paymentCompleted, isLast: true),
                ] else ...[
                  const _StatusStep(title: 'Request Accepted', done: true, isFirst: true),
                  _StatusStep(title: 'Navigating', done: request.navigating),
                  _StatusStep(title: 'Mechanic En Route', done: request.enRoute),
                  _StatusStep(title: 'Mechanic Arrived', done: request.arrived),
                  _StatusStep(title: 'Work in Progress', done: request.workStarted),
                  _StatusStep(title: 'Service Complete', done: request.serviceCompleted),
                  _StatusStep(title: 'Payment Complete', done: request.paymentCompleted, isLast: true),
                ],
                const SizedBox(height: 12),
                if (request.paymentCompleted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Payment complete — ₱${(effectivePaymentAmount(request, quote) ?? 0).toStringAsFixed(0)} sent to ${quote.mechanicName}.',
                                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                              if (request.platformFeeCharged != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                    'Plus a ₱${request.platformFeeCharged!.toStringAsFixed(0)} ${request.urgency} priority fee — ONGO service charge.',
                                    style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55), fontSize: 11)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MechanicProfileViewScreen(name: quote.mechanicName)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Write a Review'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 46), shape: const StadiumBorder()),
                  ),
                ] else if (request.serviceCompleted) ...[
                  if (request.isEmergency && request.agreedPaymentAmount == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        'Waiting for the mechanic to set a payment amount. Once they share a code, you can pay here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55), fontSize: 12),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _sendPayment(request, quote),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textlight,
                        minimumSize: const Size(double.infinity, 46),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Send Payment'),
                    ),
                ] else if (request.lastCancelReason != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('${request.lastCancelledBy ?? 'The mechanic'} cancelled this job',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(request.lastCancelReason!, style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.my_location, size: 18, color: AppColors.textlight),
                    label: const Text('Track Mechanic Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textlight,
                      minimumSize: const Size(double.infinity, 46),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text('Need help?', style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: Text('Contact Support',
                            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One "label ............ ₱amount" line in the checkout breakdown, so the
/// client can see exactly which part of the total is the mechanic's and
/// which part is ONGO's priority fee.
class _PaymentBreakdownRow extends StatelessWidget {
  final String label;
  final String value;

  const _PaymentBreakdownRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
        ),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textdark)),
      ],
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

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppColors.textdark.withValues(alpha: 0.2));
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoColumn({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor ?? AppColors.textdark)),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String title;
  final bool done;
  final bool isFirst;
  final bool isLast;

  const _StatusStep({
    required this.title,
    required this.done,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.success : AppColors.textdark.withValues(alpha: 0.2);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 20),
              if (!isLast)
                Expanded(child: Container(width: 2, color: color.withValues(alpha: 0.4))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: done ? AppColors.textdark : AppColors.textdark.withValues(alpha: 0.55))),
            ),
          ),
        ],
      ),
    );
  }
}