import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/widget_sync_service.dart';
import '../../core/utils/date_helper.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/group_model.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/student_repository.dart';
import 'package:uuid/uuid.dart';

class HomeStats {
  final int totalStudents;
  final int totalGroups;
  final int absentToday;

  const HomeStats({
    required this.totalStudents,
    required this.totalGroups,
    required this.absentToday,
  });
}

class ActiveSessionInfo {
  final GroupModel group;
  final String dayName;
  final String time;
  final int minutesUntil;
  final int studentCount;
  final bool isRunningNow;

  const ActiveSessionInfo({
    required this.group,
    required this.dayName,
    required this.time,
    required this.minutesUntil,
    required this.studentCount,
    required this.isRunningNow,
  });
}

class NextSessionInfo {
  final GroupModel group;
  final String dayName;
  final String time;
  final int minutesUntil;
  final int studentCount;

  const NextSessionInfo({
    required this.group,
    required this.dayName,
    required this.time,
    required this.minutesUntil,
    required this.studentCount,
  });
}

class HomeProvider extends ChangeNotifier {
  final GroupRepository _groupRepo;
  final StudentRepository _studentRepo;
  final AttendanceRepository _attendanceRepo;
  final NoteRepository _noteRepo;
  final _uuid = const Uuid();

  HomeProvider({
    GroupRepository? groupRepo,
    StudentRepository? studentRepo,
    AttendanceRepository? attendanceRepo,
    NoteRepository? noteRepo,
  })  : _groupRepo = groupRepo ?? GroupRepository(),
        _studentRepo = studentRepo ?? StudentRepository(),
        _attendanceRepo = attendanceRepo ?? AttendanceRepository(),
        _noteRepo = noteRepo ?? NoteRepository();

  HomeStats? _stats;
  List<GroupModel> _todaysGroups = [];
  Map<String, int> _groupStudentCounts = {};
  Set<String> _preparedGroupIds = {};
  NextSessionInfo? _nextSession;
  List<ActiveSessionInfo> _activeSessions = [];
  String _todayNote = '';
  bool _loading = false;

  HomeStats? get stats => _stats;
  List<GroupModel> get todaysGroups => _todaysGroups;
  Map<String, int> get groupStudentCounts => _groupStudentCounts;
  Set<String> get preparedGroupIds => _preparedGroupIds;
  NextSessionInfo? get nextSession => _nextSession;
  List<ActiveSessionInfo> get activeSessions => _activeSessions;
  ActiveSessionInfo? get primaryActiveSession => _activeSessions.isNotEmpty ? _activeSessions.first : null;
  String get todayNote => _todayNote;
  bool get loading => _loading;

  int get remainingPrepCount {
    final unready = _todaysGroups.where((g) => !_preparedGroupIds.contains(g.id)).length;
    return unready;
  }

