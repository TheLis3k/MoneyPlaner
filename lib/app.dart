import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/lock/lock_gate.dart';
import 'state/planner_state.dart';
import 'theme/app_theme.dart';

/// Root widget: provides app-wide state and wires up theming, localization
/// (Polish by default) and the home screen.
class MoneyPlannerApp extends StatelessWidget {
  const MoneyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlannerState()..load(),
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        darkTheme: AppTheme.theme,
        themeMode: ThemeMode.dark,
        locale: const Locale('pl'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LockGate(child: DashboardScreen()),
      ),
    );
  }
}
