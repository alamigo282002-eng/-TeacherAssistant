import 'dart:convert';

enum ActivityCategory {
  students,
  attendance,
  groups,
  finance,
  exams,
  general,
}

class ActivityLogModel {
  final String id;
  final String actionType;
  final String title;
  final String description;
  final String? entityId;
  final String? entityType;
  final String? extraData;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    required this.actionType,
    required this.title,
    required this.description,
    this.entityId,
    this.entityType,
    this.extraData,
    required this.createdAt,
  });

  ActivityCategory get category {
    if (actionType.startsWith('student_')) return ActivityCategory.students;
    if (actionType.startsWith('attendance_')) return ActivityCategory.attendance;
    if (actionType.startsWith('group_')) return ActivityCategory.groups;
    if (actionType.startsWith('payment_') || actionType.startsWith('finance_')) return ActivityCategory.finance;
    if (actionType.startsWith('exam_')) return ActivityCategory.exams;
    return ActivityCategory.general;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action_type': actionType,
      'title': title,
      'description': description,
      'entity_id': entityId,
      'entity_type': entityType,
      'extra_data': extraData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] as String,
      actionType: map['action_type'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      entityId: map['entity_id'] as String?,
      entityType: map['entity_type'] as String?,
      extraData: map['extra_data'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ActivityLogModel.fromJson(String source) =>
      ActivityLogModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
