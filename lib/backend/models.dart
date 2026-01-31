class Event {
  final String id;
  String title;
  String type; // 'exam', 'lab', 'lecture', 'submission', 'note'
  DateTime startTime;
  DateTime endTime;
  String? location;
  String? notes;
  List<String> attachments;
  List<VoiceNote> voiceNotes;
  String? subject;
  bool isImportant; // For visual distinction by colour
  List<DateTime> reminders; // For event reminders

  Event({
    required this.id,
    required this.title,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.location,
    this.notes,
    this.attachments = const [],
    this.voiceNotes = const [],
    this.subject,
    this.isImportant = false,
    this.reminders = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'location': location,
    'notes': notes,
    'attachments': attachments,
    'voiceNotes': voiceNotes.map((v) => v.toJson()).toList(),
    'subject': subject,
    'isImportant': isImportant,
    'reminders': reminders.map((r) => r.toIso8601String()).toList(),
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    title: json['title'],
    type: json['type'],
    startTime: DateTime.parse(json['startTime']),
    endTime: DateTime.parse(json['endTime']),
    location: json['location'],
    notes: json['notes'],
    attachments: List<String>.from(json['attachments'] ?? []),
    voiceNotes: (json['voiceNotes'] as List?)?.map((v) => VoiceNote.fromJson(v)).toList() ?? [],
    subject: json['subject'],
    isImportant: json['isImportant'] ?? false,
    reminders: (json['reminders'] as List?)?.map((r) => DateTime.parse(r as String)).toList() ?? [],
  );

  // Method to duplicate event
  Event duplicate() {
    return Event(
      id: '${id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      title: '$title (Copy)',
      type: type,
      startTime: startTime,
      endTime: endTime,
      location: location,
      notes: notes,
      attachments: List.from(attachments),
      voiceNotes: List.from(voiceNotes),
      subject: subject,
      isImportant: isImportant,
      reminders: List.from(reminders),
    );
  }
}

class Task {
  final String id;
  String title;
  String type; // 'assignment', 'exam', 'note'
  DateTime deadline;
  String estimatedDuration;
  String subject;
  String priority; // 'high', 'medium', 'low'
  bool completed;
  String? notes;
  List<String> attachments;
  List<VoiceNote> voiceNotes;
  bool isImportant; // For visual distinction
  List<DateTime> reminders; // For reminders

  Task({
    required this.id,
    required this.title,
    required this.type,
    required this.deadline,
    required this.estimatedDuration,
    required this.subject,
    required this.priority,
    this.completed = false,
    this.notes,
    this.attachments = const [],
    this.voiceNotes = const [],
    this.isImportant = false,
    this.reminders = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'deadline': deadline.toIso8601String(),
    'estimatedDuration': estimatedDuration,
    'subject': subject,
    'priority': priority,
    'completed': completed,
    'notes': notes,
    'attachments': attachments,
    'voiceNotes': voiceNotes.map((v) => v.toJson()).toList(),
    'isImportant': isImportant,
    'reminders': reminders.map((r) => r.toIso8601String()).toList(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    type: json['type'],
    deadline: DateTime.parse(json['deadline']),
    estimatedDuration: json['estimatedDuration'],
    subject: json['subject'],
    priority: json['priority'],
    completed: json['completed'],
    notes: json['notes'],
    attachments: List<String>.from(json['attachments'] ?? []),
    voiceNotes: (json['voiceNotes'] as List?)?.map((v) => VoiceNote.fromJson(v)).toList() ?? [],
    isImportant: json['isImportant'] ?? false,
    reminders: (json['reminders'] as List?)?.map((r) => DateTime.parse(r as String)).toList() ?? [],
  );

  // Method to duplicate task
  Task duplicate() {
    return Task(
      id: '${id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      title: '$title (Copy)',
      type: type,
      deadline: deadline,
      estimatedDuration: estimatedDuration,
      subject: subject,
      priority: priority,
      completed: false,
      notes: notes,
      attachments: List.from(attachments),
      voiceNotes: List.from(voiceNotes),
      isImportant: isImportant,
      reminders: List.from(reminders),
    );
  }
}

class VoiceNote {
  final String id;
  final String filePath;
  final DateTime recordedAt;
  final Duration duration;
  final List<String> tags;

  VoiceNote({
    required this.id,
    required this.filePath,
    required this.recordedAt,
    required this.duration,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'recordedAt': recordedAt.toIso8601String(),
    'duration': duration.inSeconds,
    'tags': tags,
  };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
    id: json['id'],
    filePath: json['filePath'],
    recordedAt: DateTime.parse(json['recordedAt']),
    duration: Duration(seconds: json['duration']),
    tags: List<String>.from(json['tags'] ?? []),
  );
}