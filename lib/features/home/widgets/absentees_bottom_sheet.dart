import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../settings/settings_provider.dart';

class AbsentStudentInfo {
  final StudentModel student;
  final String groupName;

  const AbsentStudentInfo({
    required this.student,
    required this.groupName,
  });
}

class AbsenteesBottomSheet extends StatefulWidget {
  const AbsenteesBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AbsenteesBottomSheet(),
    );
  }

  @override
  State<AbsenteesBottomSheet> createState() => _AbsenteesBottomSheetState();
}

class _AbsenteesBottomSheetState extends State<AbsenteesBottomSheet> {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();
  final StudentRepository _studentRepo = StudentRepository();
  final GroupRepository _groupRepo = GroupRepository();

  List<AbsentStudentInfo> _absentees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAbsentees();
  }

  Future<void> _loadAbsentees() async {
    final today = DateTime.now();
    final records = await _attendanceRepo.getTodayAbsentees(today);
    final list = <AbsentStudentInfo>[];

    final groups = await _groupRepo.getAll();
    final groupMap = {for (final g in groups) g.id: g.name};

    for (final r in records) {
      final student = await _studentRepo.getById(r.studentId);
      if (student != null) {
        list.add(AbsentStudentInfo(
          student: student,
          groupName: groupMap[r.groupId] ?? 'المجموعة',
        ));
      }
    }

    if (mounted) {
      setState(() {
        _absentees = list;
        _loading = false;
      });
    }
  }

  Future<void> _sendWhatsAppMessage(AbsentStudentInfo item) async {
    final phone = item.student.parentPhone.isNotEmpty
        ? item.student.parentPhone
        : item.student.phone;

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رقم هاتف مسجل لولي أمر الطالب ${item.student.name}',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cleanedPhone = AppValidators.cleanPhone(phone);
    final dateStr = DateFormat('yyyy/MM/dd').format(DateTime.now());
    
    final settings = context.read<SettingsProvider>();
    final template = settings.templateAbsence;
    final messageText = template
        .replaceAll('{student}', item.student.name)
        .replaceAll('{group}', item.groupName)
        .replaceAll('{date}', ArabicNumbers.convert(dateStr));

    final message = Uri.encodeComponent(messageText);
    final url = Uri.parse('https://wa.me/$cleanedPhone?text=$message');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر فتح تطبيق واتساب', style: GoogleFonts.tajawal()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : const Color(0xFFD0D7D9),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_off_rounded, color: AppColors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'غائبون اليوم',
                        style: GoogleFonts.changa(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                      Text(
                        'قائمة الطلاب الغائبين وإشعار أولياء الأمور عبر واتساب',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _absentees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 56, color: AppColors.green),
                            const SizedBox(height: 12),
                            Text(
                              'لا يوجد غائبون اليوم! 🎉',
                              style: GoogleFonts.changa(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkText : AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'جميع الطلاب حضروا حصصهم اليوم',
                              style: GoogleFonts.tajawal(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _absentees.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _absentees[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : const Color(0xFFFFF9F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.redSoft,
                                  child: Text(
                                    item.student.name.isNotEmpty ? item.student.name[0] : 'ط',
                                    style: GoogleFonts.changa(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.student.name,
                                        style: GoogleFonts.changa(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.darkText : AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'مجموعة: ${item.groupName}',
                                        style: GoogleFonts.tajawal(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // WhatsApp Parent Message Button
                                AppScaleButton(
                                  onTap: () => _sendWhatsAppMessage(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF25D366).withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.chat_bubble_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'إرسال واتساب',
                                          style: GoogleFonts.tajawal(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
