import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/activity_log_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../core/constants/app_constants.dart';

class GroupPaymentSummary {
  final String groupId;
  final String groupName;
  final String paymentMode;
  final double monthlyPrice;
  final double sessionPrice;
  final List<StudentPaymentStatus> studentStatuses;

  GroupPaymentSummary({
    required this.groupId,
    required this.groupName,
    this.paymentMode = 'monthly',
    required this.monthlyPrice,
    this.sessionPrice = 0,
    required this.studentStatuses,
  });

  double get basePrice => paymentMode == 'per_session' ? sessionPrice : monthlyPrice;

  double get expected =>
      studentStatuses.fold(0.0, (sum, s) => sum + s.student.calculateDueAmount(basePrice));
  double get collected =>
      studentStatuses.fold(0.0, (sum, s) => sum + s.amountPaid);
  double get remaining => (expected - collected).clamp(0.0, double.infinity);
  double get collectionRate => expected == 0 ? 0 : (collected / expected).clamp(0.0, 1.0);

  int get paidCount => studentStatuses.where((s) => s.paymentType == PaymentType.full || s.student.isExempt).length;
  int get unpaidCount => studentStatuses.where((s) => (s.paymentType == PaymentType.unpaid || s.paymentType == PaymentType.partial) && !s.student.isExempt).length;
  int get totalCount => studentStatuses.length;
}

class StudentPaymentStatus {
  final StudentModel student;
  PaymentType paymentType;
  double amountPaid;
  String? paymentId;

  StudentPaymentStatus({
    required this.student,
    required this.paymentType,
    required this.amountPaid,
    this.paymentId,
  });
}

class FinanceProvider extends ChangeNotifier {
  final PaymentRepository _paymentRepo;
  final GroupRepository _groupRepo;
  final StudentRepository _studentRepo;
  final ActivityLogRepository _activityLogRepo;
  final _uuid = const Uuid();

  FinanceProvider({
    PaymentRepository? paymentRepo,
    GroupRepository? groupRepo,
    StudentRepository? studentRepo,
    ActivityLogRepository? activityLogRepo,
  })  : _paymentRepo = paymentRepo ?? PaymentRepository(),
        _groupRepo = groupRepo ?? GroupRepository(),
        _studentRepo = studentRepo ?? StudentRepository(),
        _activityLogRepo = activityLogRepo ?? ActivityLogRepository();

  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  List<GroupPaymentSummary> _summaries = [];
  bool _loading = false;

  List<GroupPaymentSummary> get summaries => _summaries;
  bool get loading => _loading;
  int get month => _month;
  int get year => _year;

  double get totalExpected =>
      _summaries.fold(0.0, (sum, g) => sum + g.expected);
  double get totalCollected =>
      _summaries.fold(0.0, (sum, g) => sum + g.collected);
  double get totalRemaining => totalExpected - totalCollected;
  double get overallRate =>
      totalExpected == 0 ? 0 : totalCollected / totalExpected;

  Future<void> loadPayments() async {
    await loadForMonth(_month, _year);
  }

  Future<void> loadForMonth(int month, int year) async {
    _month = month;
    _year = year;
    await _reload();
  }

  Future<void> _reload() async {
    _loading = true;
    notifyListeners();
    try {
      final groups = await _groupRepo.getActive();
      final summaries = <GroupPaymentSummary>[];

      for (final group in groups) {
        final students = await _studentRepo.getByGroup(group.id);
        final payments = await _paymentRepo.getByGroupAndMonth(
            group.id, _month, _year);
        final paymentMap = {for (final p in payments) p.studentId: p};

        final statuses = students.map((s) {
          final payment = paymentMap[s.id];
          return StudentPaymentStatus(
            student: s,
            paymentType: payment?.type ?? PaymentType.unpaid,
            amountPaid: payment?.amount ?? 0,
            paymentId: payment?.id,
          );
        }).toList();

        summaries.add(GroupPaymentSummary(
          groupId: group.id,
          groupName: group.name,
          paymentMode: group.paymentMode,
          monthlyPrice: group.monthlyPrice,
          sessionPrice: group.sessionPrice,
          studentStatuses: statuses,
        ));
      }

      _summaries = summaries;
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Instant reactive payment update without UI lag
  Future<void> updatePayment(
    String studentId,
    String groupId,
    PaymentType type,
    double amount,
    double totalDue,
  ) async {
    // 1. Instant optimistic in-memory update
    for (final groupSummary in _summaries) {
      if (groupSummary.groupId == groupId) {
        for (final status in groupSummary.studentStatuses) {
          if (status.student.id == studentId) {
            status.paymentType = type;
            status.amountPaid = amount;
            break;
          }
        }
        break;
      }
    }
    notifyListeners();

    // 2. Persist to database
    final payment = PaymentModel(
      id: _uuid.v4(),
      studentId: studentId,
      groupId: groupId,
      month: _month,
      year: _year,
      amount: amount,
      totalDue: totalDue,
      type: type,
      date: DateTime.now(),
    );
    await _paymentRepo.upsert(payment);

    // Find student name
    String studentName = 'طالب';
    for (final gs in _summaries) {
      final match = gs.studentStatuses.where((s) => s.student.id == studentId);
      if (match.isNotEmpty) {
        studentName = match.first.student.name;
        break;
      }
    }

    _activityLogRepo.log(
      actionType: 'payment_record',
      title: 'تسجيل دفعة مالية 💰',
      description: 'تم تسجيل دفعة بقيمة ${amount.toInt()} ج للطالب "$studentName" لشهر $_month/$_year (${type.label})',
      entityId: studentId,
      entityType: 'payment',
    );
  }

  PaymentType cyclePayment(PaymentType current) {
    switch (current) {
      case PaymentType.unpaid:
        return PaymentType.full;
      case PaymentType.partial:
        return PaymentType.full;
      case PaymentType.full:
        return PaymentType.unpaid;
    }
  }

  void nextMonth() {
    if (_month == 12) {
      _month = 1;
      _year++;
    } else {
      _month++;
    }
    _reload();
  }

  void prevMonth() {
    if (_month == 1) {
      _month = 12;
      _year--;
    } else {
      _month--;
    }
    _reload();
  }
}
