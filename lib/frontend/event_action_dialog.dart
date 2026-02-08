// event_action_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import '../backend/timetable_models.dart';
import 'theme.dart';
import 'add_event_dialog.dart';

class EventActionDialog extends StatelessWidget {
  final Event event;

  const EventActionDialog({
    super.key,
    required this.event,
  });

  bool get _isClassEvent => event.classification == 'class';
  
  @override
  Widget build(BuildContext context) {
    final color = event.completionColor != null
        ? Color(int.parse(event.completionColor!.replaceFirst('#', '0xFF')))
        : AppTheme.getClassificationColor(event.classification);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    AppTheme.getClassificationIcon(event.classification),
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(event.startTime),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: color.withOpacity(0.1),
                    foregroundColor: color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Actions
            if (_isClassEvent)
              _buildClassActions(context, color)
            else
              _buildRegularEventActions(context, color),
          ],
        ),
      ),
    );
  }

Widget _buildClassActions(BuildContext context, Color color) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final attendance = dataProvider.getAttendanceForDate(
      event.title,
      event.startTime,
    );

    final allowedStatuses = [
      AttendanceStatus.present,
      AttendanceStatus.absent,
      AttendanceStatus.cancelled,
    ];

    return Column(
      children: [
        Text(
          'Mark Attendance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Attendance options
        ...allowedStatuses.map((status) {
          final statusColor = _getAttendanceColor(status);
          final isSelected = attendance?.status == status;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                _markAttendance(context, status);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? statusColor.withOpacity(0.15)
                      : statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getAttendanceIcon(status),
                      color: statusColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAttendanceLabel(status),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: statusColor,
                            ),
                          ),
                          Text(
                            _getAttendanceDescription(status),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: statusColor,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 20),

        // Edit button with consistent border
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AddEventDialog(editEvent: event),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Class Details'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegularEventActions(BuildContext context, Color color) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final isCompleted = event.isCompleted;

    return Column(
      children: [
        // Mark as complete/incomplete
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: () {
              dataProvider.toggleEventComplete(event.id);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isCompleted 
                        ? 'Event marked as incomplete'
                        : 'Event marked as complete',
                  ),
                  backgroundColor: isCompleted 
                      ? AppTheme.warningAmber 
                      : AppTheme.successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            icon: Icon(
              isCompleted 
                  ? Icons.restart_alt 
                  : Icons.check_circle_outline,
            ),
            label: Text(
              isCompleted 
                  ? 'Mark as Incomplete' 
                  : 'Mark as Complete',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: isCompleted 
                  ? AppTheme.warningAmber 
                  : AppTheme.successGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Edit button with consistent border
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AddEventDialog(editEvent: event),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Event'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _markAttendance(BuildContext context, AttendanceStatus status) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    
    final record = AttendanceRecord(
      id: const Uuid().v4(),
      courseName: event.title,
      date: event.startTime,
      status: status,
    );
    
    dataProvider.markAttendance(record);
    
    // Update event completion color based on attendance
    event.completionColor = '#${_getAttendanceColor(status).value.toRadixString(16).substring(2)}';
    dataProvider.updateEvent(event);
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Marked as ${_getAttendanceLabel(status)}'),
        backgroundColor: _getAttendanceColor(status),
        behavior: SnackBarBehavior.floating,
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

  String _getAttendanceLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.excused:
        return 'Excused';
      case AttendanceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getAttendanceDescription(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Attended on time';
      case AttendanceStatus.absent:
        return 'Did not attend';
      case AttendanceStatus.late:
        return 'Attended late';
      case AttendanceStatus.excused:
        return 'Excused absence';
      case AttendanceStatus.cancelled:
        return 'Class was cancelled (not counted)';
    }
  }
}