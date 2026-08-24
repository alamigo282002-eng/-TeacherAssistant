import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/student_repository.dart';

enum GroupSortType { byName, byDate, byStudentCount }

class GroupsProvider extends ChangeNotifier {
  final GroupRepository _repo;
  final StudentRepository _studentRepo;
  final ActivityLogRepository _activityLogRepo;

  GroupsProvider({
    GroupRepository? repo,
    StudentRepository? studentRepo,
    ActivityLogRepository? activityLogRepo,
  })  : _repo = repo ?? GroupRepository(),
        _studentRepo = studentRepo ?? StudentRepository(),
        _activityLogRepo = activityLogRepo ?? ActivityLogRepository();

  List<GroupModel> _groups = [];
  List<GroupModel> _pausedGroups = [];
  Map<String, int> _studentCounts = {};
  bool _loading = false;
  String? _error;
  GroupSortType _sortType = GroupSortType.byDate;

  List<GroupModel> get groups => _sortedList(_groups);
  List<GroupModel> get pausedGroups => _pausedGroups;
  Map<String, int> get studentCounts => _studentCounts;
  bool get loading => _loading;
  String? get error => _error;
  GroupSortType get sortType => _sortType;
  int get totalStudentsCount => _studentCounts.values.fold(0, (sum, count) => sum + count);

  List<GroupModel> _sortedList(List<GroupModel> list) {
    final sorted = List<GroupModel>.from(list);
    switch (_sortType) {
      case GroupSortType.byName:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case GroupSortType.byDate:
        // Default: by creation date (already sorted from DB)
        break;
      case GroupSortType.byStudentCount:
        sorted.sort((a, b) => (studentCountFor(b.id)).compareTo(studentCountFor(a.id)));
        break;
    }
    return sorted;
  }

  void setSortType(GroupSortType type) {
    if (_sortType == type) return;
    _sortType = type;
    notifyListeners();
  }

  List<GroupModel> getByType(String? type) {
    if (type == null || type == 'الكل') return groups;
    return groups.where((g) => g.type.label == type).toList();
  }

  GroupModel? getGroupById(String id) {
    try {
      return _groups.firstWhere(
        (g) => g.id == id,
        orElse: () => _pausedGroups.firstWhere((g) => g.id == id),
      );
    } catch (_) {
      return null;
    }
  }

  List<GroupModel> getPausedByType(String? type) {
    if (type == null || type == 'الكل') return pausedGroups;
    return pausedGroups.where((g) => g.type.label == type).toList();
  }

  Future<void> loadGroups({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _groups = await _repo.getActive();
      _pausedGroups = await _repo.getPaused();
      _studentCounts = await _repo.getStudentCountPerGroup();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addGroup(GroupModel group) async {
    await _repo.insert(group);
    await loadGroups(silent: true);

    _activityLogRepo.log(
      actionType: 'group_add',
      title: 'إنشاء مجموعة جديدة 👥',
      description: 'تم إنشاء مجموعة "${group.name}" مادة ${group.subject}',
      entityId: group.id,
      entityType: 'group',
    );
  }

  Future<void> updateGroup(GroupModel group) async {
    await _repo.update(group);
    await loadGroups(silent: true);

    _activityLogRepo.log(
      actionType: 'group_edit',
      title: 'تعديل مجموعة ✏️',
      description: 'تم تحديث بيانات ومواعيد مجموعة "${group.name}"',
      entityId: group.id,
      entityType: 'group',
    );
  }

  Future<bool> deleteGroup(String id) async {
    final group = getGroupById(id);
    final name = group?.name ?? 'مجموعة';
    final students = await _studentRepo.getByGroup(id);
    if (students.isNotEmpty) return false;
    await _repo.hardDelete(id);
    await loadGroups(silent: true);

    _activityLogRepo.log(
      actionType: 'group_delete',
      title: 'حذف مجموعة 🗑️',
      description: 'تم حذف مجموعة "$name" نهائياً',
      entityId: id,
      entityType: 'group',
    );
    return true;
  }

  Future<int> deleteBulkGroups(List<String> ids) async {
    int deleted = 0;
    for (final id in ids) {
      final students = await _studentRepo.getByGroup(id);
      if (students.isEmpty) {
        await _repo.hardDelete(id);
        deleted++;
      }
    }
    await loadGroups(silent: true);

    _activityLogRepo.log(
      actionType: 'group_delete',
      title: 'حذف جماعي للمجموعات 🗑️',
      description: 'تم حذف $deleted مجموعات نهائياً',
      entityType: 'group',
    );
    return deleted;
  }

  Future<void> pauseBulkGroups(List<String> ids) async {
    for (final id in ids) {
      await _repo.softDelete(id);
    }
    await loadGroups(silent: true);

    _activityLogRepo.log(
      actionType: 'group_edit',
      title: 'إيقاف مؤقت للمجموعات ⏸️',
      description: 'تم إيقاف ${ids.length} مجموعات مؤقتاً',
      entityType: 'group',
    );
  }

  Future<void> restoreBulkGroups(List<String> ids) async {
    for (final id in ids) {
      await _repo.restore(id);
    }
    await loadGroups(silent: true);

    _activityLogRepo.log(
      actionType: 'group_edit',
      title: 'استعادة مجموعات نشطة ▶️',
      description: 'تمت استعادة ${ids.length} مجموعات كنشطة',
      entityType: 'group',
    );
  }

  Future<void> pauseGroup(String id) async {
    final group = getGroupById(id);
    final name = group?.name ?? 'مجموعة';
    await _repo.softDelete(id);
    await loadGroups(silent: true);

    _activityLogRepo.log(
      actionType: 'group_edit',
      title: 'إيقاف مجموعة مؤقتاً ⏸️',
      description: 'تم إيقاف مجموعة "$name" مؤقتاً',
      entityId: id,
      entityType: 'group',
    );
  }

  Future<void> restoreGroup(String id) async {
    final group = getGroupById(id);
    final name = group?.name ?? 'مجموعة';
    await _repo.restore(id);
    await loadGroups(silent: true);

    _activityLogRepo.log(
      actionType: 'group_edit',
      title: 'استعادة وتفعيل مجموعة ▶️',
      description: 'تمت استعادة مجموعة "$name" كنشطة',
      entityId: id,
      entityType: 'group',
    );
  }

  int studentCountFor(String groupId) => _studentCounts[groupId] ?? 0;
  int getStudentCount(String groupId) => studentCountFor(groupId);

  Future<List<GroupModel>> getGroupsForToday(String arabicDayName) async {
    return _repo.getGroupsForDay(arabicDayName);
  }

  Future<List<GroupModel>> getActiveGroups() => _repo.getActive();
}
