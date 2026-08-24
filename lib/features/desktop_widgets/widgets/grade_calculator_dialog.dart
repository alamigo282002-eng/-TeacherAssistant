import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/app_scale_button.dart';

/// حاسبة الدرجات والنسب والتقديرات الفورية
class GradeCalculatorDialog extends StatefulWidget {
  const GradeCalculatorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'GradeCalculator',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const GradeCalculatorDialog(),
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
  State<GradeCalculatorDialog> createState() => _GradeCalculatorDialogState();
}

class _GradeCalculatorDialogState extends State<GradeCalculatorDialog> {
  final TextEditingController _scoreController = TextEditingController(text: '18');
  final TextEditingController _totalController = TextEditingController(text: '20');

  double _percentage = 90.0;
  String _gradeText = 'ممتاز 🌟';
  Color _gradeColor = AppColors.green;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _calculate() {
    final score = double.tryParse(_scoreController.text.replaceAll('،', '.').replaceAll(',', '.')) ?? 0;
    final total = double.tryParse(_totalController.text.replaceAll('،', '.').replaceAll(',', '.')) ?? 0;

    if (total <= 0) {
      setState(() {
        _percentage = 0.0;
        _gradeText = 'غير محدد';
        _gradeColor = AppColors.muted;
      });
      return;
    }

    final p = (score / total) * 100;
    String gText;
    Color gColor;

    if (p >= 85) {
      gText = 'ممتاز 🌟';
      gColor = const Color(0xFF10B981);
    } else if (p >= 75) {
      gText = 'جيد جداً ✨';
      gColor = const Color(0xFF0E8A6D);
    } else if (p >= 65) {
      gText = 'جيد 👍';
      gColor = const Color(0xFF3B82F6);
    } else if (p >= 50) {
      gText = 'مقبول ⚠️';
      gColor = const Color(0xFFD97706);
    } else {
      gText = 'يحتاج لمتابعة ❌';
      gColor = const Color(0xFFD64545);
    }

    setState(() {
      _percentage = p.clamp(0.0, 100.0);
      _gradeText = gText;
      _gradeColor = gColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      color: isDark ? AppColors.darkOrangeSoft : AppColors.orangeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calculate_rounded, color: AppColors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حاسبة الدرجات والنسب',
                          style: GoogleFonts.changa(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.ink,
                          ),
                        ),
                        Text(
                          'حساب النسب المئوية والتقديرات فورياً',
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

              // Inputs Row (Score & Total)
              Row(
                children: [
                  // Student Score
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'درجة الطالب',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _scoreController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          onChanged: (_) => _calculate(),
                          style: GoogleFonts.changa(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Divider Slash
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      '/',
                      style: GoogleFonts.changa(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Total Exam Score
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الدرجة الكلية',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _totalController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          onChanged: (_) => _calculate(),
                          style: GoogleFonts.changa(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.ink,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            filled: true,
                            fillColor: isDark ? AppColors.darkSurface : AppColors.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Result Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF6FAF8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _gradeColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Percentage
                    Column(
                      children: [
                        Text(
                          'النسبة المئوية',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: isDark ? AppColors.darkMuted : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ArabicNumbers.convert(_percentage.toStringAsFixed(1))}%',
                          style: GoogleFonts.changa(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _gradeColor,
                          ),
                        ),
                      ],
                    ),

                    Container(width: 1, height: 40, color: isDark ? AppColors.darkBorder : AppColors.border),

                    // Grade Appreciation
                    Column(
                      children: [
                        Text(
                          'التقدير العام',
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            color: isDark ? AppColors.darkMuted : AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _gradeText,
                          style: GoogleFonts.changa(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _gradeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Close / Done Button
              AppScaleButton(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'تم',
                      style: GoogleFonts.changa(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkBg : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

