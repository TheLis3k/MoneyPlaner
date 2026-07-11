import 'package:flutter/material.dart';

/// Dark, shadcn-inspired theme: near-black surfaces, hairline borders,
/// near-white primary actions, generous rounding. Applied app-wide.
class AppTheme {
  // Core palette (Zinc scale + accents), matching the design comp.
  static const _bg = Color(0xFF09090B); // scaffold / app bar
  static const _card = Color(0xFF131316); // cards, sheets
  static const _border = Color(0xFF1F1F23); // hairline card border
  static const _track = Color(0xFF27272A); // progress track, dividers
  static const _fg = Color(0xFFFAFAFA); // primary text / CTA
  static const _muted = Color(0xFFA1A1AA); // secondary text

  static final ColorScheme _scheme = const ColorScheme.dark().copyWith(
    primary: _fg,
    onPrimary: _bg,
    primaryContainer: _track,
    onPrimaryContainer: _fg,
    secondary: _muted,
    onSecondary: _bg,
    surface: _bg,
    onSurface: _fg,
    onSurfaceVariant: _muted,
    surfaceContainerLowest: _bg,
    surfaceContainerLow: _card,
    surfaceContainer: _card,
    surfaceContainerHigh: _border,
    surfaceContainerHighest: _track,
    outline: Color(0xFF3F3F46),
    outlineVariant: _track,
    error: Color(0xFFF87171),
    onError: _bg,
    errorContainer: Color(0xFF4C0519),
    onErrorContainer: Color(0xFFFECDD3),
  );

  static ThemeData get theme => _build();

  // Kept for the app's existing references; both resolve to the dark theme.
  static ThemeData get dark => _build();
  static ThemeData get light => _build();

  static ThemeData _build() {
    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: _scheme,
      scaffoldBackgroundColor: _bg,
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: _fg, displayColor: _fg),
      appBarTheme: const AppBarTheme(
        backgroundColor: _bg,
        foregroundColor: _fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _card,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _track, thickness: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _fg,
        foregroundColor: _bg,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _fg,
          foregroundColor: _bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _bg,
        indicatorColor: _track,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: const ListTileThemeData(iconColor: _muted),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _track),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _track),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _fg, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: _card,
        contentTextStyle: TextStyle(color: _fg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
