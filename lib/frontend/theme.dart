import 'package:flutter/material.dart';

class AppTheme {
  // Academic Theme Colors
  static const accentFocus = Color(0xFF4A90E2);
  static const accentClarity = Color(0xFF6FCFB4);
  static const accentMomentum = Color(0xFFFF8C61);
  static const accentMidnight = Color(0xFF9B72CB);
  static const accentExam = Color(0xFFFFB84D);

  // Context Colors
  static const examAmber = Color(0xFFFFB84D);
  static const labMint = Color(0xFF6FCFB4);
  static const lectureBlue = Color(0xFF4A90E2);
  static const submissionPurple = Color(0xFF9B72CB);
  static const notesGray = Color(0xFF8E8E93);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: accentFocus,
    colorScheme: const ColorScheme.light(
      primary: accentFocus,
      secondary: accentClarity,
      surface: Colors.white,
      background: Color(0xFFF8F9FA),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF1A1A1A),
      onBackground: Color(0xFF1A1A1A),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFF1A1A1A),
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: Color(0xFF1A1A1A),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFF1A1A1A),
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF4A4A4A),
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Color(0xFF8E8E93),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF1A1A1A),
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white.withOpacity(0.95),
      elevation: 8,
      selectedItemColor: accentFocus,
      unselectedItemColor: const Color(0xFF8E8E93),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    primaryColor: accentFocus,
    colorScheme: const ColorScheme.dark(
      primary: accentFocus,
      secondary: accentClarity,
      surface: Color(0xFF2C2C2E),
      background: Color(0xFF1A1A1A),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF5F5F7),
      onBackground: Color(0xFFF5F5F7),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF2C2C2E).withOpacity(0.6),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: Color(0xFFF5F5F7),
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: Color(0xFFF5F5F7),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF5F5F7),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF5F5F7),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFFF5F5F7),
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFFAEAEB2),
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: Color(0xFF8E8E93),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFF5F5F7),
      centerTitle: true,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF2C2C2E).withOpacity(0.95),
      elevation: 8,
      selectedItemColor: accentFocus,
      unselectedItemColor: const Color(0xFF8E8E93),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    ),
  );

  static Color getContextColor(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return examAmber;
      case 'lab':
        return labMint;
      case 'lecture':
        return lectureBlue;
      case 'submission':
      case 'assignment':
        return submissionPurple;
      case 'note':
        return notesGray;
      default:
        return accentFocus;
    }
  }
}