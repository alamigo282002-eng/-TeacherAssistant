import '../../core/constants/app_constants.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String groupId;
  final DateTime date;
  final AttendanceStatus status;
  final bool homeworkDone;
  final String note;
  final double? recitationPoints;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.groupId,
    required this.date,
    this.status = AttendanceStatus.present,
    this.homeworkDone = false,
    this.note = '',
    this.recitationPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'group_id': groupId,
      'date': date.toIso8601String(),
      'status': status.label,
      'homework_done': homeworkDone ? 1 : 0,
      'note': note,
      'recitation_points': recitationPoints,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      groupId: map['group_id'] as String,
      date: DateTime.parse(map['date'] as String),
      status: AttendanceStatusExt.fromLabel(map['status'] as String? ?? 'حاضر'),
      homeworkDone: (map['homework_done'] as int? ?? 0) == 1,
      note: map['note'] as String? ?? '',
      recitationPoints: map['recitation_points'] as double?,
    );
  }

  AttendanceModel copyWith({
    String? id,
    String? studentId,
    String? groupId,
    DateTime? date,
    AttendanceStatus? status,
    bool? homeworkDone,
    String? note,
    double? recitationPoints,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      groupId: groupId ?? this.groupId,
      date: date ?? this.date,
      status: status ?? this.status,
      homeworkDone: homeworkDone ?? this.homeworkDone,
      note: note ?? this.note,
      recitationPoints: recitationPoints ?? this.recitationPoints,
    );
  }

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
}
