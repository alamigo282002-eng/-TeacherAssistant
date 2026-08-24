import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/group_model.dart';
import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../settings/settings_provider.dart';
import '../attendance_provider.dart';
import 'attendance_bulk_view.dart';
import 'attendance_card_swipe_view.dart';
import 'attendance_quick_grid_view.dart';
import 'attendance_roll_call_view.dart';

class AttendanceBottomSheet extends StatefulWidget {
  final GroupModel? initialGroup;

  const AttendanceBottomSheet({super.key, this.initialGroup});

  static Future<bool?> show(BuildContext context, {GroupModel? group}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttendanceBottomSheet(initialGroup: group),
    );
  }

  @override
  State<AttendanceBottomSheet> createState() => _AttendanceBottomSheetState();
}

class _AttendanceBottomSheetState extends State<AttendanceBottomSheet> {
  final GroupRepository _groupRepo = GroupRepository();
  final StudentRepository _studentRepo = StudentRepository();

  List<GroupModel> _groups = [];
  Map<String, int> _studentCounts = {};
  bool _loadingGroups = true;
  GroupModel? _selectedGroup;
  String? _activeMode;
  final Map<String, TextEditingController> _recitationCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    for (final ctrl in _recitationCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final groups = await _groupRepo.getAll();
    final counts = <String, int>{};
    for (final g in groups) {
      final students = await _studentRepo.getByGroup(g.id);
      counts[g.id] = students.length;
    }

    if (mounted) {
      setState(() {
        _groups = groups;
        _studentCounts = counts;
        _loadingGroups = false;
        if (widget.initialGroup != null) {
          _selectedGroup = widget.initialGroup;
          context.read<AttendanceProvider>().loadForGroup(_selectedGroup!.id);
        }
      });
    }
  }

