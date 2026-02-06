// class_attendance_details_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../backend/data_provider.dart';
import '../backend/timetable_models.dart';
import 'theme.dart';

class ClassAttendanceDetailsPage extends StatelessWidget {
  final String courseName;
  final Color color;

  const ClassAttendanceDetailsPage({
    super.key,
    required this.courseName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final allRecords = dataProvider.getAttendanceForCourse(courseName);
        final stats = dataProvider.getAttendanceStats(courseName);
        
        // Get all class events for this course
        final allClassEvents = dataProvider.getClassEventsForCourse(courseName);
        
        // Separate marked and unmarked classes
        final markedDates = allRecords.map((r) {
          return DateTime(r.date.year, r.date.month, r.date.day);
        }).toSet();
        
        final unmarkedClasses = allClassEvents.where((event) {
          final eventDate = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );
          return !markedDates.contains(eventDate);
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(courseName),
            actions: [
              if (allRecords.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'clear') {
                      _showClearConfirmation(context, dataProvider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Clear All Records', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Stats Header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Attendance Rate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${stats.attendancePercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: stats.attendancePercentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn('Present', stats.present.toString(), AppTheme.successGreen),
                        _buildStatColumn('Absent', stats.absent.toString(), AppTheme.errorRed),
                        _buildStatColumn('Late', stats.late.toString(), AppTheme.warningAmber),
                        _buildStatColumn('Excused', stats.excused.toString(), AppTheme.secondaryTeal),
                      ],
                    ),
                  ],
                ),
              ),

              // Records List
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: color,
                        unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                        indicatorColor: color,
                        tabs: [
                          Tab(text: 'Marked (${allRecords.length})'),
                          Tab(text: 'Unmarked (${unmarkedClasses.length})'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Marked Attendance Tab
                            allRecords.isEmpty
                                ? _buildEmptyState('No attendance marked yet', Icons.checklist)
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: allRecords.length,
                                    itemBuilder: (context, index) {
                                      return _buildRecordCard(
                                        context,
                                        allRecords[index],
                                        dataProvider,
                                      );
                                    },
                                  ),
                            
                            // Unmarked Classes Tab
                            unmarkedClasses.isEmpty
                                ? _buildEmptyState('All classes marked!', Icons.check_circle_outline)
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: unmarkedClasses.length,
                                    itemBuilder: (context, index) {
                                      return _buildUnmarkedClassCard(
                                        context,
                                        unmarkedClasses[index],
                                        dataProvider,
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, Color statColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: color.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    AttendanceRecord record,
    DataProvider dataProvider,
  ) {
    final statusColor = _getAttendanceColor(record.status);
    final statusIcon = _getAttendanceIcon(record.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, y').format(record.date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          record.status.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      record.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  dataProvider.deleteAttendanceRecord(record.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Attendance record deleted'),
                      backgroundColor: AppTheme.errorRed,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnmarkedClassCard(
    BuildContext context,
    dynamic classEvent,
    DataProvider dataProvider,
  ) {
    final eventDate = classEvent.startTime;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Icon(Icons.event, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d, y').format(eventDate),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classEvent.endTime != null
                        ? '${DateFormat('h:mm a').format(eventDate)} - ${DateFormat('h:mm a').format(classEvent.endTime!)}'
                        : DateFormat('h:mm a').format(eventDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () {
                _showMarkAttendanceDialog(context, eventDate, dataProvider);
              },
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Mark'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkAttendanceDialog(
    BuildContext context,
    DateTime date,
    DataProvider dataProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark Attendance - ${DateFormat('MMM d').format(date)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AttendanceStatus.values.map((status) {
            final statusColor = _getAttendanceColor(status);
            final statusIcon = _getAttendanceIcon(status);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  final record = AttendanceRecord(
                    id: const Uuid().v4(),
                    courseName: courseName,
                    date: date,
                    status: status,
                  );
                  dataProvider.markAttendance(record);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Marked as ${status.toString().split('.').last}'),
                      backgroundColor: statusColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor),
                      const SizedBox(width: 12),
                      Text(
                        status.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(AttendanceStatus status) {
      switch (status) {
        case AttendanceStatus.present:
          return AppTheme.successGreen;
        case AttendanceStatus.absent:
          return AppTheme.errorRed;
        case AttendanceStatus.late:
          return AppTheme.warningAmber;
        case AttendanceStatus.excused:
          return AppTheme.secondaryTeal;
        case AttendanceStatus.cancelled:
          return AppTheme.otherGray;
      }
    }

    IconData _getAttendanceIcon(AttendanceStatus status) {
      switch (status) {
        case AttendanceStatus.present:
          return Icons.check_circle;
        case AttendanceStatus.absent:
          return Icons.cancel;
        case AttendanceStatus.late:
          return Icons.access_time;
        case AttendanceStatus.excused:
          return Icons.event_busy;
        case AttendanceStatus.cancelled:
          return Icons.block;
      }
    }
  void _showClearConfirmation(BuildContext context, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Records?'),
        content: Text(
          'This will delete all attendance records for "$courseName". This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              dataProvider.clearAttendanceForCourse(courseName);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cleared all records for $courseName'),
                  backgroundColor: AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}