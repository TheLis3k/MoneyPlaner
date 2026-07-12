import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/planner_repository.dart';
import '../models/models.dart';
import '../theme/category_visuals.dart';

/// Imports expenses from the CSV produced by [CsvExporter].
///
/// Matches sets and categories by name (creating them on demand), so a CSV can
/// round-trip the expense log. Note the CSV doesn't carry income or planned
/// amounts, so newly created sets/envelopes start at 0 — use the encrypted
/// backup for a full restore.
class CsvImporter {
  final PlannerRepository _repo;
  CsvImporter({PlannerRepository? repository})
    : _repo = repository ?? PlannerRepository();

  /// Imports the last exported CSV. Returns the number of expenses imported,
  /// or null if there is no export file.
  Future<int?> importFromFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'money_planner_export.csv'));
    if (!await file.exists()) return null;

    final lines = (await file.readAsString())
        .split(RegExp(r'\r\n|\r|\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length <= 1) return 0; // header only

    final periods = {for (final e in await _repo.getPeriods()) e.name: e};
    final categories = {
      for (final c in await _repo.getCategories()) c.name.toLowerCase(): c,
    };

    var count = 0;
    for (final line in lines.skip(1)) {
      final cols = _parseLine(line);
      if (cols.length < 4) continue;
      final periodName = cols[0].trim();
      final categoryName = cols[1].trim();
      final amount = double.tryParse(cols[2].trim());
      final date = DateTime.tryParse(cols[3].trim());
      final note = cols.length > 4 ? cols[4].trim() : '';
      if (amount == null || date == null || categoryName.isEmpty) continue;

      final period = await _ensurePeriod(periods, periodName, date);
      final category = await _ensureCategory(categories, categoryName);
      var split = await _repo.getSplitForCategory(period.id!, category.id!);
      split ??= Split(
        id: await _repo.insertSplit(
          Split(
            periodId: period.id!,
            categoryId: category.id!,
            plannedAmount: 0,
          ),
        ),
        periodId: period.id!,
        categoryId: category.id!,
        plannedAmount: 0,
      );

      await _repo.insertExpense(
        Expense(
          splitId: split.id!,
          amount: amount,
          date: date,
          note: note.isEmpty ? null : note,
        ),
      );
      count++;
    }
    return count;
  }

  Future<Period> _ensurePeriod(
    Map<String, Period> cache,
    String name,
    DateTime sampleDate,
  ) async {
    final existing = cache[name];
    if (existing != null) return existing;
    final start = DateTime(sampleDate.year, sampleDate.month, 1);
    final end = DateTime(sampleDate.year, sampleDate.month + 1, 0);
    final id = await _repo.insertPeriod(
      Period(name: name, startDate: start, endDate: end, income: 0),
    );
    return cache[name] = Period(
      id: id,
      name: name,
      startDate: start,
      endDate: end,
      income: 0,
    );
  }

  Future<Category> _ensureCategory(
    Map<String, Category> cache,
    String name,
  ) async {
    final key = name.toLowerCase();
    final existing = cache[key];
    if (existing != null) return existing;
    final color =
        categoryColorPalette[cache.length % categoryColorPalette.length];
    final id = await _repo.insertCategory(Category(name: name, color: color));
    return cache[key] = Category(id: id, name: name, color: color);
  }

  /// Parses a single CSV line, honouring quoted fields and escaped quotes.
  List<String> _parseLine(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            sb.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          sb.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ',') {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    result.add(sb.toString());
    return result;
  }
}
