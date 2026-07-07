import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';

/// Set up a new planning period: name, date range, income, and how that income
/// is split across categories. Over-allocation is warned about, never blocked.
class NewPeriodScreen extends StatefulWidget {
  const NewPeriodScreen({super.key});

  @override
  State<NewPeriodScreen> createState() => _NewPeriodScreenState();
}

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
    _nameController.text = DateFormat.yMMMM().format(now);
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

  double get _income => double.tryParse(_incomeController.text.trim()) ?? 0;

  double get _totalPlanned {
    var sum = 0.0;
    for (final c in _plannedControllers.values) {
      sum += double.tryParse(c.text.trim()) ?? 0;
    }
    return sum;
  }

  double get _unallocated => _income - _totalPlanned;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final planned = <int, double>{};
    _plannedControllers.forEach((categoryId, controller) {
      final value = double.tryParse(controller.text.trim()) ?? 0;
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

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<PlannerState>().categories;
    final currency = NumberFormat.simpleCurrency();
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('New period')),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Period name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start',
                    date: _startDate,
                    format: dateFmt,
                    onPick: (d) => setState(() => _startDate = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'End',
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Income for this period',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = double.tryParse((v ?? '').trim());
                if (value == null || value <= 0) return 'Enter your income';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Split across categories',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...categories.map(_categoryRow),
            const SizedBox(height: 16),
            _AllocationSummary(
              income: _income,
              planned: _totalPlanned,
              unallocated: _unallocated,
              currency: currency,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('Create period'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryRow(Category category) {
    final controller =
        _plannedControllers.putIfAbsent(category.id!, TextEditingController.new);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: category.displayColor.withValues(alpha: 0.2),
            child: Icon(category.displayIcon,
                size: 16, color: category.displayColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(category.name)),
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                prefixText: '\$ ',
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
  const _AllocationSummary({
    required this.income,
    required this.planned,
    required this.unallocated,
    required this.currency,
  });

  final double income;
  final double planned;
  final double unallocated;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final over = unallocated < 0;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: over ? scheme.errorContainer : scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(context, 'Planned', currency.format(planned)),
            const SizedBox(height: 4),
            _row(
              context,
              over ? 'Over-allocated' : 'Unallocated',
              currency.format(unallocated),
              emphasize: true,
              color: over ? scheme.onErrorContainer : null,
            ),
            if (over) ...[
              const SizedBox(height: 8),
              Text(
                "You've allocated ${currency.format(-unallocated)} more than "
                'your income. You can still continue.',
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool emphasize = false, Color? color}) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}
