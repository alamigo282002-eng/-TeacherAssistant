import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/activity_log_model.dart';

class ActivityLogRepository {
  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  Future<void> log({
    required String actionType,
    required String title,
    required String description,
    String? entityId,
    String? entityType,
    String? extraData,
  }) async {
    try {
      final log = ActivityLogModel(
        id: _uuid.v4(),
        actionType: actionType,
        title: title,
        description: description,
        entityId: entityId,
        entityType: entityType,
        extraData: extraData,
        createdAt: DateTime.now(),
      );
      await _db.insert(AppConstants.tableActivityLogs, log.toMap());
    } catch (_) {
      // Fail silently to never break core app flows
    }
  }

  Future<List<ActivityLogModel>> getLogs({
    String? categoryFilter,
    String? searchQuery,
    int limit = 200,
    int offset = 0,
  }) async {
    try {
      String? where;
      List<dynamic>? whereArgs;

      final conditions = <String>[];
      final args = <dynamic>[];

      if (categoryFilter != null && categoryFilter != 'all') {
        conditions.add('action_type LIKE ?');
        args.add('${categoryFilter}_%');
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        conditions.add('(title LIKE ? OR description LIKE ?)');
        args.add('%$searchQuery%');
        args.add('%$searchQuery%');
      }

      if (conditions.isNotEmpty) {
        where = conditions.join(' AND ');
        whereArgs = args;
      }

      final rows = await _db.query(
        AppConstants.tableActivityLogs,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return rows.map((r) => ActivityLogModel.fromMap(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> clearAllLogs() async {
    try {
      final db = await _db.database;
      return await db.delete(AppConstants.tableActivityLogs);
    } catch (_) {
      return 0;
    }
  }

  Future<int> deleteLog(String id) async {
    try {
      return await _db.delete(AppConstants.tableActivityLogs, id);
    } catch (_) {
      return 0;
    }
  }
}
