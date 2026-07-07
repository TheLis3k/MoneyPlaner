import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:money_planner/screens/dashboard/dashboard_screen.dart';
import 'package:money_planner/state/planner_state.dart';

void main() {
  testWidgets('Dashboard shows a loading indicator before state loads',
      (tester) async {
    // A fresh PlannerState starts in the loading state (load() not called),
    // so no database access happens during the test.
    await tester.pumpWidget(
      ChangeNotifierProvider<PlannerState>.value(
        value: PlannerState(),
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    expect(find.text('Money Planner'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
