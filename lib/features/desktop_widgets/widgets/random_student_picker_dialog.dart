import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../../../core/widgets/confetti_celebration.dart';
import '../../../data/models/student_model.dart';
import '../../groups/groups_provider.dart';
import '../../students/students_provider.dart';

/// نافذة القرعة العشوائية الذكية لاختيار طالب للإجابة أو التكريم
class RandomStudentPickerDialog extends StatefulWidget {
  final String? initialGroupId;

  const RandomStudentPickerDialog({super.key, this.initialGroupId});

  static Future<void> show(BuildContext context, {String? initialGroupId}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RandomStudentPicker',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => RandomStudentPickerDialog(initialGroupId: initialGroupId),
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
  State<RandomStudentPickerDialog> createState() => _RandomStudentPickerDialogState();
}

class _RandomStudentPickerDialogState extends State<RandomStudentPickerDialog>
    with SingleTickerProviderStateMixin {
  String? _selectedGroupId;
  StudentModel? _pickedStudent;
  bool _isSpinning = false;
  String _displayName = 'اضغط لبدء القرعة 🎲';
  Timer? _spinTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startSpin(List<StudentModel> students) {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يوجد طلاب في هذه المجموعة لإجراء القرعة', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _pickedStudent = null;
    });

    int count = 0;
    const totalTicks = 28;
    final random = Random();

    _spinTimer?.cancel();
    _spinTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      count++;
      HapticFeedback.selectionClick();
      final randomIndex = random.nextInt(students.length);
      setState(() {
        _displayName = students[randomIndex].name;
      });

      if (count >= totalTicks) {
        timer.cancel();
        final winnerIndex = random.nextInt(students.length);
        final winner = students[winnerIndex];
        HapticFeedback.heavyImpact();

        setState(() {
          _isSpinning = false;
          _pickedStudent = winner;
          _displayName = winner.name;
        });

        // Trigger celebratory confetti
        ConfettiCelebrationOverlay.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupsP = context.watch<GroupsProvider>();
    final studentsP = context.watch<StudentsProvider>();

    final allGroups = groupsP.groups;
    if (_selectedGroupId == null && allGroups.isNotEmpty) {
      _selectedGroupId = allGroups.first.id;
    }

    final availableStudents = _selectedGroupId == null
        ? studentsP.students
        : studentsP.students.where((s) => s.groupId == _selectedGroupId).toList();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 440),
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
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkOrangeSoft : AppColors.orangeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.casino_rounded, color: AppColors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'القرعة العشوائية الذكية',
                          style: GoogleFonts.changa(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkText : AppColors.ink,
                          ),
                        ),
                        Text(
                          'اختيار طالب عشوائي للإجابة والأنشطة',
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

              const SizedBox(height: 18),

              // Group Selector Dropdown
              if (allGroups.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGroupId,
                      isExpanded: true,
                      dropdownColor: Theme.of(context).cardColor,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: allGroups.map((g) {
                        return DropdownMenuItem<String>(
                          value: g.id,
                          child: Row(
                            children: [
                              const Icon(Icons.groups_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  g.name,
                                  style: GoogleFonts.changa(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkText : AppColors.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _isSpinning
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedGroupId = val;
                                  _pickedStudent = null;
                                  _displayName = 'اضغط لبدء القرعة 🎲';
                                });
                              }
                            },
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // Spin Result Box (Card with glowing animation)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: _pickedStudent != null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [const Color(0xFF103B2E), const Color(0xFF0E271F)]
                              : [const Color(0xFFE8F8F2), const Color(0xFFD3F2E5)],
                        )
                      : null,
                  color: _pickedStudent != null
                      ? null
                      : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAF9)),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _pickedStudent != null
                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: _pickedStudent != null ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    if (_pickedStudent != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🎉 الفائز بالقرعة',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkBg : Colors.white,
                          ),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 12),
                    ],

                    Text(
                      _displayName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.changa(
                        fontSize: _isSpinning ? 20 : (_pickedStudent != null ? 22 : 16),
                        fontWeight: FontWeight.bold,
                        color: _pickedStudent != null
                            ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                            : (_isSpinning
                                ? AppColors.orange
                                : (isDark ? AppColors.darkMuted : AppColors.muted)),
                      ),
                    ),

                    if (_pickedStudent != null && _pickedStudent!.phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '📞 ${ArabicNumbers.convert(_pickedStudent!.phone)}',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),
                    Text(
                      'العدد المؤهل: ${ArabicNumbers.convert(availableStudents.length)} طالب',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted.withValues(alpha: 0.7) : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: AppScaleButton(
                      onTap: _isSpinning ? null : () => _startSpin(availableStudents),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? AppColors.darkAccentGradient
                              : const LinearGradient(
                                  colors: [Color(0xFF0E8A6D), Color(0xFF14B892)],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isSpinning ? Icons.sync_rounded : Icons.casino_rounded,
                                color: isDark ? AppColors.darkBg : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isSpinning ? 'جاري السحب...' : 'سحب عشوائي 🎲',
                                style: GoogleFonts.changa(
                                  fontSize: 14,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

