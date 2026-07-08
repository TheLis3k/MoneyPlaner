import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';
import '../categories/category_editor.dart';

/// Set up a new planning period: name, date range, income, and how that income
/// is split across categories. Over-allocation is warned about, never blocked.
class NewPeriodScreen extends StatefulWidget {
  const NewPeriodScreen({super.key});

  @override
  State<NewPeriodScreen> createState() => _NewPeriodScreenState();
}

double _parseAmount(String raw) =>
    double.tryParse(raw.trim().replaceAll(',', '.')) ?? 0;

class _NewPeriodScreenState extends State<NewPeriodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;

  /// categoryId -> planned amount text controller.
  final Map<int, TextEditingController> _plannedControllers = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0); // last day of month
    _nameController.text = toBeginningOfSentenceCase(
      DateFormat.yMMMM('pl').format(now),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    for (final c in _plannedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _income => _parseAmount(_incomeController.text);

  double get _totalPlanned {
    var sum = 0.0;
    for (final c in _plannedControllers.values) {
      sum += _parseAmount(c.text);
    }
    return sum;
  }

  double get _unallocated => _income - _totalPlanned;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final planned = <int, double>{};
    _plannedControllers.forEach((categoryId, controller) {
      final value = _parseAmount(controller.text);
      if (value > 0) planned[categoryId] = value;
    });

    await context.read<PlannerState>().createPeriod(
      name: _nameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      income: _income,
      plannedByCategory: planned,
    );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addCategory() async {
    final created = await showCategoryEditor(context);
    if (created != null && mounted) {
      await context.read<PlannerState>().addCategory(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = context.watch<PlannerState>().categories;
    final dateFmt = DateFormat.yMMMd('pl');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPeriod)),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.periodName,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.enterName : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: l10n.start,
                    date: _startDate,
                    format: dateFmt,
                    onPick: (d) => setState(() => _startDate = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: l10n.end,
                    date: _endDate,
                    format: dateFmt,
                    onPick: (d) => setState(() => _endDate = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.incomeForPeriod,
                suffixText: 'zł',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final value = _parseAmount(v ?? '');
                if (value <= 0) return l10n.enterIncome;
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.splitAcrossCategories,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addCategory),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.noCategories),
              )
            else
              ...categories.map(_categoryRow),
            const SizedBox(height: 16),
            _AllocationSummary(
              planned: _totalPlanned,
              unallocated: _unallocated,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(l10n.createPeriod),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(Category category) {
    final controller = _plannedControllers.putIfAbsent(
      category.id!,
      TextEditingController.new,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: category.displayColor.withValues(alpha: 0.2),
            child: Icon(
              category.displayIcon,
              size: 16,
              color: category.displayColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(category.name)),
          SizedBox(
            width: 130,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                suffixText: 'zł',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.format,
    required this.onPick,
  });

  final String label;
  final DateTime date;
  final DateFormat format;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(format.format(date)),
      ),
    );
  }
}

class _AllocationSummary extends StatelessWidget {
  const _AllocationSummary({required this.planned, required this.unallocated});

  final double planned;
  final double unallocated;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final over = unallocated < 0;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: over ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, l10n.planned, formatZloty(planned)),
            const SizedBox(height: 4),
            _row(
              context,
              over ? l10n.overAllocated : l10n.unallocated,
              formatZloty(unallocated),
              emphasize: true,
              color: over ? scheme.onErrorContainer : null,
            ),
            if (over) ...[
              const SizedBox(height: 8),
              Text(
                l10n.overAllocationWarning(formatZloty(-unallocated)),
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
    Color? color,
  }) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
