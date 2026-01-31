import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import 'add_task_dialog.dart';
import 'voice_recorder_dialog.dart';
import 'calendar_page.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final now = DateTime.now();
        final greeting = _getGreeting();
        final stats = dataProvider.getTodayStats();
        
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16), // Reduced from 20
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingCard(context, greeting, dataProvider),
                  const SizedBox(height: 24),
                  _buildAcademicPulse(context, stats),
                  const SizedBox(height: 24),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  _buildTimelineStrip(context, dataProvider),
                  const SizedBox(height: 24),
                  _buildUpcomingDeadlines(context, dataProvider),
                  const SizedBox(height: 24),
                  _buildCalendarMini(context, now, dataProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildGreetingCard(BuildContext context, String greeting, DataProvider dataProvider) {
    // Find next event
    final now = DateTime.now();
    final todayItems = dataProvider.getTimelineItemsForDay(now);
    final upcomingItems = todayItems.where((item) {
      if (item is Event) {
        return item.startTime.isAfter(now);
      } else if (item is Task) {
        return item.deadline.isAfter(now) && !item.completed;
      }
      return false;
    }).toList();

    String nextEventText = 'No upcoming events today';
    if (upcomingItems.isNotEmpty) {
      final nextItem = upcomingItems.first;
      final nextTime = nextItem is Event ? nextItem.startTime : (nextItem as Task).deadline;
      final diff = nextTime.difference(now);
      
      if (diff.inMinutes < 60) {
        nextEventText = 'Next event in ${diff.inMinutes} min';
      } else {
        final hours = diff.inHours;
        final minutes = diff.inMinutes.remainder(60);
        nextEventText = 'Next event in ${hours}h ${minutes}m';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20), // Reduced from 24
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentFocus,
            AppTheme.accentClarity,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentFocus.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$greeting 👋',
                  style: const TextStyle(
                    fontSize: 22, // Reduced from 24
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              nextEventText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13, // Reduced from 14
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicPulse(BuildContext context, Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Academic Pulse",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPulseCard(
                context,
                '${stats['classes'] ?? 0}',
                'Classes',
                AppTheme.lectureBlue,
              ),
            ),
            const SizedBox(width: 10), // Reduced from 12
            Expanded(
              child: _buildPulseCard(
                context,
                '${stats['tasks'] ?? 0}',
                'Tasks',
                AppTheme.submissionPurple,
              ),
            ),
            const SizedBox(width: 10), // Reduced from 12
            Expanded(
              child: _buildPulseCard(
                context,
                '${stats['exams'] ?? 0}',
                'Exams',
                AppTheme.examAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPulseCard(BuildContext context, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced from 16
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 44, // Reduced from 48
            height: 44, // Reduced from 48
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 18, // Reduced from 20
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'Add Event',
                Icons.event_rounded,
                AppTheme.lectureBlue,
                () => showDialog(
                  context: context,
                  builder: (context) => const AddEventDialog(),
                ),
              ),
            ),
            const SizedBox(width: 10), // Reduced from 12
            Expanded(
              child: _buildActionCard(
                context,
                'Add Task',
                Icons.task_rounded,
                AppTheme.submissionPurple,
                () => showDialog(
                  context: context,
                  builder: (context) => const AddTaskDialog(),
                ),
              ),
            ),
            const SizedBox(width: 10), // Reduced from 12
            Expanded(
              child: _buildActionCard(
                context,
                'Voice Note',
                Icons.mic_rounded,
                AppTheme.accentClarity,
                () => showDialog(
                  context: context,
                  builder: (context) => const VoiceRecorderDialog(
                    contextType: 'quick',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8), // Adjusted padding
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28), // Reduced from 32
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, // Reduced from 12
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStrip(BuildContext context, DataProvider dataProvider) {
    final now = DateTime.now();
    final currentHour = now.hour;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Timeline',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 24,
            itemBuilder: (context, index) {
              final hour = index;
              final hourTime = DateTime(now.year, now.month, now.day, hour);
              final items = dataProvider.getTimelineItemsForDay(now).where((item) {
                if (item is Event) {
                  return item.startTime.hour == hour;
                }
                return false;
              }).toList();

              final isCurrentHour = hour == currentHour;

              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Text(
                      '$hour:00',
                      style: TextStyle(
                        fontSize: 13, // Reduced from 14
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: isCurrentHour ? AppTheme.accentFocus : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (items.isNotEmpty)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.getContextColor(
                              items.first is Event
                                  ? (items.first as Event).type
                                  : (items.first as Task).type,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingDeadlines(BuildContext context, DataProvider dataProvider) {
    final deadlines = dataProvider.getUpcomingDeadlines(limit: 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Deadlines',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        deadlines.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No upcoming deadlines',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            : SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: deadlines.length,
                  itemBuilder: (context, index) {
                    final task = deadlines[index];
                    final color = AppTheme.getContextColor(task.type);
                    final daysUntil = task.deadline.difference(DateTime.now()).inDays;
                    final timeText = daysUntil == 0
                        ? 'Today'
                        : daysUntil == 1
                            ? 'Tomorrow'
                            : '$daysUntil days';

                    return Container(
                      width: 190, // Reduced from 200
                      margin: const EdgeInsets.only(right: 12), // Reduced from 16
                      padding: const EdgeInsets.all(16), // Reduced from 20
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.8),
                            color,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 17, // Reduced from 18
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.white, size: 15),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Due in $timeText',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildCalendarMini(BuildContext context, DateTime now, DataProvider dataProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3-Day Preview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(3, (index) {
            final date = now.add(Duration(days: index));
            final counts = dataProvider.getCountsForDay(date);
            final hasItems = (counts['events'] ?? 0) > 0 || (counts['tasks'] ?? 0) > 0;
            
            return Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarPage(),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 10 : 0), // Reduced from 12
                  padding: const EdgeInsets.all(14), // Reduced from 16
                  decoration: BoxDecoration(
                    color: index == 0
                        ? AppTheme.accentFocus.withOpacity(0.1)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index == 0 ? AppTheme.accentFocus : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: Theme.of(context).textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('d').format(date),
                        style: TextStyle(
                          fontSize: 22, // Reduced from 24
                          fontWeight: FontWeight.w700,
                          color: index == 0 ? AppTheme.accentFocus : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (hasItems)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if ((counts['events'] ?? 0) > 0)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.lectureBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            if ((counts['events'] ?? 0) > 0 && (counts['tasks'] ?? 0) > 0)
                              const SizedBox(width: 4),
                            if ((counts['tasks'] ?? 0) > 0)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.submissionPurple,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}