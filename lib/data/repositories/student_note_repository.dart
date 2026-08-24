import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/student_note_model.dart';

class StudentNoteRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<StudentNoteModel>> getAll() async {
    final rows = await _db.query(
      AppConstants.tableNotes,
      orderBy: 'created_at DESC',
    );
    return rows.map(StudentNoteModel.fromMap).toList();
  }

  Future<List<StudentNoteModel>> getByStudent(String studentId) async {
    final rows = await _db.query(
      AppConstants.tableNotes,
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );
    return rows.map(StudentNoteModel.fromMap).toList();
  }

  Future<void> insert(StudentNoteModel note) async {
    await _db.insert(AppConstants.tableNotes, note.toMap());
  }

  Future<void> update(StudentNoteModel note) async {
    await _db.update(AppConstants.tableNotes, note.toMap(), note.id);
  }

  Future<void> delete(String id) async {
    await _db.delete(AppConstants.tableNotes, id);
  }
}
