import 'package:flutter/foundation.dart';
import '../../data/models/activity_log_model.dart';
import '../../data/repositories/activity_log_repository.dart';

class ActivityLogProvider extends ChangeNotifier {
  final ActivityLogRepository _repo;

  ActivityLogProvider({ActivityLogRepository? repo})
      : _repo = repo ?? ActivityLogRepository();

  List<ActivityLogModel> _logs = [];
  bool _loading = false;
  String _selectedCategory = 'all'; // 'all', 'student', 'attendance', 'group', 'payment', 'exam'
  String _searchQuery = '';

  List<ActivityLogModel> get logs => _logs;
  bool get loading => _loading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> loadLogs({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    try {
      _logs = await _repo.getLogs(
        categoryFilter: _selectedCategory,
        searchQuery: _searchQuery,
      );
    } catch (_) {
      _logs = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadLogs();
  }

  void setSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadLogs();
  }

  Future<void> logAction({
    required String actionType,
    required String title,
    required String description,
    String? entityId,
    String? entityType,
    String? extraData,
  }) async {
    await _repo.log(
      actionType: actionType,
      title: title,
      description: description,
      entityId: entityId,
      entityType: entityType,
      extraData: extraData,
    );
    loadLogs(silent: true);
  }

  Future<void> clearAll() async {
    await _repo.clearAllLogs();
    _logs.clear();
    notifyListeners();
  }

  Future<void> deleteLog(String id) async {
    await _repo.deleteLog(id);
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
  }
}
