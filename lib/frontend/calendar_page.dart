import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import 'add_task_dialog.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<dynamic> _getItemsForDay(DateTime day) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    return dataProvider.getTimelineItemsForDay(day);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Calendar'),
            actions: [
              PopupMenuButton<CalendarFormat>(
                icon: const Icon(Icons.view_module_rounded),
                onSelected: (format) {
                  setState(() => _calendarFormat = format);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: CalendarFormat.month,
                    child: Text('Month View'),
                  ),
                  const PopupMenuItem(
                    value: CalendarFormat.twoWeeks,
                    child: Text('2-Week View'),
                  ),
                  const PopupMenuItem(
                    value: CalendarFormat.week,
                    child: Text('Week View'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: _getItemsForDay,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() => _calendarFormat = format);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppTheme.accentFocus.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.accentFocus,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppTheme.submissionPurple,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    canMarkersOverflow: true,
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: Theme.of(context).textTheme.titleLarge!,
                    leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                    rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
              Expanded(
                child: _buildItemsList(dataProvider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddEventDialog(selectedDate: _selectedDay),
            ),
            backgroundColor: AppTheme.accentFocus,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildItemsList(DataProvider dataProvider) {
    final items = _getItemsForDay(_selectedDay ?? _focusedDay);

    if (items.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No events or tasks for this day',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(context, item, dataProvider);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, dynamic item, DataProvider dataProvider) {
    final isEvent = item is Event;
    final isImportant = isEvent ? item.isImportant : (item as Task).isImportant;
    final color = isImportant 
        ? AppTheme.examAmber 
        : AppTheme.getContextColor(isEvent ? item.type : (item as Task).type);
    final title = isEvent ? item.title : (item as Task).title;
    final type = isEvent ? item.type : (item as Task).type;
    
    String timeText;
    IconData icon;
    
    if (isEvent) {
      final event = item as Event;
      timeText = '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}';
      icon = _getEventIcon(event.type);
    } else {
      final task = item as Task;
      timeText = 'Due: ${DateFormat('h:mm a').format(task.deadline)}';
      icon = _getTaskIcon(task.type);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3), 
          width: isImportant ? 3 : 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(child: Icon(icon, color: color)),
              if (isImportant)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.star_rounded,
                    color: AppTheme.examAmber,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isImportant ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isImportant)
              Icon(
                Icons.star_rounded,
                color: AppTheme.examAmber,
                size: 18,
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  timeText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'edit') {
              if (isEvent) {
                showDialog(
                  context: context,
                  builder: (context) => AddEventDialog(editEvent: item),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AddTaskDialog(editTask: item),
                );
              }
            } else if (value == 'duplicate') {
              _duplicateItem(context, item, dataProvider, isEvent);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, item, dataProvider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.content_copy_rounded),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          if (isEvent) {
            showDialog(
              context: context,
              builder: (context) => AddEventDialog(editEvent: item),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) => AddTaskDialog(editTask: item),
            );
          }
        },
      ),
    );
  }

  void _duplicateItem(BuildContext context, dynamic item, DataProvider dataProvider, bool isEvent) {
    if (isEvent) {
      final duplicatedEvent = (item as Event).duplicate();
      dataProvider.addEvent(duplicatedEvent);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event duplicated!'),
          backgroundColor: AppTheme.accentClarity,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final duplicatedTask = (item as Task).duplicate();
      dataProvider.addTask(duplicatedTask);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task duplicated!'),
          backgroundColor: AppTheme.submissionPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, dynamic item, DataProvider dataProvider) {
    final isEvent = item is Event;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${isEvent ? 'Event' : 'Task'}?'),
        content: Text('Are you sure you want to delete "${isEvent ? item.title : (item as Task).title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (isEvent) {
                dataProvider.deleteEvent(item.id);
              } else {
                dataProvider.deleteTask((item as Task).id);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${isEvent ? 'Event' : 'Task'} deleted'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return Icons.quiz_rounded;
      case 'lab':
        return Icons.science_rounded;
      case 'lecture':
        return Icons.school_rounded;
      case 'submission':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  IconData _getTaskIcon(String type) {
    switch (type.toLowerCase()) {
      case 'exam':
        return Icons.quiz_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'note':
        return Icons.description_rounded;
      default:
        return Icons.task_rounded;
    }
  }
}