import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../theme/app_theme.dart';
import 'package:on_go/services/local_data.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
            final String? raw = barcode?.rawValue ?? barcode?.displayValue;
            if (raw == null) return;
            final scanned = raw;

            // showDialog is async; ensure we don't use context after dispose
            showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('QR Scanned'),
                content: Text('Scanned data:\n$scanned'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark Completed')),
                ],
              ),
              );
              final messenger = ScaffoldMessenger.of(context);
              showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('QR Scanned'),
                content: Text('Scanned data:\n$scanned'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Close')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark Completed')),
                ],
              ),
              ).then((proceed) async {
                if (!mounted) return;
                if (proceed == true) {
                  await LocalData.addCompletedJobFromQr(scanned);
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('Job added and balance updated (simulated)')));
                }
              });
          },
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_2, size: 120, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text("Scan a client's QR code",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'Use this to verify job completion or receive payment.',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Open Scanner'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}