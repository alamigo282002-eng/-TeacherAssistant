import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../attendance_provider.dart';

/// وضع التحضير الجماعي السريع (Bulk Attendance: الكل حاضر افتراضياً مع استبعاد الغائبين بنقرة)
class AttendanceBulkView extends StatelessWidget {
  final AttendanceProvider provider;
  final VoidCallback onSaved;

  const AttendanceBulkView({
    super.key,
    required this.provider,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner: Quick Bulk Presets
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFE8F8F2), const Color(0xFFD3F2E5)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ التحضير الجماعي الذكي',
                        style: GoogleFonts.changa(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                      ),
                      Text(
                        'اضغط على الطلاب الغائبين فقط لاستبعادهم',
                        style: GoogleFonts.tajawal(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                AppScaleButton(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.markAllPresent();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'الكل حاضر ✓',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkBg : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Students List with Quick Absent Toggle
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final entry = entries[i];
                final isPresent = entry.status == AttendanceStatus.present;
                final isAbsent = entry.status == AttendanceStatus.absent;

                return AppScaleButton(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.setStatus(
                      i,
                      isPresent ? AttendanceStatus.absent : AttendanceStatus.present,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? (Theme.of(context).cardColor)
                          : (isDark ? AppColors.darkRedSoft : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPresent
                            ? (isDark ? AppColors.darkBorder : AppColors.border)
                            : AppColors.red,
                        width: isAbsent ? 1.5 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isPresent
                                ? (isDark ? AppColors.darkGreenSoft : AppColors.chipTeal)
                                : (isDark ? AppColors.darkRedSoft : AppColors.redSoft),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              entry.student.initial,
                              style: GoogleFonts.changa(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isPresent
                                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                    : AppColors.red,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.student.name,
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isAbsent
                                  ? AppColors.red
                                  : (isDark ? AppColors.darkText : AppColors.ink),
                              decoration: isAbsent ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? (isDark ? AppColors.darkGreenSoft : AppColors.greenSoft)
                                : (isDark ? AppColors.darkRedSoft : AppColors.redSoft),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPresent ? 'حاضر ✅' : 'غائب ❌',
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPresent
                                  ? (isDark ? AppColors.darkPrimary : const Color(0xFF155724))
                                  : AppColors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms, delay: Duration(milliseconds: 10 * (i % 12)));
              },
            ),
          ),

          const SizedBox(height: 10),

          // Save Button
          AppScaleButton(
            onTap: () async {
              await provider.save();
              onSaved();
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.darkAccentGradient : AppColors.headerGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'حفظ الحضور (${ArabicNumbers.convert(provider.presentCount)} حاضر) 💾',
                      style: GoogleFonts.changa(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

