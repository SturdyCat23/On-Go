import 'package:flutter/material.dart';
import '../../../../data/quote_store.dart';
import '../../../../theme/app_theme.dart';

class MechanicNotificationsScreen extends StatelessWidget {
  const MechanicNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Notifications'),
      ),
      body: AnimatedBuilder(
        animation: QuoteNotificationStore.instance,
        builder: (context, _) {
          final notifications = QuoteNotificationStore.instance.mechanicNotifications;

          if (notifications.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_none, size: 48, color: AppColors.textGrey),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Accepted quotes and emergency jobs will appear here once they arrive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final quote = notifications[index];
              final request = QuoteNotificationStore.instance.requestFor(quote.requestId);
              final title = request?.isEmergency == true
                  ? 'Emergency job assigned'
                  : 'Quote accepted by client';
              final subtitle = request?.problem ?? 'A request has been matched.';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderGrey.withValues(alpha: 0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.borderGrey.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mechanic', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                              const SizedBox(height: 4),
                              Text(quote.mechanicName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Price', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                              const SizedBox(height: 4),
                              Text(quote.price, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Chip(
                          label: Text(request?.urgency ?? 'Normal'),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          'ETA ${quote.eta}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
