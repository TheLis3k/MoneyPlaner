import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category_progress.dart';
import '../../models/period.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/remaining_balance_bar.dart';
import '../add_expense/add_expense_screen.dart';
import '../category_detail/category_detail_screen.dart';
import '../period_setup/new_period_screen.dart';
import 'widgets/planned_pie_chart.dart';
import 'widgets/planned_vs_spent_chart.dart';

/// Home screen — current-period overview with planned vs. spent per category.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();
    final period = state.currentPeriod;

    return Scaffold(
      appBar: AppBar(
        title: period != null && state.periods.length > 1
            ? _PeriodSwitcher(state: state)
            : Text(l10n.appTitle),
      ),
      drawer: const AppDrawer(),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (period == null) {
            return _EmptyState(onCreate: () => _openNewPeriod(context));
          }
          return _PeriodView(state: state);
        },
      ),
      bottomNavigationBar: period == null
          ? null
          : RemainingBalanceBar(
              remaining: state.totalRemaining,
              periodName: period.name,
            ),
      floatingActionButton: period == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.addExpense),
            ),
    );
  }

  void _openNewPeriod(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NewPeriodScreen()));
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: state.currentPeriod!.id,
        isExpanded: true,
        borderRadius: BorderRadius.circular(12),
        style: Theme.of(context).textTheme.titleLarge,
        items: [
          for (final Period p in state.periods)
            DropdownMenuItem(value: p.id, child: Text(p.name)),
        ],
        onChanged: (id) {
          if (id != null) context.read<PlannerState>().selectPeriod(id);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.savings_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.dashboardEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(l10n.dashboardEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.newPeriod),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodView extends StatelessWidget {
  const _PeriodView({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(state: state),
        if (state.progress.isNotEmpty) ...[
          const SizedBox(height: 16),
          PlannedPieChart(progress: state.progress),
          const SizedBox(height: 16),
          PlannedVsSpentChart(progress: state.progress),
        ],
        const SizedBox(height: 16),
        Text(l10n.envelopes, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.progress.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(l10n.noEnvelopes)),
          )
        else
          ...state.progress.map((p) => _CategoryProgressTile(progress: p)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});
  final PlannerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Stat(label: l10n.income, value: formatZloty(state.income)),
                _Stat(
                  label: l10n.planned,
                  value: formatZloty(state.totalPlanned),
                ),
                _Stat(label: l10n.spent, value: formatZloty(state.totalSpent)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.isOverAllocated ? l10n.overAllocated : l10n.unallocated,
                  style: TextStyle(
                    color: state.isOverAllocated ? scheme.error : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  formatZloty(state.unallocated),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: state.isOverAllocated ? scheme.error : null,
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CategoryProgressTile extends StatelessWidget {
  const _CategoryProgressTile({required this.progress});
  final CategoryProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = progress.category.displayColor;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(splitId: progress.split.id!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(
                      progress.category.displayIcon,
                      size: 18,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      progress.category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${formatZloty(progress.spent)} / ${formatZloty(progress.planned)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 8,
                  backgroundColor: scheme.surfaceContainerHigh,
                  color: progress.isOverspent ? scheme.error : color,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  progress.isOverspent
                      ? l10n.overBy(formatZloty(-progress.remaining))
                      : l10n.amountLeft(formatZloty(progress.remaining)),
                  style: TextStyle(
                    fontSize: 12,
                    color: progress.isOverspent ? scheme.error : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
