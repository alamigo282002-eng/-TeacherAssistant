import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/app_lock_model.dart';

class AppLockRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<AppLockModel> getLockSettings() async {
    final rows = await _db.query(AppConstants.tableAppLock);
    if (rows.isEmpty) {
      // Return default
      return AppLockModel();
    }
    return AppLockModel.fromMap(rows.first);
  }

  Future<void> saveLockSettings(AppLockModel lock) async {
    final rows = await _db.query(AppConstants.tableAppLock);
    if (rows.isEmpty) {
      await _db.insert(AppConstants.tableAppLock, lock.toMap());
    } else {
      await _db.update(AppConstants.tableAppLock, lock.toMap(), lock.id.toString());
    }
  }

  Future<void> clearLock() async {
    final lock = AppLockModel(isEnabled: false);
    await saveLockSettings(lock);
  }
}