  void _selectGroup(GroupModel group) {
    setState(() => _selectedGroup = group);
    context.read<AttendanceProvider>().loadForGroup(group.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab Handle
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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (_selectedGroup != null && widget.initialGroup == null)
                  IconButton(
                    onPressed: () => setState(() => _selectedGroup = null),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                    tooltip: 'تغيير المجموعة',
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedGroup == null
                            ? '📋 تحضير الطلاب — اختر المجموعة'
                            : '📋 تحضير: ${_selectedGroup!.name}',
                        style: GoogleFonts.changa(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                      if (_selectedGroup?.subject != null)
                        Text(
                          '📖 ${_selectedGroup!.subject!}',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
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

          // Body: Group Picker or Student Attendance List
          Expanded(
            child: _selectedGroup == null
                ? _buildGroupPicker(isDark)
                : _buildAttendanceList(isDark),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 1: Groups List Picker
  // -------------------------------------------------------------
  Widget _buildGroupPicker(bool isDark) {
    if (_loadingGroups) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_off_rounded, size: 56, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                'لا توجد مجموعات مضافة بعد',
                style: GoogleFonts.changa(fontSize: 16, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Text(
                'يجب إضافة مجموعة أولاً لبدء التحضير',
                style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _groups.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final group = _groups[index];
        final count = _studentCounts[group.id] ?? 0;
        final firstLetter = group.name.isNotEmpty ? group.name[0] : 'م';

        return AppScaleButton(
          onTap: () => _selectGroup(group),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                // Avatar Letter
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.chipTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: GoogleFonts.changa(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Subject
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: GoogleFonts.changa(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                      if (group.subject != null && group.subject!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '📖 ${group.subject!}',
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Meta Count Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        '${ArabicNumbers.convert(count)} طالب',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.muted),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // STEP 2: Attendance Students List
  // -------------------------------------------------------------
  Widget _buildAttendanceList(bool isDark) {
    final provider = context.watch<AttendanceProvider>();
    final settingsMode = context.watch<SettingsProvider>().attendanceMode;
    final activeMode = _activeMode ?? settingsMode;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_rounded, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'لا يوجد طلاب في هذه المجموعة بعد',
              style: GoogleFonts.changa(fontSize: 15, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    final presentCount = provider.presentCount;
    final absentCount = provider.absentCount;
    final hwCount = provider.entries.where((e) => e.homeworkDone).length;

    return Column(
      children: [
        // Mode Switcher Bar
        _buildModeSelectorBar(activeMode, isDark),

        if (activeMode == 'cardSwipe')
          Expanded(
            child: AttendanceCardSwipeView(
              provider: provider,
              onSaved: () => Navigator.of(context).pop(true),
            ),
          )
        else if (activeMode == 'quickGrid')
          Expanded(
            child: AttendanceQuickGridView(
              provider: provider,
              onSaved: () => Navigator.of(context).pop(true),
            ),
          )
        else if (activeMode == 'rollCall')
          Expanded(
            child: AttendanceRollCallView(
              provider: provider,
              onSaved: () => Navigator.of(context).pop(true),
            ),
          )
        else if (activeMode == 'bulk')
          Expanded(
            child: AttendanceBulkView(
              provider: provider,
              onSaved: () => Navigator.of(context).pop(true),
            ),
          )
        else ...[
          // Classic List Mode
          // Live Summary Chips & Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
              // Present Chip
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'حاضر: ${ArabicNumbers.convert(presentCount)}',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF155724),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Absent Chip
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'غائب: ${ArabicNumbers.convert(absentCount)}',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF721C24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Homework Chip
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'الواجب: ${ArabicNumbers.convert(hwCount)}',
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF856404),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Students Interactive List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: provider.entries.length,
            itemBuilder: (context, index) {
              final entry = provider.entries[index];
              final isPresent = entry.status == AttendanceStatus.present;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isPresent
                      ? (isDark ? AppColors.darkSurface : Colors.white)
                      : (isDark ? const Color(0xFF2A1515) : const Color(0xFFFFF5F5)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPresent
                        ? (isDark ? AppColors.darkBorder : AppColors.border)
                        : AppColors.red.withValues(alpha: 0.5),
                    width: isPresent ? 0.8 : 1.4,
                  ),
                ),
                child: Row(
                  children: [
                    // Status Toggle Button
                    InkWell(
                      onTap: () => provider.toggleStatus(index),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPresent ? AppColors.green : AppColors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPresent ? 'حاضر' : 'غائب',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Student Name & points
                    Expanded(
                      child: InkWell(
                        onTap: () => provider.toggleStatus(index),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.student.name,
                              style: GoogleFonts.changa(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkText : AppColors.ink,
                              ),
                            ),
                            Text(
                              '${ArabicNumbers.convert(entry.student.points)} ⭐',
                              style: GoogleFonts.tajawal(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Live +1 Star button
                    AppScaleButton(
                      onTap: () async {
                        final newPts = await provider.addLiveParticipationPoint(index);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🌟 +١ نقطة تفاعل لـ ${entry.student.name} (الإجمالي: ${ArabicNumbers.convert(newPts)})', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                              backgroundColor: AppColors.orange,
                              duration: const Duration(milliseconds: 1200),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 2),
                            Text('+١', style: GoogleFonts.changa(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF856404))),
                          ],
                        ),
                      ),
                    ),

                    // Homework Slider / Pill Switch (ONLY IF PRESENT)
                    if (isPresent) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 48,
                        child: TextFormField(
                          controller: _recitationCtrls.putIfAbsent(
                            entry.student.id,
                            () => TextEditingController(
                              text: entry.recitationPoints != null ? (entry.recitationPoints! % 1 == 0 ? entry.recitationPoints!.toInt().toString() : entry.recitationPoints!.toString()) : '',
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.primary),
                          decoration: InputDecoration(
                            hintText: 'تسميع/10',
                            hintStyle: GoogleFonts.tajawal(fontSize: 9),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            final points = double.tryParse(val);
                            if (points != null && points >= 0 && points <= 10) {
                              provider.setRecitationPoints(index, points);
                            } else if (val.isEmpty) {
                              provider.setRecitationPoints(index, null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => provider.toggleHomework(index),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: entry.homeworkDone
                                ? AppColors.primary
                                : (isDark ? AppColors.darkCard : const Color(0xFFE9ECEF)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.homeworkDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 14,
                                color: entry.homeworkDone ? Colors.white : AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.homeworkDone ? 'حل الواجب' : 'الواجب',
                                style: GoogleFonts.tajawal(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: entry.homeworkDone ? Colors.white : AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Save Bottom Action
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 0.8,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: AppScaleButton(
                onTap: () async {
                  final ok = await provider.save();
                  if (mounted) {
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                '✅ تم حفظ التحضير',
                                style: GoogleFonts.tajawal(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      Navigator.of(context).pop(true);
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: provider.saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'حفظ التحضير (✅ تم حفظ التحضير)',
                            style: GoogleFonts.changa(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ],
    );
  }

  Widget _buildModeSelectorBar(String currentMode, bool isDark) {
    final modes = [
      {'key': 'list', 'label': 'قائمة 📋'},
      {'key': 'cardSwipe', 'label': 'سحب 🎴'},
      {'key': 'quickGrid', 'label': 'شبكة 🟢'},
      {'key': 'rollCall', 'label': 'مناداة 📢'},
      {'key': 'bulk', 'label': 'جماعي ⚡'},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final m = modes[i];
          final isSelected = currentMode == m['key'];
          return AppScaleButton(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeMode = m['key']);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : (isDark ? AppColors.darkSurface : const Color(0xFFEDF4F1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  m['label']!,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isDark ? AppColors.darkBg : Colors.white)
                        : (isDark ? AppColors.darkText : AppColors.ink),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

