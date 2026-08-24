import 'package:flutter/foundation.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../data/repositories/student_repository.dart';

class ExamWithResults {
  final ExamModel exam;
  final List<ExamResult> results;
  final List<StudentModel> students;

  ExamWithResults({
    required this.exam,
    required this.results,
    required this.students,
  });

  double? get highest {
    final marks = results.where((r) => r.marks != null).map((r) => r.marks!);
    return marks.isEmpty ? null : marks.reduce((a, b) => a > b ? a : b);
  }

  double? get lowest {
    final marks = results.where((r) => r.marks != null).map((r) => r.marks!);
    return marks.isEmpty ? null : marks.reduce((a, b) => a < b ? a : b);
  }

  double? get average {
    final marks = results.where((r) => r.marks != null).map((r) => r.marks!).toList();
    if (marks.isEmpty) return null;
    return marks.reduce((a, b) => a + b) / marks.length;
  }

  int get passCount {
    return results
        .where((r) => r.marks != null && r.marks! / exam.totalMarks >= 0.5)
        .length;
  }

  double get passRate {
    final entered = results.where((r) => r.marks != null).length;
    if (entered == 0) return 0;
    return passCount / entered;
  }
}

class ExamsProvider extends ChangeNotifier {
  final ExamRepository _examRepo;
  final StudentRepository _studentRepo;
  final ActivityLogRepository _activityLogRepo;

  ExamsProvider({
    ExamRepository? examRepo,
    StudentRepository? studentRepo,
    ActivityLogRepository? activityLogRepo,
  })  : _examRepo = examRepo ?? ExamRepository(),
        _studentRepo = studentRepo ?? StudentRepository(),
        _activityLogRepo = activityLogRepo ?? ActivityLogRepository();

  final Map<String, List<ExamWithResults>> _examsByGroup = {};
  bool _loading = false;

  Map<String, List<ExamWithResults>> get examsByGroup => _examsByGroup;
  bool get loading => _loading;

  List<ExamWithResults> getForGroup(String groupId) =>
      _examsByGroup[groupId] ?? [];

  Future<void> loadForGroup(String groupId) async {
    _loading = true;
    notifyListeners();
    try {
      final exams = await _examRepo.getByGroup(groupId);
      final students = await _studentRepo.getByGroup(groupId);
      final withResults = <ExamWithResults>[];

      for (final exam in exams) {
        final results = await _examRepo.getResultsForExam(exam.id);
        withResults.add(ExamWithResults(
          exam: exam,
          results: results,
          students: students,
        ));
      }

      _examsByGroup[groupId] = withResults;
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addExam(ExamModel exam) async {
    await _examRepo.insert(exam);
    await loadForGroup(exam.groupId);

    _activityLogRepo.log(
      actionType: 'exam_add',
      title: 'إنشاء اختبار جديد 📝',
      description: 'تم إنشاء اختبار "${exam.name}" من ${exam.totalMarks.toInt()} درجة',
      entityId: exam.id,
      entityType: 'exam',
    );
  }

  Future<void> updateExam(ExamModel exam) async {
    await _examRepo.update(exam);
    await loadForGroup(exam.groupId);

    _activityLogRepo.log(
      actionType: 'exam_edit',
      title: 'تعديل اختبار ✏️',
      description: 'تم تحديث بيانات اختبار "${exam.name}"',
      entityId: exam.id,
      entityType: 'exam',
    );
  }

  Future<void> deleteExam(String examId, String groupId) async {
    await _examRepo.delete(examId);
    await loadForGroup(groupId);

    _activityLogRepo.log(
      actionType: 'exam_delete',
      title: 'حذف اختبار 🗑️',
      description: 'تم حذف الاختبار نهائياً',
      entityId: examId,
      entityType: 'exam',
    );
  }

  Future<void> saveResults(
      String examId, String groupId, List<Map<String, dynamic>> results) async {
    await _examRepo.upsertResultsBatch(examId, results);
    await loadForGroup(groupId);

    _activityLogRepo.log(
      actionType: 'exam_marks',
      title: 'رصد درجات الاختبار 📊',
      description: 'تم رصد وتحديث درجات ${results.length} طالب للاختبار',
      entityId: examId,
      entityType: 'exam',
    );
  }

  Future<List<Map<String, dynamic>>> getStudentExamHistory(String studentId) =>
      _examRepo.getStudentExamHistory(studentId);
}
