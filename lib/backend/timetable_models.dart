/// Timetable Models - Course Schedule Management
/// 
/// This file defines models for managing recurring class schedules:
/// - TimetableEntry: Course schedule that auto-generates events
/// - AttendanceRecord: Records for marking attendance on class sessions
/// - AttendanceStats: Calculated attendance statistics per course
/// 
/// When a TimetableEntry is added, it automatically creates Event records
/// for each scheduled day within the semester date range

import 'package:flutter/material.dart';

// ========== TIMETABLE ENTRY ==========
/// TimetableEntry - Represents a recurring course schedule
/// 
/// When added to DataProvider, automatically generates Events for:
/// - Each day in daysOfWeek (1=Monday, 7=Sunday)
/// - Within the semester date range
/// - Excluding dates in excludedDates (holidays, breaks)
/// 
/// Example: Monday/Wednesday/Friday 9:00-10:30 from Jan 1 - May 31
/// generates ~40 class events (3 per week × ~13 weeks)
class TimetableEntry {
  final String id;
  /// Course name (e.g., 'Computer Science 101')
  String courseName;
  /// Course code (e.g., 'CS101')
  String? courseCode;
  /// Professor/instructor name
  String? instructor;
  /// Classroom location
  String? room;
  /// Days this class meets: 1=Monday through 7=Sunday (e.g., [1,3,5] = MWF)
  List<int> daysOfWeek; // 1=Monday, 7=Sunday
  /// Start time for each class session (e.g., 9:00 AM)
  TimeOfDay startTime;
  /// End time for each class session (e.g., 10:30 AM)
  TimeOfDay endTime;
  /// Category for filtering/organization (optional, e.g., 'Major Requirement')
  String? category; // Link to existing categories
  String? color;
  /// First day of semester - used to generate events
  DateTime? semesterStart;
  /// Last day of semester - events generated up to this date
  DateTime? semesterEnd;
  /// ISO date strings for holidays/breaks to skip (e.g., ['2024-03-18', '2024-11-28'])
  List<String> excludedDates; // ISO strings for holidays/breaks
  int periodCount; // How many periods this entry counts for (default 1)


  TimetableEntry({
    required this.id,
    required this.courseName,
    this.courseCode,
    this.instructor,
    this.room,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    this.category,
    this.color,
    DateTime? semesterStart,
    DateTime? semesterEnd,
    this.excludedDates = const [],
    this.periodCount = 1,
  }) : semesterStart = semesterStart ?? DateTime.now(),
       semesterEnd = semesterEnd ?? DateTime.now().add(const Duration(days: 180)); // Default 6 months

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseName': courseName,
        'courseCode': courseCode,
        'instructor': instructor,
        'room': room,
        'daysOfWeek': daysOfWeek,
        'startTime': '${startTime.hour}:${startTime.minute}',
        'endTime': '${endTime.hour}:${endTime.minute}',
        'category': category,
        'color': color,
        'semesterStart': semesterStart?.toIso8601String(),
        'semesterEnd': semesterEnd?.toIso8601String(),
        'excludedDates': excludedDates,
        'periodCount': periodCount,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    final startParts = (json['startTime'] as String).split(':');
    final endParts = (json['endTime'] as String).split(':');

    return TimetableEntry(
      id: json['id'],
      courseName: json['courseName'],
      courseCode: json['courseCode'],
      instructor: json['instructor'],
      room: json['room'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      startTime: TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
      category: json['category'],
      color: json['color'],
      semesterStart: json['semesterStart'] != null
          ? DateTime.parse(json['semesterStart'])
          : null,
      semesterEnd: json['semesterEnd'] != null
          ? DateTime.parse(json['semesterEnd'])
          : null,
      excludedDates: List<String>.from(json['excludedDates'] ?? []),
      periodCount: json['periodCount'] ?? 1,
    );
  }

  TimetableEntry copyWith({
    String? id,
    String? courseName,
    String? courseCode,
    String? instructor,
    String? room,
    List<int>? daysOfWeek,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? category,
    String? color,
    DateTime? semesterStart,
    DateTime? semesterEnd,
    List<String>? excludedDates,
    int? periodCount,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      category: category ?? this.category,
      color: color ?? this.color,
      semesterStart: semesterStart ?? this.semesterStart,
      semesterEnd: semesterEnd ?? this.semesterEnd,
      excludedDates: excludedDates ?? this.excludedDates,
      periodCount: periodCount ?? this.periodCount,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String courseName; // Changed from timetableEntryId to courseName
  final DateTime date;
  AttendanceStatus status;
  String? notes;
  int periodCount; // How many periods this attendance record counts for

  AttendanceRecord({
    required this.id,
    required this.courseName,
    required this.date,
    required this.status,
    this.notes,
    this.periodCount = 1,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseName': courseName,
        'date': date.toIso8601String(),
        'status': status.toString().split('.').last,
        'notes': notes,
        'periodCount': periodCount,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      courseName: json['courseName'],
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AttendanceStatus.present,
      ),
      notes: json['notes'],
      periodCount: json['periodCount'] ?? 1,
    );
  }
}

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
  cancelled
}

class AttendanceStats {
  final int totalClasses;
  final int present;
  final int absent;
  final int late;
  final int excused;

  AttendanceStats({
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });

  double get attendancePercentage {
    if (totalClasses == 0) return 0;
    return (present / totalClasses) * 100;
  }

  double get presentWithLatePercentage {
    if (totalClasses == 0) return 0;
    return ((present + late) / totalClasses) * 100;
  }
}