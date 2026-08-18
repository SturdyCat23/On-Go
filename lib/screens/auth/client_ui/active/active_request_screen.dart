import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
// Todo: adjust this path to wherever quote_store.dart lives in your project
import '../../../../data/quote_store.dart';
import '../profile/mechanic_profile_view_screen.dart';
import 'qr_scan_screen.dart';

class ActiveRequestScreen extends StatefulWidget {
  const ActiveRequestScreen({super.key});

  @override
  State<ActiveRequestScreen> createState() => _ActiveRequestScreenState();
}

class _ActiveRequestScreenState extends State<ActiveRequestScreen> {
  final _store = QuoteNotificationStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendPayment(HelpRequest request) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              title: const Text('Scan QR Code'),
              subtitle: const Text('Use your camera to scan the mechanic\'s code'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: AppColors.primary),
              title: const Text('Upload/Scan QR Image'),
              subtitle: const Text('Pick a photo of the QR code from your gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
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
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final controller = MobileScannerController();
      try {
        // v3's analyzeImage() doesn't return the result directly — the
        // decoded barcode (if any) comes through the barcodes stream, so we
        // listen for it before/while kicking off analysis, with a timeout
        // in case the image has no readable code at all.
        final completer = Completer<BarcodeCapture?>();
        final sub = controller.barcodes.listen((capture) {
          if (!completer.isCompleted) completer.complete(capture);
        });

        await controller.analyzeImage(picked.path);
        final capture = await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        if (capture != null && capture.barcodes.isNotEmpty) {
          raw = capture.barcodes.first.rawValue ?? capture.barcodes.first.displayValue;
        }
        await sub.cancel();
      } finally {
        controller.dispose();
      }

      if (raw == null) {
        _showSnack('No QR code found in that image.');
        return;
      }
    }

    if (raw == null || !mounted) return;

    final payload = parsePaymentQrData(raw);
    if (payload == null || payload.requestId != request.id) {
      _showSnack("That QR code doesn't match this job.");
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay ${payload.mechanicName}', style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
            const SizedBox(height: 8),
            Text('₱${payload.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary)),
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
    final request = _store.activeRequest;
    final quote = request == null ? null : _store.acceptedQuoteFor(request.id);

    if (request == null || request.status == RequestStatus.pending || quote == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No active service request yet.\nUpload a problem from the Need Help tab to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }

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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      request.arrived ? 'Mechanic has arrived' : (request.enRoute ? 'Mechanic is on the way' : 'Mechanic is preparing'),
                      style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(request.durationLabel,
                        style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: -46,
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.background,
                            child: Icon(Icons.person, color: AppColors.textGrey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(quote.mechanicName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(request.urgency, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                          _CircleIconButton(icon: Icons.call, color: AppColors.green, onTap: () {}),
                          const SizedBox(width: 8),
                          _CircleIconButton(icon: Icons.chat_bubble_outline, color: AppColors.blue, onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            _InfoColumn(label: 'ETA', value: quote.eta),
                            const _VerticalDivider(),
                            _InfoColumn(label: 'Rating', value: quote.rating.toStringAsFixed(1)),
                            const _VerticalDivider(),
                            _InfoColumn(label: 'Quote', value: quote.price, valueColor: AppColors.green),
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
                const _StatusStep(title: 'Request Accepted', done: true, isFirst: true),
                _StatusStep(title: 'Mechanic En Route', done: request.enRoute),
                _StatusStep(title: 'Mechanic Arrived', done: request.arrived),
                _StatusStep(title: 'Work in Progress', done: request.workStarted),
                _StatusStep(title: 'Service Complete', done: request.serviceCompleted),
                _StatusStep(title: 'Payment Complete', done: request.paymentCompleted, isLast: true),
                const SizedBox(height: 12),
                if (request.paymentCompleted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Payment complete — ${quote.price} sent to ${quote.mechanicName}.',
                              style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 13)),
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
                  ElevatedButton(
                    onPressed: () => _sendPayment(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Send Payment'),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'Payment unlocks once the mechanic marks the service complete.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      const Text('Need help?', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: const Text('Contact Support',
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
    return Container(width: 1, height: 28, color: AppColors.borderGrey);
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
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor ?? AppColors.textDark)),
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
    final color = done ? AppColors.green : AppColors.borderGrey;
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
                      fontSize: 13, fontWeight: FontWeight.w600, color: done ? AppColors.textDark : AppColors.textGrey)),
            ),
          ),
        ],
      ),
    );
  }
}