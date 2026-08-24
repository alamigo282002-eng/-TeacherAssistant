import 'package:flutter/foundation.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/exam_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/student_repository.dart';

class ReportsProvider extends ChangeNotifier {
  final GroupRepository _groupRepo;
  final StudentRepository _studentRepo;
  final ExamRepository _examRepo;

  ReportsProvider({
    GroupRepository? groupRepo,
    StudentRepository? studentRepo,
    ExamRepository? examRepo,
  })  : _groupRepo = groupRepo ?? GroupRepository(),
        _studentRepo = studentRepo ?? StudentRepository(),
        _examRepo = examRepo ?? ExamRepository();

  bool _loading = false;
  List<GroupModel> _groups = [];
  List<ExamModel> _exams = [];
  List<StudentModel> _leaderboard = [];
  String? _error;

  bool get loading => _loading;
  List<GroupModel> get groups => _groups;
  List<ExamModel> get exams => _exams;
  List<StudentModel> get leaderboard => _leaderboard;
  String? get error => _error;

  int get totalExams => _exams.length;
  int get totalLeaderboardStudents => _leaderboard.length;
  int get totalPointsCount => _leaderboard.fold(0, (s, st) => s + st.points);
  int get totalGroupsCount => _groups.length;

  Future<void> loadReportsData({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final groups = await _groupRepo.getAll();
      final exams = await _examRepo.getAll();
      final topStudents = await _studentRepo.getTopByPoints(limit: 50);

      _groups = groups;
      _exams = exams;
      _leaderboard = topStudents;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> resetAllPoints() async {
    try {
      await _studentRepo.resetAllPoints();
      _leaderboard = _leaderboard.map((s) => s.copyWith(points: 0)).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
