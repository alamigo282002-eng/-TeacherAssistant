import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../attendance_provider.dart';

/// وضع شبكة اللمس السريع البصرية (Quick-Tap Bubble Grid)
class AttendanceQuickGridView extends StatelessWidget {
  final AttendanceProvider provider;
  final VoidCallback onSaved;

  const AttendanceQuickGridView({
    super.key,
    required this.provider,
    required this.onSaved,
  });

  void _cycleStatus(int index) {
    HapticFeedback.lightImpact();
    final current = provider.entries[index].status;
    AttendanceStatus next;
    if (current == AttendanceStatus.present) {
      next = AttendanceStatus.absent;
    } else if (current == AttendanceStatus.absent) {
      next = AttendanceStatus.excused;
    } else {
      next = AttendanceStatus.present;
    }
    provider.setStatus(index, next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = provider.entries;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick Tap Legend & Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF1F6F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('🟢 حاضر (${ArabicNumbers.convert(provider.presentCount)})', isDark),
                const SizedBox(width: 8),
                _buildLegendItem('🔴 غائب (${ArabicNumbers.convert(provider.absentCount)})', isDark),
                const SizedBox(width: 8),
                _buildLegendItem('⚪ تخطي (${ArabicNumbers.convert(provider.excusedCount)})', isDark),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Instruction Text
          Text(
            '💡 انقر على اسم الطالب لتغيير حالته (حاضر 🟢 / غائب 🔴 / تخطي ⚪)',
            style: GoogleFonts.tajawal(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
          ),

          const SizedBox(height: 12),

          // Grid of Students
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemCount: entries.length,
              itemBuilder: (ctx, i) {
                final entry = entries[i];
                final status = entry.status;
                Color statusBg;
                Color statusBorder;
                Color statusText;
                IconData statusIcon;

                if (status == AttendanceStatus.present) {
                  statusBg = isDark ? AppColors.darkGreenSoft : const Color(0xFFE8F8F2);
                  statusBorder = isDark ? AppColors.darkPrimary : AppColors.primary;
                  statusText = isDark ? AppColors.darkPrimary : AppColors.primary;
                  statusIcon = Icons.check_circle_rounded;
                } else if (status == AttendanceStatus.absent) {
                  statusBg = isDark ? AppColors.darkRedSoft : const Color(0xFFFEE2E2);
                  statusBorder = isDark ? AppColors.darkRed : AppColors.red;
                  statusText = isDark ? AppColors.darkRed : AppColors.red;
                  statusIcon = Icons.cancel_rounded;
                } else {
                  statusBg = isDark ? AppColors.darkOrangeSoft : const Color(0xFFFEF3C7);
                  statusBorder = isDark ? AppColors.darkOrange : AppColors.orange;
                  statusText = isDark ? AppColors.darkOrange : AppColors.orange;
                  statusIcon = Icons.warning_amber_rounded;
                }

                return AppScaleButton(
                  onTap: () => _cycleStatus(i),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: statusBorder, width: 1.6),
                      boxShadow: [
                        BoxShadow(
                          color: statusBorder.withValues(alpha: isDark ? 0.2 : 0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Status Icon & Initial Avatar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  entry.student.initial,
                                  style: GoogleFonts.changa(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: statusText,
                                  ),
                                ),
                              ),
                            ),
                            Icon(statusIcon, color: statusBorder, size: 16),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Student Name
                        Text(
                          entry.student.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.tajawal(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.ink,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 250.ms, delay: Duration(milliseconds: 15 * (i % 15))).scale(begin: const Offset(0.9, 0.9));
              },
            ),
          ),

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
                      'حفظ الحضور والغياب 💾',
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

  Widget _buildLegendItem(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.tajawal(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkText : AppColors.ink,
      ),
    );
  }
}

