import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/category_progress.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';

/// Log a real expense against one of the current period's envelopes.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _splitId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_splitId == null) return;

    setState(() => _saving = true);
    await context.read<PlannerState>().addExpense(
          splitId: _splitId!,
          amount: double.parse(_amountController.text.trim()),
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<PlannerState>().progress;
    final dateFmt = DateFormat.yMMMd();
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: progress.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This period has no envelopes yet. Add categories to the '
                  'period before logging expenses.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _splitId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Envelope',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in progress)
                        DropdownMenuItem(
                          value: p.split.id,
                          child: _EnvelopeItem(progress: p, currency: currency),
                        ),
                    ],
                    onChanged: (v) => setState(() => _splitId = v),
                    validator: (v) => v == null ? 'Pick an envelope' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final value = double.tryParse((v ?? '').trim());
                      if (value == null || value <= 0) {
                        return 'Enter an amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(dateFmt.format(_date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
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
                    label: const Text('Save expense'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EnvelopeItem extends StatelessWidget {
  const _EnvelopeItem({required this.progress, required this.currency});
  final CategoryProgress progress;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(progress.category.displayIcon,
            size: 18, color: progress.category.displayColor),
        const SizedBox(width: 8),
        Expanded(child: Text(progress.category.name)),
        Text('${currency.format(progress.remaining)} left',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
