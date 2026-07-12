import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/transaction.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../add_expense/add_expense_screen.dart';

/// History (Historia): the current period's transactions grouped by day, with
/// a category filter.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _categoryId; // null = all

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<PlannerState>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
      body: FutureBuilder<List<Transaction>>(
        key: ValueKey(state.totalSpent),
        future: state.currentPeriodTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          if (all.isEmpty) {
            return Center(child: Text(l10n.noExpenses));
          }

          // Distinct categories for the filter row (first-seen order).
          final categories = <int, String>{};
          for (final t in all) {
            categories.putIfAbsent(t.category.id!, () => t.category.name);
          }

          final visible = _categoryId == null
              ? all
              : all.where((t) => t.category.id == _categoryId).toList();

          return Column(
            children: [
              _FilterBar(
                categories: categories,
                selected: _categoryId,
                onSelect: (id) => setState(() => _categoryId = id),
              ),
              const Divider(height: 1),
              Expanded(child: _DayGroups(transactions: visible)),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final Map<int, String> categories;
  final int? selected;
  final ValueChanged<int?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _Chip(
            label: l10n.all,
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final entry in categories.entries)
            _Chip(
              label: entry.value,
              selected: selected == entry.key,
              onTap: () => onSelect(entry.key),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? scheme.primary : scheme.surfaceContainerHigh,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayGroups extends StatelessWidget {
  const _DayGroups({required this.transactions});
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    // Group by calendar day, preserving newest-first order.
    final groups = <DateTime, List<Transaction>>{};
    for (final t in transactions) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      groups.putIfAbsent(day, () => []).add(t);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label(DateTime day) {
      final md = DateFormat.MMMMd('pl').format(day);
      if (day == today) return '${l10n.today} · $md';
      if (day == yesterday) return '${l10n.yesterday} · $md';
      return md;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              label(day).toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < groups[day]!.length; i++) ...[
                  _TransactionTile(transaction: groups[day]![i]),
                  if (i < groups[day]!.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = transaction.category.displayColor;
    final timeFmt = DateFormat.Hm('pl');

    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddExpenseScreen(existing: transaction.toExpense()),
        ),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(transaction.category.displayIcon, color: color, size: 20),
      ),
      title: Text(
        transaction.category.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: transaction.note == null || transaction.note!.isEmpty
          ? null
          : Text(
              transaction.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '−${formatZloty(transaction.amount)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            timeFmt.format(transaction.date),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
