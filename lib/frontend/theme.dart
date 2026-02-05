// theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Professional Color Palette
  static const primaryBlue = Color(0xFF2563EB); // Professional blue
  static const secondaryTeal = Color(0xFF14B8A6); // Clean teal
  static const accentPurple = Color(0xFF8B5CF6); // Modern purple
  static const warningAmber = Color(0xFFF59E0B); // Warm amber
  static const successGreen = Color(0xFF10B981); // Fresh green
  static const errorRed = Color(0xFFEF4444); // Clear red

  // Classification Colors (more subtle and professional)
  static const classBlue = Color(0xFF3B82F6);
  static const examOrange = Color(0xFFF59E0B);
  static const assignmentPurple = Color(0xFF8B5CF6);
  static const deadlineRed = Color(0xFFEF4444);
  static const meetingTeal = Color(0xFF14B8A6);
  static const personalGreen = Color(0xFF10B981);
  static const otherGray = Color(0xFF6B7280);

  // Priority Colors
  static const priorityCritical = Color(0xFFDC2626);
  static const priorityHigh = Color(0xFFEA580C);
  static const priorityMedium = Color(0xFFF59E0B);
  static const priorityLow = Color(0xFF6B7280);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF9FAFB),
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryTeal,
      tertiary: accentPurple,
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFF3F4F6),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF111827),
      error: errorRed,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 36,  // was 32
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFF111827),
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,  // was 28
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: const Color(0xFF111827),
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 24,  // was 22
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111827),
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,  // was 16
        fontWeight: FontWeight.w600,
        color: const Color(0xFF111827),
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,  // was 14
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,  // was 16
        fontWeight: FontWeight.w400,
        color: const Color(0xFF111827),
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,  // was 14
        fontWeight: FontWeight.w400,
        color: const Color(0xFF4B5563),
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,  // was 12
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6B7280),
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 16,  // was 14
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: const Color(0xFF374151),
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 14,  // was 12
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: const Color(0xFF6B7280),
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 13,  // was 11
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: const Color(0xFF9CA3AF),
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFFF9FAFB),
      foregroundColor: Color(0xFF111827),
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Color(0xFF6B7280),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF3F4F6),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF374151),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E7EB),
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    primaryColor: primaryBlue,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: secondaryTeal,
      tertiary: accentPurple,
      surface: Color(0xFF1E293B),
      surfaceContainerHighest: Color(0xFF334155),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFF1F5F9),
      error: errorRed,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFFF1F5F9), 
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: const Color(0xFFF1F5F9), 
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF1F5F9), 
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF1F5F9), 
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFCBD5E1), 
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFF1F5F9), 
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFCBD5E1), 
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF94A3B8), 
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: const Color(0xFFCBD5E1), 
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: const Color(0xFF94A3B8), 
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: const Color(0xFF64748B), 
      ),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFF0F172A),
      foregroundColor: Color(0xFFF1F5F9),
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E293B),
      elevation: 8,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF334155),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFFCBD5E1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF334155),
      thickness: 1,
      space: 1,
    ),
  );

  static Color getClassificationColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'class':
        return classBlue;
      case 'exam':
        return examOrange;
      case 'assignment':
        return assignmentPurple;
      case 'deadline':
        return deadlineRed;
      case 'meeting':
        return meetingTeal;
      case 'personal':
        return personalGreen;
      default:
        return otherGray;
    }
  }

  // Helper method to get priority color
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return priorityCritical;
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }
  static IconData getClassificationIcon(String classification) {
    switch (classification.toLowerCase()) {
      case 'class':
        return Icons.school_outlined;
      case 'exam':
        return Icons.quiz_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'meeting':
        return Icons.groups_outlined;
      case 'personal':
        return Icons.person_outline;
      default:
        return Icons.event_outlined;
    }
  }
}