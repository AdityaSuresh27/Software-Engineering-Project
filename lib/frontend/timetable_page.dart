// timetable_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/data_provider.dart';
import '../backend/timetable_models.dart';
import 'theme.dart';
import 'add_timetable_dialog.dart';
import 'attendance_page.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday - 1; // 0=Monday
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: today.clamp(0, 6),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Timetable'),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendancePage(),
                    ),
                  );
                },
                tooltip: 'View Attendance',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: _days.map((day) => Tab(text: day)).toList(),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: List.generate(7, (index) {
              final dayOfWeek = index + 1; // 1=Monday
              return _buildDayView(dataProvider, dayOfWeek);
            }),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const AddTimetableDialog(),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Class'),
          ),
        );
      },
    );
  }

  Widget _buildDayView(DataProvider dataProvider, int dayOfWeek) {
    final entries = dataProvider.getTimetableForDay(dayOfWeek);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a class',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return _buildTimetableCard(context, entries[index], dataProvider, dayOfWeek);
      },
    );
  }

  Widget _buildTimetableCard(
    BuildContext context,
    TimetableEntry entry,
    DataProvider dataProvider,
    int dayOfWeek,
  ) {
    final color = entry.color != null
        ? Color(int.parse(entry.color!.replaceFirst('#', '0xFF')))
        : AppTheme.classBlue;

    final startTime = entry.startTime.format(context);
    final endTime = entry.endTime.format(context);
    final duration = _calculateDuration(entry.startTime, entry.endTime);

    // Get attendance for today
    final today = DateTime.now();
    final thisWeekDay = _getNextDateForDay(today, dayOfWeek);
    final attendance = dataProvider.getAttendanceForDate(entry.id, thisWeekDay);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AddTimetableDialog(editEntry: entry),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: color,
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.courseName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (entry.courseCode != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry.courseCode!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (attendance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getAttendanceColor(attendance.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getAttendanceColor(attendance.status),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAttendanceIcon(attendance.status),
                            size: 16,
                            color: _getAttendanceColor(attendance.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            attendance.status.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _getAttendanceColor(attendance.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        showDialog(
                          context: context,
                          builder: (context) => AddTimetableDialog(editEntry: entry),
                        );
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, entry, dataProvider);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    '$startTime - $endTime',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      duration,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              if (entry.room != null || entry.instructor != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (entry.room != null) ...[
                      Icon(Icons.room_outlined, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        entry.room!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (entry.room != null && entry.instructor != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('•', style: Theme.of(context).textTheme.bodySmall),
                      ),
                    if (entry.instructor != null) ...[
                      Icon(Icons.person_outline, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.instructor!,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TimetableEntry entry, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Timetable Entry'),
        content: Text('Are you sure you want to delete "${entry.courseName}"? This will also remove all attendance records for this class.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              dataProvider.deleteTimetableEntry(entry.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Timetable entry deleted'),
                  backgroundColor: AppTheme.errorRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  DateTime _getNextDateForDay(DateTime from, int targetDayOfWeek) {
    final currentDayOfWeek = from.weekday;
    int daysToAdd = targetDayOfWeek - currentDayOfWeek;
    if (daysToAdd < 0) daysToAdd += 7;
    return from.add(Duration(days: daysToAdd));
  }

  String _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final duration = endMinutes - startMinutes;
    
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
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
    }
  }
}