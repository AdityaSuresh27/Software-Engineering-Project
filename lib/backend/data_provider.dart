// data_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';
import 'notification_service.dart';
import 'timetable_models.dart';
import 'package:uuid/uuid.dart';

class DataProvider extends ChangeNotifier {
  List<Event> _events = [];
  List<Category> _categories = [];
  bool _isAuthenticated = false;
  List<TimetableEntry> _timetableEntries = [];
  List<AttendanceRecord> _attendanceRecords = [];

  List<TimetableEntry> get timetableEntries => _timetableEntries;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  List<Event> get events => _events;
  List<Category> get categories => _categories;
  bool get isAuthenticated => _isAuthenticated;

  DataProvider() {
    _loadData();
    _checkAuthStatus();
  }

  // Check authentication status
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    notifyListeners();
  }

  // Sign in
  Future<void> signIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', true);
    _isAuthenticated = true;
    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.remove('events');
    await prefs.remove('categories');
    // Keep old data for migration if needed
    _isAuthenticated = false;
    _events = [];
    _categories = [];
    notifyListeners();
  }

  // Load data from SharedPreferences with migration
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try loading new unified events first
    final eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final List<dynamic> eventsList = jsonDecode(eventsJson);
      _events = eventsList.map((e) => Event.fromJson(e)).toList();
    } else {
      // Migration: Load old events and tasks, convert to new format
      await _migrateOldData(prefs);
    }
    
    // Load categories
    final categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      final List<dynamic> categoriesList = jsonDecode(categoriesJson);
      _categories = categoriesList.map((c) => Category.fromJson(c)).toList();
    } else {
      _initializeDefaultCategories();
    }
    // Load timetable entries
    final timetableJson = prefs.getString('timetable');
    if (timetableJson != null) {
      final List<dynamic> timetableList = jsonDecode(timetableJson);
      _timetableEntries = timetableList.map((e) => TimetableEntry.fromJson(e)).toList();
    }

    // Load attendance records
    final attendanceJson = prefs.getString('attendance');
    if (attendanceJson != null) {
      final List<dynamic> attendanceList = jsonDecode(attendanceJson);
      _attendanceRecords = attendanceList.map((e) => AttendanceRecord.fromJson(e)).toList();
    }
    notifyListeners();
  }

  // Migrate old Event/Task data to new unified Event system
  Future<void> _migrateOldData(SharedPreferences prefs) async {
    final oldEventsJson = prefs.getString('events');
    final oldTasksJson = prefs.getString('tasks');
    
    List<Event> migratedEvents = [];
    
    // Migrate old events
    if (oldEventsJson != null) {
      try {
        final List<dynamic> oldEventsList = jsonDecode(oldEventsJson);
        for (var oldEvent in oldEventsList) {
          migratedEvents.add(Event(
            id: oldEvent['id'],
            title: oldEvent['title'],
            classification: _mapOldTypeToClassification(oldEvent['type']),
            category: oldEvent['subject'],
            startTime: DateTime.parse(oldEvent['startTime']),
            endTime: DateTime.parse(oldEvent['endTime']),
            location: oldEvent['location'],
            notes: oldEvent['notes'],
            attachments: List<String>.from(oldEvent['attachments'] ?? []),
            voiceNotes: (oldEvent['voiceNotes'] as List?)
                ?.map((v) => VoiceNote.fromJson(v))
                .toList() ?? [],
            isImportant: oldEvent['isImportant'] ?? false,
            reminders: (oldEvent['reminders'] as List?)
                ?.map((r) => DateTime.parse(r as String))
                .toList() ?? [],
            priority: 'medium',
          ));
        }
      } catch (e) {
        debugPrint('Error migrating old events: $e');
      }
    }
    
    // Migrate old tasks
    if (oldTasksJson != null) {
      try {
        final List<dynamic> oldTasksList = jsonDecode(oldTasksJson);
        for (var oldTask in oldTasksList) {
          migratedEvents.add(Event(
            id: oldTask['id'],
            title: oldTask['title'],
            classification: _mapOldTypeToClassification(oldTask['type']),
            category: oldTask['subject'],
            startTime: DateTime.parse(oldTask['deadline']),
            endTime: null,
            notes: oldTask['notes'],
            attachments: List<String>.from(oldTask['attachments'] ?? []),
            voiceNotes: (oldTask['voiceNotes'] as List?)
                ?.map((v) => VoiceNote.fromJson(v))
                .toList() ?? [],
            isCompleted: oldTask['completed'] ?? false,
            priority: oldTask['priority'] ?? 'medium',
            estimatedDuration: oldTask['estimatedDuration'],
            isImportant: oldTask['isImportant'] ?? false,
            reminders: (oldTask['reminders'] as List?)
                ?.map((r) => DateTime.parse(r as String))
                .toList() ?? [],
          ));
        }
      } catch (e) {
        debugPrint('Error migrating old tasks: $e');
      }
    }
    
    _events = migratedEvents;
    if (migratedEvents.isNotEmpty) {
      await _saveData();
    }
  }

  String _mapOldTypeToClassification(String oldType) {
    switch (oldType.toLowerCase()) {
      case 'lecture':
        return 'class';
      case 'lab':
        return 'class';
      case 'exam':
        return 'exam';
      case 'submission':
      case 'assignment':
        return 'assignment';
      case 'note':
        return 'other';
      default:
        return 'other';
    }
  }

  void _initializeDefaultCategories() {
    _categories = [
      Category(id: 'general', name: 'General', color: '#8E8E93'),
      Category(id: 'math', name: 'Mathematics', color: '#4A90E2'),
      Category(id: 'science', name: 'Science', color: '#6FCFB4'),
      Category(id: 'language', name: 'Language', color: '#9B72CB'),
      Category(id: 'social', name: 'Social Studies', color: '#FF8C61'),
    ];
    _saveData();
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final eventsJson = jsonEncode(_events.map((e) => e.toJson()).toList());
    await prefs.setString('events', eventsJson);
    
    final categoriesJson = jsonEncode(_categories.map((c) => c.toJson()).toList());
    await prefs.setString('categories', categoriesJson);

    final timetableJson = jsonEncode(_timetableEntries.map((e) => e.toJson()).toList());
    await prefs.setString('timetable', timetableJson);

    final attendanceJson = jsonEncode(_attendanceRecords.map((e) => e.toJson()).toList());
    await prefs.setString('attendance', attendanceJson);
  }

  // Event methods
  void addEvent(Event event) {
    _events.add(event);
    _scheduleEventNotifications(event);
    _saveData();
    notifyListeners();
  }

  void updateEvent(Event event) {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _cancelEventNotifications(event.id);
      _events[index] = event;
      _scheduleEventNotifications(event);
      _saveData();
      notifyListeners();
    }
  }

  void deleteEvent(String id) {
    _cancelEventNotifications(id);
    _events.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }

  void toggleEventComplete(String id) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      _events[index].isCompleted = !_events[index].isCompleted;
      _saveData();
      notifyListeners();
    }
  }

  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.startTime.year == day.year &&
          event.startTime.month == day.month &&
          event.startTime.day == day.day;
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Event> getEventsForRange(DateTime start, DateTime end) {
    return _events.where((event) {
      return event.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
          event.startTime.isBefore(end.add(const Duration(days: 1)));
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Get tasks (events that are task-like)
  List<Event> get incompleteTasks => _events
      .where((e) => e.isTask && !e.isCompleted)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  List<Event> get completedTasks => _events
      .where((e) => e.isTask && e.isCompleted)
      .toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  List<Event> get allTasks => _events
      .where((e) => e.isTask)
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  // Get upcoming deadlines
  List<Event> getUpcomingDeadlines({int limit = 10}) {
    final now = DateTime.now();
    final upcoming = _events
        .where((e) => e.isTask && !e.isCompleted && e.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.take(limit).toList();
  }

  // Get today's stats
  Map<String, int> getTodayStats() {
    final now = DateTime.now();
    final todayEvents = getEventsForDay(now);
    
    int classes = todayEvents.where((e) => e.classification == 'class').length;
    int exams = todayEvents.where((e) => e.classification == 'exam').length;
    int assignments = todayEvents.where((e) => 
        e.classification == 'assignment' && !e.isCompleted).length;
    int meetings = todayEvents.where((e) => e.classification == 'meeting').length;
    
    return {
      'classes': classes,
      'exams': exams,
      'assignments': assignments,
      'meetings': meetings,
    };
  }

  // Voice note methods
  void addVoiceNoteToEvent(String eventId, VoiceNote voiceNote) {
    final event = _events.firstWhere((e) => e.id == eventId);
    event.voiceNotes = [...event.voiceNotes, voiceNote];
    updateEvent(event);
  }

  // Category methods
  void addCategory(Category category) {
    _categories.add(category);
    _saveData();
    notifyListeners();
  }

  void updateCategory(Category category) {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      _saveData();
      notifyListeners();
    }
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    // Update events that used this category
    for (var event in _events) {
      if (event.category == id) {
        event.category = null;
      }
    }
    _saveData();
    notifyListeners();
  }

  Category? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter events by classification
  List<Event> getEventsByClassification(String classification) {
    return _events
        .where((e) => e.classification == classification)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Filter events by category
  List<Event> getEventsByCategory(String categoryId) {
    return _events
        .where((e) => e.category == categoryId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  // Count events for a day (for calendar preview)
  Map<String, int> getCountsForDay(DateTime day) {
    final events = getEventsForDay(day);
    
    return {
      'events': events.where((e) => !e.isTask).length,
      'tasks': events.where((e) => e.isTask && !e.isCompleted).length,
    };
  }
  // Notification scheduling helpers
  void _scheduleEventNotifications(Event event) {
    final notificationService = NotificationService();
    
    for (int i = 0; i < event.reminders.length; i++) {
      final reminder = event.reminders[i];
      if (reminder.isAfter(DateTime.now())) {
        final notificationId = event.id.hashCode + i;
        notificationService.scheduleNotification(
          id: notificationId,
          title: event.title,
          body: 'Reminder: ${event.classification} event',
          scheduledDate: reminder,
        );
      }
    }
  }

  void _cancelEventNotifications(String eventId) {
    final notificationService = NotificationService();
    final event = _events.firstWhere((e) => e.id == eventId, orElse: () => _events.first);
    
    for (int i = 0; i < event.reminders.length; i++) {
      final notificationId = eventId.hashCode + i;
      notificationService.cancelNotification(notificationId);
    }
  }
  // ==================== TIMETABLE METHODS ====================

void addTimetableEntry(TimetableEntry entry) {
  _timetableEntries.add(entry);
  _saveData();
  notifyListeners();
  // Auto-generate events for the next 30 days
  _generateEventsFromTimetable(entry);
}

void updateTimetableEntry(TimetableEntry entry) {
  final index = _timetableEntries.indexWhere((e) => e.id == entry.id);
  if (index != -1) {
    _timetableEntries[index] = entry;
    
    // Remove old auto-generated events for this timetable entry
    _events.removeWhere((e) => 
      e.metadata != null && 
      e.metadata!['timetableEntryId'] == entry.id
    );
    
    // Regenerate events
    _generateEventsFromTimetable(entry);
    
    _saveData();
    notifyListeners();
  }
}

void deleteTimetableEntry(String id) {
  // Get the course name before deleting
  final entry = _timetableEntries.firstWhere((e) => e.id == id);
  final courseName = entry.courseName;
  
  _timetableEntries.removeWhere((e) => e.id == id);
  
  // Remove auto-generated events for this timetable entry
  _events.removeWhere((e) => 
    e.metadata != null && 
    e.metadata!['timetableEntryId'] == id
  );
  
  // Only delete attendance if there are no more classes with this name
  final hasOtherClasses = _events.any((e) => 
    e.classification == 'class' && 
    e.title.toLowerCase() == courseName.toLowerCase()
  );
  
  if (!hasOtherClasses) {
    _attendanceRecords.removeWhere((r) => 
      r.courseName.toLowerCase() == courseName.toLowerCase()
    );
  }
  
  _saveData();
  notifyListeners();
}

// Generate events from timetable entry for the next 30 days
void _generateEventsFromTimetable(TimetableEntry entry) {
  final now = DateTime.now();
  final endDate = now.add(const Duration(days: 30));
  
  // Start from today
  var currentDate = DateTime(now.year, now.month, now.day);
  
  while (currentDate.isBefore(endDate)) {
    final dayOfWeek = currentDate.weekday; // 1=Monday, 7=Sunday
    
    // Check if this day is included in the timetable
    if (entry.daysOfWeek.contains(dayOfWeek)) {
      // Check if this date is excluded
      final dateStr = currentDate.toIso8601String().split('T')[0];
      if (!entry.excludedDates.contains(dateStr)) {
        // Check semester dates
        bool withinSemester = true;
        if (entry.semesterStart != null && currentDate.isBefore(entry.semesterStart!)) {
          withinSemester = false;
        }
        if (entry.semesterEnd != null && currentDate.isAfter(entry.semesterEnd!)) {
          withinSemester = false;
        }
        
        if (withinSemester) {
          // Create event for this day
          final startDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            entry.startTime.hour,
            entry.startTime.minute,
          );
          
          final endDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            entry.endTime.hour,
            entry.endTime.minute,
          );
          
          // Check if event already exists (avoid duplicates)
          final existingEvent = _events.firstWhere(
            (e) => 
              e.metadata != null &&
              e.metadata!['timetableEntryId'] == entry.id &&
              e.startTime.year == startDateTime.year &&
              e.startTime.month == startDateTime.month &&
              e.startTime.day == startDateTime.day,
            orElse: () => Event(
              id: '',
              title: '',
              classification: 'class',
              startTime: DateTime.now(),
            ),
          );
          
          if (existingEvent.id.isEmpty) {
            final event = Event(
              id: const Uuid().v4(),
              title: entry.courseName,
              classification: 'class',
              category: entry.category,
              startTime: startDateTime,
              endTime: endDateTime,
              location: entry.room,
              notes: entry.courseCode != null 
                ? 'Course: ${entry.courseCode}\nInstructor: ${entry.instructor ?? 'N/A'}'
                : (entry.instructor != null ? 'Instructor: ${entry.instructor}' : null),
              priority: 'medium',
              isAllDay: false,
              metadata: {
                'timetableEntryId': entry.id,
                'autoGenerated': true,
              },
            );
            
            _events.add(event);
          }
        }
      }
    }
    
    // Move to next day
    currentDate = currentDate.add(const Duration(days: 1));
  }
  
  _saveData();
}

List<TimetableEntry> getTimetableForDay(int dayOfWeek) {
  return _timetableEntries
      .where((entry) => entry.daysOfWeek.contains(dayOfWeek))
      .toList()
    ..sort((a, b) {
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });
}

List<TimetableEntry> getTimetableForDate(DateTime date) {
  final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
  final dateStr = date.toIso8601String().split('T')[0];
  
  return _timetableEntries.where((entry) {
    // Check if this day is included
    if (!entry.daysOfWeek.contains(dayOfWeek)) return false;
    
    // Check if date is excluded
    if (entry.excludedDates.contains(dateStr)) return false;
    
    // Check semester dates
    if (entry.semesterStart != null && date.isBefore(entry.semesterStart!)) {
      return false;
    }
    if (entry.semesterEnd != null && date.isAfter(entry.semesterEnd!)) {
      return false;
    }
    
    return true;
  }).toList()
    ..sort((a, b) {
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });
}

// ==================== ATTENDANCE METHODS ====================

void markAttendance(AttendanceRecord record) {
  final index = _attendanceRecords.indexWhere(
    (r) => r.courseName.toLowerCase() == record.courseName.toLowerCase() && 
           r.date.year == record.date.year &&
           r.date.month == record.date.month &&
           r.date.day == record.date.day,
  );
  
  if (index != -1) {
    _attendanceRecords[index] = record;
  } else {
    _attendanceRecords.add(record);
  }
  
  _saveData();
  notifyListeners();
}

AttendanceRecord? getAttendanceForDate(String courseName, DateTime date) {
  try {
    return _attendanceRecords.firstWhere(
      (r) => r.courseName.toLowerCase() == courseName.toLowerCase() &&
             r.date.year == date.year &&
             r.date.month == date.month &&
             r.date.day == date.day,
    );
  } catch (e) {
    return null;
  }
}

List<AttendanceRecord> getAttendanceForCourse(String courseName) {
  return _attendanceRecords
      .where((r) => r.courseName.toLowerCase() == courseName.toLowerCase())
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
}

AttendanceStats getAttendanceStats(String courseName) {
  final records = getAttendanceForCourse(courseName);
  
  int present = 0;
  int absent = 0;
  int late = 0;
  int excused = 0;
  
  for (var record in records) {
    switch (record.status) {
      case AttendanceStatus.present:
        present++;
        break;
      case AttendanceStatus.absent:
        absent++;
        break;
      case AttendanceStatus.late:
        late++;
        break;
      case AttendanceStatus.excused:
        excused++;
        break;
    }
  }
  
  return AttendanceStats(
    totalClasses: records.length,
    present: present,
    absent: absent,
    late: late,
    excused: excused,
  );
}

Map<String, AttendanceStats> getAllAttendanceStats() {
  final stats = <String, AttendanceStats>{};
  
  // Get unique course names from both timetable and events
  final courseNames = <String>{};
  
  // From timetable
  for (var entry in _timetableEntries) {
    courseNames.add(entry.courseName);
  }
  
  // From class events
  for (var event in _events) {
    if (event.classification == 'class') {
      courseNames.add(event.title);
    }
  }
  
  // Calculate stats for each course
  for (var courseName in courseNames) {
    stats[courseName] = getAttendanceStats(courseName);
  }
  
  return stats;
}

// Get all class events for a specific course name
List<Event> getClassEventsForCourse(String courseName) {
  return _events
      .where((e) => 
        e.classification == 'class' && 
        e.title.toLowerCase() == courseName.toLowerCase())
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
}

// Reset timetable and attendance completely
Future<void> resetTimetableAndAttendance() async {
  _timetableEntries.clear();
  _attendanceRecords.clear();
  
  // Remove ALL class events (both auto-generated AND manual)
  _events.removeWhere((e) => e.classification == 'class');
  
  await _saveData();
  notifyListeners();
}

// Reset attendance only
Future<void> resetAttendance() async {
  _attendanceRecords.clear();
  await _saveData();
  notifyListeners();
}

// Delete specific attendance record
void deleteAttendanceRecord(String id) {
  _attendanceRecords.removeWhere((r) => r.id == id);
  _saveData();
  notifyListeners();
}

// Clear all attendance for a specific course
void clearAttendanceForCourse(String courseName) {
  _attendanceRecords.removeWhere((r) => 
    r.courseName.toLowerCase() == courseName.toLowerCase()
  );
  _saveData();
  notifyListeners();
}
}