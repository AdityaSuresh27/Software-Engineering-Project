// home_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'add_event_dialog.dart';
import 'calendar_page.dart';
import 'events_page.dart';
import '../backend/data_provider.dart';
import '../backend/models.dart';
import 'timetable_page.dart';
import 'attendance_page.dart';
import 'event_action_dialog.dart';

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
            heroTag: 'home_fab',
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
        shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                      'Assignments',
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
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
        // First row - Create events
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
        const SizedBox(height: 12),
        // Second row - Timetable & Attendance
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Timetable',
                Icons.calendar_view_week,
                AppTheme.meetingTeal,
                150,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TimetablePage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Attendance',
                Icons.bar_chart_outlined,
                AppTheme.personalGreen,
                200,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendancePage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Meeting',
                Icons.groups_outlined,
                AppTheme.secondaryTeal,
                250,
                () => showDialog(
                  context: context,
                  builder: (context) => const AddEventDialog(presetClassification: 'meeting'),
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
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
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
  // Get today's events that need completion
  final todayEvents = dataProvider.getEventsForDay(now);
  
  final upcomingEvents = todayEvents.where((event) {
    // Check if event is incomplete/unmarked (including classes)
    final isIncomplete = !event.isCompleted && event.completionColor == null;
    
    return isIncomplete;
  }).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  // Take only first 3 events
  final displayEvents = upcomingEvents.take(3).toList();

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
      displayEvents.isEmpty
          ? _buildEmptyUpcoming(context)
          : Column(
              children: displayEvents.asMap().entries.map((entry) {
                return _buildEventCard(context, entry.value, entry.key, now);
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
                  color: AppTheme.successGreen.withValues(alpha: 0.6),
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

  Widget _buildEventCard(BuildContext context, Event event, int index, DateTime now) {
    final color = event.completionColor != null
        ? Color(int.parse(event.completionColor!.replaceFirst('#', '0xFF')))
        : AppTheme.getClassificationColor(event.classification);
    
    // Determine time status
    String timeStatusText;
    Color timeStatusColor;
    IconData timeStatusIcon;
    
    final endTime = event.endTime ?? event.startTime; // Use startTime as fallback
    
    if (now.isBefore(event.startTime)) {
      // Event hasn't started yet
      final timeUntil = event.startTime.difference(now);
      if (timeUntil.inMinutes < 60) {
        timeStatusText = 'In ${timeUntil.inMinutes} min';
      } else if (timeUntil.inHours < 24) {
        final hours = timeUntil.inHours;
        final minutes = timeUntil.inMinutes.remainder(60);
        timeStatusText = 'In ${hours}h ${minutes}m';
      } else {
        timeStatusText = DateFormat('h:mm a').format(event.startTime);
      }
      timeStatusColor = color;
      timeStatusIcon = Icons.schedule;
    } else if (now.isAfter(event.startTime) && now.isBefore(endTime)) {
      // Event is in progress
      timeStatusText = 'In Progress';
      timeStatusColor = AppTheme.warningAmber;
      timeStatusIcon = Icons.play_circle_outline;
    } else {
      // Event is overdue
      timeStatusText = 'Overdue';
      timeStatusColor = AppTheme.errorRed;
      timeStatusIcon = Icons.warning_outlined;
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
              builder: (context) => EventActionDialog(event: event),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(
                    AppTheme.getClassificationIcon(event.classification),
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
              child: Text(
                event.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
              ),
              child: Text(
                event.classification[0].toUpperCase() + event.classification.substring(1),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(timeStatusIcon, size: 14, color: timeStatusColor),
            const SizedBox(width: 4),
            Text(
              timeStatusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: timeStatusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
                          if (event.estimatedDuration != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.timer_outlined, size: 14, color: color.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              event.estimatedDuration!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color.withValues(alpha: 0.7),
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
            final dayEvents = dataProvider.getEventsForDay(date);
            
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
                  child: InkWell(
                    onTap: () {
                      // Navigate to calendar page with the selected date
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalendarPage(),
                          settings: RouteSettings(arguments: date),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        child: Column(
                          children: [
                            // Day name - FIXED: Ensure it's always visible
                            Text(
                              DateFormat('EEE').format(date),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Date number - FIXED: Make it larger and always visible
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? AppTheme.primaryBlue
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                DateFormat('d').format(date),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: index == 0 ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Event count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: dayEvents.isEmpty
                                    ? Colors.grey[200]
                                    : AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${dayEvents.length} ${dayEvents.length == 1 ? 'event' : 'events'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: dayEvents.isEmpty
                                      ? Colors.grey[600]
                                      : AppTheme.primaryBlue,
                                ),
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
