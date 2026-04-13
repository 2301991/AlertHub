import 'package:flutter/material.dart';

class AppTheme {
  // ===== LIGHT MODE =====
  static const lightBackground = Color(0xFFF4F7FF); // tinted white
  static const lightCardGray = Color(0xFFE5E7EB);
  static const accentBlue = Color(0xFF2563EB);

  // ===== DARK MODE =====
  static const darkBackground = Color(0xFF0B1220);
  static const darkCardGray = Color(0xFF374151);

  static const outlineBlack = Colors.black;

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: accentBlue,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: lightBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black),
        bodySmall: TextStyle(color: Colors.black87),
        titleMedium: TextStyle(color: Colors.black),
      ),

      iconTheme: const IconThemeData(color: Colors.black),

      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.all(accentBlue),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFE0EDFF); // blue-tinted white
          }
          return const Color(0xFFF0F4FF); // soft tinted white
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentBlue;
          }
          return Colors.white;
        }),
      ),
    );
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: accentBlue,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: darkBackground,

      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
      ),

      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  // Reusable widget style
  static ShapeBorder outlinedCardShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: outlineBlack, width: 1.5),
    );
  }

  static Color widgetGray(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardGray
        : lightCardGray;
  }
}