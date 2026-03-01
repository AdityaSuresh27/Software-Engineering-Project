// attendance_predictor.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../backend/data_provider.dart';
import '../backend/timetable_models.dart';
import 'theme.dart';

class AttendancePredictorPage extends StatefulWidget {
  final String? initialCourseName;
  final Color? initialColor;
  final Map<String, Color>? initialSelectedCourses;

  const AttendancePredictorPage({
    super.key,
    this.initialCourseName,
    this.initialColor,
    this.initialSelectedCourses,
  });

  @override
  State<AttendancePredictorPage> createState() => _AttendancePredictorPageState();
}

class _AttendancePredictorPageState extends State<AttendancePredictorPage> {
  late DateTime _currentDate;
  late DateTime _displayMonth;
  Set<DateTime> _leaveDates = {};
  bool _considerUnmarkedAsPresent = true;
  DateTime? _lastLeaveDay;
  
  // Multi-course support
  Map<String, Color> _selectedCourses = {};

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _displayMonth = DateTime(_currentDate.year, _currentDate.month);
    
    // Initialize with initial selected courses (multi-select from attendance page)
    if (widget.initialSelectedCourses != null && widget.initialSelectedCourses!.isNotEmpty) {
      _selectedCourses = Map.from(widget.initialSelectedCourses!);
    }
    // Or initialize with single initial course (from course details page)
    else if (widget.initialCourseName != null) {
      _selectedCourses[widget.initialCourseName!] = widget.initialColor ?? AppTheme.classBlue;
    }
    
