import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/period_summary.dart';
import '../../state/planner_state.dart';
import '../../util/money_format.dart';
import 'period_detail_screen.dart';

/// Read-only list of every planning period with its headline totals.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      body: FutureBuilder<List<PeriodSummary>>(
        future: context.read<PlannerState>().periodSummaries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summaries = snapshot.data!;
          if (summaries.isEmpty) {
            return Center(child: Text(l10n.noPeriodsYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: summaries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _PeriodTile(summary: summaries[i]),
          );
        },
      ),
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({required this.summary});
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.yMMMd('pl');
    final scheme = Theme.of(context).colorScheme;
    final over = summary.spent > summary.planned;

    return ListTile(
      title: Text(
        summary.period.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        l10n.periodRange(
          dateFmt.format(summary.period.startDate),
          dateFmt.format(summary.period.endDate),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatZloty(summary.spent),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: over ? scheme.error : null,
            ),
          ),
          Text(
            '/ ${formatZloty(summary.income)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PeriodDetailScreen(period: summary.period),
        ),
      ),
    );
  }
}
