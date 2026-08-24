import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/note_model.dart';

class NoteRepository {
  final DatabaseHelper _db;

  NoteRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<NoteModel>> getAll() async {
    final rows = await _db.query(
      AppConstants.tableNotes,
      orderBy: 'created_at DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<List<NoteModel>> getByTarget(String type, String targetId) async {
    final rows = await _db.query(
      AppConstants.tableNotes,
      where: 'type = ? AND target_id = ?',
      whereArgs: [type, targetId],
      orderBy: 'created_at DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }
  
  Future<List<NoteModel>> getGeneralNotes() async {
    final rows = await _db.query(
      AppConstants.tableNotes,
      where: 'type = ?',
      whereArgs: ['general'],
      orderBy: 'created_at DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<void> insert(NoteModel note) async {
    await _db.insert(AppConstants.tableNotes, note.toMap());
  }

  Future<void> update(NoteModel note) async {
    await _db.update(AppConstants.tableNotes, note.toMap(), note.id);
  }

  Future<void> delete(String id) async {
    await _db.delete(AppConstants.tableNotes, id);
  }
}
