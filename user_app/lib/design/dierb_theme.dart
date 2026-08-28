import 'package:flutter/material.dart';

abstract final class DierbPalette {
  static const primary = Color(0xFF0D6B4E);
  static const primaryDark = Color(0xFF074C38);
  static const accent = Color(0xFFFFB547);
  static const background = Color(0xFFF5F7F4);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF14231D);
  static const muted = Color(0xFF68766F);
  static const border = Color(0xFFE1E8E3);
  static const danger = Color(0xFFC63C3C);
}

abstract final class DierbTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: DierbPalette.primary,
      brightness: Brightness.light,
      surface: DierbPalette.surface,
      error: DierbPalette.danger,
    );
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(18));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DierbPalette.background,
      fontFamily: 'Kiwi',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: DierbPalette.background,
        foregroundColor: DierbPalette.text,
        titleTextStyle: TextStyle(color: DierbPalette.text, fontSize: 21, fontWeight: FontWeight.w900),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: DierbPalette.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: DierbPalette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DierbPalette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: DierbPalette.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: DierbPalette.primary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: rounded,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: rounded,
          side: const BorderSide(color: DierbPalette.border),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: DierbPalette.border),
        backgroundColor: const Color(0xFFF0F5F2),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: DierbPalette.surface,
        modalBackgroundColor: DierbPalette.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: DierbPalette.surface,
        indicatorColor: const Color(0xFFDCEFE6),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          color: states.contains(WidgetState.selected) ? DierbPalette.primary : DierbPalette.muted,
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w900 : FontWeight.w700,
        )),
      ),
      dividerTheme: const DividerThemeData(color: DierbPalette.border, thickness: 1),
    );
  }
}
