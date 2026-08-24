import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_scale_button.dart';
import '../attendance/widgets/attendance_bottom_sheet.dart';
import '../home/home_provider.dart';
import '../home/widgets/absentees_bottom_sheet.dart';
import 'widgets/classroom_timer_dialog.dart';
import 'widgets/grade_calculator_dialog.dart';
import 'widgets/random_student_picker_dialog.dart';

/// شاشة ومركز ودجات سطح المكتب وأدوات المعلم التفاعلية
class DesktopWidgetsScreen extends StatefulWidget {
  const DesktopWidgetsScreen({super.key});

  @override
  State<DesktopWidgetsScreen> createState() => _DesktopWidgetsScreenState();
}

class _DesktopWidgetsScreenState extends State<DesktopWidgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeP = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'لوحة ودجات سطح المكتب وأدوات المعلم',
          style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث البيانات',
            onPressed: () => context.read<HomeProvider>().loadData(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Welcome & Description Banner
            _buildIntroBanner(isDark),

            const SizedBox(height: 18),

            // 1. ودجت الحصة المباشرة
            _buildLiveSessionWidget(homeP, isDark),

            const SizedBox(height: 16),

            // 2. ودجت أدوات المعلم السريعة (القرعة، المؤقت، الحاسبة)
            _buildToolsGridWidget(context, isDark),

            const SizedBox(height: 16),

            // 3. ودجت بطاقات الملاحظات السريعة
            _buildStickyNotesWidget(homeP, isDark),

            const SizedBox(height: 16),

            // 4. ودجت غائبون اليوم والتواصل السريع
            _buildAbsenteesWidget(homeP, isDark),

            const SizedBox(height: 16),

            // 5. ودجت الشاشة الرئيسية لنظام أندرويد (Android Widget Info Card)
            _buildAndroidAppWidgetCard(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkHeaderGradient : AppColors.headerGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.widgets_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز الودجات والأدوات التفاعلية',
                  style: GoogleFonts.changa(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ودجات مكتبية مصممة لتسريع مهام المعلم وإدارة الحصة بسلاسة فائقة',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLiveSessionWidget(HomeProvider homeP, bool isDark) {
    final next = homeP.nextSession;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ودجت الحصة والجدول المباشر',
                    style: GoogleFonts.changa(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (next != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${next.dayName} · ${ArabicNumbers.formatTime12(next.time)}',
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (next == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.free_breakfast_outlined, color: AppColors.muted, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      'لا توجد حصص قادمة مجدولة اليوم',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Text(
              next.group.name,
              style: GoogleFonts.changa(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.ink,
              ),
            ),
            if (next.group.subject != null && next.group.subject!.isNotEmpty)
              Text(
                '📖 ${next.group.subject!}',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  next.group.type == GroupType.online
                      ? Icons.videocam_rounded
                      : Icons.location_on_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  next.group.type.label,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.people_alt_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${ArabicNumbers.convert(next.studentCount)} طالب',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
                const Spacer(),
                AppScaleButton(
                  onTap: () {
                    AttendanceBottomSheet.show(context, group: next.group).then((_) {
                      if (mounted) context.read<HomeProvider>().loadData();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_rounded,
                          size: 15,
                          color: isDark ? AppColors.darkBg : Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'تحضير فوري',
                          style: GoogleFonts.changa(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkBg : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildToolsGridWidget(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أدوات الحصة التفاعلية',
          style: GoogleFonts.changa(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkText : AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 1. القرعة العشوائية
            Expanded(
              child: _buildToolCard(
                icon: Icons.casino_rounded,
                title: 'القرعة الذكية',
                subtitle: 'سحب عشوائي للطلاب',
                color: AppColors.orange,
                isDark: isDark,
                onTap: () => RandomStudentPickerDialog.show(context),
              ),
            ),
            const SizedBox(width: 10),

            // 2. مؤقت الحصة
            Expanded(
              child: _buildToolCard(
                icon: Icons.timer_rounded,
                title: 'مؤقت الأنشطة',
                subtitle: 'عد تنازلي وتنبيهات',
                color: const Color(0xFF3B82F6),
                isDark: isDark,
                onTap: () => ClassroomTimerDialog.show(context),
              ),
            ),
            const SizedBox(width: 10),

            // 3. حاسبة الدرجات
            Expanded(
              child: _buildToolCard(
                icon: Icons.calculate_rounded,
                title: 'حاسبة الدرجات',
                subtitle: 'نسب وتقديرات فورية',
                color: const Color(0xFF10B981),
                isDark: isDark,
                onTap: () => GradeCalculatorDialog.show(context),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 450.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AppScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.changa(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 10,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyNotesWidget(HomeProvider homeP, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.orange.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📌', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'ودجت الملاحظة والمهام السريعة',
                    style: GoogleFonts.changa(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'حفظ تلقائي',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF856404),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            homeP.todayNote.isNotEmpty ? homeP.todayNote : 'لا توجد ملاحظات مسجلة لليوم حتى الآن.',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              color: isDark ? AppColors.darkText : AppColors.ink,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 150.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAbsenteesWidget(HomeProvider homeP, bool isDark) {
    final absentCount = homeP.stats?.absentToday ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkRedSoft : AppColors.redSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_off_rounded, color: AppColors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ودجت متابعة الغياب والتواصل',
                  style: GoogleFonts.changa(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.ink,
                  ),
                ),
                Text(
                  absentCount == 0
                    ? '🎉 لا يوجد أي غياب مسجل اليوم!'
                    : 'يوجد $absentCount طالب غائب اليوم يحتاج متابعة',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          AppScaleButton(
            onTap: () {
              AbsenteesBottomSheet.show(context).then((_) {
                if (mounted) context.read<HomeProvider>().loadData();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.chipTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'عرض الغائبين',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 550.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAndroidAppWidgetCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF1F9F6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'ودجت الشاشة الرئيسية لهاتف أندرويد (Android Widget)',
                style: GoogleFonts.changa(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك إضافة ودجت "مساعد المعلم" مباشرة على شاشة الهاتف الرئيسية لجهازك لمتابعة الحصص القادمة والحضور دون الحاجة لفتح التطبيق!',
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: isDark ? AppColors.darkMuted : AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'طريقة التفعيل: اضغط مطولاً على الشاشة الرئيسية لهاتفك > اختر Widgets (الويدجتس) > ابحث عن "مساعد المعلم" واسحب الودجت للشاشة.',
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 250.ms).slideY(begin: 0.1, end: 0);
  }
}

