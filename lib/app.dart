import 'package:flutter/material.dart';

import 'screens/dashboard/dashboard_screen.dart';
import 'theme/app_theme.dart';

/// Root widget: wires up theming and the home screen.
class MoneyPlannerApp extends StatelessWidget {
  const MoneyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}
