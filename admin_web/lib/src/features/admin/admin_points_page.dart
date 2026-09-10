import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/console_shell.dart';
import '../../backend/console_backend.dart';
import '../../theme/console_theme.dart';
import '../../widgets/console_widgets.dart';

/// Points Modifier: what a job is worth, in points.
///
/// These are the numbers every calculation on the platform uses. Nothing in
/// the mobile app carries its own copy — a client's reward for finishing a
/// job and a mechanic's for being paid for one are both worked out from what
/// is set here, so changing a figure changes the arithmetic rather than a
/// label describing it.
class AdminPointsPage extends StatefulWidget {
  const AdminPointsPage({super.key});

  @override
  State<AdminPointsPage> createState() => _AdminPointsPageState();
}

class _AdminPointsPageState extends State<AdminPointsPage> {
  /// Subscribed here rather than through a `StreamBuilder` in [build] — see
  /// `AdminAuditPage` for why a page under [ConsoleShell] must own its
  /// subscription.
  StreamSubscription<PointsPolicy>? _subscription;

  PointsPolicy _saved = PointsPolicy.defaults;

  /// One controller per rate, so the admin can type freely and the page only
  /// disagrees with storage while there are unsaved edits.
  final Map<String, TextEditingController> _clientRates = {
    for (final urgency in PointsPolicy.urgencies) urgency: TextEditingController(),
  };
  final _mechanicRate = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription =
        ConsoleBackend.instance.pointsPolicy.watch().listen((policy) {
      if (!mounted) return;
      setState(() {
        _saved = policy;
        _fillFrom(policy);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    for (final controller in _clientRates.values) {
      controller.dispose();
    }
    _mechanicRate.dispose();
    super.dispose();
  }

  void _fillFrom(PointsPolicy policy) {
    for (final urgency in PointsPolicy.urgencies) {
      _clientRates[urgency]!.text = formatPoints(policy.clientPointsFor(urgency));
    }
    _mechanicRate.text = formatPoints(policy.mechanicPerPeso);
  }

  /// The policy the fields currently describe, or null when one will not
  /// parse — which is what stops a typo being saved as zero.
  PointsPolicy? get _edited {
    var next = _saved;
    for (final urgency in PointsPolicy.urgencies) {
      final value = double.tryParse(_clientRates[urgency]!.text.trim());
      if (value == null || value < 0) return null;
      next = next.withClientRate(urgency, value);
    }
    final mechanic = double.tryParse(_mechanicRate.text.trim());
    if (mechanic == null || mechanic < 0) return null;
    return next.copyWith(mechanicPerPeso: mechanic);
  }

  bool get _dirty {
    final edited = _edited;
    return edited == null || edited != _saved;
  }

  Future<void> _save() async {
    final edited = _edited;
    if (edited == null) {
      setState(() => _error = 'Every rate must be a number, and none can be negative.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ConsoleBackend.instance.pointsPolicy.update(edited);
      if (mounted) showConsoleMessage(context, 'Points rules updated');
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetToDefaults() {
    setState(() {
      _error = null;
      _fillFrom(PointsPolicy.defaults);
    });
  }

  void _revert() {
    setState(() {
      _error = null;
      _fillFrom(_saved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final edited = _edited;

    return ConsoleShell(
      child: Builder(
        builder: (context) => ListView(
          padding: consolePagePadding(context),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.layout.formMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConsoleCard(
                    title: 'What clients earn',
                    subtitle:
                        'Awarded once the client completes payment for a job',
                    child: Column(
                      children: [
                        for (final urgency in PointsPolicy.urgencies)
                          _RateField(
                            label: '$urgency job',
                            helper: 'Points per completed $urgency job',
                            suffix: 'pts',
                            controller: _clientRates[urgency]!,
                            onChanged: () => setState(() => _error = null),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.layout.sectionSpacing),
                  ConsoleCard(
                    title: 'What mechanics earn',
                    subtitle: 'Awarded on the amount a mechanic is actually paid',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RateField(
                          label: 'Points per ₱1 paid out',
                          helper: 'A ₱1000 job earns '
                              '${edited == null ? '—' : formatPointsLabel(edited.mechanicPointsFor(1000))}',
                          suffix: 'pts / ₱1',
                          controller: _mechanicRate,
                          onChanged: () => setState(() => _error = null),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.layout.sectionSpacing),
                  ConsoleCard(
                    title: 'What a point is worth',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 17, color: ConsoleColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '1 pt = ${formatPesos(pesosPerPoint)}. Clients spend points on '
                            'priority fees; mechanics convert them to balance at the same rate.',
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: context.layout.sectionSpacing),
                    Text(_error!,
                        style: text.bodySmall?.copyWith(color: ConsoleColors.danger)),
                  ],
                  SizedBox(height: context.layout.sectionSpacing),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: _busy || !_dirty ? null : _save,
                        child: Text(_busy ? 'Saving…' : 'Save changes'),
                      ),
                      OutlinedButton(
                        onPressed: _busy || !_dirty ? null : _revert,
                        child: const Text('Discard changes'),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _resetToDefaults,
                        child: const Text('Reset to defaults'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One editable rate.
class _RateField extends StatelessWidget {
  const _RateField({
    required this.label,
    required this.helper,
    required this.suffix,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String helper;
  final String suffix;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          suffixText: suffix,
        ),
      ),
    );
  }
}
