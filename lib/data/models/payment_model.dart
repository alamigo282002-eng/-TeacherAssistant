import '../../core/constants/app_constants.dart';

class PaymentModel {
  final String id;
  final String studentId;
  final String groupId;
  final int month; // 1-12
  final int year;
  final double amount; // amount actually paid
  final double totalDue; // full price
  final PaymentType type;
  final DateTime date;

  const PaymentModel({
    required this.id,
    required this.studentId,
    required this.groupId,
    required this.month,
    required this.year,
    required this.amount,
    required this.totalDue,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'group_id': groupId,
      'month': month,
      'year': year,
      'amount': amount,
      'total_due': totalDue,
      'type': type.label,
      'date': date.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      groupId: map['group_id'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      amount: (map['amount'] as num).toDouble(),
      totalDue: (map['total_due'] as num).toDouble(),
      type: PaymentTypeExt.fromLabel(map['type'] as String? ?? 'لم يدفع'),
      date: DateTime.parse(map['date'] as String),
    );
  }

  PaymentModel copyWith({
    String? id,
    String? studentId,
    String? groupId,
    int? month,
    int? year,
    double? amount,
    double? totalDue,
    PaymentType? type,
    DateTime? date,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      groupId: groupId ?? this.groupId,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      totalDue: totalDue ?? this.totalDue,
      type: type ?? this.type,
      date: date ?? this.date,
    );
  }

  bool get isPaid => type == PaymentType.full;
  bool get isPartial => type == PaymentType.partial;
  bool get isUnpaid => type == PaymentType.unpaid;
}
