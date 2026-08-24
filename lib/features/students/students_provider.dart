import 'package:flutter/foundation.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../../data/repositories/student_repository.dart';

class StudentDetailData {
  final StudentModel student;
  final List<AttendanceModel> attendance;
  final List<Map<String, dynamic>> examHistory;
  final List<NoteModel> notes;

  const StudentDetailData({
    required this.student,
    this.attendance = const [],
    this.examHistory = const [],
    this.notes = const [],
  });
}

enum StudentSortType {
  alphabetical,
  dateAdded,
  points,
}

class StudentsProvider extends ChangeNotifier {
  final StudentRepository _repo;
  final AttendanceRepository _attendanceRepo;
  final ExamRepository _examRepo;
  final NoteRepository _noteRepo;
  final ActivityLogRepository _activityLogRepo;

  StudentsProvider({
    StudentRepository? repo,
    AttendanceRepository? attendanceRepo,
    ExamRepository? examRepo,
    NoteRepository? noteRepo,
    ActivityLogRepository? activityLogRepo,
  })  : _repo = repo ?? StudentRepository(),
        _attendanceRepo = attendanceRepo ?? AttendanceRepository(),
        _examRepo = examRepo ?? ExamRepository(),
        _noteRepo = noteRepo ?? NoteRepository(),
        _activityLogRepo = activityLogRepo ?? ActivityLogRepository();

  List<StudentModel> _students = [];
  List<StudentModel> _filtered = [];
  bool _loading = false;
  String _searchQuery = '';
  String? _groupFilter;
  StudentSortType _sortType = StudentSortType.alphabetical;

  StudentDetailData? _selectedStudentDetail;
  bool _detailLoading = false;

  List<StudentModel> get students => _filtered;
  List<StudentModel> get allStudents => _students;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  String? get groupFilter => _groupFilter;
  String? get selectedGroupId => _groupFilter;
  StudentSortType get sortType => _sortType;
  int get totalStudentsCount => _students.length;
  StudentDetailData? get selectedStudentDetail => _selectedStudentDetail;
  bool get detailLoading => _detailLoading;

  int getStudentCountForGroup(String groupId) =>
      _students.where((s) => s.groupId == groupId).length;

  Future<void> loadStudents({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    try {
      if (_searchQuery.isNotEmpty) {
        _students = await _repo.search(_searchQuery);
      } else {
        _students = await _repo.getAll();
      }
      _applyFilterAndSort();
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadStudents();
  }

  void setSearchQuery(String query) => setSearch(query);

  void setGroupFilter(String? groupId) {
    if (_groupFilter == groupId) return;
    _groupFilter = groupId;
    _applyFilterAndSort();
    notifyListeners();
  }

  void setSortType(StudentSortType type) {
    if (_sortType == type) return;
    _sortType = type;
    _applyFilterAndSort();
    notifyListeners();
  }

  void _applyFilter() {
    _applyFilterAndSort();
  }

  void _applyFilterAndSort() {
    List<StudentModel> list;
    if (_groupFilter == null) {
      list = List.from(_students);
    } else {
      list = _students.where((s) => s.groupId == _groupFilter).toList();
    }

    switch (_sortType) {
      case StudentSortType.alphabetical:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case StudentSortType.dateAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case StudentSortType.points:
        list.sort((a, b) => b.points.compareTo(a.points));
        break;
    }

    _filtered = list;
  }

  Future<void> addStudent(StudentModel student) async {
    await _repo.insert(student);
    _students.insert(0, student);
    _applyFilter();
    notifyListeners();

    _activityLogRepo.log(
      actionType: 'student_add',
      title: 'إضافة طالب جديد 👨‍🎓',
      description: 'تمت إضافة الطالب "${student.name}" بنجاح',
      entityId: student.id,
      entityType: 'student',
    );
  }

  Future<void> updateStudent(StudentModel student) async {
    await _repo.update(student);
    final idx = _students.indexWhere((s) => s.id == student.id);
    if (idx != -1) {
      _students[idx] = student;
      _applyFilter();
      notifyListeners();
    } else {
      await loadStudents(silent: true);
    }

    _activityLogRepo.log(
      actionType: 'student_edit',
      title: 'تعديل بيانات طالب ✏️',
      description: 'تم تحديث بيانات الطالب "${student.name}"',
      entityId: student.id,
      entityType: 'student',
    );
  }

  Future<void> deleteStudent(String id) async {
    final matches = _students.where((s) => s.id == id);
    final studentName = matches.isNotEmpty ? matches.first.name : 'طالب';
    await _repo.softDelete(id);
    _students.removeWhere((s) => s.id == id);
    _applyFilter();
    notifyListeners();

    _activityLogRepo.log(
      actionType: 'student_delete',
      title: 'حذف طالب 🗑️',
      description: 'تم نقل الطالب "$studentName" إلى سلة المحذوفات',
      entityId: id,
      entityType: 'student',
    );
  }

  Future<void> deleteBulkStudents(List<String> ids) async {
    for (final id in ids) {
      await _repo.softDelete(id);
      _students.removeWhere((s) => s.id == id);
    }
    _applyFilter();
    notifyListeners();

    _activityLogRepo.log(
      actionType: 'student_delete',
      title: 'حذف جماعي للطلاب 🗑️',
      description: 'تم نقل ${ids.length} طلاب إلى سلة المحذوفات',
      entityType: 'student',
    );
  }

  Future<void> loadStudentDetail(String studentId, {bool silent = false}) async {
    if (!silent) {
      _detailLoading = true;
      notifyListeners();
    }

    try {
      final student = await _repo.getById(studentId);
      if (student != null) {
        final attendance = await _attendanceRepo.getByStudent(studentId);
        final examHistory = await _examRepo.getStudentExamHistory(studentId);
        final notes = await _noteRepo.getByTarget('student', studentId);

        _selectedStudentDetail = StudentDetailData(
          student: student,
          attendance: attendance,
          examHistory: examHistory,
          notes: notes,
        );
      }
    } catch (_) {
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  Future<List<StudentModel>> getByGroup(String groupId) {
    return _repo.getByGroup(groupId);
  }

  Future<StudentModel?> getById(String id) => _repo.getById(id);

  Future<int> countActive() => _repo.countActive();

  Future<List<StudentModel>> getTopByPoints() => _repo.getTopByPoints();
}
