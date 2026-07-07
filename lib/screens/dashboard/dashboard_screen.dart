import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category_progress.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../widgets/remaining_balance_bar.dart';
import '../add_expense/add_expense_screen.dart';
import '../period_setup/new_period_screen.dart';

/// Home screen — current-period overview with planned vs. spent per category.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PlannerState>();
    final period = state.currentPeriod;

    return Scaffold(
      appBar: AppBar(title: const Text('Money Planner')),
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
              label: const Text('Add expense'),
            ),
    );
  }

  void _openNewPeriod(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewPeriodScreen()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.savings_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Your envelope budget lives here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a period and split your income to get started.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New period'),
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
    final currency = NumberFormat.simpleCurrency();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryCard(state: state, currency: currency),
        const SizedBox(height: 16),
        Text('Envelopes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (state.progress.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No categories allocated yet.')),
          )
        else
          ...state.progress.map(
            (p) => _CategoryProgressTile(progress: p, currency: currency),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state, required this.currency});
  final PlannerState state;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Stat(label: 'Income', value: currency.format(state.income)),
                _Stat(label: 'Planned', value: currency.format(state.totalPlanned)),
                _Stat(label: 'Spent', value: currency.format(state.totalSpent)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.isOverAllocated ? 'Over-allocated' : 'Unallocated',
                  style: TextStyle(
                    color: state.isOverAllocated
                        ? Theme.of(context).colorScheme.error
                        : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currency.format(state.unallocated),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: state.isOverAllocated
                        ? Theme.of(context).colorScheme.error
                        : null,
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
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CategoryProgressTile extends StatelessWidget {
  const _CategoryProgressTile({required this.progress, required this.currency});
  final CategoryProgress progress;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = progress.category.displayColor;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
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
                  child: Icon(progress.category.displayIcon,
                      size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(progress.category.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(
                  '${currency.format(progress.spent)} / ${currency.format(progress.planned)}',
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
                    ? 'Over by ${currency.format(-progress.remaining)}'
                    : '${currency.format(progress.remaining)} left',
                style: TextStyle(
                  fontSize: 12,
                  color: progress.isOverspent ? scheme.error : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
