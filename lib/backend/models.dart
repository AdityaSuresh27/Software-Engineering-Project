// models.dart
class Event {
  final String id;
  String title;
  String classification; // 'class', 'exam', 'assignment', 'deadline', 'meeting', 'personal', 'other'
  String? category; // Subject/Course name
  DateTime startTime;
  DateTime? endTime; // Optional for tasks/deadlines
  String? location;
  String? notes;
  List<String> attachments;
  List<VoiceNote> voiceNotes;
  bool isCompleted; // For task-like events
  String priority; // 'low', 'medium', 'high', 'critical'
  String? estimatedDuration; // For assignments
  bool isImportant; // Star/flag for emphasis
  List<DateTime> reminders;
  String? color; // Custom color override
  Map<String, dynamic>? metadata; // Flexible field for future extensions

  Event({
    required this.id,
    required this.title,
    required this.classification,
    required this.startTime,
    this.category,
    this.endTime,
    this.location,
    this.notes,
    this.attachments = const [],
    this.voiceNotes = const [],
    this.isCompleted = false,
    this.priority = 'medium',
    this.estimatedDuration,
    this.isImportant = false,
    this.reminders = const [],
    this.color,
    this.metadata,
  });

  // Helper to check if this is a task-type event
  bool get isTask => classification == 'assignment' || 
                     classification == 'deadline' || 
                     classification == 'exam';

  // Helper to check if this has a specific end time
  bool get hasEndTime => endTime != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'classification': classification,
    'category': category,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'location': location,
    'notes': notes,
    'attachments': attachments,
    'voiceNotes': voiceNotes.map((v) => v.toJson()).toList(),
    'isCompleted': isCompleted,
    'priority': priority,
    'estimatedDuration': estimatedDuration,
    'isImportant': isImportant,
    'reminders': reminders.map((r) => r.toIso8601String()).toList(),
    'color': color,
    'metadata': metadata,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    title: json['title'],
    classification: json['classification'],
    category: json['category'],
    startTime: DateTime.parse(json['startTime']),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    location: json['location'],
    notes: json['notes'],
    attachments: List<String>.from(json['attachments'] ?? []),
    voiceNotes: (json['voiceNotes'] as List?)?.map((v) => VoiceNote.fromJson(v)).toList() ?? [],
    isCompleted: json['isCompleted'] ?? false,
    priority: json['priority'] ?? 'medium',
    estimatedDuration: json['estimatedDuration'],
    isImportant: json['isImportant'] ?? false,
    reminders: (json['reminders'] as List?)?.map((r) => DateTime.parse(r as String)).toList() ?? [],
    color: json['color'],
    metadata: json['metadata'],
  );

  Event duplicate() {
    return Event(
      id: '${id}_copy_${DateTime.now().millisecondsSinceEpoch}',
      title: '$title (Copy)',
      classification: classification,
      category: category,
      startTime: startTime,
      endTime: endTime,
      location: location,
      notes: notes,
      attachments: List.from(attachments),
      voiceNotes: List.from(voiceNotes),
      isCompleted: false,
      priority: priority,
      estimatedDuration: estimatedDuration,
      isImportant: isImportant,
      reminders: List.from(reminders),
      color: color,
      metadata: metadata != null ? Map.from(metadata!) : null,
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

// Category model for organizing events
class Category {
  final String id;
  String name;
  String? color;
  String? icon;
  
  Category({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'icon': icon,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    color: json['color'],
    icon: json['icon'],
  );
}