import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category_progress.dart';
import '../../models/expense.dart';
import '../../state/planner_state.dart';
import '../../theme/category_visuals.dart';
import '../../util/money_format.dart';

String _amountText(double v) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  return s.replaceAll('.', ',');
}

/// Log a real expense against one of the current period's envelopes, or edit
/// an existing one when [existing] is provided.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.initialSplitId, this.existing});

  /// Pre-selects this envelope (e.g. when opened from a category's detail).
  final int? initialSplitId;

  /// When non-null, the screen edits this expense instead of adding one.
  final Expense? existing;

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

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _splitId = e.splitId;
      _amountController.text = _amountText(e.amount);
      _date = e.date;
      _noteController.text = e.note ?? '';
    } else {
      _splitId = widget.initialSplitId;
    }
  }

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
    final state = context.read<PlannerState>();
    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    if (_isEdit) {
      await state.updateExpense(
        widget.existing!.copyWith(
          splitId: _splitId!,
          amount: amount,
          date: _date,
          note: note,
        ),
      );
    } else {
      await state.addExpense(
        splitId: _splitId!,
        amount: amount,
        date: _date,
        note: note,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = context.watch<PlannerState>().progress;
    final dateFmt = DateFormat.yMMMd('pl');

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editExpense : l10n.addExpense)),
      body: progress.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noEnvelopesForExpense,
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
                    decoration: InputDecoration(
                      labelText: l10n.envelope,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final p in progress)
                        DropdownMenuItem(
                          value: p.split.id,
                          child: _EnvelopeItem(progress: p),
                        ),
                    ],
                    onChanged: (v) => setState(() => _splitId = v),
                    validator: (v) => v == null ? l10n.pickEnvelope : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      suffixText: 'zł',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final value = double.tryParse(
                        (v ?? '').trim().replaceAll(',', '.'),
                      );
                      if (value == null || value <= 0) return l10n.enterAmount;
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
                      decoration: InputDecoration(
                        labelText: l10n.date,
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(dateFmt.format(_date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: l10n.noteOptional,
                      border: const OutlineInputBorder(),
                    ),
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
                    label: Text(_isEdit ? l10n.saveChanges : l10n.saveExpense),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EnvelopeItem extends StatelessWidget {
  const _EnvelopeItem({required this.progress});
  final CategoryProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Icon(
          progress.category.displayIcon,
          size: 18,
          color: progress.category.displayColor,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(progress.category.name)),
        Text(
          l10n.amountLeft(formatZloty(progress.remaining)),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
