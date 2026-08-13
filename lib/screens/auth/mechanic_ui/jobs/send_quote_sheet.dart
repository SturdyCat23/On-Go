import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
// Todo: adjust this path to wherever quote_store.dart lives in your project
import '../../../../data/quote_store.dart';

/// What the mechanic entered on the quote form. Returned by [SendQuoteSheet]
/// so the caller can turn it into a real [MechanicQuote] via
/// `QuoteNotificationStore.instance.mechanicSendQuote(...)`.
class QuoteInput {
  final double labor;
  final double parts;
  final double travel;
  final String estimatedTime;

  const QuoteInput({
    required this.labor,
    required this.parts,
    required this.travel,
    required this.estimatedTime,
  });

  double get total => labor + parts + travel;
}

class SendQuoteSheet extends StatefulWidget {
  final HelpRequest request;
  const SendQuoteSheet({super.key, required this.request});

  @override
  State<SendQuoteSheet> createState() => _SendQuoteSheetState();
}

class _SendQuoteSheetState extends State<SendQuoteSheet> {
  final _laborCtrl = TextEditingController(text: '100');
  final _partsCtrl = TextEditingController(text: '100');
  final _travelCtrl = TextEditingController(text: '100');
  final _timeCtrl = TextEditingController(text: '1 hour');

  double get _total {
    final labor = double.tryParse(_laborCtrl.text) ?? 0;
    final parts = double.tryParse(_partsCtrl.text) ?? 0;
    final travel = double.tryParse(_travelCtrl.text) ?? 0;
    return labor + parts + travel;
  }

  @override
  void dispose() {
    _laborCtrl.dispose();
    _partsCtrl.dispose();
    _travelCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _send() {
    Navigator.pop(
      context,
      QuoteInput(
        labor: double.tryParse(_laborCtrl.text) ?? 0,
        parts: double.tryParse(_partsCtrl.text) ?? 0,
        travel: double.tryParse(_travelCtrl.text) ?? 0,
        estimatedTime: _timeCtrl.text.trim().isEmpty ? '1 hour' : _timeCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send a Quote — ${widget.request.clientName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _QuoteField(label: 'Labor Fee', controller: _laborCtrl, onChanged: (_) => setState(() {})),
            const SizedBox(height: 14),
            _QuoteField(label: 'Parts Needed', controller: _partsCtrl, onChanged: (_) => setState(() {})),
            const SizedBox(height: 14),
            _QuoteField(label: 'Travel Fee', controller: _travelCtrl, onChanged: (_) => setState(() {})),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text('₱${_total.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 14),
            _QuoteField(label: 'Estimated Time', controller: _timeCtrl, keyboardType: TextInputType.text),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Send Quote'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;

  const _QuoteField({
    required this.label,
    required this.controller,
    this.onChanged,
    this.keyboardType = TextInputType.number,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixText: keyboardType == TextInputType.number ? '₱ ' : null,
            isDense: true,
            border: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderGrey)),
          ),
        ),
      ],
    );
  }
}