import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/student_repository.dart';

class AttendanceEntry {
  final StudentModel student;
  AttendanceStatus status;
  bool homeworkDone;
  String note;
  double? recitationPoints;

  AttendanceEntry({
    required this.student,
    this.status = AttendanceStatus.present,
    this.homeworkDone = false,
    this.note = '',
    this.recitationPoints,
  });
}

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _repo;
  final StudentRepository _studentRepo;
  final ActivityLogRepository _activityLogRepo;
  final _uuid = const Uuid();

  AttendanceProvider({
    AttendanceRepository? repo,
    StudentRepository? studentRepo,
    ActivityLogRepository? activityLogRepo,
  })  : _repo = repo ?? AttendanceRepository(),
        _studentRepo = studentRepo ?? StudentRepository(),
        _activityLogRepo = activityLogRepo ?? ActivityLogRepository();

  List<AttendanceEntry> _entries = [];
  bool _loading = false;
  bool _saving = false;
  String? _groupId;
  DateTime _date = DateTime.now();

  List<AttendanceEntry> get entries => _entries;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get groupId => _groupId;
  DateTime get date => _date;

  Future<void> loadForGroup(String groupId, {DateTime? date}) async {
    _groupId = groupId;
    DateTime targetDate = date ?? DateTime.now();
    if (targetDate.isAfter(DateTime.now())) {
      targetDate = DateTime.now();
    }
    _date = targetDate;
    _loading = true;
    notifyListeners();

    try {
      final students = await _studentRepo.getByGroup(groupId);
      // Load existing records for today
      final existing = await _repo.getByGroupAndDate(groupId, _date);
      final existingMap = {for (final a in existing) a.studentId: a};

      _entries = students.map((s) {
        final record = existingMap[s.id];
        return AttendanceEntry(
          student: s,
          status: record?.status ?? AttendanceStatus.present,
          homeworkDone: record?.homeworkDone ?? false,
          note: record?.note ?? '',
          recitationPoints: record?.recitationPoints,
        );
      }).toList();
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void toggleStatus(int index) {
    final newStatus = _entries[index].status == AttendanceStatus.present
        ? AttendanceStatus.absent
        : AttendanceStatus.present;
    _entries[index].status = newStatus;
    if (newStatus == AttendanceStatus.absent) {
      _entries[index].homeworkDone = false;
    }
    notifyListeners();
  }

  void setStatus(int index, AttendanceStatus status) {
    _entries[index].status = status;
    if (status == AttendanceStatus.absent) {
      _entries[index].homeworkDone = false;
    }
    notifyListeners();
  }

  void setHomework(int index, bool done) {
    _entries[index].homeworkDone = done;
    notifyListeners();
  }

  void setRecitationPoints(int index, double? points) {
    _entries[index].recitationPoints = points;
    notifyListeners();
  }

  void toggleHomework(int index) {
    _entries[index].homeworkDone = !_entries[index].homeworkDone;
    notifyListeners();
  }

  void setNote(int index, String note) {
    _entries[index].note = note;
    notifyListeners();
  }

  Future<int> addLiveParticipationPoint(int index) async {
    final studentId = _entries[index].student.id;
    await _studentRepo.addPoints(studentId, 1);
    final updatedStudent = _entries[index].student.copyWith(
      points: _entries[index].student.points + 1,
    );
    _entries[index] = AttendanceEntry(
      student: updatedStudent,
      status: _entries[index].status,
      homeworkDone: _entries[index].homeworkDone,
      note: _entries[index].note,
      recitationPoints: _entries[index].recitationPoints,
    );
    notifyListeners();
    return updatedStudent.points;
  }

  void markAllPresent() {
    for (final e in _entries) {
      e.status = AttendanceStatus.present;
    }
    notifyListeners();
  }

  void markAllAbsent() {
    for (final e in _entries) {
      e.status = AttendanceStatus.absent;
      e.homeworkDone = false;
    }
    notifyListeners();
  }

  Future<bool> save() async {
    if (_groupId == null) return false;
    _saving = true;
    notifyListeners();

    try {
      final records = _entries.map((e) => AttendanceModel(
            id: _uuid.v4(),
            studentId: e.student.id,
            groupId: _groupId!,
            date: _date,
            status: e.status,
            homeworkDone: e.status == AttendanceStatus.present ? e.homeworkDone : false,
            note: e.note,
            recitationPoints: e.recitationPoints,
          )).toList();

      await _repo.upsertBatch(records);

      // Award points (+1 for attendance, +1 for homework)
      for (final e in _entries) {
        if (e.status == AttendanceStatus.present) {
          await _studentRepo.addPoints(e.student.id, AppConstants.pointsForAttendance);
          if (e.homeworkDone) {
            await _studentRepo.addPoints(e.student.id, AppConstants.pointsForHomework);
          }
        }
      }

      _activityLogRepo.log(
        actionType: 'attendance_record',
        title: 'تسجيل الحضور والغياب 📋',
        description: 'تم رصد حضور $presentCount طالب وغياب $absentCount طالب',
        entityId: _groupId,
        entityType: 'attendance',
      );

      return true;
    } catch (_) {
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  int get presentCount => _entries.where((e) => e.status == AttendanceStatus.present).length;
  int get absentCount => _entries.where((e) => e.status == AttendanceStatus.absent).length;
  int get excusedCount => _entries.where((e) => e.status == AttendanceStatus.excused).length;
}
