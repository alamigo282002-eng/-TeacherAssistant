import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../../../core/widgets/confetti_celebration.dart';

/// مؤقت الحصة والأنشطة التفاعلي
class ClassroomTimerDialog extends StatefulWidget {
  const ClassroomTimerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ClassroomTimer',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const ClassroomTimerDialog(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ClassroomTimerDialog> createState() => _ClassroomTimerDialogState();
}

class _ClassroomTimerDialogState extends State<ClassroomTimerDialog> {
  int _totalSeconds = 300; // Default 5 minutes
  int _remainingSeconds = 300;
  bool _isRunning = false;
  Timer? _timer;

  final List<int> _presetMinutes = [1, 3, 5, 10, 15, 30, 45];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) {
      _remainingSeconds = _totalSeconds;
    }
    setState(() => _isRunning = true);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _isRunning = false);
        HapticFeedback.heavyImpact();
        ConfettiCelebrationOverlay.show(context);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _setPreset(int minutes) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _totalSeconds = minutes * 60;
      _remainingSeconds = _totalSeconds;
    });
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return ArabicNumbers.convert('$mm:$ss');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds) : 0.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.16),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مؤقت الحصة والأنشطة',
                          style: GoogleFonts.changa(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.ink,
                          ),
                        ),
                        Text(
                          'إدارة أوقات التمارين والاختبارات بذكاء',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: isDark ? AppColors.darkMuted : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Circular Countdown Visualizer
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Track
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.darkSurface : const Color(0xFFEDF2F0),
                          ),
                        ),
                      ),
                      // Active Progress Track
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _remainingSeconds <= 30
                                ? AppColors.red
                                : (_isRunning ? (isDark ? AppColors.darkPrimary : AppColors.primary) : AppColors.orange),
                          ),
                        ),
                      ),
                      // Time Text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_remainingSeconds),
                            style: GoogleFonts.changa(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: _remainingSeconds <= 30
                                  ? AppColors.red
                                  : (isDark ? AppColors.darkText : AppColors.ink),
                            ),
                          ),
                          Text(
                            _isRunning ? 'جاري العد...' : (_remainingSeconds == 0 ? 'انتهى الوقت 🔔' : 'جاهز للبدء'),
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkMuted : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Preset Minutes Chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: _presetMinutes.map((mins) {
                  final isSelected = _totalSeconds == mins * 60;
                  return AppScaleButton(
                    onTap: () => _setPreset(mins),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                            : (isDark ? AppColors.darkSurface : AppColors.chipTeal),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${ArabicNumbers.convert(mins)} دقيقة',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (isDark ? AppColors.darkBg : Colors.white)
                              : (isDark ? AppColors.darkText : AppColors.primary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // Controls
              Row(
                children: [
                  // Start / Pause Button
                  Expanded(
                    flex: 2,
                    child: AppScaleButton(
                      onTap: _isRunning ? _pauseTimer : _startTimer,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isRunning
                              ? AppColors.orange
                              : (isDark ? AppColors.darkPrimary : AppColors.primary),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: _isRunning ? Colors.white : (isDark ? AppColors.darkBg : Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isRunning ? 'إيقاف مؤقت' : 'بدء المؤقت',
                                style: GoogleFonts.changa(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isRunning ? Colors.white : (isDark ? AppColors.darkBg : Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Reset Button
                  Expanded(
                    child: AppScaleButton(
                      onTap: _resetTimer,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded, size: 18, color: isDark ? AppColors.darkMuted : AppColors.muted),
                              const SizedBox(width: 4),
                              Text(
                                'إعادة',
                                style: GoogleFonts.changa(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

