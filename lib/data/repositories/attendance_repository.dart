import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  final DatabaseHelper _db;

  AttendanceRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<AttendanceModel>> getByGroupAndDate(String groupId, DateTime date) async {
    final dateStr = _dateKey(date);
    final rows = await _db.query(
      AppConstants.tableAttendance,
      where: 'group_id = ? AND date LIKE ?',
      whereArgs: [groupId, '$dateStr%'],
    );
    return rows.map(AttendanceModel.fromMap).toList();
  }

  Future<List<AttendanceModel>> getByStudent(String studentId) async {
    final rows = await _db.query(
      AppConstants.tableAttendance,
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'date DESC',
    );
    return rows.map(AttendanceModel.fromMap).toList();
  }

  Future<List<AttendanceModel>> getAbsentToday() async => getTodayAbsentees();

  Future<List<AttendanceModel>> getTodayAbsentees([DateTime? date]) async {
    final targetDate = date ?? DateTime.now();
    final dateStr = _dateKey(targetDate);
    final rows = await _db.query(
      AppConstants.tableAttendance,
      where: 'date LIKE ? AND status = ?',
      whereArgs: ['$dateStr%', AttendanceStatus.absent.label],
    );
    return rows.map(AttendanceModel.fromMap).toList();
  }

  Future<List<AttendanceModel>> getByStudentAndMonth(
      String studentId, int month, int year) async {
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final end = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final rows = await _db.rawQuery('''
      SELECT * FROM ${AppConstants.tableAttendance}
      WHERE student_id = ? AND date >= ? AND date < ?
      ORDER BY date DESC
    ''', [studentId, start, end]);
    return rows.map(AttendanceModel.fromMap).toList();
  }

  Future<Map<String, int>> getAbsenceCountThisWeek() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startStr = _dateKey(weekStart);

    final rows = await _db.rawQuery('''
      SELECT student_id, COUNT(*) as count
      FROM ${AppConstants.tableAttendance}
      WHERE date >= ? AND status = ?
      GROUP BY student_id
    ''', [startStr, AttendanceStatus.absent.label]);

    return {for (final r in rows) r['student_id'] as String: r['count'] as int};
  }

  Future<void> upsertBatch(List<AttendanceModel> records) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final record in records) {
        await txn.insert(
          AppConstants.tableAttendance,
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> insert(AttendanceModel record) async {
    await _db.insert(AppConstants.tableAttendance, record.toMap());
  }

  Future<void> update(AttendanceModel record) async {
    await _db.update(AppConstants.tableAttendance, record.toMap(), record.id);
  }

  Future<int> countAbsentForStudent(String studentId, int month, int year) async {
    final records = await getByStudentAndMonth(studentId, month, year);
    return records.where((r) => r.isAbsent).length;
  }

  Future<int> countHomeworkNotDone(String studentId, int month, int year) async {
    final records = await getByStudentAndMonth(studentId, month, year);
    return records.where((r) => r.isPresent && !r.homeworkDone).length;
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
