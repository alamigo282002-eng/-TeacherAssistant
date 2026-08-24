import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/student_repository.dart';

class DiscountsListScreen extends StatefulWidget {
  const DiscountsListScreen({super.key});

  @override
  State<DiscountsListScreen> createState() => _DiscountsListScreenState();
}

class _DiscountsListScreenState extends State<DiscountsListScreen> {
  final StudentRepository _studentRepo = StudentRepository();
  final GroupRepository _groupRepo = GroupRepository();

  bool _loading = true;
  List<StudentModel> _discountedStudents = [];
  Map<String, GroupModel> _groupMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final allStudents = await _studentRepo.getAll();
      final allGroups = await _groupRepo.getAll();
      
      _groupMap = {for (final g in allGroups) g.id: g};
      _discountedStudents = allStudents.where((s) => s.hasDiscount).toList();
      
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'قائمة الخصومات والإعفاءات',
          style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _discountedStudents.isEmpty
              ? Center(
                  child: Text(
                    'لا يوجد طلاب لديهم خصومات أو إعفاءات حالياً',
                    style: GoogleFonts.tajawal(fontSize: 16, color: AppColors.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _discountedStudents.length,
                  itemBuilder: (context, index) {
                    final student = _discountedStudents[index];
                    final group = _groupMap[student.groupId];
                    final groupPrice = group?.monthlyPrice ?? 0.0;
                    final dueAmount = student.calculateDueAmount(groupPrice);
                    
                    return _buildDiscountCard(student, group, dueAmount, isDark);
                  },
                ),
    );
  }

  Widget _buildDiscountCard(StudentModel student, GroupModel? group, double dueAmount, bool isDark) {
    final groupPrice = group?.monthlyPrice ?? 0.0;
    String discountText = '';
    Color discountColor = AppColors.orange;
    
    if (student.isExempt) {
      discountText = 'إعفاء كامل';
      discountColor = AppColors.green;
    } else if (student.discountType == 'fixed') {
      discountText = 'خصم ${ArabicNumbers.convert(student.discountAmount.toInt())} ج.م';
    } else if (student.discountType == 'percent') {
      discountText = 'خصم ${ArabicNumbers.convert(student.discountAmount.toInt())}٪';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: discountColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: discountColor.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: discountColor.withValues(alpha: 0.1),
                child: Text(
                  student.initial,
                  style: GoogleFonts.changa(
                    fontWeight: FontWeight.bold,
                    color: discountColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.changa(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'مجموعة: ${group?.name ?? "-"}',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: discountColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  discountText,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: discountColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المبلغ الأصلي',
                    style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                  ),
                  Text(
                    '${ArabicNumbers.convert(groupPrice.toInt())} ج.م',
                    style: GoogleFonts.changa(
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'المبلغ المستحق',
                    style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                  ),
                  Text(
                    '${ArabicNumbers.convert(dueAmount.toInt())} ج.م',
                    style: GoogleFonts.changa(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (student.discountReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: discountColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'السبب: ${student.discountReason}',
                      style: GoogleFonts.tajawal(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

