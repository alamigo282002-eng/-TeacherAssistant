import 'dart:convert';

class NoteModel {
  final String id;
  final String type; // 'general', 'student', 'group'
  final String? targetId; // student_id or group_id, nullable for general
  final String content;
  final String color; // Hex string, e.g. '#FEF3C7'
  final bool isPinned;
  final String category; // 'general', 'urgent', 'homework', 'exam', 'behavior'
  final bool reminderEnabled;
  final DateTime? reminderTime;
  final String? reminderTimingType; // 'specific_time' | 'before_group_15' | 'before_group_30' | 'after_group'
  final String? reminderGroupId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NoteModel({
    required this.id,
    required this.type,
    this.targetId,
    required this.content,
    this.color = '#FEF3C7',
    this.isPinned = false,
    this.category = 'general',
    this.reminderEnabled = false,
    this.reminderTime,
    this.reminderTimingType,
    this.reminderGroupId,
    required this.createdAt,
    this.updatedAt,
  });

  NoteModel copyWith({
    String? id,
    String? type,
    String? targetId,
    String? content,
    String? color,
    bool? isPinned,
    String? category,
    bool? reminderEnabled,
    DateTime? reminderTime,
    String? reminderTimingType,
    String? reminderGroupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      category: category ?? this.category,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderTimingType: reminderTimingType ?? this.reminderTimingType,
      reminderGroupId: reminderGroupId ?? this.reminderGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'target_id': targetId,
      'content': content,
      'color': color,
      'is_pinned': isPinned ? 1 : 0,
      'category': category,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_time': reminderTime?.toIso8601String(),
      'reminder_timing_type': reminderTimingType,
      'reminder_group_id': reminderGroupId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      type: map['type'] as String,
      targetId: map['target_id'] as String?,
      content: map['content'] as String,
      color: (map['color'] as String?) ?? '#FEF3C7',
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      category: (map['category'] as String?) ?? 'general',
      reminderEnabled: (map['reminder_enabled'] as int? ?? 0) == 1,
      reminderTime: map['reminder_time'] != null ? DateTime.tryParse(map['reminder_time'] as String) : null,
      reminderTimingType: map['reminder_timing_type'] as String?,
      reminderGroupId: map['reminder_group_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory NoteModel.fromJson(String source) => NoteModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
