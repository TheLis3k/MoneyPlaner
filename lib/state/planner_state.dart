import 'package:flutter/foundation.dart' hide Category;

import '../data/planner_repository.dart';
import '../models/models.dart';
import '../models/category_progress.dart';

/// App-wide state for the current planning period.
///
/// Wraps [PlannerRepository] and exposes the current period, its category
/// progress, and the derived totals every screen reads (planned, spent,
/// remaining, unallocated).
class PlannerState extends ChangeNotifier {
  PlannerState({PlannerRepository? repository})
      : _repo = repository ?? PlannerRepository();

  final PlannerRepository _repo;

  bool _loading = true;
  bool get isLoading => _loading;

  Period? _currentPeriod;
  Period? get currentPeriod => _currentPeriod;

  List<Category> _categories = const [];
  List<Category> get categories => _categories;

  List<CategoryProgress> _progress = const [];
  List<CategoryProgress> get progress => _progress;

  // ---- derived totals -------------------------------------------------------

  double get income => _currentPeriod?.income ?? 0;

  double get totalPlanned =>
      _progress.fold(0, (sum, p) => sum + p.planned);

  double get totalSpent => _progress.fold(0, (sum, p) => sum + p.spent);

  double get totalRemaining => totalPlanned - totalSpent;

  /// Income not yet assigned to any envelope — grows when a category is
  /// removed, shrinks as you allocate more. Can go negative if over-allocated.
  double get unallocated => income - totalPlanned;

  bool get isOverAllocated => unallocated < 0;

  // ---- lifecycle ------------------------------------------------------------

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    await _repo.seedDefaultCategoriesIfEmpty();
    _categories = await _repo.getCategories();
    _currentPeriod = await _repo.getCurrentPeriod();
    await _refreshProgress();

    _loading = false;
    notifyListeners();
  }

  Future<void> _refreshProgress() async {
    final period = _currentPeriod;
    _progress = period?.id == null
        ? const []
        : await _repo.categoryProgress(period!.id!);
  }

  // ---- mutations ------------------------------------------------------------

  /// Creates a new period and its initial splits, then makes it current.
  Future<void> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double income,
    required Map<int, double> plannedByCategory,
  }) async {
    final periodId = await _repo.insertPeriod(Period(
      name: name,
      startDate: startDate,
      endDate: endDate,
      income: income,
    ));

    for (final entry in plannedByCategory.entries) {
      if (entry.value <= 0) continue;
      await _repo.insertSplit(Split(
        periodId: periodId,
        categoryId: entry.key,
        plannedAmount: entry.value,
      ));
    }

    _currentPeriod = await _repo.getCurrentPeriod();
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> addExpense({
    required int splitId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await _repo.insertExpense(Expense(
      splitId: splitId,
      amount: amount,
      date: date,
      note: note,
    ));
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _repo.insertCategory(category);
    _categories = await _repo.getCategories();
    notifyListeners();
  }
}
