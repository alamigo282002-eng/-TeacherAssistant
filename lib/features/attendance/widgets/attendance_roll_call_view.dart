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

/// وضع المناداة المتسلسلة التفاعلي (Interactive Sequential Roll Call)
class AttendanceRollCallView extends StatefulWidget {
  final AttendanceProvider provider;
  final VoidCallback onSaved;

  const AttendanceRollCallView({
    super.key,
    required this.provider,
    required this.onSaved,
  });

  @override
  State<AttendanceRollCallView> createState() => _AttendanceRollCallViewState();
}

class _AttendanceRollCallViewState extends State<AttendanceRollCallView> {
  int _currentIndex = 0;

  void _mark(AttendanceStatus status) {
    if (_currentIndex >= widget.provider.entries.length) return;

    HapticFeedback.lightImpact();
    widget.provider.setStatus(_currentIndex, status);

    setState(() {
      _currentIndex++;
    });

    if (_currentIndex >= widget.provider.entries.length) {
      HapticFeedback.heavyImpact();
      ConfettiCelebrationOverlay.show(context);
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex--);
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Counter & Navigation Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                tooltip: 'السابق',
                onPressed: _currentIndex > 0 ? _previous : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.chipTeal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'طالب ${ArabicNumbers.convert((_currentIndex + 1).clamp(1, entries.length))} من ${ArabicNumbers.convert(entries.length)}',
                  style: GoogleFonts.changa(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                tooltip: 'التالي',
                onPressed: _currentIndex < entries.length - 1
                    ? () => setState(() => _currentIndex++)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Active Student Large Card
          Expanded(
            child: isFinished
                ? _buildFinishedCard(isDark)
                : _buildSpeakerStudentCard(entries[_currentIndex], isDark),
          ),

          const SizedBox(height: 18),

          // Big Actions Row
          if (!isFinished)
            Row(
              children: [
                Expanded(
                  child: AppScaleButton(
                    onTap: () => _mark(AttendanceStatus.absent),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkRedSoft : AppColors.redSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.red, width: 1.6),
                      ),
                      child: Center(
                        child: Text(
                          'غائب ❌',
                          style: GoogleFonts.changa(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppScaleButton(
                    onTap: () => _mark(AttendanceStatus.excused),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkOrangeSoft : AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.orange, width: 1.6),
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
                Expanded(
                  flex: 2,
                  child: AppScaleButton(
                    onTap: () => _mark(AttendanceStatus.present),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkBg : Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'حاضر الآن ✅',
                              style: GoogleFonts.changa(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkBg : Colors.white,
                              ),
                            ),
                          ],
                        ),
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
                  child: Text(
                    'حفظ الحضور والغياب 💾',
                    style: GoogleFonts.changa(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpeakerStudentCard(AttendanceEntry entry, bool isDark) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.campaign_rounded, color: AppColors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'المناداة على الطالب:',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Student Big Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.student.initial,
                style: GoogleFonts.changa(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Big Student Name
          Text(
            entry.student.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.changa(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkText : AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),

          if (entry.student.phone.isNotEmpty)
            Text(
              '📞 ${ArabicNumbers.convert(entry.student.phone)}',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
        ],
      ),
    ).animate(key: ValueKey('speaker_${entry.student.id}')).fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95));
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
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'اكتملت المناداة على جميع الطلاب!',
            textAlign: TextAlign.center,
            style: GoogleFonts.changa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

