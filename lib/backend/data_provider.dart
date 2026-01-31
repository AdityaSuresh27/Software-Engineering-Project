import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';

class DataProvider extends ChangeNotifier {
  List<Event> _events = [];
  List<Task> _tasks = [];
  bool _isAuthenticated = false;

  List<Event> get events => _events;
  List<Task> get tasks => _tasks;
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
    await prefs.remove('tasks');
    _isAuthenticated = false;
    _events = [];
    _tasks = [];
    notifyListeners();
  }

  // Load data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load events
    final eventsJson = prefs.getString('events');
    if (eventsJson != null) {
      final List<dynamic> eventsList = jsonDecode(eventsJson);
      _events = eventsList.map((e) => Event.fromJson(e)).toList();
    }
    
    // Load tasks
    final tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final List<dynamic> tasksList = jsonDecode(tasksJson);
      _tasks = tasksList.map((t) => Task.fromJson(t)).toList();
    }
    
    notifyListeners();
  }

  // Save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save events
    final eventsJson = jsonEncode(_events.map((e) => e.toJson()).toList());
    await prefs.setString('events', eventsJson);
    
    // Save tasks
    final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('tasks', tasksJson);
  }

  // Event methods
  void addEvent(Event event) {
    _events.add(event);
    _saveData();
    notifyListeners();
  }

  void updateEvent(Event event) {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      _saveData();
      notifyListeners();
    }
  }

  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    _saveData();
    notifyListeners();
  }

  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.startTime.year == day.year &&
          event.startTime.month == day.month &&
          event.startTime.day == day.day;
    }).toList();
  }

  // Get events for date range (for 3-day preview)
  List<Event> getEventsForRange(DateTime start, DateTime end) {
    return _events.where((event) {
      return event.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
          event.startTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Task methods
  void addTask(Task task) {
    _tasks.add(task);
    _saveData();
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveData();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _saveData();
    notifyListeners();
  }

  void toggleTaskComplete(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].completed = !_tasks[index].completed;
      _saveData();
      notifyListeners();
    }
  }

  List<Task> get incompleteTasks => _tasks.where((t) => !t.completed).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.completed).toList();

  // Get tasks for today
  List<Task> getTasksForDay(DateTime day) {
    return _tasks.where((task) {
      return task.deadline.year == day.year &&
          task.deadline.month == day.month &&
          task.deadline.day == day.day;
    }).toList();
  }

  // Get all items (events + tasks) for timeline on a specific day
  List<dynamic> getTimelineItemsForDay(DateTime day) {
    final dayEvents = getEventsForDay(day);
    final dayTasks = getTasksForDay(day);
    
    // Combine and sort by time
    final items = <dynamic>[...dayEvents, ...dayTasks];
    items.sort((a, b) {
      final aTime = a is Event ? a.startTime : a.deadline;
      final bTime = b is Event ? b.startTime : b.deadline;
      return aTime.compareTo(bTime);
    });
    
    return items;
  }

  // Count tasks/events for a specific day (for 3-day preview)
  Map<String, int> getCountsForDay(DateTime day) {
    final events = getEventsForDay(day);
    final tasks = getTasksForDay(day);
    
    return {
      'events': events.length,
      'tasks': tasks.length,
    };
  }

  // Get upcoming deadlines
  List<Task> getUpcomingDeadlines({int limit = 10}) {
    final now = DateTime.now();
    final upcoming = _tasks
        .where((t) => !t.completed && t.deadline.isAfter(now))
        .toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    return upcoming.take(limit).toList();
  }

  // Get today's stats
  Map<String, int> getTodayStats() {
    final now = DateTime.now();
    final todayEvents = getEventsForDay(now);
    final todayTasks = getTasksForDay(now);
    
    // Count by type
    int classes = todayEvents.where((e) => e.type == 'lecture' || e.type == 'lab').length;
    int exams = todayEvents.where((e) => e.type == 'exam').length + 
                todayTasks.where((t) => t.type == 'exam').length;
    int tasksCount = todayTasks.where((t) => !t.completed).length;
    
    return {
      'classes': classes,
      'exams': exams,
      'tasks': tasksCount,
    };
  }

  // Add voice note to an event
  void addVoiceNoteToEvent(String eventId, VoiceNote voiceNote) {
    final event = _events.firstWhere((e) => e.id == eventId);
    event.voiceNotes = [...event.voiceNotes, voiceNote];
    updateEvent(event);
  }

  // Add voice note to a task
  void addVoiceNoteToTask(String taskId, VoiceNote voiceNote) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.voiceNotes = [...task.voiceNotes, voiceNote];
    updateTask(task);
  }
}