/// EventsPage - Event List with Filtering & Sorting
/// 
/// Comprehensive view of all events with advanced filtering and organization.
/// 
/// Features:
/// - Filter by classification (Class, Exam, Assignment, Meeting, Personal, Other)
/// - Sort by date, priority level, or type
/// - Search events by title or notes
/// - Mark events as complete/incomplete
/// - Swipe to delete events
/// - Tap to view/edit event details
/// - Add notes and voice recordings
/// - Set reminders and priorities
/// - Color-coded priority levels (Low/Medium/High/Critical)
/// - Important event flagging with star indicator
/// 
/// Only shows incomplete events. Completed events can be filtered separately.
/// All changes persist to local storage via DataProvider.

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import 'event_action_dialog.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String _filterClassification = 'all';
  String _sortBy = 'date';
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        List<Event> events;
        if (_filterClassification == 'all') {
          events = List.from(dataProvider.events);
        } else {
          events = dataProvider.getEventsByClassification(_filterClassification);
        }
        
        events = events.where((e) => !e.isCompleted).toList();
        
        // Sort
        events.sort((a, b) {
          switch (_sortBy) {
            case 'date':
              return a.startTime.compareTo(b.startTime);
            case 'priority':
              return _getPriorityValue(b.priority).compareTo(_getPriorityValue(a.priority));
            case 'classification':
              return a.classification.compareTo(b.classification);
            default:
              return 0;
          }
        });
        
        return Scaffold(
          appBar: AppBar(
  title: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.assignmentPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.event_note_rounded,
          color: AppTheme.assignmentPurple,
          size: 22,
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'Events',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    ],
  ),
  actions: [
              AppPopupMenuButton<String>(
                tooltip: 'Sort',
                iconData: Icons.sort,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
                  const PopupMenuItem(value: 'priority', child: Text('Sort by Priority')),
                  const PopupMenuItem(value: 'classification', child: Text('Sort by Type')),
                ],
                onSelected: (value) {
                  setState(() => _sortBy = value);
                },
              ),
            ],
          ),
          
          body: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first event',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          return _buildEventCard(context, events[index], dataProvider);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'events_fab',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const AddEventDialog(),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New Event'),
          ),
        );
      },
    );
  }


  int _getPriorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  Widget _buildFilterChips() {
      final classifications = ['all', 'class', 'exam', 'assignment', 'meeting', 'personal', 'other'];
      
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: classifications.length,
          itemBuilder: (context, index) {
            final classification = classifications[index];
            final isSelected = _filterClassification == classification;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(classification[0].toUpperCase() + classification.substring(1)),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() => _filterClassification = classification);
                },
                avatar: classification != 'all'
                    ? Icon(
                        AppTheme.getClassificationIcon(classification),
                        size: 18,
                        color: isSelected
                            ? AppTheme.getClassificationColor(classification)
                            : null,
                      )
                    : null,
              ),
            );
          },
        ),
      );
    }
    
  Widget _buildEventCard(BuildContext context, Event event, DataProvider dataProvider) {
    final color = AppTheme.getClassificationColor(event.classification);
    final daysUntil = event.startTime.difference(DateTime.now()).inDays;
    
    return Slidable(
      key: ValueKey(event.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          if (event.isTask)
            SlidableAction(
              onPressed: (context) async {
                final wasCompleted = event.isCompleted;
                dataProvider.toggleEventComplete(event.id);
                
                // Play completion sound when task is marked complete (if not muted)
                if (!wasCompleted && !dataProvider.muteRingtone) {
                  final audioPlayer = AudioPlayer();
                  try {
                    await audioPlayer.play(AssetSource('accept2.mp3'));
                  } catch (e) {
                    debugPrint('Error playing accept2.mp3: $e');
                  }
                }
              },
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: event.isCompleted ? 'Undo' : 'Complete',
            ),
          SlidableAction(
            onPressed: (context) {
              _showDeleteDialog(context, event, dataProvider);
            },
            backgroundColor: AppTheme.errorRed,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => EventActionDialog(event: event),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        event.isCompleted
                            ? Icons.check_circle
                            : AppTheme.getClassificationIcon(event.classification),
                        color: color,
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
                              decoration: event.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule, size: 14, color: color),
                              const SizedBox(width: 4),
                              Text(
                                daysUntil == 0
                                    ? 'Today'
                                    : daysUntil == 1
                                        ? 'Tomorrow'
                                        : daysUntil < 0
                                            ? 'Overdue'
                                            : 'In $daysUntil days',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: daysUntil < 0 ? AppTheme.errorRed : color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (event.isImportant)
                      Icon(Icons.star, color: AppTheme.warningAmber, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(
                      context,
                      event.classification[0].toUpperCase() + event.classification.substring(1),
                      color,
                    ),
                    _buildChip(
                      context,
                      event.priority[0].toUpperCase() + event.priority.substring(1),
                      AppTheme.getPriorityColor(event.priority),
                    ),
                    if (event.category != null)
                      _buildChip(
                        context,
                        Provider.of<DataProvider>(context, listen: false)
                                .getCategoryById(event.category)
                                ?.name ??
                            '',
                        AppTheme.otherGray,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
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

  void _showDeleteDialog(BuildContext context, Event event, DataProvider dataProvider) {
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

