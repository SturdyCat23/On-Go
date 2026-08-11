import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
// Todo: adjust this path to wherever quote_store.dart lives in your project
import '../../../../data/quote_store.dart';

class QuotesScreen extends StatelessWidget {
  const QuotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mark quotes as seen the moment the client opens this screen
    // (clears the badge on the bell icon).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      QuoteNotificationStore.instance.markSeen();
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Quotes'),
      ),
      body: AnimatedBuilder(
        animation: QuoteNotificationStore.instance,
        builder: (context, _) {
          final quotes = QuoteNotificationStore.instance.quotes;
          final hasAccepted = QuoteNotificationStore.instance.hasAcceptedQuote;

          if (quotes.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty, size: 48, color: AppColors.textGrey),
                  const SizedBox(height: 12),
                  const Text(
                    'No quotes yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Upload a problem from the Need Help tab and mechanic quotes will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quotes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Compare offers from mechanics',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text('Mechanic',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
                    Expanded(
                        flex: 2,
                        child: Text('Price',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
                    Expanded(
                        flex: 2,
                        child: Text('ETA',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
                    Expanded(
                        flex: 2,
                        child: Text('Rating',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
                    SizedBox(width: 80),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: quotes.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, i) {
                      final q = quotes[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: Text(q.mechanicName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            Expanded(flex: 2, child: Text(q.price, style: const TextStyle(fontSize: 13))),
                            Expanded(flex: 2, child: Text(q.eta, style: const TextStyle(fontSize: 13))),
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: AppColors.yellow),
                                  const SizedBox(width: 2),
                                  Text(q.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: q.accepted
                                  ? const Text(
                                      'Accepted',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.green),
                                    )
                                  : ElevatedButton(
                                      onPressed: hasAccepted
                                          ? null
                                          : () {
                                              QuoteNotificationStore.instance.acceptQuote(q.id);
                                              Navigator.pop(context, true);
                                            },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(70, 32),
                                        textStyle: const TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                      child: const Text('Accept'),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}