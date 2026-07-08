// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Money Planner';

  @override
  String get dashboardEmptyTitle => 'Your envelope budget lives here.';

  @override
  String get dashboardEmptyBody =>
      'Create a period and split your income to get started.';

  @override
  String get newPeriod => 'New period';

  @override
  String get addExpense => 'Add expense';

  @override
  String get envelopes => 'Envelopes';

  @override
  String get noEnvelopes => 'No categories allocated yet.';

  @override
  String get income => 'Income';

  @override
  String get planned => 'Planned';

  @override
  String get spent => 'Spent';

  @override
  String get unallocated => 'Unallocated';

  @override
  String get overAllocated => 'Over-allocated';

  @override
  String get remaining => 'Remaining';

  @override
  String remainingIn(String period) {
    return 'Remaining · $period';
  }

  @override
  String amountLeft(String amount) {
    return '$amount left';
  }

  @override
  String overBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get periodName => 'Period name';

  @override
  String get enterName => 'Enter a name';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get incomeForPeriod => 'Income for this period';

  @override
  String get enterIncome => 'Enter your income';

  @override
  String get splitAcrossCategories => 'Split across categories';

  @override
  String overAllocationWarning(String amount) {
    return 'You\'ve allocated $amount more than your income. You can still continue.';
  }

  @override
  String get createPeriod => 'Create period';

  @override
  String get noEnvelopesForExpense =>
      'This period has no envelopes yet. Add categories to the period before logging expenses.';

  @override
  String get envelope => 'Envelope';

  @override
  String get pickEnvelope => 'Pick an envelope';

  @override
  String get amount => 'Amount';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get date => 'Date';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get saveExpense => 'Save expense';

  @override
  String get categories => 'Categories';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get name => 'Name';

  @override
  String get icon => 'Icon';

  @override
  String get color => 'Color';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get addCategory => 'Add category';

  @override
  String get noCategories => 'No categories yet. Add your first one.';

  @override
  String get categoryInUse =>
      'Can\'t delete a category that\'s used in a period.';

  @override
  String get period => 'Period';

  @override
  String get expenses => 'Expenses';

  @override
  String get noExpenses => 'No expenses in this envelope yet.';

  @override
  String get deleteExpense => 'Delete expense';

  @override
  String deleteExpenseConfirm(String amount) {
    return 'Delete this expense of $amount?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get expenseDeleted => 'Expense deleted';
}
