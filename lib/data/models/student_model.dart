import '../../core/constants/app_constants.dart';

class StudentModel {
  final String id;
  final String name;
  final String phone;
  final String parentPhone;
  final int level; // 1-10
  final String groupId;
  final int points;
  final StudentStatus status;
  final double discountAmount;
  final String discountType; // 'none' | 'fixed' | 'percent' | 'exempt' | 'sibling'
  final String discountReason;
  final String? siblingId; // ID of sibling student if discountType == 'sibling'
  final String? siblingName; // Name of sibling student
  final String specialNote; // ملاحظة خاصة تظهر تحت اسم الطالب في الكارت
  final String paymentMode; // 'monthly' | 'per_session'
  final DateTime createdAt;

  const StudentModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.parentPhone,
    required this.level,
    required this.groupId,
    this.points = 0,
    this.status = StudentStatus.active,
    this.discountAmount = 0.0,
    this.discountType = 'none',
    this.discountReason = '',
    this.siblingId,
    this.siblingName,
    this.specialNote = '',
    this.paymentMode = 'monthly',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'parent_phone': parentPhone,
      'level': level,
      'group_id': groupId,
      'points': points,
      'status': status.label,
      'discount_amount': discountAmount,
      'discount_type': discountType,
      'discount_reason': discountReason,
      'sibling_id': siblingId ?? '',
      'sibling_name': siblingName ?? '',
      'special_note': specialNote,
      'payment_mode': paymentMode,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      parentPhone: map['parent_phone'] as String? ?? '',
      level: map['level'] as int? ?? 5,
      groupId: map['group_id'] as String,
      points: map['points'] as int? ?? 0,
      status: StudentStatusExt.fromLabel(map['status'] as String? ?? 'نشط'),
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      discountType: map['discount_type'] as String? ?? 'none',
      discountReason: map['discount_reason'] as String? ?? '',
      siblingId: map['sibling_id'] as String?,
      siblingName: map['sibling_name'] as String?,
      specialNote: map['special_note'] as String? ?? '',
      paymentMode: map['payment_mode'] as String? ?? 'monthly',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? parentPhone,
    int? level,
    String? groupId,
    int? points,
    StudentStatus? status,
    double? discountAmount,
    String? discountType,
    String? discountReason,
    String? siblingId,
    String? siblingName,
    String? specialNote,
    String? paymentMode,
    DateTime? createdAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      level: level ?? this.level,
      groupId: groupId ?? this.groupId,
      points: points ?? this.points,
      status: status ?? this.status,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      discountReason: discountReason ?? this.discountReason,
      siblingId: siblingId ?? this.siblingId,
      siblingName: siblingName ?? this.siblingName,
      specialNote: specialNote ?? this.specialNote,
      paymentMode: paymentMode ?? this.paymentMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// First character of name for avatar
  String get initial => name.isNotEmpty ? name[0] : '؟';

  /// Level label
  String get levelLabel {
    if (level <= 3) return 'ضعيف';
    if (level <= 6) return 'متوسط';
    return 'متفوق';
  }

  /// Check if the student is completely exempt from payment
  bool get isExempt => discountType == 'exempt';

  /// Check if student has sibling discount
  bool get isSiblingDiscount => discountType == 'sibling';

  /// Check if student has any active discount
  bool get hasDiscount => discountType != 'none' && (discountAmount > 0 || isExempt || isSiblingDiscount);

  /// Human readable discount description
  String get discountDescription {
    if (isExempt) return 'إعفاء كامل ${discountReason.isNotEmpty ? "($discountReason)" : ""}';
    if (isSiblingDiscount) {
      final name = siblingName ?? '';
      return 'خصم إخوة (${discountAmount.toInt()} ج) ${name.isNotEmpty ? "- أخو $name" : ""}';
    }
    if (discountType == 'fixed') {
      return 'خصم ثابت (${discountAmount.toInt()} ج) ${discountReason.isNotEmpty ? "($discountReason)" : ""}';
    }
    if (discountType == 'percent') {
      return 'خصم ${discountAmount.toInt()}% ${discountReason.isNotEmpty ? "($discountReason)" : ""}';
    }
    return '';
  }

  /// Calculate actual expected fee for this student given the base group price
  double calculateDueAmount(double originalPrice) {
    if (isExempt) return 0.0;
    if (discountType == 'fixed' || discountType == 'sibling') {
      return (originalPrice - discountAmount).clamp(0.0, double.infinity);
    }
    if (discountType == 'percent') {
      return (originalPrice * (1.0 - (discountAmount / 100.0))).clamp(0.0, double.infinity);
    }
    return originalPrice;
  }
}
