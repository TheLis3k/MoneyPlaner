import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/period_summary.dart';
import '../../state/planner_state.dart';
import '../../util/money_format.dart';
import '../period_setup/new_period_screen.dart';

/// Read-only list of every planning period with its headline totals, plus the
/// controls to create and delete periods.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Watch so the list refreshes after a period is created or deleted.
    final state = context.watch<PlannerState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NewPeriodScreen())),
        icon: const Icon(Icons.add),
        label: Text(l10n.newPeriod),
      ),
      body: FutureBuilder<List<PeriodSummary>>(
        // Re-query whenever the set of periods changes.
        key: ValueKey(state.periods.length),
        future: state.periodSummaries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final summaries = snapshot.data!;
          if (summaries.isEmpty) {
            return Center(child: Text(l10n.noPeriodsYet));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deletePeriod,
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      // Make the tapped set the active one and return to the main view.
      onTap: () async {
        await context.read<PlannerState>().selectPeriod(summary.period.id!);
        if (context.mounted) Navigator.of(context).pop();
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<PlannerState>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePeriod),
        content: Text(l10n.deletePeriodConfirm(summary.period.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await state.deletePeriod(summary.period.id!);
      messenger.showSnackBar(SnackBar(content: Text(l10n.periodDeleted)));
    }
  }
}
