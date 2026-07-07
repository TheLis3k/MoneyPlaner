import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:money_planner/screens/dashboard/dashboard_screen.dart';

void main() {
  testWidgets('Dashboard renders its empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DashboardScreen()));

    expect(find.text('Money Planner'), findsOneWidget);
    expect(find.text('Your envelope budget lives here.'), findsOneWidget);
    expect(find.text('New period'), findsOneWidget);
  });
}
