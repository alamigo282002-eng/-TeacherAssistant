import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../../../core/widgets/confetti_celebration.dart';
import '../attendance_provider.dart';

/// وضع التحضير بالسحب والبطاقات التفاعلية (Card Swipe / Flipper)
class AttendanceCardSwipeView extends StatefulWidget {
  final AttendanceProvider provider;
  final VoidCallback onSaved;

  const AttendanceCardSwipeView({
    super.key,
    required this.provider,
    required this.onSaved,
  });

  @override
  State<AttendanceCardSwipeView> createState() => _AttendanceCardSwipeViewState();
}

class _AttendanceCardSwipeViewState extends State<AttendanceCardSwipeView> {
  int _currentIndex = 0;
  final List<int> _history = [];

  void _mark(AttendanceStatus status) {
    if (_currentIndex >= widget.provider.entries.length) return;

    HapticFeedback.lightImpact();
    widget.provider.setStatus(_currentIndex, status);
    _history.add(_currentIndex);

    setState(() {
      _currentIndex++;
    });

    if (_currentIndex >= widget.provider.entries.length) {
      HapticFeedback.heavyImpact();
      ConfettiCelebrationOverlay.show(context);
    }
  }

  void _undo() {
    if (_history.isNotEmpty) {
      HapticFeedback.selectionClick();
      final lastIndex = _history.removeLast();
      setState(() {
        _currentIndex = lastIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = widget.provider.entries;

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'لا يوجد طلاب في هذه المجموعة',
          style: GoogleFonts.changa(fontSize: 16, color: AppColors.muted),
        ),
      );
    }

    final isFinished = _currentIndex >= entries.length;
    final progress = entries.isNotEmpty ? (_currentIndex / entries.length) : 1.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress & Undo Bar
          Row(
            children: [
              Text(
                'التقدم: ${ArabicNumbers.convert(_currentIndex.clamp(0, entries.length))} / ${ArabicNumbers.convert(entries.length)}',
                style: GoogleFonts.changa(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFE2E8E4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  tooltip: 'تراجع عن الأخير',
                  color: isDark ? AppColors.darkOrange : AppColors.orange,
                  onPressed: _undo,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Swipeable Card / Finish Card
          Expanded(
            child: isFinished
                ? _buildFinishedCard(isDark)
                : _buildActiveStudentCard(entries[_currentIndex], isDark),
          ),

          const SizedBox(height: 16),

          // Action Buttons Bar
          if (!isFinished)
            Row(
              children: [
                // 1. Absent (غائب)
                Expanded(
                  child: AppScaleButton(
                    onTap: () => _mark(AttendanceStatus.absent),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkRedSoft : AppColors.redSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.red, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close_rounded, color: AppColors.red, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            'غائب ❌',
                            style: GoogleFonts.changa(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Skipped (تخطي)
                Expanded(
                  child: AppScaleButton(
                    onTap: () => _mark(AttendanceStatus.excused),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: Center(
                        child: Text(
                          'تخطي ⏩',
                          style: GoogleFonts.changa(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Present (حاضر)
                Expanded(
                  child: AppScaleButton(
                    onTap: () => _mark(AttendanceStatus.present),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkGreenSoft : AppColors.greenSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'حاضر ✅',
                            style: GoogleFonts.changa(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            AppScaleButton(
              onTap: () async {
                await widget.provider.save();
                widget.onSaved();
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkAccentGradient : AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'حفظ الحضور والغياب 💾',
                        style: GoogleFonts.changa(
                          fontSize: 15,
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

  Widget _buildActiveStudentCard(AttendanceEntry entry, bool isDark) {
    final student = entry.student;
    final initial = student.initial;

    return Dismissible(
      key: ValueKey('swipe_${student.id}_$_currentIndex'),
      direction: DismissDirection.horizontal,
      onDismissed: (dir) {
        if (dir == DismissDirection.startToEnd) {
          // Swipe Right (in RTL: right is start) -> Present
          _mark(AttendanceStatus.present);
        } else {
          // Swipe Left -> Absent
          _mark(AttendanceStatus.absent);
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.greenSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 40),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: AppColors.redSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.cancel_rounded, color: AppColors.red, size: 40),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Student Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.changa(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Student Name
            Text(
              student.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.changa(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),

            // Phone
            if (student.phone.isNotEmpty)
              Text(
                '📞 ${ArabicNumbers.convert(student.phone)}',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                ),
              ),

            const SizedBox(height: 18),

            // Swipe Hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swipe_rounded, size: 16, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(
                    'اسحب يميناً للحضور أو يساراً للغياب',
                    style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 250.ms, curve: Curves.easeOutBack);
  }

  Widget _buildFinishedCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'تم تسجيل الحضور لجميع الطلاب!',
            textAlign: TextAlign.center,
            style: GoogleFonts.changa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الحاضرون: ${ArabicNumbers.convert(widget.provider.presentCount)} · الغائبون: ${ArabicNumbers.convert(widget.provider.absentCount)}',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: isDark ? AppColors.darkText : AppColors.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

