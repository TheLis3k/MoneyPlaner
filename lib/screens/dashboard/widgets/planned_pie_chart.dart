import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/category_progress.dart';
import '../../../theme/category_visuals.dart';
import '../../../util/money_format.dart';
import '../../../widgets/chart_card.dart';

/// Donut chart of how the period's income is planned across categories.
class PlannedPieChart extends StatelessWidget {
  const PlannedPieChart({super.key, required this.progress});

  final List<CategoryProgress> progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = progress.where((p) => p.planned > 0).toList();
    final total = items.fold<double>(0, (sum, p) => sum + p.planned);

    if (items.isEmpty || total <= 0) {
      return ChartCard(
        title: l10n.plannedSplit,
        child: Text(l10n.notEnoughData),
      );
    }

    return ChartCard(
      title: l10n.plannedSplit,
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  for (final p in items)
                    PieChartSectionData(
                      value: p.planned,
                      color: p.category.displayColor,
                      title: '${(p.planned / total * 100).round()}%',
                      radius: 46,
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final p in items)
                LegendDot(
                  color: p.category.displayColor,
                  label: '${p.category.name} · ${formatZloty(p.planned)}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
