/// AttendancePage - Attendance Tracking & Risk Analysis
/// 
/// Displays attendance statistics across all courses and identifies at-risk students.
/// 
/// Features:
/// - Overall attendance percentage per course
/// - Color-coded risk indicators (Safe/Warning/At Risk based on <75% threshold)
/// - Mark attendance for classes
/// - View detailed attendance history per class
/// - Attendance predictor showing future risk based on current rate
/// - Tap course to view session-by-session attendance
/// 
/// Statistics update automatically when attendance is marked or updated.
/// At-risk students (<75% attendance) are highlighted for intervention.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/data_provider.dart';
import '../backend/timetable_models.dart';
import 'theme.dart';
import 'class_attendance_details_page.dart';
import 'attendance_predictor.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final allStats = dataProvider.getAllAttendanceStats();
        
        // Get unique course names from class events
        final courseNames = <String>{};
        for (var event in dataProvider.events) {
          if (event.classification == 'class') {
            courseNames.add(event.title);
          }
        }

        return Scaffold(
          appBar: AppBar(
  title: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.bar_chart_rounded,
          color: AppTheme.successGreen,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'Attendance',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    ],
  ),
  actions: [
              // Attendance Predictor Button
              IconButton(
                icon: const Icon(Icons.show_chart),
                tooltip: 'Attendance Predictor',
                onPressed: () {
                  _showPredictorSelection(context, courseNames);
                },
              ),
              // Reset/Delete Button
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Reset All Attendance',
                onPressed: () {
                  _showResetConfirmation(context, dataProvider);
                },
              ),
            ],
          ),
          body: courseNames.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No classes found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add classes to your timetable to track attendance',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Overall Stats Card
                    if (allStats.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlue.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildOverallStats(allStats),
                      ),

                    // Subject List Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Text(
                            'Classes (${courseNames.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),

                    // Classes List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: courseNames.length,
                        itemBuilder: (context, index) {
                          final courseName = courseNames.elementAt(index);
                          final stats = allStats[courseName];
                          
                          // Get first class event for this course to extract metadata
                          final classEvent = dataProvider.events.firstWhere(
                            (e) => e.classification == 'class' && e.title == courseName,
                          );
                          
                          return _buildCourseCard(
                            context,
                            courseName,
                            stats,
                            classEvent.color,
                            dataProvider,
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildOverallStats(Map<String, AttendanceStats> allStats) {
    int totalClasses = 0;
    int totalPresent = 0;
    int totalLate = 0;

    for (var stats in allStats.values) {
      totalClasses += stats.totalClasses;
      totalPresent += stats.present;
      totalLate += stats.late;
    }

    final percentage = totalClasses > 0 ? (totalPresent / totalClasses * 100) : 0.0;
    final withLatePercentage = totalClasses > 0 ? ((totalPresent + totalLate) / totalClasses * 100) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Overall Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (totalLate > 0)
                  Text(
                    '${withLatePercentage.toStringAsFixed(1)}% with late',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$totalPresent / $totalClasses classes attended',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Text(
              '${allStats.length} subjects',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    String courseName,
    AttendanceStats? stats,
    String? colorHex,
    DataProvider dataProvider,
  ) {
    final color = colorHex != null
        ? Color(int.parse(colorHex.replaceFirst('#', '0xFF')))
        : AppTheme.classBlue;

    final hasStats = stats != null && stats.totalClasses > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassAttendanceDetailsPage(
                courseName: courseName,
                color: color,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 5,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 16),
              
              // Course info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasStats) ...[
                      Row(
                        children: [
                          _buildStatChip(
                            'P: ${stats.present}',
                            AppTheme.successGreen,
                          ),
                          const SizedBox(width: 8),
                          _buildStatChip(
                            'A: ${stats.absent}',
                            AppTheme.errorRed,
                          ),
                          if (stats.late > 0) ...[
                            const SizedBox(width: 8),
                            _buildStatChip(
                              'L: ${stats.late}',
                              AppTheme.warningAmber,
                            ),
                          ],
                          if (stats.excused > 0) ...[
                            const SizedBox(width: 8),
                            _buildStatChip(
                              'E: ${stats.excused}',
                              AppTheme.secondaryTeal,
                            ),
                          ],
                        ],
                      ),
                    ] else
                      Text(
                        'No attendance marked yet',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              
              // Percentage badge
              if (hasStats)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getPercentageColor(stats.attendancePercentage).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPercentageColor(stats.attendancePercentage),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${stats.attendancePercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _getPercentageColor(stats.attendancePercentage),
                        ),
                      ),
                      Text(
                        '${stats.totalClasses} total',
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPercentageColor(stats.attendancePercentage),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 75) return AppTheme.successGreen;
    if (percentage >= 60) return AppTheme.warningAmber;
    return AppTheme.errorRed;
  }

  void _showResetConfirmation(BuildContext context, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Attendance?'),
        content: const Text(
          'This will permanently delete all attendance records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await dataProvider.resetAttendance();
              if (context.mounted) {
                Navigator.pop(context);
                AppTheme.showTopNotification(
                  context,
                  'All attendance records have been cleared.',
                  type: NotificationType.success,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _showPredictorSelection(BuildContext context, Set<String> courseNames) {
    final selectedCourses = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Courses for Predictor'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Select All Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FilledButton.tonal(
                      onPressed: () {
                        setDialogState(() {
                          if (selectedCourses.length == courseNames.length) {
                            selectedCourses.clear();
                          } else {
                            selectedCourses.clear();
                            selectedCourses.addAll(courseNames);
                          }
                        });
                      },
                      child: Text(
                        selectedCourses.length == courseNames.length
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ),
                  ),
                  
                  // Course List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: courseNames.length,
                      itemBuilder: (context, index) {
                        final courseName = courseNames.elementAt(index);
                        
                        return Consumer<DataProvider>(
                          builder: (context, dataProvider, _) {
                            // Get first class event for this course to extract color
                            final classEvent = dataProvider.events.firstWhere(
                              (e) => e.classification == 'class' && e.title == courseName,
                              orElse: () => dataProvider.events.first,
                            );
                            
                            final color = classEvent.color != null
                                ? Color(int.parse(classEvent.color!.replaceFirst('#', '0xFF')))
                                : AppTheme.classBlue;

                            final isSelected = selectedCourses.contains(courseName);

                            return CheckboxListTile(
                              title: Text(courseName),
                              value: isSelected,
                              secondary: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedCourses.add(courseName);
                                  } else {
                                    selectedCourses.remove(courseName);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedCourses.isEmpty
                    ? null
                    : () {
                        // Build selected courses map with colors
                        final selectedWithColors = <String, Color>{};
                        final dataProvider = Provider.of<DataProvider>(context, listen: false);
                        
                        for (var courseName in selectedCourses) {
                          final classEvent = dataProvider.events.firstWhere(
                            (e) => e.classification == 'class' && e.title == courseName,
                            orElse: () => dataProvider.events.first,
                          );
                          final color = classEvent.color != null
                              ? Color(int.parse(classEvent.color!.replaceFirst('#', '0xFF')))
                              : AppTheme.classBlue;
                          selectedWithColors[courseName] = color;
                        }

                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttendancePredictorPage(
                              initialSelectedCourses: selectedWithColors,
                            ),
                          ),
                        );
                      },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }
}
