import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
// Todo: adjust this path to wherever quote_store.dart lives in your project
import '../../../../data/quote_store.dart';

class MechanicActiveJobScreen extends StatefulWidget {
  final String requestId;
  const MechanicActiveJobScreen({super.key, required this.requestId});

  @override
  State<MechanicActiveJobScreen> createState() => _MechanicActiveJobScreenState();
}

class _MechanicActiveJobScreenState extends State<MechanicActiveJobScreen> {
  final _store = QuoteNotificationStore.instance;
  StreamSubscription<Position>? _positionSub;
  double? _initialDistance;
  String? _trackingError;

  static const _arrivalRadiusMeters = 100.0;
  static const _movementThresholdMeters = 20.0;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
    _startTracking();
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    _positionSub?.cancel();
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _startTracking() async {
    final request = _store.requestFor(widget.requestId);
    if (request == null || request.arrived) return;

    // No GPS coordinates on this request (client typed a freeform address
    // instead of using "Use Current Location") — nothing to auto-detect
    // against. The UI falls back to a manual "Confirm Arrival" control.
    if (!request.hasClientCoordinates) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _trackingError = 'Location services are off.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _trackingError = 'Location permission denied — arrival must be confirmed manually.');
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((pos) => _handlePosition(request, pos));
    } catch (e) {
      setState(() => _trackingError = 'Could not start location tracking — arrival must be confirmed manually.');
    }
  }

  void _handlePosition(HelpRequest request, Position pos) {
    final distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, request.clientLat!, request.clientLng!);
    _initialDistance ??= distance;

    if (!request.enRoute && distance < _initialDistance! - _movementThresholdMeters) {
      _store.mechanicMarkEnRoute(request.id);
    }
    if (!request.arrived && distance <= _arrivalRadiusMeters) {
      _store.mechanicMarkArrived(request.id);
      _positionSub?.cancel();
    }
  }

  /// Fallback only used when the request has no GPS coordinates to compare
  /// against — see [_startTracking].
  void _confirmArrivalManually(HelpRequest request) {
    _store.mechanicMarkEnRoute(request.id);
    _store.mechanicMarkArrived(request.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Active Job'),
      ),
      body: Builder(
        builder: (context) {
          final request = _store.requestFor(widget.requestId);
          if (request == null) {
            return const Center(child: Text('This job is no longer active.', style: TextStyle(color: AppColors.textGrey)));
          }
          final quote = _store.acceptedQuoteFor(widget.requestId);

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
                            request.arrived ? "You've arrived" : (request.enRoute ? 'Heading to client' : 'Ready to head out'),
                            style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          if (_trackingError != null) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(_trackingError!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 11)),
                            ),
                          ],
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
                                      Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
                                  const _InfoColumn(label: 'Location', value: 'Client'),
                                  const _VerticalDivider(),
                                  _InfoColumn(label: 'Quote', value: quote?.price ?? '₱200', valueColor: AppColors.green),
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
                      const SizedBox(height: 16),
                      _buildAction(request, quote),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAction(HelpRequest request, MechanicQuote? quote) {
    if (request.paymentCompleted) {
      return Container(
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
              child: Text(
                'Payment received — ${quote?.price ?? ''} · +${request.pointsAwarded ?? 0} points',
                style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    if (request.serviceCompleted) {
      // Waiting for the CLIENT to pay — the mechanic can only display the
      // QR, never mark this complete themselves.
      final amount = quote == null ? 0.0 : parsePesoAmount(quote.price);
      final qrData = buildPaymentQrData(
        requestId: request.id,
        mechanicName: quote?.mechanicName ?? QuoteNotificationStore.currentMechanicName,
        amount: amount,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: const Text('Waiting for Client Payment',
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB07A00))),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(16)),
            child: QrImageView(data: qrData, size: 200),
          ),
          const SizedBox(height: 10),
          Text('Have the client scan this to pay ${quote?.price ?? ''}',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ],
      );
    }

    if (request.workStarted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _store.mechanicCompleteService(request.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: const StadiumBorder(),
          ),
          child: const Text('Service Complete'),
        ),
      );
    }

    if (request.arrived) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _store.mechanicStartWork(request.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: const StadiumBorder(),
          ),
          child: const Text('Start Work'),
        ),
      );
    }

    if (!request.hasClientCoordinates) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _confirmArrivalManually(request),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textDark,
            side: const BorderSide(color: AppColors.borderGrey),
            minimumSize: const Size(double.infinity, 46),
            shape: const StadiumBorder(),
          ),
          child: const Text('Confirm Arrival'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: const Text(
        'Tracking your location — En Route and Arrived will be detected automatically as you travel.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textGrey, fontSize: 12),
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