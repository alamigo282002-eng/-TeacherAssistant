class ExamResult {
  final String id;
  final String examId;
  final String studentId;
  final double? marks; // null = not entered yet

  const ExamResult({
    this.id = '',
    this.examId = '',
    required this.studentId,
    this.marks,
  });

  Map<String, dynamic> toMap() => {
        if (id.isNotEmpty) 'id': id,
        if (examId.isNotEmpty) 'exam_id': examId,
        'student_id': studentId,
        'marks': marks,
      };

  factory ExamResult.fromMap(Map<String, dynamic> map) => ExamResult(
        id: (map['id'] as String?) ?? '',
        examId: (map['exam_id'] as String?) ?? '',
        studentId: map['student_id'] as String,
        marks: map['marks'] != null ? (map['marks'] as num).toDouble() : null,
      );
}

typedef ExamResultModel = ExamResult;

class ExamModel {
  final String id;
  final String groupId;
  final String name;
  final double totalMarks;
  final DateTime date;

  const ExamModel({
    required this.id,
    required this.groupId,
    required this.name,
    required this.totalMarks,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'name': name,
      'total_marks': totalMarks,
      'date': date.toIso8601String(),
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      name: map['name'] as String,
      totalMarks: (map['total_marks'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }

  ExamModel copyWith({
    String? id,
    String? groupId,
    String? name,
    double? totalMarks,
    DateTime? date,
  }) {
    return ExamModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      totalMarks: totalMarks ?? this.totalMarks,
      date: date ?? this.date,
    );
  }
}
