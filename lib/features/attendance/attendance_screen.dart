import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../core/widgets/pdf_viewer_screen.dart';
import '../attendance/attendance_provider.dart';
import '../groups/groups_provider.dart';

import '../settings/settings_provider.dart';
import 'widgets/attendance_bulk_view.dart';
import 'widgets/attendance_card_swipe_view.dart';
import 'widgets/attendance_quick_grid_view.dart';
import 'widgets/attendance_roll_call_view.dart';

class AttendanceScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const AttendanceScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Map<int, bool> _showNoteMap = {};
  String? _activeMode;
  String _searchQuery = '';
  late String _selectedGroupId;
  late String _selectedGroupName;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.groupId;
    _selectedGroupName = widget.groupName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().loadForGroup(_selectedGroupId);
    });
  }

  void _onGroupChanged(String newGroupId, String newGroupName) {
    if (_selectedGroupId != newGroupId) {
      setState(() {
        _selectedGroupId = newGroupId;
        _selectedGroupName = newGroupName;
        _searchQuery = '';
      });
      context.read<AttendanceProvider>().loadForGroup(newGroupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final groupsP = context.watch<GroupsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final settingsMode = context.watch<SettingsProvider>().attendanceMode;
    final activeMode = _activeMode ?? settingsMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تحضير الطلاب',
              style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              _selectedGroupName,
              style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'تقرير المجموعة PDF',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final group = groupsP.groups.firstWhere((g) => g.id == _selectedGroupId);
                final students = provider.entries.map((e) => e.student).toList();

                final file = await PdfGenerator.generateGroupReport(group, students);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      file: file,
                      title: 'تقرير مجموعة $_selectedGroupName',
                    ),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء استخراج التقرير: $e', style: GoogleFonts.tajawal())),
                  );
                }
              }
            },
          ),
          TextButton.icon(
            onPressed: provider.markAllPresent,
            icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
            label: Text('الكل حاضر', style: GoogleFonts.changa(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Group Selector Strip
          if (groupsP.groups.length > 1)
            Container(
              height: 42,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: groupsP.groups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final g = groupsP.groups[i];
                  final isSelected = g.id == _selectedGroupId;
                  return AppScaleButton(
                    onTap: () => _onGroupChanged(g.id, g.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (Theme.of(context).cardColor),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        g.name,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.ink),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 2. Attendance Date Bar with Schedule Validation
          _buildAttendanceDateBar(context, provider, groupsP, isDark),

          // 2. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              textDirection: TextDirection.rtl,
              style: GoogleFonts.tajawal(fontSize: 13),
              decoration: InputDecoration(
                hintText: '🔍 ابحث عن طالب بالاسم أو الرقم...',
                hintStyle: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // 3. Mode selector
          _buildModeSelectorBar(activeMode, isDark),

          // 4. Content
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : provider.entries.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد طلاب في هذه المجموعة',
                          style: GoogleFonts.changa(fontSize: 16, color: AppColors.muted),
                        ),
                      )
                    : activeMode == 'cardSwipe'
                        ? AttendanceCardSwipeView(
                            provider: provider,
                            onSaved: () => Navigator.of(context).pop(),
                          )
                        : activeMode == 'quickGrid'
                            ? AttendanceQuickGridView(
                                provider: provider,
                                onSaved: () => Navigator.of(context).pop(),
                              )
                            : activeMode == 'rollCall'
                                ? AttendanceRollCallView(
                                    provider: provider,
                                    onSaved: () => Navigator.of(context).pop(),
                                  )
                                : activeMode == 'bulk'
                                    ? AttendanceBulkView(
                                        provider: provider,
                                        onSaved: () => Navigator.of(context).pop(),
                                      )
                                    : _buildListMode(provider, isDark),
          ),
        ],
      ),
    );
  }

  String _arabicDayName(DateTime date) {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[date.weekday - 1];
  }

  Widget _buildAttendanceDateBar(
    BuildContext context,
    AttendanceProvider provider,
    GroupsProvider groupsP,
    bool isDark,
  ) {
    final activeDate = provider.date;
    final activeDay = _arabicDayName(activeDate);
    final group = groupsP.groups.where((g) => g.id == _selectedGroupId).firstOrNull;
    final isScheduled = group != null && group.isScheduledOn(activeDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              // Date picker button
              Expanded(
                child: AppScaleButton(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: activeDate.isAfter(DateTime.now()) ? DateTime.now() : activeDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(), // Prevents future dates!
                    );
                    if (picked != null) {
                      provider.loadForGroup(_selectedGroupId, date: picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'تاريخ التحضير: $activeDay (${DateFormat('yyyy/MM/dd').format(activeDate)})',
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkText : AppColors.ink,
                            ),
                          ),
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (group != null && !isScheduled) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'المجموعة غير مجدولة رسمياً في يوم ($activeDay) · سيتم رصدها كحصة إضافية/تعويضية',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListMode(AttendanceProvider provider, bool isDark) {
    final filteredEntries = provider.entries.asMap().entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      final student = entry.value.student;
      return student.name.toLowerCase().contains(_searchQuery) ||
          student.phone.contains(_searchQuery) ||
          student.parentPhone.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        _buildSummaryBar(provider, isDark),
        Expanded(
          child: filteredEntries.isEmpty
              ? Center(
                  child: Text(
                    'لا يوجد طلاب مطابقين للبحث',
                    style: GoogleFonts.tajawal(fontSize: 14, color: AppColors.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEntries.length,
                  itemBuilder: (ctx, i) {
                    final originalIndex = filteredEntries[i].key;
                    return _buildStudentRow(ctx, provider, originalIndex, isDark);
                  },
                ),
        ),
        _buildSaveButton(provider),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

  Widget _buildSummaryBar(AttendanceProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          _summaryItem(ArabicNumbers.convert(provider.presentCount), 'حاضر', AppColors.green, AppColors.greenSoft),
          const SizedBox(width: 8),
          _summaryItem(ArabicNumbers.convert(provider.absentCount), 'غائب', AppColors.red, AppColors.redSoft),
          const SizedBox(width: 8),
          _summaryItem(ArabicNumbers.convert(provider.excusedCount), 'تخطي', const Color(0xFFD97706), const Color(0xFFFEF3C7)),
          const Spacer(),
          Text(
            '⭐ نقطة للحضور والواجب',
            style: GoogleFonts.tajawal(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color, Color softColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.changa(fontWeight: FontWeight.bold, color: color, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(BuildContext ctx, AttendanceProvider provider, int i, bool isDark) {
    final entry = provider.entries[i];
    final isPresent = entry.status == AttendanceStatus.present;
    final isAbsent = entry.status == AttendanceStatus.absent;
    final isSkipped = entry.status == AttendanceStatus.excused;
    final showNote = _showNoteMap[i] ?? (entry.note.isNotEmpty);

    Color cardBg;
    Color borderColor;
    if (isPresent) {
      cardBg = Theme.of(context).cardColor;
      borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    } else if (isAbsent) {
      cardBg = isDark ? const Color(0xFF2A1515) : const Color(0xFFFFF7F7);
      borderColor = AppColors.red.withValues(alpha: 0.4);
    } else {
      cardBg = isDark ? const Color(0xFF2A2415) : const Color(0xFFFFFDF5);
      borderColor = const Color(0xFFD97706).withValues(alpha: 0.4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top line: Name + Points + Note icon
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.student.name,
                            style: GoogleFonts.changa(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: isDark ? AppColors.darkText : AppColors.ink,
                            ),
                          ),
                          Text(
                            '${ArabicNumbers.convert(entry.student.points)} نقطة ⭐️ ${entry.student.phone.isNotEmpty ? "· ${entry.student.phone}" : ""}',
                            style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                    // Live In-Class Participation Point Button (+1 ⭐️)
                    AppScaleButton(
                      onTap: () async {
                        final newPoints = await provider.addLiveParticipationPoint(i);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                '🌟 تم إضافة نقطة مشاركة لـ ${entry.student.name}! الإجمالي: ${ArabicNumbers.convert(newPoints)}',
                                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: AppColors.orange,
                              duration: const Duration(milliseconds: 1400),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orangeSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⭐️', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 3),
                            Text(
                              '+١ تفاعل',
                              style: GoogleFonts.tajawal(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF856404),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Note Toggle Icon
                    IconButton(
                      icon: Icon(
                        entry.note.isNotEmpty ? Icons.sticky_note_2_rounded : Icons.note_add_outlined,
                        color: entry.note.isNotEmpty ? AppColors.primary : AppColors.muted,
                        size: 20,
                      ),
                      tooltip: 'ملاحظة للحصة',
                      onPressed: () {
                        setState(() {
                          _showNoteMap[i] = !showNote;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 3 Status Action Buttons: حاضر | غائب | تخطي
                Row(
                  children: [
                    // حاضر
                    Expanded(
                      child: InkWell(
                        onTap: () => provider.setStatus(i, AttendanceStatus.present),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: isPresent ? AppColors.green : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isPresent ? AppColors.green : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: isPresent ? Colors.white : AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  'حاضر',
                                  style: GoogleFonts.changa(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isPresent ? Colors.white : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // غائب
                    Expanded(
                      child: InkWell(
                        onTap: () => provider.setStatus(i, AttendanceStatus.absent),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: isAbsent ? AppColors.red : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isAbsent ? AppColors.red : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cancel_rounded, size: 14, color: isAbsent ? Colors.white : AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  'غائب',
                                  style: GoogleFonts.changa(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isAbsent ? Colors.white : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // تخطي
                    Expanded(
                      child: InkWell(
                        onTap: () => provider.setStatus(i, AttendanceStatus.excused),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: isSkipped ? const Color(0xFFD97706) : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSkipped ? const Color(0xFFD97706) : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fast_forward_rounded, size: 14, color: isSkipped ? Colors.white : AppColors.muted),
                                const SizedBox(width: 4),
                                Text(
                                  'تخطي',
                                  style: GoogleFonts.changa(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSkipped ? Colors.white : AppColors.muted,
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

          // Homework Interactive Slider (ONLY shown when student is PRESENT)
          if (isPresent) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'الواجب المنزلي:',
                    style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),

                  // Interactive Slider / Switch for Homework
                  InkWell(
                    onTap: () => provider.toggleHomework(i),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.homeworkDone ? AppColors.primary : (isDark ? AppColors.darkSurface : const Color(0xFFE9ECEF)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.homeworkDone ? Icons.check_circle_rounded : Icons.cancel_outlined,
                            size: 16,
                            color: entry.homeworkDone ? Colors.white : AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.homeworkDone ? 'حل الواجب (+١ ⭐)' : 'لم يحل الواجب',
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: entry.homeworkDone ? Colors.white : AppColors.muted,
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

          // Note Input Box (Expandable)
          if (showNote) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: TextField(
                onChanged: (v) => provider.setNote(i, v),
                controller: TextEditingController(text: entry.note)
                  ..selection = TextSelection.collapsed(offset: entry.note.length),
                textDirection: TextDirection.rtl,
                style: GoogleFonts.tajawal(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظة خاصة بالحصة (مثال: نسي الكشكول / شارك بامتياز)...',
                  hintStyle: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(AttendanceProvider provider) {
    final isToday = DateUtils.isSameDay(provider.date, DateTime.now());
    final dateStr = DateFormat('yyyy/MM/dd').format(provider.date);
    final dayName = _arabicDayName(provider.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: isToday ? 'حفظ التحضير ومنح النقاط' : 'حفظ تحضير يوم $dayName ($dateStr)',
          width: double.infinity,
          color: isToday ? AppColors.primary : const Color(0xFFD97706),
          loading: provider.saving,
          icon: isToday ? Icons.save_outlined : Icons.history_edu_rounded,
          onPressed: () async {
            final success = await provider.save();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? '✅ تم حفظ التحضير وتحديث النقاط بنجاح' : '❌ حدث خطأ أثناء الحفظ',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: success ? AppColors.green : AppColors.red,
                ),
              );
              if (success) Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}

