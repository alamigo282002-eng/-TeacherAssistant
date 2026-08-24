import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/exam_model.dart';

class ExamRepository {
  final DatabaseHelper _db;
  final _uuid = const Uuid();

  ExamRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<ExamModel>> getAll() async {
    final rows = await _db.query(
      AppConstants.tableExams,
      orderBy: 'date DESC',
    );
    return rows.map(ExamModel.fromMap).toList();
  }

  Future<List<ExamModel>> getByGroup(String groupId) async {
    final rows = await _db.query(
      AppConstants.tableExams,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC',
    );
    return rows.map(ExamModel.fromMap).toList();
  }

  Future<ExamModel?> getById(String id) async {
    final row = await _db.queryById(AppConstants.tableExams, id);
    return row != null ? ExamModel.fromMap(row) : null;
  }

  Future<void> insert(ExamModel exam) async {
    await _db.insert(AppConstants.tableExams, exam.toMap());
  }

  Future<void> update(ExamModel exam) async {
    await _db.update(AppConstants.tableExams, exam.toMap(), exam.id);
  }

  Future<void> delete(String examId) async {
    await _db.delete(AppConstants.tableExams, examId);
    final db = await _db.database;
    await db.delete(
      AppConstants.tableExamResults,
      where: 'exam_id = ?',
      whereArgs: [examId],
    );
  }

  // Exam Results
  Future<List<ExamResult>> getResults(String examId) => getResultsForExam(examId);

  Future<List<ExamResult>> getResultsForExam(String examId) async {
    final rows = await _db.query(
      AppConstants.tableExamResults,
      where: 'exam_id = ?',
      whereArgs: [examId],
    );
    return rows.map((r) => ExamResult.fromMap(r)).toList();
  }

  Future<List<ExamResult>> getResultsForStudent(String studentId) async {
    final rows = await _db.query(
      AppConstants.tableExamResults,
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
    return rows.map((r) => ExamResult.fromMap(r)).toList();
  }

  Future<void> saveResults(String examId, List<ExamResult> results) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final r in results) {
        final existing = await txn.query(
          AppConstants.tableExamResults,
          where: 'exam_id = ? AND student_id = ?',
          whereArgs: [examId, r.studentId],
        );
        if (existing.isEmpty) {
          await txn.insert(AppConstants.tableExamResults, {
            'id': r.id.isNotEmpty ? r.id : _uuid.v4(),
            'exam_id': examId,
            'student_id': r.studentId,
            'marks': r.marks,
          });
        } else {
          await txn.update(
            AppConstants.tableExamResults,
            {'marks': r.marks},
            where: 'exam_id = ? AND student_id = ?',
            whereArgs: [examId, r.studentId],
          );
        }
      }
    });
  }

  Future<void> upsertResult(String examId, String studentId, double? marks) async {
    final db = await _db.database;
    final existing = await db.query(
      AppConstants.tableExamResults,
      where: 'exam_id = ? AND student_id = ?',
      whereArgs: [examId, studentId],
    );
    if (existing.isEmpty) {
      await db.insert(AppConstants.tableExamResults, {
        'id': _uuid.v4(),
        'exam_id': examId,
        'student_id': studentId,
        'marks': marks,
      });
    } else {
      await db.update(
        AppConstants.tableExamResults,
        {'marks': marks},
        where: 'exam_id = ? AND student_id = ?',
        whereArgs: [examId, studentId],
      );
    }
  }

  Future<void> upsertResultsBatch(
      String examId, List<Map<String, dynamic>> results) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final r in results) {
        final studentId = r['student_id'] as String;
        final marks = r['marks'] as double?;
        final existing = await txn.query(
          AppConstants.tableExamResults,
          where: 'exam_id = ? AND student_id = ?',
          whereArgs: [examId, studentId],
        );
        if (existing.isEmpty) {
          await txn.insert(AppConstants.tableExamResults, {
            'id': _uuid.v4(),
            'exam_id': examId,
            'student_id': studentId,
            'marks': marks,
          });
        } else {
          await txn.update(
            AppConstants.tableExamResults,
            {'marks': marks},
            where: 'exam_id = ? AND student_id = ?',
            whereArgs: [examId, studentId],
          );
        }
      }
    });
  }

  /// Returns exam results joined with exam info for a student
  Future<List<Map<String, dynamic>>> getStudentExamHistory(String studentId) async {
    return _db.rawQuery('''
      SELECT e.name, e.total_marks, e.date, er.marks
      FROM ${AppConstants.tableExamResults} er
      JOIN ${AppConstants.tableExams} e ON er.exam_id = e.id
      WHERE er.student_id = ?
      ORDER BY e.date DESC
    ''', [studentId]);
  }
}
