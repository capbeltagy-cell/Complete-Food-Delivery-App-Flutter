import 'package:flutter/material.dart';

abstract final class DierbTheme {
  static const primary = Color(0xFF0D6B4E);
  static const background = Color(0xFFF5F7F4);
  static const text = Color(0xFF14231D);
  static const muted = Color(0xFF68766F);
  static const border = Color(0xFFE1E8E3);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, surface: Colors.white, error: const Color(0xFFC63C3C)),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
          backgroundColor: background, foregroundColor: text,
          titleTextStyle: TextStyle(color: text, fontSize: 21, fontWeight: FontWeight.w900),
        ),
        cardTheme: CardThemeData(
          elevation: 0, color: Colors.white, margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: const BorderSide(color: border)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.5)),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: const TextStyle(fontWeight: FontWeight.w900))),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: const BorderSide(color: border), textStyle: const TextStyle(fontWeight: FontWeight.w800))),
        chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: border), backgroundColor: const Color(0xFFF0F5F2), labelStyle: const TextStyle(fontWeight: FontWeight.w800)),
        bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, modalBackgroundColor: Colors.white, showDragHandle: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
        dividerTheme: const DividerThemeData(color: border),
      );
}
