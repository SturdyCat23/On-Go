import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
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
          final store = QuoteNotificationStore.instance;
          final pending = store.myPendingRequests;

          if (pending.isEmpty) {
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

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Quotes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${pending.length} request${pending.length == 1 ? '' : 's'} awaiting your decision',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 16),
              ...pending.map((request) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _RequestQuoteCard(request: request, store: store),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _ProblemText {
  final String issue;
  final String description;
  const _ProblemText(this.issue, this.description);
}

_ProblemText _splitProblem(String problem) {
  final idx = problem.indexOf(':');
  if (idx == -1 || idx > 40) return _ProblemText('Reported Issue', problem);
  final rest = problem.substring(idx + 1).trim();
  return _ProblemText(problem.substring(0, idx).trim(), rest.isEmpty ? problem : rest);
}

Color _urgencyColor(String urgency) {
  switch (urgency) {
    case 'Emergency':
      return AppColors.primary;
    case 'Urgent':
      return AppColors.yellow;
    default:
      return AppColors.green;
  }
}

class _RequestQuoteCard extends StatelessWidget {
  final HelpRequest request;
  final QuoteNotificationStore store;

  const _RequestQuoteCard({required this.request, required this.store});

  @override
  Widget build(BuildContext context) {
    final problem = _splitProblem(request.problem);
    final urgencyColor = _urgencyColor(request.urgency);
    final quotes = store.quotesForRequest(request.id);
    final hasAccepted = quotes.any((q) => q.accepted);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: urgencyColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(request.urgency, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: urgencyColor)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          if (quotes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                request.isEmergency ? 'Waiting for a mechanic to accept this emergency.' : 'Waiting for mechanics to send quotes...',
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            )
          else ...[
            const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Mechanic',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
                Expanded(
                    flex: 2,
                    child:
                        Text('Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
                Expanded(
                    flex: 2,
                    child: Text('ETA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
                Expanded(
                    flex: 2,
                    child: Text('Rating',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textGrey))),
                SizedBox(width: 74),
              ],
            ),
            const Divider(height: 16),
            ...quotes.map((q) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(q.mechanicName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
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
                        width: 74,
                        child: q.accepted
                            ? const Text('Accepted',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green))
                            : ElevatedButton(
                                onPressed: hasAccepted ? null : () => store.clientAcceptQuote(q.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: const StadiumBorder(),
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(70, 32),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                child: const Text('Accept'),
                              ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}