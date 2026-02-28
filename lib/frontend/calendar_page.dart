// calendar_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import 'event_action_dialog.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is DateTime) {
      setState(() {
        _focusedDay = args;
        _selectedDay = args;
      });
    }
  }

  List<Event> _getItemsForDay(DateTime day) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    return dataProvider.getEventsForDay(day);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return Scaffold(
          appBar: AppBar(
  title: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          color: AppTheme.primaryBlue,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'Calendar',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    ],
  ),
  actions: [
              AppPopupMenuButton<CalendarFormat>(
                tooltip: 'Options',
                iconData: Icons.view_module_outlined,
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
                onSelected: (format) {
                  setState(() => _calendarFormat = format);
                },
              ),
            ],
          ),
          
          body: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
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
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
              Expanded(
                child: _buildItemsList(dataProvider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'calendar_fab',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AddEventDialog(selectedDate: _selectedDay),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New Event'),
          ),
        );
      },
    );
  }

  Widget _buildItemsList(DataProvider dataProvider) {
    final items = _getItemsForDay(_selectedDay ?? _focusedDay);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No events for this day',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add an event',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildEventCard(context, items[index], dataProvider);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, DataProvider dataProvider) {
    final color = event.completionColor != null
        ? Color(int.parse(event.completionColor!.replaceFirst('#', '0xFF')))
        : (event.isCompleted 
            ? AppTheme.successGreen 
            : AppTheme.getClassificationColor(event.classification));
    
   String timeText;
    if (event.hasEndTime) {
      timeText = '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime!)}';
    } else {
      timeText = 'Due: ${DateFormat('h:mm a').format(event.startTime)}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Show action dialog instead of edit dialog
          showDialog(
            context: context,
            builder: (context) => EventActionDialog(event: event),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        event.isCompleted || event.completionColor != null
                            ? Icons.check_circle
                            : AppTheme.getClassificationIcon(event.classification),
                        color: color,
                      ),
                    ),
                    if (event.isImportant)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Icon(
                          Icons.star,
                          color: AppTheme.warningAmber,
                          size: 16,
                        ),
                      ),
                  ],
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
                        fontWeight: event.isImportant ? FontWeight.w700 : FontWeight.w500,
                        decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            timeText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            event.classification[0].toUpperCase() + event.classification.substring(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppPopupMenuButton<String>(
                iconData: Icons.more_vert,
                iconColor: color,
                backgroundColor: color.withOpacity(0.08),
                iconSize: 18,
                onSelected: (value) {
                  if (value == 'edit') {
                    showDialog(
                      context: context,
                      builder: (context) => AddEventDialog(editEvent: event),
                    );
                  } else if (value == 'duplicate') {
                    _duplicateEvent(context, event, dataProvider);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, event, dataProvider);
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
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy),
                        SizedBox(width: 8),
                        Text('Duplicate'),
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
        ),
      ),
    );
  }

  void _duplicateEvent(BuildContext context, Event event, DataProvider dataProvider) async {
    final duplicatedEvent = event.duplicate();
    dataProvider.addEvent(duplicatedEvent);
    
    // Play accept sound when event is duplicated (created) if not muted
    if (!dataProvider.muteRingtone) {
      final audioPlayer = AudioPlayer();
      try {
        await audioPlayer.play(AssetSource('accept1.mp3'));
      } catch (e) {
        debugPrint('Error playing accept1.mp3: $e');
      }
    }
    
    AppTheme.showTopNotification(
      context,
      'Event duplicated.',
      type: NotificationType.success,
    );
  }

  void _showDeleteConfirmation(BuildContext context, Event event, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              dataProvider.deleteEvent(event.id);
              Navigator.pop(context);
              AppTheme.showTopNotification(
                context,
                'Event deleted.',
                type: NotificationType.info,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}