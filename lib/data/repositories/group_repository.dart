import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/group_model.dart';

class GroupRepository {
  final DatabaseHelper _db;

  GroupRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  Future<List<GroupModel>> getAll({bool includeNonActive = false}) async {
    final rows = await _db.query(
      AppConstants.tableGroups,
      orderBy: 'created_at ASC',
    );
    final groups = rows.map(GroupModel.fromMap).toList();
    if (includeNonActive) return groups;
    return groups.where((g) => g.status == GroupStatus.active).toList();
  }

  Future<List<GroupModel>> getActive() async {
    final rows = await _db.query(
      AppConstants.tableGroups,
      where: 'status = ?',
      whereArgs: [GroupStatus.active.label],
      orderBy: 'created_at ASC',
    );
    return rows.map(GroupModel.fromMap).toList();
  }

  Future<List<GroupModel>> getPaused() async {
    final rows = await _db.query(
      AppConstants.tableGroups,
      where: 'status = ? OR status = ?',
      whereArgs: [GroupStatus.paused.label, GroupStatus.ended.label],
      orderBy: 'created_at ASC',
    );
    return rows.map(GroupModel.fromMap).toList();
  }

  Future<GroupModel?> getById(String id) async {
    final row = await _db.queryById(AppConstants.tableGroups, id);
    return row != null ? GroupModel.fromMap(row) : null;
  }

  Future<void> insert(GroupModel group) async {
    await _db.insert(AppConstants.tableGroups, group.toMap());
  }

  Future<void> update(GroupModel group) async {
    await _db.update(AppConstants.tableGroups, group.toMap(), group.id);
  }

  Future<void> softDelete(String id) async {
    await _db.rawUpdate(
      'UPDATE ${AppConstants.tableGroups} SET status = ? WHERE id = ?',
      [GroupStatus.paused.label, id],
    );
  }

  Future<List<GroupModel>> getDeleted() async {
    final rows = await _db.query(
      AppConstants.tableGroups,
      where: 'status = ? OR status = ?',
      whereArgs: [GroupStatus.paused.label, GroupStatus.ended.label],
      orderBy: 'created_at ASC',
    );
    return rows.map(GroupModel.fromMap).toList();
  }

  Future<void> hardDelete(String id) async {
    await _db.delete(AppConstants.tableGroups, id);
  }

  Future<void> restore(String id) async {
    await _db.rawUpdate(
      'UPDATE ${AppConstants.tableGroups} SET status = ? WHERE id = ?',
      [GroupStatus.active.label, id],
    );
  }

  /// Count of active students in each group (for stats)
  Future<Map<String, int>> getStudentCountPerGroup() async {
    final rows = await _db.rawQuery(
      'SELECT group_id, COUNT(*) as count FROM ${AppConstants.tableStudents} WHERE status = ? GROUP BY group_id',
      [AppConstants.statusActive],
    );
    return {for (final r in rows) r['group_id'] as String: r['count'] as int};
  }

  /// Get groups scheduled for a specific Arabic day name
  Future<List<GroupModel>> getGroupsForDay(String arabicDayName) async {
    final all = await getActive();
    return all.where((g) => g.isScheduledOn(arabicDayName)).toList();
  }
}