  Future<void> loadHomeData() => loadData();

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();
    try {
      // Load today's general note from unified NoteRepository
      final generalNotes = await _noteRepo.getGeneralNotes();
      if (generalNotes.isNotEmpty) {
        _todayNote = generalNotes.first.content;
      } else {
        final prefs = await SharedPreferences.getInstance();
        _todayNote = prefs.getString('today_note_${DateTime.now().toString().substring(0, 10)}') ?? '';
      }

      final todayName = AppDateUtils.todayArabicDayName();
      final groups = await _groupRepo.getAll();
      final studentCount = await _studentRepo.countActive();
      final absentToday = await _attendanceRepo.getAbsentToday();
      final todaysGroups = await _groupRepo.getGroupsForDay(todayName);

      // Student counts per group
      final counts = <String, int>{};
      for (final g in groups) {
        final students = await _studentRepo.getByGroup(g.id);
        counts[g.id] = students.length;
      }
      _groupStudentCounts = counts;

      // Check which groups are prepared today
      final prepared = <String>{};
      final todayDate = DateTime.now();
      for (final g in todaysGroups) {
        final records = await _attendanceRepo.getByGroupAndDate(g.id, todayDate);
        if (records.isNotEmpty) {
          prepared.add(g.id);
        }
      }
      _preparedGroupIds = prepared;

      // Find next session
      final sessionCandidates = <Map<String, dynamic>>[];
      for (final g in groups.where((g) => g.status == GroupStatus.active)) {
        for (final day in g.days) {
          final weekday = AppDateUtils.weekdayFromArabicName(day.day);
          sessionCandidates.add({
            'groupId': g.id,
            'group': g,
            'dayName': day.day,
            'weekday': weekday,
            'time': day.time,
          });
        }
      }

      NextSessionInfo? nextInfo;
      int? minMinutes;
      for (final candidate in sessionCandidates) {
        final minutes = AppDateUtils.minutesUntilNextSession(
          candidate['weekday'] as int,
          candidate['time'] as String,
        );
        if (minutes != null && (minMinutes == null || minutes < minMinutes)) {
          minMinutes = minutes;
          nextInfo = NextSessionInfo(
            group: candidate['group'] as GroupModel,
            dayName: candidate['dayName'] as String,
            time: candidate['time'] as String,
            minutesUntil: minutes,
            studentCount: counts[(candidate['group'] as GroupModel).id] ?? 0,
          );
        }
      }

      // Check for running / concurrent active sessions today
      final runningList = <ActiveSessionInfo>[];
      final todayWeekday = DateTime.now().weekday;

      for (final g in todaysGroups.where((g) => g.status == GroupStatus.active)) {
        for (final day in g.days) {
          if (AppDateUtils.weekdayFromArabicName(day.day) == todayWeekday) {
            final isRunning = AppDateUtils.isSessionCurrentlyRunning(todayWeekday, day.time);
            if (isRunning) {
              runningList.add(
                ActiveSessionInfo(
                  group: g,
                  dayName: day.day,
                  time: day.time,
                  minutesUntil: 0,
                  studentCount: counts[g.id] ?? 0,
                  isRunningNow: true,
                ),
              );
            }
          }
        }
      }

      // If no session is running right now, fallback to the upcoming session
      if (runningList.isEmpty && nextInfo != null) {
        runningList.add(
          ActiveSessionInfo(
            group: nextInfo.group,
            dayName: nextInfo.dayName,
            time: nextInfo.time,
            minutesUntil: nextInfo.minutesUntil,
            studentCount: nextInfo.studentCount,
            isRunningNow: false,
          ),
        );
      }

      _stats = HomeStats(
        totalStudents: studentCount,
        totalGroups: groups.where((g) => g.status == GroupStatus.active).length,
        absentToday: absentToday.length,
      );
      _todaysGroups = todaysGroups;
      _nextSession = nextInfo;
      _activeSessions = runningList;

      // Sync data to native Android Home Screen Widget
      try {
        final prefs = await SharedPreferences.getInstance();
        final teacherName = prefs.getString('teacher_name') ?? 'المعلم';
        await WidgetSyncService.syncWidgetData(
          teacherName: teacherName,
          nextGroupName: nextInfo?.group.name,
          nextGroupTime: nextInfo?.time,
          todayGroupsCount: todaysGroups.length,
        );
      } catch (_) {}
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveTodayNote(String note) async {
    _todayNote = note;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('today_note_${DateTime.now().toString().substring(0, 10)}', note);
    
    // Save to unified NoteRepository
    try {
      final generalNotes = await _noteRepo.getGeneralNotes();
      if (generalNotes.isNotEmpty) {
        final updated = generalNotes.first.copyWith(
          content: note,
          updatedAt: DateTime.now(),
        );
        await _noteRepo.update(updated);
      } else {
        final newNote = NoteModel(
          id: _uuid.v4(),
          type: 'general',
          targetId: 'today_${DateTime.now().toString().substring(0, 10)}',
          content: note,
          createdAt: DateTime.now(),
        );
        await _noteRepo.insert(newNote);
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> resetAllPoints() async {
    await _studentRepo.resetAllPoints();
    await loadData();
  }
}
