import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../attendance/attendance_screen.dart';
import '../groups/group_profile_screen.dart';
import '../groups/groups_provider.dart';
import '../groups/widgets/cancel_session_sheet.dart';
import '../settings/settings_provider.dart';

enum ScheduleViewMode { daily, weekly }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with AutomaticKeepAliveClientMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  late final ScrollController _dateStripScrollController;

  // View Mode: Daily or Weekly
  ScheduleViewMode _viewMode = ScheduleViewMode.daily;

  // Filter state (null = All Groups / كل المجموعات)
  String? _selectedGroupId;
  final Set<String> _preparedGroupIdsToday = {};
  final AttendanceRepository _attendanceRepo = AttendanceRepository();

  // Realtime ticker for current active status
  Timer? _timeTicker;
  DateTime _now = DateTime.now();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _dateStripScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsProvider>().loadGroups();
      _loadPreparedStatus();
      _scrollToSelectedDay();
    });

    _timeTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timeTicker?.cancel();
    _dateStripScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPreparedStatus() async {
    try {
      final groups = context.read<GroupsProvider>().groups;
      final prepared = <String>{};
      for (final g in groups) {
        final records = await _attendanceRepo.getByGroupAndDate(g.id, _selectedDate);
        if (records.isNotEmpty) {
          prepared.add(g.id);
        }
      }
      if (mounted) {
        setState(() => _preparedGroupIdsToday.addAll(prepared));
      }
    } catch (_) {}
  }

  void _scrollToSelectedDay() {
    if (!_dateStripScrollController.hasClients) return;
    final dayIndex = _selectedDate.day - 1;
    final targetOffset = (dayIndex * 68.0) - 120.0;
    _dateStripScrollController.animateTo(
      targetOffset.clamp(0.0, _dateStripScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  String _arabicDayNameFromDate(DateTime date) {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[date.weekday - 1];
  }

  String _shortDayName(DateTime date) {
    const days = ['إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
    return days[date.weekday - 1];
  }

  Color _getGroupAssignedColor(String groupId, int index) {
    return AppColors.groupPalette[(groupId.hashCode.abs() + index) % AppColors.groupPalette.length];
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      lastDay.day,
      (i) => DateTime(month.year, month.month, i + 1),
    );
  }

  void _onMonthChanged(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
      if (_selectedDate.month != _currentMonth.month || _selectedDate.year != _currentMonth.year) {
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
      }
    });
    _loadPreparedStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDay());
  }

  void _showAllCalendarFilterModal(List<GroupModel> groups, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.filter_list_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'تصفية جدول المجموعات',
                        style: GoogleFonts.changa(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Option 1: All Calendar (كل المجموعات)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: _selectedGroupId == null
                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: _selectedGroupId == null ? 1.5 : 0.8,
                  ),
                ),
                tileColor: _selectedGroupId == null
                    ? (isDark ? AppColors.darkGreenSoft : AppColors.chipTeal)
                    : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFA)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 20),
                ),
                title: Text(
                  'كل المجموعات (All Calendar)',
                  style: GoogleFonts.changa(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkText : AppColors.ink,
                  ),
                ),
                trailing: _selectedGroupId == null
                    ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedGroupId = null);
                  Navigator.pop(ctx);
                },
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Option List: Specific Groups
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (ctx, idx) {
                    final g = groups[idx];
                    final isSelected = _selectedGroupId == g.id;
                    final groupColor = _getGroupAssignedColor(g.id, idx);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? groupColor
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: isSelected ? 1.5 : 0.8,
                        ),
                      ),
                      tileColor: isSelected
                          ? groupColor.withValues(alpha: isDark ? 0.25 : 0.1)
                          : (isDark ? AppColors.darkSurface : Colors.white),
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: groupColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        g.name,
                        style: GoogleFonts.changa(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                      subtitle: Text(
                        '${g.type.label} · ${g.days.length} مواعيد أسبوعياً',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: groupColor)
                          : null,
                      onTap: () {
                        setState(() => _selectedGroupId = g.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrintMenu(BuildContext context, List<GroupModel> groups, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('خيارات الطباعة والتصدير 🖨️', style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_view_day_rounded, color: AppColors.primary),
                title: Text('طباعة جدول اليوم المحدد (${_arabicDayNameFromDate(_selectedDate)})', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _printSchedule(groups, settings, isWeekly: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_week_rounded, color: AppColors.primary),
                title: Text('طباعة الجدول الأسبوعي الكامل (PDF)', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _printSchedule(groups, settings, isWeekly: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printSchedule(List<GroupModel> groups, SettingsProvider settings, {required bool isWeekly}) async {
    try {
      final title = isWeekly
          ? 'الجدول الأسبوعي الكامل - أ. ${settings.teacherName}'
          : 'جدول يوم ${_arabicDayNameFromDate(_selectedDate)} - أ. ${settings.teacherName}';

      final pdfBytes = await PdfGenerator.generateSchedulePdf(
        groups: groups,
        teacherName: settings.teacherName,
        teacherPhone: settings.teacherPhone,
        selectedDate: isWeekly ? null : _selectedDate,
        isWeekly: isWeekly,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إعداد الطباعة: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final groupsP = context.watch<GroupsProvider>();
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final visibleGroups = _selectedGroupId == null
        ? groupsP.groups
        : groupsP.groups.where((g) => g.id == _selectedGroupId).toList();

    // Group sessions for selected date
    final activeDayName = _arabicDayNameFromDate(_selectedDate);
    final daySessions = <Map<String, dynamic>>[];

    for (int i = 0; i < visibleGroups.length; i++) {
      final g = visibleGroups[i];
      if (g.isScheduledOn(activeDayName)) {
        final timeStr = g.timeForDay(activeDayName) ?? '';
        final isPrepared = _preparedGroupIdsToday.contains(g.id);
        daySessions.add({
          'group': g,
          'time': timeStr,
          'color': _getGroupAssignedColor(g.id, i),
          'isPrepared': isPrepared,
        });
      }
    }

    final selectedGroupName = _selectedGroupId == null
        ? 'كل المجموعات (All Calendar)'
        : groupsP.groups.firstWhere((g) => g.id == _selectedGroupId, orElse: () => groupsP.groups.first).name;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: groupsP.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () async {
                await context.read<GroupsProvider>().loadGroups();
                await _loadPreparedStatus();
              },
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. SLEEK CURVED TOP HEADER WITH VIEW SWITCHER
                  SliverToBoxAdapter(
                    child: _buildModernCurvedHeader(
                      context: context,
                      groups: groupsP.groups,
                      selectedGroupName: selectedGroupName,
                      settings: settings,
                      isDark: isDark,
                    ),
                  ),

                  // 2. VIEW MODE CONTENT (Daily Timeline or Weekly Matrix)
                  if (_viewMode == ScheduleViewMode.daily) ...[
                    // Daily Header Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateUtils.isSameDay(_selectedDate, _now)
                                      ? 'اليوم (Today)'
                                      : 'جدول يوم ${_arabicDayNameFromDate(_selectedDate)}',
                                  style: GoogleFonts.changa(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkText : AppColors.ink,
                                  ),
                                ),
                                Text(
                                  AppDateUtils.formatArabicDate(_selectedDate),
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                '${ArabicNumbers.convert(daySessions.length)} حصص',
                                style: GoogleFonts.changa(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Daily Session Cards List
                    if (daySessions.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(isDark),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final session = daySessions[index];
                              return _buildScheduleItemCard(
                                context: context,
                                session: session,
                                isDark: isDark,
                              ).animate().fadeIn(duration: 250.ms, delay: Duration(milliseconds: 40 * index)).slideY(begin: 0.08, end: 0);
                            },
                            childCount: daySessions.length,
                          ),
                        ),
                      ),
                  ] else ...[
                    // Weekly Timetable Matrix
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      sliver: SliverToBoxAdapter(
                        child: _buildWeeklyScheduleMatrix(visibleGroups, isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  // =============================================================
  // 1. SLEEK CURVED TOP HEADER WITH VIEW SWITCHER
  // =============================================================
  Widget _buildModernCurvedHeader({
    required BuildContext context,
    required List<GroupModel> groups,
    required String selectedGroupName,
    required SettingsProvider settings,
    required bool isDark,
  }) {
    final daysInMonth = _getDaysInMonth(_currentMonth);

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkHeaderGradient : AppColors.headerGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Filter / View Mode / Print Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Calendar Pill
                  Expanded(
                    child: AppScaleButton(
                      onTap: () => _showAllCalendarFilterModal(groups, isDark),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 15, color: isDark ? AppColors.darkPrimary : Colors.white),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                selectedGroupName,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.changa(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Print Schedule PDF
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.print_outlined, color: Colors.white),
                    tooltip: 'طباعة وتصدير الجدول 🖨️',
                    onPressed: () => _showPrintMenu(context, groups, settings),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Segmented Switcher: Daily (اليومي) vs. Weekly (الجدول الأسبوعي)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppScaleButton(
                        onTap: () => setState(() => _viewMode = ScheduleViewMode.daily),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == ScheduleViewMode.daily
                                ? (isDark ? AppColors.darkPrimary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_view_day_rounded,
                                size: 16,
                                color: _viewMode == ScheduleViewMode.daily
                                    ? (isDark ? AppColors.darkBg : AppColors.primary)
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'جدول اليوم (Daily)',
                                style: GoogleFonts.changa(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _viewMode == ScheduleViewMode.daily
                                      ? (isDark ? AppColors.darkBg : AppColors.primary)
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AppScaleButton(
                        onTap: () => setState(() => _viewMode = ScheduleViewMode.weekly),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _viewMode == ScheduleViewMode.weekly
                                ? (isDark ? AppColors.darkPrimary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_view_week_rounded,
                                size: 16,
                                color: _viewMode == ScheduleViewMode.weekly
                                    ? (isDark ? AppColors.darkBg : AppColors.primary)
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'الجدول الأسبوعي (Weekly)',
                                style: GoogleFonts.changa(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _viewMode == ScheduleViewMode.weekly
                                      ? (isDark ? AppColors.darkBg : AppColors.primary)
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Date Strip visible in Daily Mode
              if (_viewMode == ScheduleViewMode.daily) ...[
                const SizedBox(height: 12),
                // Month Navigation Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'ar').format(_currentMonth),
                      style: GoogleFonts.changa(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        AppScaleButton(
                          onTap: () => _onMonthChanged(1),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppScaleButton(
                          onTap: () => _onMonthChanged(-1),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Horizontal Date Strip
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    controller: _dateStripScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: daysInMonth.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final dayDate = daysInMonth[idx];
                      final isSelected = DateUtils.isSameDay(dayDate, _selectedDate);
                      final isToday = DateUtils.isSameDay(dayDate, _now);

                      return AppScaleButton(
                        onTap: () {
                          setState(() => _selectedDate = dayDate);
                          _loadPreparedStatus();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? AppColors.darkPrimary : Colors.white)
                                : (isToday ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(18),
                            border: isToday && !isSelected
                                ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5)
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _shortDayName(dayDate),
                                style: GoogleFonts.tajawal(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? (isDark ? AppColors.darkBg : AppColors.primary)
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ArabicNumbers.convert(dayDate.day),
                                style: GoogleFonts.changa(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? (isDark ? AppColors.darkBg : AppColors.primary)
                                      : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // 2. WEEKLY SCHEDULE MATRIX (Weekly View)
  // =============================================================
  Widget _buildWeeklyScheduleMatrix(List<GroupModel> groups, bool isDark) {
    const weekDays = [
      AppStrings.saturday,
      AppStrings.sunday,
      AppStrings.monday,
      AppStrings.tuesday,
      AppStrings.wednesday,
      AppStrings.thursday,
      AppStrings.friday,
    ];

    int totalWeeklySessions = 0;
    for (final d in weekDays) {
      totalWeeklySessions += groups.where((g) => g.isScheduledOn(d)).length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary Header Pill
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'إجمالي حصص الأسبوع',
                    style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${ArabicNumbers.convert(totalWeeklySessions)} حصة أسبوعياً',
                  style: GoogleFonts.changa(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Day by Day Timetable Sections
        ...weekDays.map((dayName) {
          final dayGroups = groups.where((g) => g.isScheduledOn(dayName)).toList();
          final isToday = dayName == _arabicDayNameFromDate(_now);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isToday
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : (isDark ? AppColors.darkBorder : AppColors.border),
                width: isToday ? 1.8 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Day Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isToday
                        ? (isDark ? AppColors.darkGreenSoft : AppColors.chipTeal)
                        : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFA)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.changa(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : (isDark ? AppColors.darkText : AppColors.ink),
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'اليوم 📍',
                            style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkBg : Colors.white),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        dayGroups.isEmpty ? 'يوم راحة ☕' : '${ArabicNumbers.convert(dayGroups.length)} حصص',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkMuted : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Day Sessions List
                if (dayGroups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Center(
                      child: Text(
                        'لا توجد حصص مجدولة في هذا اليوم',
                        style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: dayGroups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final g = dayGroups[idx];
                      final timeStr = g.timeForDay(dayName) ?? '';
                      final groupColor = _getGroupAssignedColor(g.id, idx);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFF9FBFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: groupColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                color: groupColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.name,
                                    style: GoogleFonts.changa(fontSize: 13.5, fontWeight: FontWeight.bold),
                                  ),
                                  if (g.subject != null && g.subject!.isNotEmpty)
                                    Text(
                                      '📖 ${g.subject!}',
                                      style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
                                    const SizedBox(width: 4),
                                    Text(
                                      ArabicNumbers.formatTime12(timeStr),
                                      style: GoogleFonts.changa(fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  g.type.label,
                                  style: GoogleFonts.tajawal(fontSize: 10.5, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // =============================================================
  // 3. SCHEDULE ITEM CARD (Daily View)
  // =============================================================
  Widget _buildScheduleItemCard({
    required BuildContext context,
    required Map<String, dynamic> session,
    required bool isDark,
  }) {
    final group = session['group'] as GroupModel;
    final timeStr = session['time'] as String;
    final groupColor = session['color'] as Color;
    final isPrepared = session['isPrepared'] as bool;
    final studentsCount = context.read<GroupsProvider>().getStudentCount(group.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrepared
              ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.6) : AppColors.green.withValues(alpha: 0.5))
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: isPrepared ? 1.4 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupProfileScreen(group: group),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: groupColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(
                          group.type == GroupType.online ? Icons.videocam_rounded : Icons.domain_rounded,
                          color: groupColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            Text(
                              '📖 ${group.subject!}',
                              style: GoogleFonts.tajawal(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            ArabicNumbers.formatTime12(timeStr),
                            style: GoogleFonts.changa(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkText : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Bottom Line Actions
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 14, color: isDark ? AppColors.darkMuted : AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${ArabicNumbers.convert(studentsCount)} طالب',
                      style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
                    ),
                    const SizedBox(width: 12),

                    Text(
                      group.type.label,
                      style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
                    ),
                    const Spacer(),

                    // Attendance button
                    AppScaleButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceScreen(
                              groupId: group.id,
                              groupName: group.name,
                            ),
                          ),
                        ).then((_) => _loadPreparedStatus());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPrepared
                              ? (isDark ? AppColors.darkGreenSoft : AppColors.greenSoft)
                              : (isDark ? AppColors.darkPrimary : AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPrepared ? Icons.check_circle_rounded : Icons.how_to_reg_rounded,
                              size: 14,
                              color: isPrepared
                                  ? (isDark ? AppColors.darkPrimary : const Color(0xFF155724))
                                  : (isDark ? AppColors.darkBg : Colors.white),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPrepared ? 'تم التحضير' : 'رصد الحضور',
                              style: GoogleFonts.changa(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPrepared
                                    ? (isDark ? AppColors.darkPrimary : const Color(0xFF155724))
                                    : (isDark ? AppColors.darkBg : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Cancel Session option
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.event_busy_rounded, color: AppColors.orange, size: 20),
                      tooltip: 'إلغاء الحصة وتنبيه الطلاب',
                      onPressed: () {
                        CancelSessionSheet.show(context, group: group);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Text('☕', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              'لا توجد حصص مجدولة في هذا اليوم',
              style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'استمتع بوقتك أو أضف موعد مجموعة جديد لهذا اليوم',
              style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

