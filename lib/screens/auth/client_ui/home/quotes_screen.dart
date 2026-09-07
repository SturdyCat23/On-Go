import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
// Todo: adjust this path to wherever quote_store.dart lives in your project
import '../../../../data/quote_store.dart';

class QuotesScreen extends StatefulWidget {
  /// When set, only this request's quotes are shown (used by the "Quotes"
  /// button on each Uploaded job card). When null, every pending request is
  /// listed — kept for backward compatibility, though nothing wires the
  /// bell to this anymore.
  final String? requestId;

  const QuotesScreen({super.key, this.requestId});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.requestId != null) {
        QuoteNotificationStore.instance.markRequestQuotesSeen(widget.requestId!);
      } else {
        QuoteNotificationStore.instance.markSeen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textmedium,
        title: const Text('Quotes'),
      ),
      body: AnimatedBuilder(
        animation: QuoteNotificationStore.instance,
        builder: (context, _) {
          final store = QuoteNotificationStore.instance;

          List<HelpRequest> pending;
          if (widget.requestId != null) {
            final single = store.requestFor(widget.requestId!);
            pending = (single != null && single.status == RequestStatus.pending) ? [single] : [];
          } else {
            pending = store.myPendingRequests;
          }

          if (pending.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 48, color: AppColors.textdark.withValues(alpha: 0.55)),
                  const SizedBox(height: 12),
                  Text(
                    widget.requestId != null ? 'No quotes for this job yet' : 'No quotes yet',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.requestId != null
                        ? 'This job has either already been matched or is still waiting on mechanics.'
                        : 'Upload a problem from the Need Help tab and mechanic quotes will show up here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
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
                  style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
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
      return AppColors.warning;
    default:
      return AppColors.success;
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
      color: AppColors.surface.withValues(alpha: 0.55),
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
          Text(problem.description, style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
          const SizedBox(height: 12),
          if (quotes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                request.isEmergency ? 'Waiting for a mechanic to accept this emergency.' : 'Waiting for mechanics to send quotes...',
                style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Mechanic',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textdark.withValues(alpha: 0.55)))),
                Expanded(
                    flex: 2,
                    child:
                        Text('Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textdark.withValues(alpha: 0.55)))),
                Expanded(
                    flex: 2,
                    child: Text('ETA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textdark.withValues(alpha: 0.55)))),
                Expanded(
                    flex: 2,
                    child: Text('Rating',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textdark.withValues(alpha: 0.55)))),
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
                            Icon(Icons.star, size: 14, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(q.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 74,
                        child: q.accepted
                            ? Text('Accepted',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success))
                            : ElevatedButton(
                                onPressed: hasAccepted ? null : () => store.clientAcceptQuote(q.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: const StadiumBorder(),
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(70, 32),
                                  textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textmedium),
                                ),
                                child: Text('Accept', style: TextStyle(color: AppColors.textlight)),
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