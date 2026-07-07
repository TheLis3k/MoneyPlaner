import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'state/planner_state.dart';
import 'theme/app_theme.dart';

/// Root widget: provides app-wide state and wires up theming + home screen.
class MoneyPlannerApp extends StatelessWidget {
  const MoneyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlannerState()..load(),
      child: MaterialApp(
        title: 'Money Planner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const DashboardScreen(),
      ),
    );
  }
}
