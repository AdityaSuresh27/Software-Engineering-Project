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
  // Call this instead of ScaffoldMessenger.showSnackBar everywhere.
  // Shows a polished banner pinned to the TOP of the screen so it never
  // hides behind dialogs or the keyboard, and looks intentional rather
  // than like a system error.
  static void showTopNotification(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final (Color bg, Color fg, IconData icon) = switch (type) {
      NotificationType.success => (
          const Color(0xFF10B981),
          Colors.white,
          Icons.check_circle_rounded,
        ),
      NotificationType.error => (
          const Color(0xFFEF4444),
          Colors.white,
          Icons.error_rounded,
        ),
      NotificationType.warning => (
          const Color(0xFFF59E0B),
          Colors.white,
          Icons.warning_rounded,
        ),
      NotificationType.info => (
          const Color(0xFF2563EB),
          Colors.white,
          Icons.info_rounded,
        ),
    };

    entry = OverlayEntry(
      builder: (_) => _TopNotificationBanner(
        message: message,
        backgroundColor: bg,
        foregroundColor: fg,
        icon: icon,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}
enum NotificationType { success, error, warning, info }

class _TopNotificationBanner extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopNotificationBanner({
    required this.message,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            elevation: 8,
            shadowColor: widget.backgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.foregroundColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.foregroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(Icons.close_rounded,
                        color: widget.foregroundColor.withValues(alpha: 0.8), size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A polished branded dropdown that replaces Flutter's default DropdownButtonFormField
/// everywhere in the app. Uses the same border/fill style as the rest of the form fields.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData prefixIcon;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Color? accentColor;
  final String? Function(T?)? validator;

  const AppDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    this.accentColor,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primaryBlue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF111827),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 15),
        prefixIcon: Icon(prefixIcon, color: color),
        filled: true,
        fillColor: color.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color.withValues(alpha: 0.3), width: 1.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color.withValues(alpha: 0.3), width: 1.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.errorRed,
            width: 1.8,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.errorRed, width: 2.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 26),
      isExpanded: true,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item.value,
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 18, color: item.iconColor ?? color),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });
}

/// A styled popup menu button used throughout the app. It mimics the design of
/// the “Options” menu on the Timetable page app bar: an icon inside a rounded
/// container with a light translucent background. Parameters allow customizing
/// the icon, colors, and tooltip while preserving the common shape and padding.
class AppPopupMenuButton<T> extends StatelessWidget {
  /// Builds the list of menu entries. Use the same signature as
  /// `PopupMenuButton.itemBuilder` to avoid type mismatches.
  final PopupMenuItemBuilder<T> itemBuilder;
  final void Function(T)? onSelected;
  final IconData iconData;
  final String? tooltip;
  final Color iconColor;
  final Color backgroundColor;
  final double iconSize;
  final ShapeBorder shape;
  /// Optional child widget which will be wrapped by the button instead of
  /// the default icon container. This allows the caller to provide a custom
  /// field (e.g. an InputDecorator) while still using the styled popup logic.
  final Widget? child;

  const AppPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.iconData = Icons.more_vert_rounded,
    this.tooltip,
    this.iconColor = Colors.white,
    this.backgroundColor = const Color(0x26ffffff), // white with 15% opacity
    this.iconSize = 20,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      shape: shape,
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      // if a custom child is supplied, use it; otherwise fall back to the
      // styled icon container used previously.
      child: child,
      icon: child == null
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: iconSize),
            )
          : null,
    );
  }
}
