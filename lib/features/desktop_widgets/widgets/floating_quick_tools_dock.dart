import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../../attendance/widgets/attendance_bottom_sheet.dart';
import '../desktop_widgets_screen.dart';
import 'classroom_timer_dialog.dart';
import 'grade_calculator_dialog.dart';
import 'random_student_picker_dialog.dart';

/// زر وقائمة الأدوات السريعة العائمة للمعلم
class FloatingQuickToolsDock extends StatefulWidget {
  const FloatingQuickToolsDock({super.key});

  @override
  State<FloatingQuickToolsDock> createState() => _FloatingQuickToolsDockState();
}

class _FloatingQuickToolsDockState extends State<FloatingQuickToolsDock>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _close() {
    if (_isOpen) {
      _controller.reverse();
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),

        Positioned(
          left: 18,
          bottom: 92,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expanded Action Items
              ScaleTransition(
                scale: _expandAnimation,
                alignment: Alignment.bottomLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. مركز ودجات سطح المكتب
                      _buildMenuItem(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'لوحة ودجات سطح المكتب',
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        isDark: isDark,
                        onTap: () {
                          _close();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DesktopWidgetsScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 4),

                      // 2. قرعة عشوائية للطلاب
                      _buildMenuItem(
                        icon: Icons.casino_rounded,
                        label: 'القرعة العشوائية الذكية',
                        color: AppColors.orange,
                        isDark: isDark,
                        onTap: () {
                          _close();
                          RandomStudentPickerDialog.show(context);
                        },
                      ),
                      const SizedBox(height: 4),

                      // 3. مؤقت الحصة والأنشطة
                      _buildMenuItem(
                        icon: Icons.timer_rounded,
                        label: 'مؤقت الحصة والاختبارات',
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                        onTap: () {
                          _close();
                          ClassroomTimerDialog.show(context);
                        },
                      ),
                      const SizedBox(height: 4),

                      // 4. حاسبة الدرجات والنسب
                      _buildMenuItem(
                        icon: Icons.calculate_rounded,
                        label: 'حاسبة الدرجات والنسب',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                        onTap: () {
                          _close();
                          GradeCalculatorDialog.show(context);
                        },
                      ),
                      const SizedBox(height: 4),

                      // 5. تحضير سريع
                      _buildMenuItem(
                        icon: Icons.how_to_reg_rounded,
                        label: 'التحضير السريع',
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        onTap: () {
                          _close();
                          AttendanceBottomSheet.show(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Main Trigger Button
              AppScaleButton(
                onTap: _toggle,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.darkAccentGradient
                        : const LinearGradient(
                            colors: [Color(0xFF0E8A6D), Color(0xFF14B892)],
                          ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 250),
                        turns: _isOpen ? 0.125 : 0,
                        child: Icon(
                          _isOpen ? Icons.close_rounded : Icons.auto_awesome_rounded,
                          color: isDark ? AppColors.darkBg : Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOpen ? 'إغلاق' : 'أدوات الحصة ⚡',
                        style: GoogleFonts.changa(
                          fontSize: 13,
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
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AppScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : const Color(0xFFF6FAF8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

