// data_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';
import 'notification_service.dart';
import 'timetable_models.dart';
import 'api_service.dart'; // Import ApiService
import 'package:uuid/uuid.dart';

class DataProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService(); // Initialize ApiService
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
  Future<void> signIn(String email, String password) async {
    try {
      await _apiService.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      _isAuthenticated = true;
      
      // Load data from backend after login
      await _loadData();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  // Sign up
  Future<void> signUp(String name, String email, String password) async {
    try {
      await _apiService.register(name, email, password);
      // Auto login after registration
      await signIn(email, password);
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _apiService.logout(); // Clear token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAuthenticated', false);
    await prefs.remove('events');
    await prefs.remove('categories');
    await prefs.remove('timetable');
    await prefs.remove('attendance');
    
    _isAuthenticated = false;
    _events = [];
    _categories = [];
    _timetableEntries = [];
    _attendanceRecords = [];
    
    // Load local defaults if any, or just clear
    _initializeDefaultCategories();
    
    notifyListeners();
  }

  // Load data from SharedPreferences and Backend
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Load Local Data (Cache)
    _loadLocalData(prefs);

    // 2. Sync from Backend if authenticated
    if (_isAuthenticated) {
      await _syncWithBackend();
    }
    
    notifyListeners();
  }

  void _loadLocalData(SharedPreferences prefs) {
    // Events
    final eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final List<dynamic> eventsList = jsonDecode(eventsJson);
      _events = eventsList.map((e) => Event.fromJson(e)).toList();
    }
    
    // Categories
    final categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      final List<dynamic> categoriesList = jsonDecode(categoriesJson);
      _categories = categoriesList.map((c) => Category.fromJson(c)).toList();
    } else {
      _initializeDefaultCategories();
    }

    // Timetable
    final timetableJson = prefs.getString('timetable');
    if (timetableJson != null) {
      final List<dynamic> timetableList = jsonDecode(timetableJson);
      _timetableEntries = timetableList.map((e) => TimetableEntry.fromJson(e)).toList();
    }

    // Attendance
    final attendanceJson = prefs.getString('attendance');
    if (attendanceJson != null) {
      final List<dynamic> attendanceList = jsonDecode(attendanceJson);
      _attendanceRecords = attendanceList.map((e) => AttendanceRecord.fromJson(e)).toList();
    }
  }

  Future<void> _syncWithBackend() async {
    try {
      // Refresh all data from backend
      final backendTasks = await _apiService.getTasks();
      final backendEvents = await _apiService.getEvents();
      final backendTimetable = await _apiService.getTimetable();
      final backendAttendance = await _apiService.getAttendance();
      final backendCategories = await _apiService.getCategories();

      // Merge Logic: Backend is source of truth for synced items.
      // We keep local auto-generated items.

      // 1. Merge Events & Tasks
      // Create a map of backend events (Tasks + Events)
      final backendEventMap = {
        for (var e in backendTasks) e.id: e,
        for (var e in backendEvents) e.id: e,
      };

      // Keep local events that are NOT in backend ONLY if they are auto-generated or unsynced (if we had queue)
      // For now, we replace any event that has a matching ID, and add new ones.
      // We also need to keep auto-generated events from current local state?
      // No, we should regenerate them from the synced timetable.
      
      // So, _events = BackendEvents + GeneratedEventsFrom(BackendTimetable)
      
      _events = backendEventMap.values.toList();
      _timetableEntries = backendTimetable;
      _attendanceRecords = backendAttendance;
      
      // Update categories if backend has them, else keep local manual ones?
      // Let's assume backend covers it.
      if (backendCategories.isNotEmpty) {
        _categories = backendCategories;
      }
      
      // Regenerate timetable events based on new timetable
      for (var entry in _timetableEntries) {
        _generateEventsFromTimetable(entry, save: false); // Don't save yet
      }

      await _saveData();
    } catch (e) {
      debugPrint('Failed to sync with backend: $e');
    }
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

  void _initializeDefaultCategories() {
    if (_categories.isEmpty) {
      _categories = [
        Category(id: 'general', name: 'General', color: '#8E8E93'),
        Category(id: 'math', name: 'Mathematics', color: '#4A90E2'),
        Category(id: 'science', name: 'Science', color: '#6FCFB4'),
        Category(id: 'language', name: 'Language', color: '#9B72CB'),
        Category(id: 'social', name: 'Social Studies', color: '#FF8C61'),
      ];
      _saveData();
    }
  }

  // ==================== EVENT METHODS ====================

  Future<void> addEvent(Event event) async {
    // Optimistic Update
    _events.add(event);
    _scheduleEventNotifications(event);
    _saveData();
    notifyListeners();

    if (_isAuthenticated) {
       try {
         Event createdEvent;
         // Check if it should be a Task (Assignment/Exam) or Generic Event
         if (event.isTask) {
            createdEvent = await _apiService.createTask(event);
         } else {
            createdEvent = await _apiService.createEvent(event);
         }
         
         // Replace local temp event with backend event (updated ID)
         final index = _events.indexWhere((e) => e.id == event.id);
         if (index != -1) {
           _events[index] = createdEvent;
           _saveData();
           notifyListeners();
         }
       } catch (e) {
         debugPrint('Failed to sync add event: $e');
         // TODO: Mark as unsynced for later retry
       }
    }
  }

  Future<void> updateEvent(Event event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _cancelEventNotifications(event.id);
      _events[index] = event;
      _scheduleEventNotifications(event);
      _saveData();
      notifyListeners();

      if (_isAuthenticated) {
        // Skip sync for auto-generated events unless they are being converted to real events?
        // For now, assume if user edits, we might want to convert (not implemented).
        if (event.metadata != null && event.metadata!['autoGenerated'] == true) {
           return; 
        }

        try {
          if (event.isTask) {
            await _apiService.updateTask(event);
          } else {
            await _apiService.updateEvent(event);
          }
        } catch (e) {
          debugPrint('Failed to sync update event: $e');
        }
      }
    }
  }

  Future<void> deleteEvent(String id) async {
    final eventToCheck = _events.firstWhere(
        (e) => e.id == id, 
        orElse: () => Event(id: '', title: '', classification: '', startTime: DateTime.now())
    );
    
    _cancelEventNotifications(id);
    _events.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();

    if (_isAuthenticated && eventToCheck.id.isNotEmpty) {
       // Skip auto-generated
       if (eventToCheck.metadata != null && eventToCheck.metadata!['autoGenerated'] == true) {
          return;
       }

       try {
         if (eventToCheck.isTask) {
           await _apiService.deleteTask(id);
         } else {
           await _apiService.deleteEvent(id);
         }
       } catch (e) {
          debugPrint('Failed to sync delete event: $e');
       }
    }
  }

  void toggleEventComplete(String id) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      final event = _events[index];
      event.isCompleted = !event.isCompleted;
      updateEvent(event); // Handles sync
    }
  }

  // ==================== TIMETABLE METHODS ====================

  Future<void> addTimetableEntry(TimetableEntry entry) async {
    _timetableEntries.add(entry);
    _generateEventsFromTimetable(entry);
    _saveData();
    notifyListeners();

    if (_isAuthenticated) {
      try {
        final createdEntry = await _apiService.createTimetableEntry(entry);
        // Update local ID
        final index = _timetableEntries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          _timetableEntries[index] = createdEntry;
          // Re-generate events with new ID
          // First remove old ones
          _events.removeWhere((e) => e.metadata != null && e.metadata!['timetableEntryId'] == entry.id);
          _generateEventsFromTimetable(createdEntry);
          _saveData();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Failed to sync add timetable: $e');
      }
    }
  }

  Future<void> updateTimetableEntry(TimetableEntry entry) async {
    final index = _timetableEntries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _timetableEntries[index] = entry;
      // Regenerate events
      _events.removeWhere((e) => e.metadata != null && e.metadata!['timetableEntryId'] == entry.id);
      _generateEventsFromTimetable(entry);
      
      _saveData();
      notifyListeners();

      if (_isAuthenticated) {
        try {
          await _apiService.updateTimetableEntry(entry);
        } catch (e) {
          debugPrint('Failed to sync update timetable: $e');
        }
      }
    }
  }

  Future<void> deleteTimetableEntry(String id) async {
    final index = _timetableEntries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final entry = _timetableEntries[index];

    _timetableEntries.removeAt(index);
    _events.removeWhere((e) => e.metadata != null && e.metadata!['timetableEntryId'] == id);
    
     // Only delete attendance if there are no more classes with this name
    final hasOtherClasses = _events.any((e) => 
      e.classification == 'class' && 
      e.title.toLowerCase() == entry.courseName.toLowerCase()
    );
    
    if (!hasOtherClasses) {
      // Optional: Ask user before deleting attendance? For now, we keep it locally unsafe or delete safe
      // Logic from original code:
       _attendanceRecords.removeWhere((r) => 
        r.courseName.toLowerCase() == entry.courseName.toLowerCase()
      );
    }

    _saveData();
    notifyListeners();

    if (_isAuthenticated) {
      try {
        await _apiService.deleteTimetableEntry(id);
      } catch (e) {
        debugPrint('Failed to sync delete timetable: $e');
      }
    }
  }

  void _generateEventsFromTimetable(TimetableEntry entry, {bool save = true}) {
    // Logic to generate events... (Same as before but ensures they are pushed to _events)
    final startDate = entry.semesterStart ?? DateTime.now();
    final endDate = entry.semesterEnd ?? DateTime.now().add(const Duration(days: 180));
    final now = DateTime.now();
    var currentDate = startDate.isAfter(now) 
        ? DateTime(startDate.year, startDate.month, startDate.day)
        : DateTime(now.year, now.month, now.day);
    
    while (currentDate.isBefore(endDate)) {
      final dayOfWeek = currentDate.weekday;
      
      if (entry.daysOfWeek.contains(dayOfWeek)) {
        final dateStr = currentDate.toIso8601String().split('T')[0];
        if (!entry.excludedDates.contains(dateStr)) {
          bool withinSemester = true;
          if (entry.semesterStart != null && currentDate.isBefore(entry.semesterStart!)) withinSemester = false;
          if (entry.semesterEnd != null && currentDate.isAfter(entry.semesterEnd!)) withinSemester = false;
          
          if (withinSemester) {
             final startDateTime = DateTime(currentDate.year, currentDate.month, currentDate.day, entry.startTime.hour, entry.startTime.minute);
             final endDateTime = DateTime(currentDate.year, currentDate.month, currentDate.day, entry.endTime.hour, entry.endTime.minute);

             // Check duplicate
             final existing = _events.any((e) => 
               e.metadata != null && e.metadata!['timetableEntryId'] == entry.id &&
               e.startTime.year == startDateTime.year && e.startTime.month == startDateTime.month && e.startTime.day == startDateTime.day
             );

             if (!existing) {
               _events.add(Event(
                 id: const Uuid().v4(),
                 title: entry.courseName,
                 classification: 'class',
                 category: entry.category,
                 startTime: startDateTime,
                 endTime: endDateTime,
                 location: entry.room,
                 notes: entry.courseCode != null ? 'Course: ${entry.courseCode}' : null,
                 metadata: {'timetableEntryId': entry.id, 'autoGenerated': true}
               ));
             }
          }
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    if (save) _saveData();
  }


  // ==================== ATTENDANCE METHODS ====================

  Future<void> markAttendance(AttendanceRecord record) async {
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

    if (_isAuthenticated) {
      try {
        await _apiService.markAttendance(record);
      } catch (e) {
        debugPrint('Failed to sync attendance: $e');
      }
    }
  }

  Future<void> deleteAttendanceRecord(String id) async {
     _attendanceRecords.removeWhere((r) => r.id == id);
     _saveData();
     notifyListeners();
     
     if (_isAuthenticated) {
       try {
         await _apiService.deleteAttendance(id);
       } catch (e) {
         debugPrint('Failed to sync delete attendance: $e');
       }
     }
  }

  // ==================== CATEGORY METHODS ====================

  Future<void> addCategory(Category category) async {
    _categories.add(category);
    _saveData();
    notifyListeners();

    if (_isAuthenticated) {
      try {
        final created = await _apiService.createCategory(category);
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = created;
          _saveData();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Failed to sync add category: $e');
      }
    }
  }

  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      _saveData();
      notifyListeners();

      if (_isAuthenticated) {
        try {
          await _apiService.updateCategory(category);
        } catch (e) {
           debugPrint('Failed to sync update category: $e');
        }
      }
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    _saveData();
    notifyListeners();

    if (_isAuthenticated) {
      try {
        await _apiService.deleteCategory(id);
      } catch (e) {
        debugPrint('Failed to sync delete category: $e');
      }
    }
  }
  
  // Helpers
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

  List<Event> get incompleteTasks => _events.where((e) => e.isTask && !e.isCompleted).toList();
  List<Event> get completedTasks => _events.where((e) => e.isTask && e.isCompleted).toList();
  List<Event> get allTasks => _events.where((e) => e.isTask).toList();

  List<Event> getUpcomingDeadlines({int limit = 10}) {
    final now = DateTime.now();
    return _events.where((e) => e.isTask && !e.isCompleted && e.startTime.isAfter(now)).take(limit).toList();
  }

  Map<String, int> getTodayStats() {
    final now = DateTime.now();
    final todayEvents = getEventsForDay(now);
    return {
      'classes': todayEvents.where((e) => e.classification == 'class').length,
      'exams': todayEvents.where((e) => e.classification == 'exam').length,
      'assignments': todayEvents.where((e) => e.classification == 'assignment' && !e.isCompleted).length,
      'meetings': todayEvents.where((e) => e.classification == 'meeting').length,
    };
  }
  
  Category? getCategoryById(String? id) => id == null ? null : _categories.firstWhere((c) => c.id == id, orElse: () => Category(id: 'unknown', name: 'Unknown'));
  
  // Count events for a day (for calendar preview)
  Map<String, int> getCountsForDay(DateTime day) {
    final events = getEventsForDay(day);
    return {
      'events': events.where((e) => !e.isTask).length,
      'tasks': events.where((e) => e.isTask && !e.isCompleted).length,
    };
  }

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
    try {
      final event = _events.firstWhere((e) => e.id == eventId);
      for (int i = 0; i < event.reminders.length; i++) {
        final notificationId = eventId.hashCode + i;
        notificationService.cancelNotification(notificationId);
      }
    } catch (e) {
      // Event might already be gone or not found
    }
  }
  
  // Re-implement simplified helpers to match original file structure if needed
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

  // ==================== MISSING METHODS RESTORED ====================

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
    final dayOfWeek = date.weekday;
    final dateStr = date.toIso8601String().split('T')[0];
    
    return _timetableEntries.where((entry) {
      if (!entry.daysOfWeek.contains(dayOfWeek)) return false;
      if (entry.excludedDates.contains(dateStr)) return false;
      if (entry.semesterStart != null && date.isBefore(entry.semesterStart!)) return false;
      if (entry.semesterEnd != null && date.isAfter(entry.semesterEnd!)) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });
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
    int cancelled = 0;
    
    for (var record in records) {
      switch (record.status) {
        case AttendanceStatus.present: present++; break;
        case AttendanceStatus.absent: absent++; break;
        case AttendanceStatus.late: late++; break;
        case AttendanceStatus.excused: excused++; break;
        case AttendanceStatus.cancelled: cancelled++; break;
      }
    }
    
    final totalClasses = records.length - cancelled;
    
    return AttendanceStats(
      totalClasses: totalClasses,
      present: present,
      absent: absent,
      late: late,
      excused: excused,
    );
  }

  Map<String, AttendanceStats> getAllAttendanceStats() {
    final stats = <String, AttendanceStats>{};
    final courseNames = <String>{};
    
    for (var entry in _timetableEntries) {
      courseNames.add(entry.courseName);
    }
    
    for (var event in _events) {
      if (event.classification == 'class') {
        courseNames.add(event.title);
      }
    }
    
    for (var courseName in courseNames) {
      stats[courseName] = getAttendanceStats(courseName);
    }
    
    return stats;
  }

  List<Event> getClassEventsForCourse(String courseName) {
    return _events
        .where((e) => 
          e.classification == 'class' && 
          e.title.toLowerCase() == courseName.toLowerCase())
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> resetTimetableAndAttendance() async {
    _timetableEntries.clear();
    _attendanceRecords.clear();
    _events.removeWhere((e) => e.classification == 'class');
    await _saveData();
    notifyListeners();
  }

  Future<void> resetAttendance() async {
    _attendanceRecords.clear();
    await _saveData();
    notifyListeners();
  }

  void clearAttendanceForCourse(String courseName) {
    _attendanceRecords.removeWhere((r) => 
      r.courseName.toLowerCase() == courseName.toLowerCase()
    );
    _saveData();
    notifyListeners();
  }

  // ==================== MORE MISSING METHODS RESTORED ====================

  List<Event> getEventsByClassification(String classification) {
    return _events
        .where((e) => e.classification == classification)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<Event> getEventsByCategory(String categoryId) {
    return _events
        .where((e) => e.category == categoryId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void addVoiceNoteToEvent(String eventId, VoiceNote voiceNote) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _events[index];
      // Create a new list to ensure change detection or immutability if needed
      final updatedVoiceNotes = List<VoiceNote>.from(event.voiceNotes)..add(voiceNote);
      
      // We need to update the event's voiceNotes. 
      // Assuming Event is mutable or we replace it.
      // Based on models.dart usage in original file, it seemed mutable access or copyWith.
      // But looking at models.dart in Step 666 migration logic:
      // event.voiceNotes = ...
      // So let's try direct assignment if the field is mutable.
      // If Event class has final voiceNotes, we need copyWith.
      // Let's assume mutable for now as per previous code, but safer to replace event in list.
      
      event.voiceNotes = updatedVoiceNotes; 
      updateEvent(event);
    }
  }
}