    // Show course pre-selection dialog if no courses provided
    if (_selectedCourses.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCoursePreSelectionDialog();
      });
    }
  }

  void _toggleLeaveDate(DateTime date) {
    // Normalize to date only (ignore time)
    final normalizedDate = DateTime(date.year, date.month, date.day);

    setState(() {
      if (_leaveDates.contains(normalizedDate)) {
        _leaveDates.remove(normalizedDate);
      } else {
        _leaveDates.add(normalizedDate);
      }

      // Update last leave day
      if (_leaveDates.isNotEmpty) {
        _lastLeaveDay = _leaveDates.reduce((a, b) => a.isAfter(b) ? a : b);
      } else {
        _lastLeaveDay = null;
      }
    });
  }

  Map<String, dynamic> _calculatePredictedAttendance(
    String courseName,
    DataProvider dataProvider,
  ) {
    final allClassEvents = dataProvider.getClassEventsForCourse(courseName);
    final currentAttendance = dataProvider.getAttendanceForCourse(courseName);

    final markedAttendance = <DateTime, AttendanceRecord>{};
    for (var record in currentAttendance) {
      final normalizedDate = DateTime(record.date.year, record.date.month, record.date.day);
      markedAttendance[normalizedDate] = record;
    }

    // Calculate CURRENT attendance (all marked records - past, present, future)
    // Marked classes are fixed and cannot be changed, so all marked counts as current
    int currentPresent = 0;
    int currentAbsent = 0;
    int currentExcused = 0;
    int currentTotal = 0;

    // Count ALL marked attendance records (regardless of date - these are immutable)
    for (var record in currentAttendance) {
      // Don't count cancelled classes in total (matching data_provider logic)
      if (record.status == AttendanceStatus.cancelled) {
        continue;
      }

      currentTotal += record.periodCount;
      switch (record.status) {
        case AttendanceStatus.present:
          currentPresent += record.periodCount;
          break;
        case AttendanceStatus.absent:
          currentAbsent += record.periodCount;
          break;
        case AttendanceStatus.late:
          // Late is counted in total but NOT in present (matching getAttendanceStats)
          break;
        case AttendanceStatus.excused:
          currentExcused += record.periodCount;
          break;
        case AttendanceStatus.cancelled:
          break;
      }
    }

    // Current percentage = present / total (NOT including late, matching attendance page)
    double currentPercentage = currentTotal > 0 ? (currentPresent / currentTotal * 100) : 0.0;

    // Calculate PREDICTED attendance (current marked + future unmarked with leave/toggle logic)
    int predictedPresent = 0;
    int predictedAbsent = 0;
    int predictedExcused = 0;
    int predictedTotal = 0;

    // Add current marked attendance to predicted base (these don't change)
    predictedPresent = currentPresent;
    predictedAbsent = currentAbsent;
    predictedExcused = currentExcused;
    predictedTotal = currentTotal;

    // Now only consider unmarked classes from today onwards to the leave end date
    // These are the classes that could be affected by leave selection
    for (var event in allClassEvents) {
      final eventDate = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );

      // Only consider classes from today onwards (past unmarked are already in current)
      if (eventDate.isBefore(_currentDate)) {
        continue;
      }

      final considerUntil = _lastLeaveDay ?? _currentDate;
      if (eventDate.isAfter(considerUntil)) {
        continue;
      }

      final record = markedAttendance[eventDate];

      // Only process UNMARKED classes here
      if (record == null) {
        // This is an unmarked class
        predictedTotal += event.periodCount;
        
        if (_leaveDates.contains(eventDate)) {
          // If leave is selected, mark as absent
          predictedAbsent += event.periodCount;
        } else if (_considerUnmarkedAsPresent) {
          // Otherwise check toggle setting
          predictedPresent += event.periodCount;
        }
      }
    }

    double predictedPercentage = predictedTotal > 0 ? (predictedPresent / predictedTotal * 100) : 0.0;

    return {
      // Current Attendance
      'currentPresent': currentPresent,
      'currentAbsent': currentAbsent,
      'currentExcused': currentExcused,
      'currentTotal': currentTotal,
      'currentPercentage': currentPercentage,
      // Predicted Attendance
      'predictedPresent': predictedPresent,
      'predictedAbsent': predictedAbsent,
      'predictedExcused': predictedExcused,
      'predictedTotal': predictedTotal,
      'predictedPercentage': predictedPercentage,
    };
  }

  void _addCourse(DataProvider dataProvider) {
    final courseNames = <String>{};
    for (var event in dataProvider.events) {
      if (event.classification == 'class' && !_selectedCourses.containsKey(event.title)) {
        courseNames.add(event.title);
      }
    }

    if (courseNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All courses already selected')),
      );
      return;
    }

    _showSelectCoursesDialog(dataProvider, courseNames.toList(), isInitial: false);
  }

  void _showCoursePreSelectionDialog() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final courseNames = <String>{};
    for (var event in dataProvider.events) {
      if (event.classification == 'class') {
        courseNames.add(event.title);
      }
    }

    if (courseNames.isEmpty) {
      return;
    }

    _showSelectCoursesDialog(dataProvider, courseNames.toList(), isInitial: true);
  }

  void _showSelectCoursesDialog(
    DataProvider dataProvider,
    List<String> courseNames,
    {required bool isInitial}
  ) {
    final selectedForDialog = <String>{};

    showDialog(
      context: context,
      barrierDismissible: !isInitial,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Courses'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Select All Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.tonal(
                    onPressed: () {
                      setDialogState(() {
                        if (selectedForDialog.length == courseNames.length) {
                          selectedForDialog.clear();
                        } else {
                          selectedForDialog.clear();
                          selectedForDialog.addAll(courseNames);
                        }
                      });
                    },
                    child: Text(
                      selectedForDialog.length == courseNames.length
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ),
                
                // Course List
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: courseNames.length,
                    itemBuilder: (context, index) {
                      final courseName = courseNames[index];
                      final classEvent = dataProvider.events.firstWhere(
                        (e) => e.classification == 'class' && e.title == courseName,
                      );
                      
                      final color = classEvent.color != null
                          ? Color(int.parse(classEvent.color!.replaceFirst('#', '0xFF')))
                          : AppTheme.classBlue;

                      final isSelected = selectedForDialog.contains(courseName);

                      return CheckboxListTile(
                        title: Text(courseName),
                        value: isSelected,
                        secondary: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedForDialog.add(courseName);
                            } else {
                              selectedForDialog.remove(courseName);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!isInitial)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            FilledButton(
              onPressed: selectedForDialog.isEmpty
                  ? null
                  : () {
                      setState(() {
                        for (var courseName in selectedForDialog) {
                          final classEvent = dataProvider.events.firstWhere(
                            (e) => e.classification == 'class' && e.title == courseName,
                          );
                          final color = classEvent.color != null
                              ? Color(int.parse(classEvent.color!.replaceFirst('#', '0xFF')))
                              : AppTheme.classBlue;
                          _selectedCourses[courseName] = color;
                        }
                      });
                      Navigator.pop(context);
                    },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Attendance Predictor'),
            elevation: 0,
            actions: [
              if (_selectedCourses.isNotEmpty)
                Tooltip(
                  message: 'Add course',
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addCourse(dataProvider),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Toggle Switch
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Consider Unmarked as Present',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _considerUnmarkedAsPresent
                                  ? 'Unmarked classes will be counted as present'
                                  : 'Unmarked classes will not be counted',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _considerUnmarkedAsPresent,
                        onChanged: (value) {
                          setState(() {
                            _considerUnmarkedAsPresent = value;
                          });
                        },
                        activeThumbColor: AppTheme.successGreen,
                      ),
                    ],
                  ),
                ),
              ),

              // Calendar Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _displayMonth = DateTime(
                                _displayMonth.year,
                                _displayMonth.month - 1,
                              );
                            });
                          },
                        ),
                        Text(
                          DateFormat('MMMM yyyy').format(_displayMonth),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              _displayMonth = DateTime(
                                _displayMonth.year,
                                _displayMonth.month + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Calendar Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildLegendItem('Today', AppTheme.primaryBlue),
                        _buildLegendItem('Leave', AppTheme.errorRed),
                        if (_considerUnmarkedAsPresent)
                          _buildLegendItem('Unmarked→Present', AppTheme.successGreen),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Calendar Grid
                    _buildCalendarGrid(_displayMonth),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Course Predictions
              Expanded(
                child: _selectedCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_view_month,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No courses selected',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _addCourse(dataProvider),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Course'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ..._selectedCourses.entries.map((entry) {
                              final courseName = entry.key;
                              final color = entry.value;
                              final prediction = _calculatePredictedAttendance(courseName, dataProvider);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCourseCard(
                                  courseName,
                                  color,
                                  prediction,
                                  dataProvider,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startingWeekday = firstDay.weekday;

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Day Labels Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: dayLabels.asMap().entries.map((entry) {
                final label = entry.value;
                final isWeekend = entry.key >= 5;
                
                return SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isWeekend
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Day Divider
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 1,
              color: Colors.grey.withValues(alpha: 0.1),
            ),
          ),

          // Days Grid
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: [
              // Empty cells
              ...List.generate(startingWeekday - 1, (_) => const SizedBox()),

              // Day cells
              ...List.generate(daysInMonth, (index) {
                final day = index + 1;
                final date = DateTime(month.year, month.month, day);
                final normalizedDate = DateTime(date.year, date.month, date.day);
                
                final isLeaveDay = _leaveDates.contains(normalizedDate);
                final isToday = normalizedDate.isAtSameMomentAs(
                  DateTime(_currentDate.year, _currentDate.month, _currentDate.day),
                );
                final isFutureDate = date.isAfter(_currentDate);
                
                final inPredictionRange = _lastLeaveDay != null &&
                    !normalizedDate.isAfter(_lastLeaveDay!) &&
                    !normalizedDate.isBefore(DateTime(_currentDate.year, _currentDate.month, _currentDate.day)) &&
                    !isLeaveDay;

                Color bgColor = Colors.transparent;
                Color borderColor = Colors.grey.withValues(alpha: 0.08);
                Color textColor = Colors.black87;
                double borderWidth = 1;
                double elevation = 0;

                if (isToday) {
                  bgColor = AppTheme.primaryBlue.withValues(alpha: 0.12);
                  borderColor = AppTheme.primaryBlue;
                  textColor = AppTheme.primaryBlue;
                  borderWidth = 2;
                  elevation = 2;
                } else if (isLeaveDay) {
                  bgColor = AppTheme.errorRed.withValues(alpha: 0.12);
                  borderColor = AppTheme.errorRed;
                  textColor = AppTheme.errorRed;
                  borderWidth = 2;
                  elevation = 2;
                } else if (inPredictionRange && _considerUnmarkedAsPresent) {
                  bgColor = AppTheme.successGreen.withValues(alpha: 0.08);
                  borderColor = AppTheme.successGreen.withValues(alpha: 0.4);
                  elevation = 1;
                }

                return GestureDetector(
                  onTap: isFutureDate ? () => _toggleLeaveDate(date) : null,
                  child: Material(
                    color: bgColor,
                    elevation: isFutureDate ? elevation : 0,
                    shadowColor: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: borderColor, width: borderWidth),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: textColor,
                              ),
                            ),
                          ),
                          // Indicators
                          if (isToday)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          else if (isLeaveDay)
                            Positioned(
                              bottom: 4,
                              child: Icon(
                                Icons.close,
                                size: 13,
                                color: AppTheme.errorRed,
                              ),
                            )
                          else if (inPredictionRange && _considerUnmarkedAsPresent)
                            Positioned(
                              bottom: 4,
                              child: Icon(
                                Icons.check_circle,
                                size: 12,
                                color: AppTheme.successGreen,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildCourseCard(
    String courseName,
    Color color,
    Map<String, dynamic> prediction,
    DataProvider dataProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.05), color.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              courseName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From today to ${_lastLeaveDay != null ? DateFormat('MMM d').format(_lastLeaveDay!) : 'today'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: color.withValues(alpha: 0.5)),
                  onPressed: () {
                    setState(() {
                      _selectedCourses.remove(courseName);
                    });
                  },
                  iconSize: 20,
                ),
              ],
            ),
          ),

          // Stats Section with Current vs Predicted (Side by Side)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Current Attendance (Left)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(prediction['currentPercentage'] as double).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (prediction['currentPercentage'] as double) / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCompactStatItem(
                            'Present',
                            prediction['currentPresent'].toString(),
                            AppTheme.successGreen,
                          ),
                          _buildCompactStatItem(
                            'Absent',
                            prediction['currentAbsent'].toString(),
                            AppTheme.errorRed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 140,
                  color: color.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // Predicted Attendance (Right)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Predicted',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(prediction['predictedPercentage'] as double).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (prediction['predictedPercentage'] as double) / 100,
                          minHeight: 6,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCompactStatItem(
                            'Present',
                            prediction['predictedPresent'].toString(),
                            AppTheme.successGreen,
                          ),
                          _buildCompactStatItem(
                            'Absent',
                            prediction['predictedAbsent'].toString(),
                            AppTheme.errorRed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }
}