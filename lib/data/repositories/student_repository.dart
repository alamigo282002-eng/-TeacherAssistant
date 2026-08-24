import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/student_model.dart';

class StudentRepository {
  final DatabaseHelper _db;

  StudentRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<StudentModel>> getAll() async {
    final rows = await _db.query(
      AppConstants.tableStudents,
      where: 'status = ?',
      whereArgs: [AppConstants.statusActive],
      orderBy: 'name ASC',
    );
    return rows.map(StudentModel.fromMap).toList();
  }

  Future<List<StudentModel>> getActive() => getAll();

  Future<List<StudentModel>> getByGroup(String groupId) async {
    final rows = await _db.query(
      AppConstants.tableStudents,
      where: 'group_id = ? AND status = ?',
      whereArgs: [groupId, AppConstants.statusActive],
      orderBy: 'name ASC',
    );
    return rows.map(StudentModel.fromMap).toList();
  }

  Future<StudentModel?> getById(String id) async {
    final row = await _db.queryById(AppConstants.tableStudents, id);
    return row != null ? StudentModel.fromMap(row) : null;
  }

  Future<List<StudentModel>> search(String query) async {
    final rows = await _db.query(
      AppConstants.tableStudents,
      where: "(name LIKE ? OR phone LIKE ? OR parent_phone LIKE ?) AND status = ?",
      whereArgs: ['%$query%', '%$query%', '%$query%', AppConstants.statusActive],
      orderBy: 'name ASC',
    );
    return rows.map(StudentModel.fromMap).toList();
  }

  Future<void> insert(StudentModel student) async {
    await _db.insert(AppConstants.tableStudents, student.toMap());
  }

  Future<void> update(StudentModel student) async {
    await _db.update(AppConstants.tableStudents, student.toMap(), student.id);
  }

  Future<void> softDelete(String id) async {
    await _db.rawUpdate(
      'UPDATE ${AppConstants.tableStudents} SET status = ? WHERE id = ?',
      [AppConstants.statusDeleted, id],
    );
  }

  Future<void> hardDelete(String id) async {
    await _db.delete(AppConstants.tableStudents, id);
  }

  Future<List<StudentModel>> getDeleted() async {
    final rows = await _db.query(
      AppConstants.tableStudents,
      where: 'status = ?',
      whereArgs: [AppConstants.statusDeleted],
      orderBy: 'name ASC',
    );
    return rows.map(StudentModel.fromMap).toList();
  }

  Future<void> restore(String id) async {
    await _db.rawUpdate(
      'UPDATE ${AppConstants.tableStudents} SET status = ? WHERE id = ?',
      [AppConstants.statusActive, id],
    );
  }

  Future<void> addPoints(String studentId, int pts) async {
    await _db.rawUpdate(
      'UPDATE ${AppConstants.tableStudents} SET points = points + ? WHERE id = ?',
      [pts, studentId],
    );
  }

  Future<int> countActive() async {
    final rows = await _db.rawQuery(
      'SELECT COUNT(*) as c FROM ${AppConstants.tableStudents} WHERE status = ?',
      [AppConstants.statusActive],
    );
    return rows.first['c'] as int? ?? 0;
  }

  Future<List<StudentModel>> getTopByPoints({int limit = 10}) async {
    final rows = await _db.query(
      AppConstants.tableStudents,
      where: 'status = ?',
      whereArgs: [AppConstants.statusActive],
      orderBy: 'points DESC',
      limit: limit,
    );
    return rows.map(StudentModel.fromMap).toList();
  }

  Future<void> resetAllPoints() async {
    await _db.rawUpdate(
      'UPDATE ${AppConstants.tableStudents} SET points = 0',
    );
  }

  Future<void> resetStudentPoints(String studentId) async {
    await _db.rawUpdate(
      'UPDATE ${AppConstants.tableStudents} SET points = 0 WHERE id = ?',
      [studentId],
    );
  }
}
