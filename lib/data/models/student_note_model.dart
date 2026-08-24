import 'dart:convert';

class StudentNoteModel {
  final String id;
  final String studentId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StudentNoteModel({
    required this.id,
    required this.studentId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  StudentNoteModel copyWith({
    String? id,
    String? studentId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentNoteModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'student_id': studentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory StudentNoteModel.fromMap(Map<String, dynamic> map) {
    return StudentNoteModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory StudentNoteModel.fromJson(String source) => StudentNoteModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(covariant StudentNoteModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.studentId == studentId &&
      other.content == content &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      studentId.hashCode ^
      content.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
}
