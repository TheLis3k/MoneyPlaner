// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Money Planner';

  @override
  String get dashboardEmptyTitle => 'Tutaj mieszka Twój budżet kopertowy.';

  @override
  String get dashboardEmptyBody =>
      'Utwórz okres i podziel swój dochód, aby zacząć.';

  @override
  String get newPeriod => 'Nowy okres';

  @override
  String get addExpense => 'Dodaj wydatek';

  @override
  String get envelopes => 'Koperty';

  @override
  String get noEnvelopes => 'Nie przydzielono jeszcze żadnych kategorii.';

  @override
  String get income => 'Dochód';

  @override
  String get planned => 'Zaplanowano';

  @override
  String get spent => 'Wydano';

  @override
  String get unallocated => 'Nieprzydzielone';

  @override
  String get overAllocated => 'Przydzielono za dużo';

  @override
  String get remaining => 'Pozostało';

  @override
  String remainingIn(String period) {
    return 'Pozostało · $period';
  }

  @override
  String amountLeft(String amount) {
    return 'pozostało $amount';
  }

  @override
  String overBy(String amount) {
    return 'przekroczono o $amount';
  }

  @override
  String get periodName => 'Nazwa okresu';

  @override
  String get enterName => 'Podaj nazwę';

  @override
  String get start => 'Początek';

  @override
  String get end => 'Koniec';

  @override
  String get incomeForPeriod => 'Dochód w tym okresie';

  @override
  String get enterIncome => 'Podaj swój dochód';

  @override
  String get splitAcrossCategories => 'Podziel na kategorie';

  @override
  String overAllocationWarning(String amount) {
    return 'Przydzielono o $amount więcej niż wynosi dochód. Możesz mimo to kontynuować.';
  }

  @override
  String get createPeriod => 'Utwórz okres';

  @override
  String get noEnvelopesForExpense =>
      'Ten okres nie ma jeszcze żadnych kopert. Dodaj kategorie do okresu, zanim zapiszesz wydatki.';

  @override
  String get envelope => 'Koperta';

  @override
  String get pickEnvelope => 'Wybierz kopertę';

  @override
  String get amount => 'Kwota';

  @override
  String get enterAmount => 'Podaj kwotę';

  @override
  String get date => 'Data';

  @override
  String get noteOptional => 'Notatka (opcjonalnie)';

  @override
  String get saveExpense => 'Zapisz wydatek';

  @override
  String get categories => 'Kategorie';

  @override
  String get manageCategories => 'Zarządzaj kategoriami';

  @override
  String get newCategory => 'Nowa kategoria';

  @override
  String get editCategory => 'Edytuj kategorię';

  @override
  String get name => 'Nazwa';

  @override
  String get icon => 'Ikona';

  @override
  String get color => 'Kolor';

  @override
  String get save => 'Zapisz';

  @override
  String get delete => 'Usuń';

  @override
  String get addCategory => 'Dodaj kategorię';

  @override
  String get noCategories => 'Brak kategorii. Dodaj swoją pierwszą.';

  @override
  String get categoryInUse => 'Nie można usunąć kategorii używanej w okresie.';

  @override
  String get period => 'Okres';

  @override
  String get expenses => 'Wydatki';

  @override
  String get noExpenses => 'Brak wydatków w tej kopercie.';

  @override
  String get deleteExpense => 'Usuń wydatek';

  @override
  String deleteExpenseConfirm(String amount) {
    return 'Usunąć ten wydatek na $amount?';
  }

  @override
  String get cancel => 'Anuluj';

  @override
  String get expenseDeleted => 'Wydatek usunięty';
}
