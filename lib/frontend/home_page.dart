// home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import 'voice_recorder_dialog.dart';
import 'calendar_page.dart';
import 'events_page.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final now = DateTime.now();
        final greeting = _getGreeting();
        final stats = dataProvider.getTodayStats();
        
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  DateFormat('EEEE, MMMM d').format(now),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications feature coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _fadeController.reset();
                  _slideController.reset();
                });
                await Future.delayed(const Duration(milliseconds: 100));
                _fadeController.forward();
                _slideController.forward();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTodayOverview(context, stats),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildUpcomingEvents(context, dataProvider, now),
                        const SizedBox(height: 24),
                        _buildNextDays(context, dataProvider, now),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const AddEventDialog(),
            ),
            icon: const Icon(Icons.add),
            label: const Text('New Event'),
            elevation: 4,
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

  Widget _buildTodayOverview(BuildContext context, Map<String, int> stats) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Overview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '${stats['classes'] ?? 0}',
                      'Classes',
                      Icons.school_outlined,
                      AppTheme.classBlue,
                      0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '${stats['assignments'] ?? 0}',
                      'Tasks',
                      Icons.assignment_outlined,
                      AppTheme.assignmentPurple,
                      100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '${stats['exams'] ?? 0}',
                      'Exams',
                      Icons.quiz_outlined,
                      AppTheme.examOrange,
                      200,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      '${stats['meetings'] ?? 0}',
                      'Meetings',
                      Icons.groups_outlined,
                      AppTheme.meetingTeal,
                      300,
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

  Widget _buildStatCard(
    BuildContext context,
    String count,
    String label,
    IconData icon,
    Color color,
    int delay,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Class',
                Icons.school_outlined,
                AppTheme.classBlue,
                0,
                () => showDialog(
                  context: context,
                  builder: (context) => const AddEventDialog(presetClassification: 'class'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Assignment',
                Icons.assignment_outlined,
                AppTheme.assignmentPurple,
                50,
                () => showDialog(
                  context: context,
                  builder: (context) => const AddEventDialog(presetClassification: 'assignment'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Exam',
                Icons.quiz_outlined,
                AppTheme.examOrange,
                100,
                () => showDialog(
                  context: context,
                  builder: (context) => const AddEventDialog(presetClassification: 'exam'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    int delay,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, DataProvider dataProvider, DateTime now) {
    // Get all upcoming events for today, sorted by time
    final todayEvents = dataProvider.getEventsForDay(now);
    final upcomingEvents = todayEvents.where((event) {
      return event.startTime.isAfter(now);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (upcomingEvents.length > 3)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventsPage(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        upcomingEvents.isEmpty
            ? _buildEmptyUpcoming(context)
            : Column(
                children: upcomingEvents.take(3).toList().asMap().entries.map((entry) {
                  return _buildEventCard(context, entry.value, entry.key);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyUpcoming(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: AppTheme.successGreen.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'All Caught Up!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'No more events today',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event, int index) {
    final color = AppTheme.getClassificationColor(event.classification);
    final now = DateTime.now();
    final timeUntil = event.startTime.difference(now);
    
    String timeUntilText;
    if (timeUntil.inMinutes < 60) {
      timeUntilText = 'In ${timeUntil.inMinutes} min';
    } else if (timeUntil.inHours < 24) {
      final hours = timeUntil.inHours;
      final minutes = timeUntil.inMinutes.remainder(60);
      timeUntilText = 'In ${hours}h ${minutes}m';
    } else {
      timeUntilText = DateFormat('h:mm a').format(event.startTime);
    }
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddEventDialog(editEvent: event),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'event_${event.id}',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                    ),
                    child: Icon(
                      AppTheme.getClassificationIcon(event.classification),
                      color: color,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            timeUntilText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (event.estimatedDuration != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.timer_outlined, size: 14, color: color.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              event.estimatedDuration!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (event.isImportant)
                  Icon(Icons.star, color: AppTheme.warningAmber, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextDays(BuildContext context, DataProvider dataProvider, DateTime now) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next 3 Days',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(3, (index) {
            final date = now.add(Duration(days: index));
            final counts = dataProvider.getCountsForDay(date);
            final hasItems = (counts['events'] ?? 0) > 0 || (counts['tasks'] ?? 0) > 0;
            final isToday = index == 0;
            
            return Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.9 + (0.1 * value),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  child: Card(
                    elevation: isToday ? 3 : 1,
                    color: isToday
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    shadowColor: isToday 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : null,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const CalendarPage(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEE').format(date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isToday
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('d').format(date),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).textTheme.displayMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 20,
                              child: hasItems
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if ((counts['events'] ?? 0) > 0) ...[
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: AppTheme.classBlue,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        if ((counts['tasks'] ?? 0) > 0)
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: AppTheme.assignmentPurple,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    )
                                  : Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: AppTheme.successGreen.withOpacity(0.4),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
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