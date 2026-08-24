import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final DatabaseHelper _db;

  PaymentRepository({DatabaseHelper? db}) : _db = db ?? DatabaseHelper();

  /// Get all payments for a specific month/year
  Future<List<PaymentModel>> getByMonth(int month, int year) => getByMonthYear(month, year);

  Future<List<PaymentModel>> getByMonthYear(int month, int year) async {
    final rows = await _db.query(
      AppConstants.tablePayments,
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
    return rows.map(PaymentModel.fromMap).toList();
  }

  /// Get payment for a specific student in a month/year
  Future<PaymentModel?> getForStudent(
      String studentId, int month, int year) async {
    final rows = await _db.query(
      AppConstants.tablePayments,
      where: 'student_id = ? AND month = ? AND year = ?',
      whereArgs: [studentId, month, year],
    );
    return rows.isEmpty ? null : PaymentModel.fromMap(rows.first);
  }

  /// Get payment history for a student
  Future<List<PaymentModel>> getByStudent(String studentId) async {
    final rows = await _db.query(
      AppConstants.tablePayments,
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'year DESC, month DESC',
    );
    return rows.map(PaymentModel.fromMap).toList();
  }

  /// Get payments by group for a month
  Future<List<PaymentModel>> getByGroupAndMonth(
      String groupId, int month, int year) async {
    final rows = await _db.query(
      AppConstants.tablePayments,
      where: 'group_id = ? AND month = ? AND year = ?',
      whereArgs: [groupId, month, year],
    );
    return rows.map(PaymentModel.fromMap).toList();
  }

  Future<void> insert(PaymentModel payment) async {
    await _db.insert(AppConstants.tablePayments, payment.toMap());
  }

  Future<void> update(PaymentModel payment) async {
    await _db.update(AppConstants.tablePayments, payment.toMap(), payment.id);
  }

  Future<void> upsert(PaymentModel payment) async {
    final existing = await getForStudent(
        payment.studentId, payment.month, payment.year);
    if (existing == null) {
      await insert(payment);
    } else {
      await update(payment.copyWith(id: existing.id));
    }
  }

  Future<void> delete(String id) async {
    await _db.delete(AppConstants.tablePayments, id);
  }

  /// Financial summary for a month: expected vs collected
  Future<Map<String, double>> getMonthlySummary(int month, int year) async {
    final payments = await getByMonthYear(month, year);
    double expected = 0;
    double collected = 0;

    for (final p in payments) {
      expected += p.totalDue;
      collected += p.amount;
    }

    return {
      'expected': expected,
      'collected': collected,
      'remaining': expected - collected,
    };
  }

  /// Get students who haven't paid (unpaid) for a given month
  Future<List<String>> getUnpaidStudentIds(int month, int year) async {
    final rows = await _db.query(
      AppConstants.tablePayments,
      where: "month = ? AND year = ? AND type = 'لم يدفع'",
      whereArgs: [month, year],
    );
    return rows.map((r) => r['student_id'] as String).toList();
  }
}
