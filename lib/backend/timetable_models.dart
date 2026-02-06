//timetable_models.dart
import 'package:flutter/material.dart';
class TimetableEntry {
  final String id;
  String courseName;
  String? courseCode;
  String? instructor;
  String? room;
  List<int> daysOfWeek; // 1=Monday, 7=Sunday
  TimeOfDay startTime;
  TimeOfDay endTime;
  String? category; // Link to existing categories
  String? color;
  DateTime? semesterStart;
  DateTime? semesterEnd;
  List<String> excludedDates; // ISO strings for holidays/breaks

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
    this.semesterStart,
    this.semesterEnd,
    this.excludedDates = const [],
  });

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
    );
  }
}

class AttendanceRecord {
  final String id;
  final String courseName; // Changed from timetableEntryId to courseName
  final DateTime date;
  AttendanceStatus status;
  String? notes;

  AttendanceRecord({
    required this.id,
    required this.courseName,
    required this.date,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseName': courseName,
        'date': date.toIso8601String(),
        'status': status.toString().split('.').last,
        'notes': notes,
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