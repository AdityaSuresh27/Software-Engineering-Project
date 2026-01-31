import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import 'add_task_dialog.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final itemHeight = 100.0; // Approximate height per hour block
    final scrollPosition = now.hour * itemHeight;
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final now = DateTime.now();
        final isToday = _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              isToday 
                  ? 'Timeline - Today'
                  : 'Timeline - ${DateFormat('MMM dd').format(_selectedDate)}',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today_rounded),
                onPressed: _selectDate,
                tooltip: 'Select Date',
              ),
              if (!isToday)
                IconButton(
                  icon: const Icon(Icons.today_rounded),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                    _scrollToCurrentTime();
                  },
                  tooltip: 'Jump to Today',
                ),
            ],
          ),
          body: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: 24,
            itemBuilder: (context, index) {
              final hour = index;
              final isCurrentHour = isToday && hour == now.hour;
              
              return _buildTimelineBlock(context, hour, isCurrentHour, dataProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildTimelineBlock(BuildContext context, int hour, bool isCurrentHour, DataProvider dataProvider) {
    // Get items for this hour
    final blockTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
    );
    
    final items = dataProvider.getTimelineItemsForDay(_selectedDate).where((item) {
      if (item is Event) {
        return item.startTime.hour == hour;
      } else if (item is Task) {
        return item.deadline.hour == hour;
      }
      return false;
    }).toList();
    
    final hasItems = items.isNotEmpty;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time label
        SizedBox(
          width: 70,
          child: Text(
            DateFormat('h:mm a').format(blockTime),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrentHour ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'monospace',
              color: isCurrentHour 
                  ? AppTheme.accentFocus 
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        
        // Timeline rail
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isCurrentHour ? AppTheme.accentFocus : Colors.transparent,
                border: Border.all(
                  color: isCurrentHour 
                      ? AppTheme.accentFocus 
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            ),
            if (hour < 23)
              Container(
                width: 2,
                height: hasItems ? (items.length * 110.0) : 70,
                color: isCurrentHour 
                    ? AppTheme.accentFocus.withOpacity(0.3)
                    : Theme.of(context).dividerColor,
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Event/Task blocks
        Expanded(
          child: hasItems
              ? Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildItemCard(context, item, isCurrentHour),
                    );
                  }).toList(),
                )
              : const SizedBox(height: 70),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuildContext context, dynamic item, bool isCurrentHour) {
    final isEvent = item is Event;
    final color = AppTheme.getContextColor(isEvent ? item.type : item.type);
    final title = isEvent ? item.title : item.title;
    final type = isEvent ? item.type : item.type;
    
    String subtitle;
    String duration;
    IconData icon;
    
    if (isEvent) {
      final event = item as Event;
      subtitle = event.location ?? event.subject ?? '';
      final diff = event.endTime.difference(event.startTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      duration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      icon = _getEventIcon(event.type);
    } else {
      final task = item as Task;
      subtitle = task.subject;
      duration = task.estimatedDuration;
      icon = _getTaskIcon(task.type);
    }
    
    return InkWell(
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentHour ? color : color.withOpacity(0.3),
            width: isCurrentHour ? 2 : 1,
          ),
          boxShadow: isCurrentHour
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isEvent ? Icons.location_on_outlined : Icons.book_outlined,
                    size: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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