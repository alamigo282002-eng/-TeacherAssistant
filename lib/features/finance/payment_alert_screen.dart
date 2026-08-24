import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/student_repository.dart';

class PaymentAlertScreen extends StatefulWidget {
  const PaymentAlertScreen({super.key});

  @override
  State<PaymentAlertScreen> createState() => _PaymentAlertScreenState();
}

class _PaymentAlertScreenState extends State<PaymentAlertScreen> {
  final _paymentRepo = PaymentRepository();
  final _studentRepo = StudentRepository();
  
  bool _loading = true;
  List<StudentModel> _unpaidStudents = [];
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUnpaidStudents();
  }

  Future<void> _loadUnpaidStudents() async {
    setState(() => _loading = true);
    try {
      final allStudents = await _studentRepo.getAll();
      
      // Filter out students who haven't paid explicitly or don't have a record
      // Actually, if they don't have a record, they haven't paid either.
      // Let's get all payments for this month
      final monthPayments = await _paymentRepo.getByMonthYear(_now.month, _now.year);
      final paidOrExemptIds = monthPayments
          .where((p) => p.type == PaymentType.full)
          .map((p) => p.studentId)
          .toSet();

      final unpaid = allStudents.where((s) => !paidOrExemptIds.contains(s.id)).toList();

      if (mounted) {
        setState(() {
          _unpaidStudents = unpaid;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنبيه المدفوعات المتأخرة'),
        backgroundColor: AppColors.error,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _unpaidStudents.isEmpty
              ? _buildEmptyState(isDark)
              : _buildUnpaidList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: AppColors.success),
          const SizedBox(height: 16),
          Text(
            'ممتاز!',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          Text(
            'لا يوجد طلاب متأخرين في الدفع لهذا الشهر',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidList(bool isDark) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: AppColors.warning.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'يوجد ${_unpaidStudents.length} طلاب لم يسددوا رسوم شهر ${_now.month}',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _unpaidStudents.length,
            itemBuilder: (context, index) {
              final student = _unpaidStudents[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border(
                    right: BorderSide(color: AppColors.error, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    StudentAvatar(name: student.name, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            student.phone.isNotEmpty ? student.phone : 'لا يوجد رقم',
                            style: GoogleFonts.cairo(
                              color: AppColors.lightTextSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.payment, color: AppColors.primary),
                      tooltip: 'تسجيل دفع',
                      onPressed: () {
                        // Navigate to finance tab or payment dialog
                        // Here we just pop and let the user navigate manually or 
                        // we could open a dialog to record payment.
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
