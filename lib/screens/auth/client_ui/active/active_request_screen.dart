import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';

class ActiveRequestScreen extends StatelessWidget {
  const ActiveRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'Mechanic is on the way',
                      style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '20 km away · 30 mins',
                      style: TextStyle(color: AppColors.textDark.withValues(alpha: 0.7), fontSize: 12),
                    ),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Juan Dela Cruz',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text('Service · Gold', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                                    SizedBox(width: 4),
                                    Icon(Icons.military_tech, size: 14, color: AppColors.yellow),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _CircleIconButton(
                              icon: Icons.call, color: AppColors.green, onTap: () {}),
                          const SizedBox(width: 8),
                          _CircleIconButton(
                              icon: Icons.chat_bubble_outline, color: AppColors.blue, onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            _InfoColumn(label: 'ETA', value: '20 mins'),
                            _VerticalDivider(),
                            _InfoColumn(label: 'Distance', value: '20 km'),
                            _VerticalDivider(),
                            _InfoColumn(label: 'Quote', value: '₱200', valueColor: AppColors.green),
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
                const Text('Service Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const _StatusStep(title: 'Request Submitted', time: '1:00 PM', done: true, isFirst: true),
                const _StatusStep(title: 'Mechanic Accepted', time: '1:05 PM', done: true),
                const _StatusStep(title: 'Mechanic En Route', time: '1:10 PM', done: true),
                const _StatusStep(title: 'Mechanic Arrived', time: 'Expected 12:15 PM', done: false),
                const _StatusStep(title: 'Service Complete', time: 'Pending...', done: false, isLast: true),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.my_location, size: 18, color: AppColors.white),
                  label: const Text('Track Mechanic Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: const StadiumBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Send Payment'),
                ),
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
  final String time;
  final bool done;
  final bool isFirst;
  final bool isLast;

  const _StatusStep({
    required this.title,
    required this.time,
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
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: color,
                size: 20,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color.withValues(alpha: 0.4)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: done ? AppColors.textDark : AppColors.textGrey)),
                  Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}