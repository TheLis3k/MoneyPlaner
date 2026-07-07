import 'package:flutter/material.dart';

/// Centralised theming so light/dark stay consistent across every screen.
class AppTheme {
  static const _seed = Color(0xFF2E7D32); // envelope-budgeting green

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }
}
