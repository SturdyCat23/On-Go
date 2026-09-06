import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../data/quote_store.dart';
import '../../../../theme/app_theme.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  bool _scanning = false;
  MobileScannerController? _controller;

  void _openScanner() {
    setState(() {
      _scanning = true;
      _controller = MobileScannerController();
    });
  }

  void _closeScanner() {
    _controller?.dispose();
    setState(() {
      _scanning = false;
      _controller = null;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final raw = barcode?.rawValue ?? barcode?.displayValue;
    if (raw == null) return;
    _closeScanner();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Code Scanned'),
        content: Text('Scanned data:\n$raw'),
        // Todo: hand this off to whatever real cash-out/transfer flow you
        // integrate — for now this just confirms the scan worked.
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_scanning) {
      return Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned(
            top: 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(icon: Icon(Icons.close, color: AppColors.textmedium), onPressed: _closeScanner),
            ),
          ),
        ],
      );
    }

    final mechanicName = QuoteNotificationStore.currentMechanicName;
    final qrData = buildMechanicAccountQrData(mechanicName);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(data: qrData, size: 200, backgroundColor: AppColors.textlight),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: Text('Open Scanner'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
          ),
        ],
      ),
    );
  }
}