// timeline_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import 'event_action_dialog.dart';

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
    final itemHeight = 100.0;
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
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _selectDate,
                tooltip: 'Select Date',
              ),
              if (!isToday)
                IconButton(
                  icon: const Icon(Icons.today),
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
    final blockTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
    );
    
    final events = dataProvider.getEventsForDay(_selectedDate).where((event) {
      return event.startTime.hour == hour;
    }).toList();
    
    final hasItems = events.isNotEmpty;
    
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
                  ? Theme.of(context).colorScheme.primary
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
                color: isCurrentHour 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.transparent,
                border: Border.all(
                  color: isCurrentHour 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            ),
            if (hour < 23)
              Container(
                width: 2,
                height: hasItems ? (events.length * 110.0) : 70,
                color: isCurrentHour 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Theme.of(context).dividerColor,
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Event blocks
        Expanded(
          child: hasItems
              ? Column(
                  children: events.map((event) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildEventCard(context, event, isCurrentHour),
                    );
                  }).toList(),
                )
              : const SizedBox(height: 70),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, bool isCurrentHour) {
    final color = AppTheme.getClassificationColor(event.classification);
    final icon = AppTheme.getClassificationIcon(event.classification);
    
    String duration;
    if (event.hasEndTime) {
      final diff = event.endTime!.difference(event.startTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      duration = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    } else {
      duration = event.estimatedDuration ?? '—';
    }
    
    String subtitle = '';
    if (event.location != null && event.location!.isNotEmpty) {
      subtitle = event.location!;
    } else if (event.category != null) {
      final category = Provider.of<DataProvider>(context, listen: false)
          .getCategoryById(event.category);
      if (category != null) {
        subtitle = category.name;
      }
    }
    
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => EventActionDialog(event: event),
        );
      },
      borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentHour ? color : color.withOpacity(0.3),
            width: isCurrentHour ? 2 : 1,
          ),
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
                        event.classification[0].toUpperCase() + 
                            event.classification.substring(1),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 14, color: color),
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
              event.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                decoration: event.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    event.location != null 
                        ? Icons.location_on_outlined 
                        : Icons.folder_outlined,
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
            if (event.isImportant)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppTheme.warningAmber),
                    const SizedBox(width: 4),
                    Text(
                      'Important',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningAmber,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}