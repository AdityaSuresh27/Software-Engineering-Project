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
  final List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 170,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppTheme.primaryBlue,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.zero,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryBlue,
                            AppTheme.primaryBlue.withOpacity(0.88),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Decorative elements
                          Positioned(
                            top: -80,
                            right: -60,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.04),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 100,
                            left: -40,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.03),
                              ),
                            ),
                          ),
                          // Content
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Back button
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12, bottom: 2),
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                  // Title and info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Timetable',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 28,
                                            letterSpacing: -0.5,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.25),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.class_rounded,
                                                color: Colors.white.withOpacity(0.95),
                                                size: 15,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${dataProvider.timetableEntries.length} ${dataProvider.timetableEntries.length == 1 ? 'class' : 'classes'} this week',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.95),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AttendancePage(),
                            ),
                          );
                        },
                        tooltip: 'Attendance',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PopupMenuButton<String>(
                        tooltip: 'Options',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                        ),
                        onSelected: (value) {
                          if (value == 'reset') {
                            _showResetConfirmation(context, dataProvider);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(Icons.restart_alt_rounded, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Reset All',
                                  style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: false,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.45),
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        tabs: _days.map((day) => Tab(
                          height: 50,
                          child: Text(day),
                        )).toList(),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) {
                final dayOfWeek = index + 1; // 1=Monday
                return _buildDayView(dataProvider, dayOfWeek, _fullDays[index]);
              }),
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const AddTimetableDialog(),
              ),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'Add Class',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  letterSpacing: 0.2,
                ),
              ),
              backgroundColor: AppTheme.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayView(DataProvider dataProvider, int dayOfWeek, String dayName) {
    final entries = dataProvider.getTimetableForDay(dayOfWeek);

    if (entries.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.02),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.08),
                      AppTheme.primaryBlue.withOpacity(0.02),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  size: 64,
                  color: AppTheme.primaryBlue.withOpacity(0.32),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No classes on $dayName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.2,
                  color: Theme.of(context).textTheme.titleLarge?.color?.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add a class',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.02),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return _buildTimetableCard(context, entries[index], dataProvider, dayOfWeek, index);
        },
      ),
    );
  }

  Widget _buildTimetableCard(
    BuildContext context,
    TimetableEntry entry,
    DataProvider dataProvider,
    int dayOfWeek,
    int index,
  ) {
    final color = entry.color != null
        ? Color(int.parse(entry.color!.replaceFirst('#', '0xFF')))
        : AppTheme.classBlue;

    final startTime = entry.startTime.format(context);
    final endTime = entry.endTime.format(context);
    final duration = _calculateDuration(entry.startTime, entry.endTime);
    
    final today = DateTime.now();
    final thisWeekDay = _getNextDateForDay(today, dayOfWeek);
    final attendance = dataProvider.getAttendanceForDate(entry.courseName, thisWeekDay);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 60)),
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
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        elevation: 1.5,
        shadowColor: color.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddTimetableDialog(editEntry: entry),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.03),
                  color.withOpacity(0.01),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.07),
                        color.withOpacity(0.03),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Row(
                    children: [
                      // Time badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color,
                              color.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              startTime,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                                height: 1,
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 2,
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            Text(
                              endTime,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withOpacity(0.95),
                                letterSpacing: -0.1,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      
                      // Course info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.courseName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.1,
                                height: 1.2,
                              ),
                            ),
                            if (entry.courseCode != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.11),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: color.withOpacity(0.22),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  entry.courseCode!,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Attendance badge
                      if (attendance != null)
                        Container(
                          margin: const EdgeInsets.only(right: 2),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _getAttendanceColor(attendance.status),
                                _getAttendanceColor(attendance.status).withOpacity(0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: _getAttendanceColor(attendance.status).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getAttendanceIcon(attendance.status),
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      
                      // Menu button
                      PopupMenuButton<String>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        icon: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.more_vert_rounded, color: color, size: 18),
                        ),
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
                                Icon(Icons.edit_rounded, size: 19),
                                SizedBox(width: 10),
                                Text('Edit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, color: Colors.red, size: 19),
                                SizedBox(width: 10),
                                Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Details section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Duration chip
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(Icons.schedule_rounded, size: 16, color: color),
                          ),
                          const SizedBox(width: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.11),
                                  color.withOpacity(0.07),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: color.withOpacity(0.18),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              duration,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Location and instructor
                      if (entry.room != null || entry.instructor != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (entry.room != null)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        size: 15,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        entry.room!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          letterSpacing: -0.05,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (entry.room != null && entry.instructor != null)
                                const SizedBox(height: 10),
                              if (entry.instructor != null)
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 15,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        entry.instructor!,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          letterSpacing: -0.05,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TimetableEntry entry, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.delete_rounded, color: AppTheme.errorRed, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Class?',
                style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${entry.courseName}"? This will also remove all attendance records for this class.',
          style: const TextStyle(fontSize: 14.5, height: 1.5, letterSpacing: -0.05),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
          ),
          FilledButton(
            onPressed: () {
              dataProvider.deleteTimetableEntry(entry.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 17),
                      ),
                      const SizedBox(width: 10),
                      const Text('Class deleted successfully', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  backgroundColor: AppTheme.errorRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(14),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
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
        return Icons.check_circle_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.late:
        return Icons.access_time_rounded;
      case AttendanceStatus.excused:
        return Icons.event_busy_rounded;
    }
  }

  void _showResetConfirmation(BuildContext context, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.warning_rounded, color: AppTheme.errorRed, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reset Everything?',
                style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete:\n\n'
          '• All timetable entries\n'
          '• All class events (both auto-generated and manual)\n'
          '• All attendance records\n\n'
          'This action cannot be undone.',
          style: TextStyle(fontSize: 14.5, height: 1.55, letterSpacing: -0.05),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
          ),
          FilledButton(
            onPressed: () async {
              await dataProvider.resetTimetableAndAttendance();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 17),
                        ),
                        const SizedBox(width: 10),
                        const Text('Reset successful', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(14),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset Everything', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          ),
        ],
      ),
    );
  }
}