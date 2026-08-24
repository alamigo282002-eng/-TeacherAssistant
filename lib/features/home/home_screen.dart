import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/hijri_helper.dart';
import '../../core/widgets/animated_counter_text.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../core/widgets/confetti_celebration.dart';
import '../../core/widgets/dot_grid_pattern.dart';
import '../../data/models/group_model.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/note_repository.dart';
import '../attendance/attendance_screen.dart';
import '../desktop_widgets/widgets/random_student_picker_dialog.dart';
import '../exams/add_edit_exam_screen.dart';
import '../notes/notes_screen.dart';
import '../reports/alerts_provider.dart';
import '../reports/alerts_screen.dart';
import '../settings/settings_provider.dart';
import '../students/add_edit_student_screen.dart';
import 'home_provider.dart';
import 'widgets/absentees_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  Timer? _noteDebounce;
  late AnimationController _pulseController;
  bool _celebratedToday = false;
  int _activeSessionIndex = 0;
  bool _showAllTodaysGroups = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHome();
    });
  }

  @override
  void dispose() {
    _noteDebounce?.cancel();
    _noteController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadHome() {
    final homeProvider = context.read<HomeProvider>();
    final settings = context.read<SettingsProvider>();
    context.read<AlertsProvider>().refreshAlerts(settings: settings);
    homeProvider.loadData().then((_) {
      if (mounted) {
        if (_noteController.text.isEmpty) {
          _noteController.text = homeProvider.todayNote;
        }
        if (homeProvider.todaysGroups.isNotEmpty &&
            homeProvider.remainingPrepCount == 0 &&
            !_celebratedToday) {
          _celebratedToday = true;
          ConfettiCelebrationOverlay.show(context);
        }
      }
    });
  }

  void _onNoteChanged(String val) {
    _noteDebounce?.cancel();
    _noteDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        context.read<HomeProvider>().saveTodayNote(val);
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) return 'صباح الخير ☀️';
    if (hour >= 12 && hour < 17) return 'مساء الخير ☀️';
    return 'مساء الخير 🌙';
  }

  void _showSessionReminderDialog(BuildContext context, GroupModel group) {
    final contentCtrl = TextEditingController(text: 'تذكير لحصة ${group.name}');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.add_alert_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('إضافة تنبيه للحصة', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'مجموعة: ${group.name}',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'اكتب نص التذكير أو الملاحظة الخاصة بهذه الحصة...',
                labelText: 'نص التنبيه',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('حفظ التنبيه'),
            onPressed: () async {
              if (contentCtrl.text.trim().isNotEmpty) {
                final note = NoteModel(
                  id: const Uuid().v4(),
                  type: 'group',
                  targetId: group.id,
                  content: contentCtrl.text.trim(),
                  reminderEnabled: true,
                  reminderTime: DateTime.now().add(const Duration(minutes: 30)),
                  createdAt: DateTime.now(),
                );
                await NoteRepository().insert(note);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔔 تم حفظ التنبيه بنجاح لمجموعة ${group.name}', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeP = context.watch<HomeProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => _loadHome(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCompactHeaderSection(context, homeP, settings, isDark),

              SizedBox(height: settings.homeDesignStyle == 'classic' ? 46 : 90),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (homeP.activeSessions.isNotEmpty) ...[
                      _buildActiveSessionsSection(context, homeP, isDark),
                      const SizedBox(height: 16),
                    ],

                    _buildTodaysGroupsSection(homeP, isDark),

                    const SizedBox(height: 14),

                    _buildTodayNoteCard(isDark),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeaderSection(
    BuildContext context,
    HomeProvider homeP,
    SettingsProvider settings,
    bool isDark,
  ) {
    final teacherName = settings.teacherName.startsWith('أ.')
        ? settings.teacherName
        : 'أ. ${settings.teacherName}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        DotGridSurface(
          gradient: isDark ? AppColors.darkHeaderGradient : AppColors.headerGradient,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 68),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Greeting and Live Clock
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: GoogleFonts.tajawal(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '·',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _LiveClockWidget(
                                    dateFormatType: settings.dateFormatType,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              teacherName,
                              style: GoogleFonts.changa(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Notification Bell Button (Top Left in RTL)
                      AppScaleButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AlertsScreen()),
                          );
                        },
                        child: Consumer<AlertsProvider>(
                          builder: (ctx, alertsP, _) {
                            final count = alertsP.upcomingCount;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                if (count > 0)
                                  Positioned(
                                    top: -4,
                                    left: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                      child: Text(
                                        ArabicNumbers.convert(count),
                                        style: GoogleFonts.tajawal(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: settings.homeDesignStyle == 'classic' ? -32 : -76,
          child: settings.homeDesignStyle == 'classic'
              ? _buildClassicStatsRow(homeP, isDark)
              : _buildModernStatsAndNextGroupRow(context, homeP, isDark),
        ),
      ],
    );
  }

  Widget _buildClassicStatsRow(HomeProvider homeP, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'إجمالي الطلاب',
            count: homeP.stats?.totalStudents ?? 0,
            icon: Icons.people_alt_rounded,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            softColor: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
            isDark: isDark,
            onTap: () => widget.onNavigateTab?.call(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'مجموعات اليوم',
            count: homeP.todaysGroups.length,
            icon: Icons.calendar_today_rounded,
            color: isDark ? AppColors.darkOrange : AppColors.orange,
            softColor: isDark ? AppColors.darkOrangeSoft : AppColors.orangeSoft,
            isDark: isDark,
            onTap: () {
              if (homeP.todaysGroups.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('لا توجد حصص مجدولة اليوم', style: GoogleFonts.tajawal()),
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
                  ),
                );
              } else {
                widget.onNavigateTab?.call(4);
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'غائبون اليوم',
            count: homeP.stats?.absentToday ?? 0,
            icon: Icons.person_off_rounded,
            color: isDark ? AppColors.darkRed : AppColors.red,
            softColor: isDark ? AppColors.darkRedSoft : AppColors.redSoft,
            isDark: isDark,
            onTap: () => AbsenteesBottomSheet.show(context).then((_) => _loadHome()),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 100.ms).slideY(begin: 0.12, end: 0);
  }

  Widget _buildModernStatsAndNextGroupRow(BuildContext context, HomeProvider homeP, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Left Side: 2 Horizontal Rectangular Student Widgets
        Expanded(
          flex: 5,
          child: Column(
            children: [
              // Rect 1: Total Students
              AppScaleButton(
                onTap: () => widget.onNavigateTab?.call(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.people_alt_rounded,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إجمالي الطلاب',
                              style: GoogleFonts.tajawal(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkMuted : AppColors.muted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ArabicNumbers.formatStudentsCount(homeP.stats?.totalStudents ?? 0),
                              style: GoogleFonts.changa(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkText : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Rect 2: Absent Today
              AppScaleButton(
                onTap: () => AbsenteesBottomSheet.show(context).then((_) => _loadHome()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (homeP.stats?.absentToday ?? 0) > 0
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ((homeP.stats?.absentToday ?? 0) > 0 ? AppColors.red : AppColors.primary).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_off_rounded,
                          color: (homeP.stats?.absentToday ?? 0) > 0 ? AppColors.red : (isDark ? AppColors.darkPrimary : AppColors.primary),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'غائبون اليوم',
                              style: GoogleFonts.tajawal(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkMuted : AppColors.muted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ArabicNumbers.formatStudentsCount(homeP.stats?.absentToday ?? 0),
                              style: GoogleFonts.changa(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: (homeP.stats?.absentToday ?? 0) > 0 ? AppColors.red : (isDark ? AppColors.darkText : AppColors.ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // 2. Right Side: Multi-Slide Smart Gradient Carousel Card
        Expanded(
          flex: 6,
          child: _HomeSmartGradientCarouselCard(
            homeP: homeP,
            isDark: isDark,
            noteController: _noteController,
            onRefreshHome: _loadHome,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 100.ms).slideY(begin: 0.12, end: 0);
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color softColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AppScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark ? color.withValues(alpha: 0.2) : softColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 4),
            AnimatedCounterText(
              count: count,
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.ink,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionsSection(BuildContext context, HomeProvider homeP, bool isDark) {
    final activeSessions = homeP.activeSessions;

    if (activeSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_activeSessionIndex >= activeSessions.length) {
      _activeSessionIndex = 0;
    }

    final currentSession = activeSessions[_activeSessionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeSessions.length > 1) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.layers_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'الحصص الجارية بالتزامن (${activeSessions.length})',
                    style: GoogleFonts.changa(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'اختر الحصة للتحكم',
                style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activeSessions.indexed.map((entry) {
                final idx = entry.$1;
                final sess = entry.$2;
                final isSelected = idx == _activeSessionIndex;

                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AppScaleButton(
                    onTap: () => setState(() => _activeSessionIndex = idx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                            : (Theme.of(context).cardColor),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : (isDark ? AppColors.darkBorder : AppColors.border),
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            sess.isRunningNow ? Icons.play_circle_filled_rounded : Icons.schedule_rounded,
                            size: 14,
                            color: isSelected ? (isDark ? AppColors.darkBg : Colors.white) : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sess.group.name,
                            style: GoogleFonts.changa(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? (isDark ? AppColors.darkBg : Colors.white) : (isDark ? AppColors.darkText : AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _buildActiveSessionCard(context, currentSession, isDark),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 150.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildActiveSessionCard(
    BuildContext context,
    ActiveSessionInfo session,
    bool isDark,
  ) {
    final group = session.group;
    final isRunning = session.isRunningNow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRunning
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: isRunning ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isRunning ? AppColors.primary : Colors.black)
                .withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isRunning ? AppColors.green : AppColors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isRunning ? AppColors.green : AppColors.orange).withValues(
                            alpha: 0.3 + (_pulseController.value * 0.5),
                          ),
                          blurRadius: 4 + (_pulseController.value * 6),
                          spreadRadius: _pulseController.value * 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),

              Text(
                isRunning ? 'الحصة الجارية الآن 🟢' : 'الحصة القادمة ⏳',
                style: GoogleFonts.changa(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isRunning
                      ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                      : (isDark ? AppColors.darkOrange : AppColors.orange),
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${session.dayName} · ${ArabicNumbers.formatTime12(session.time)}',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              AppScaleButton(
                onTap: () => _showSessionReminderDialog(context, group),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2E2616) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.notification_add_rounded, size: 17, color: AppColors.orange),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Group name with optional number badge
          _buildGroupNameWithBadge(group.name, isDark),
          if (group.subject != null && group.subject!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '📖 المادة: ${group.subject!}',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                group.type == GroupType.online ? Icons.videocam_rounded : Icons.location_on_rounded,
                size: 15,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                group.type.label,
                style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
              ),
              const SizedBox(width: 14),

              Icon(Icons.people_alt_rounded, size: 15, color: isDark ? AppColors.darkMuted : AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '${ArabicNumbers.convert(session.studentCount)} طالب',
                style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Primary Action: التحضير (most used daily)
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
              ).then((_) => _loadHome());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_reg_rounded, size: 20, color: isDark ? AppColors.darkBg : Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'التحضير',
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

          const SizedBox(height: 10),

          // Secondary Actions Row (smaller icons)
          Row(
            children: [
              Expanded(
                child: _buildSecondaryActionBtn(
                  icon: Icons.quiz_rounded,
                  label: 'امتحان',
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditExamScreen(preselectedGroupId: group.id),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryActionBtn(
                  icon: Icons.casino_rounded,
                  label: 'قرعة',
                  color: AppColors.orange,
                  isDark: isDark,
                  onTap: () {
                    RandomStudentPickerDialog.show(context, initialGroupId: group.id);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryActionBtn(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'طالب +',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditStudentScreen(preselectedGroupId: group.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Extracts number in parentheses from group name and shows it as a badge
  /// e.g. "رياضيات - ثالث إعدادي - سنتر النور (15)" → name: "رياضيات - ثالث إعدادي - سنتر النور" + badge: "15"
  Widget _buildGroupNameWithBadge(String fullName, bool isDark) {
    final match = RegExp(r'\((\d+)\)\s*$').firstMatch(fullName);
    if (match != null) {
      final badgeNumber = match.group(1)!;
      final cleanName = fullName.substring(0, match.start).trim();
      return Row(
        children: [
          Flexible(
            child: Text(
              cleanName,
              style: GoogleFonts.changa(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ArabicNumbers.convert(badgeNumber),
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
              ),
            ),
          ),
        ],
      );
    }

    // No number in parentheses - show name as-is
    return Text(
      fullName,
      style: GoogleFonts.changa(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkText : AppColors.ink,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSecondaryActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AppScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.tajawal(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysGroupsSection(HomeProvider homeP, bool isDark) {
    final groups = homeP.todaysGroups;
    final total = groups.length;
    final remaining = homeP.remainingPrepCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'مجموعات اليوم',
              style: GoogleFonts.changa(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkText : AppColors.ink,
              ),
            ),
            const SizedBox(width: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ArabicNumbers.convert(total),
                style: GoogleFonts.changa(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
                ),
              ),
            ),

            const Spacer(),

            if (total > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: remaining == 0
                      ? (isDark ? AppColors.darkGreenSoft : AppColors.greenSoft)
                      : (isDark ? AppColors.darkOrangeSoft : AppColors.orangeSoft),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  remaining == 0 ? '🎉 اكتمل التحضير' : 'متبقي ${ArabicNumbers.convert(remaining)}',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: remaining == 0
                        ? (isDark ? AppColors.darkPrimary : const Color(0xFF155724))
                        : (isDark ? AppColors.darkOrange : const Color(0xFF856404)),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Text('☕', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'لا توجد حصص مجدولة لهذا اليوم',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (_showAllTodaysGroups || groups.length <= 2) ? groups.length : 2,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final group = groups[index];
              final isPrepared = homeP.preparedGroupIds.contains(group.id);
              final isNext = homeP.nextSession?.group.id == group.id;
              final studentCount = homeP.groupStudentCounts[group.id] ?? 0;
              final todayName = AppDateUtils.todayArabicDayName();
              final timeStr = group.timeForDay(todayName) ?? '';

              return _buildGroupTodayCard(
                group: group,
                isPrepared: isPrepared,
                isNext: isNext,
                studentCount: studentCount,
                timeStr: timeStr,
                isDark: isDark,
              ).animate().fadeIn(duration: 300.ms, delay: Duration(milliseconds: 40 * index)).slideY(begin: 0.08, end: 0);
            },
          ),
          if (groups.length > 2) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showAllTodaysGroups = !_showAllTodaysGroups),
                icon: Icon(
                  _showAllTodaysGroups ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
                label: Text(
                  _showAllTodaysGroups
                      ? 'عرض أقل ⌃'
                      : 'عرض باقي مجموعات اليوم (${ArabicNumbers.convert(groups.length - 2)}) ⌵',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildGroupTodayCard({
    required GroupModel group,
    required bool isPrepared,
    required bool isNext,
    required int studentCount,
    required String timeStr,
    required bool isDark,
  }) {
    final firstLetter = group.name.isNotEmpty ? group.name[0] : 'م';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNext
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isPrepared
                  ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.5) : AppColors.green.withValues(alpha: 0.4))
                  : (isDark ? AppColors.darkBorder : AppColors.border)),
          width: isNext ? 1.8 : (isPrepared ? 1.2 : 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: isNext
                ? (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: isNext ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isNext) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '⏳ الحصة القادمة تالياً',
                        style: GoogleFonts.changa(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    firstLetter,
                    style: GoogleFonts.changa(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.changa(
                        fontSize: 14.5,
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
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF0F4F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  group.type.label,
                  style: GoogleFonts.tajawal(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (timeStr.isNotEmpty) ...[
                Icon(Icons.access_time_rounded, size: 14, color: isDark ? AppColors.darkMuted : AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  ArabicNumbers.formatTime12(timeStr),
                  style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
                ),
                const SizedBox(width: 10),
              ],
              Icon(Icons.people_alt_rounded, size: 14, color: isDark ? AppColors.darkMuted : AppColors.muted),
              const SizedBox(width: 4),
              Text(
                '${ArabicNumbers.convert(studentCount)} طالب',
                style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
              ),
              const Spacer(),
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
                  ).then((_) => _loadHome());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPrepared
                        ? (isDark ? AppColors.darkGreenSoft : AppColors.greenSoft)
                        : (isDark ? AppColors.darkPrimary : AppColors.primary),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPrepared
                          ? (isDark ? AppColors.darkPrimary : AppColors.green)
                          : (isDark ? AppColors.darkPrimary : AppColors.primary),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPrepared ? Icons.check_circle_rounded : Icons.how_to_reg_rounded,
                        size: 13,
                        color: isPrepared
                            ? (isDark ? AppColors.darkPrimary : const Color(0xFF155724))
                            : (isDark ? AppColors.darkBg : Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPrepared ? 'تم التحضير' : 'تحضير الحصة',
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
            ],
          ),
        ],
      ),
    );
  }




  // -------------------------------------------------------------
  // 4. "📌 ملاحظة اليوم" CARD
  // -------------------------------------------------------------
  Widget _buildTodayNoteCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ملاحظة اليوم',
                style: GoogleFonts.changa(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotesScreen()),
                  ).then((_) => _loadHome());
                },
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
                label: Text(
                  'الملاحظات',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            onChanged: _onNoteChanged,
            maxLines: 2,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              hintText: 'اكتب ملاحظة سريعة أو تذكير لليوم...',
              hintStyle: GoogleFonts.tajawal(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.muted,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isolated widget for the 1-second live clock to prevent full-screen rebuilds
class _LiveClockWidget extends StatefulWidget {
  final String dateFormatType;
  final bool isDark;

  const _LiveClockWidget({
    required this.dateFormatType,
    required this.isDark,
  });

  @override
  State<_LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<_LiveClockWidget> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullDate = AppDateUtils.formatArabicDate(_now);
    final hijriDate = HijriHelper.formatHijriDate(_now);

    return Text(
      widget.dateFormatType == 'hijri'
          ? hijriDate
          : (widget.dateFormatType == 'gregorian' ? fullDate : '$fullDate | $hijriDate'),
      style: GoogleFonts.tajawal(
        fontSize: 11,
        color: Colors.white.withValues(alpha: 0.9),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// ويدجت الجرادينت الذكي المتعدد (Smart Multi-Slide Gradient Carousel)
class _HomeSmartGradientCarouselCard extends StatefulWidget {
  final HomeProvider homeP;
  final bool isDark;
  final VoidCallback onRefreshHome;
  final TextEditingController? noteController;

  const _HomeSmartGradientCarouselCard({
    required this.homeP,
    required this.isDark,
    required this.onRefreshHome,
    this.noteController,
  });

  @override
  State<_HomeSmartGradientCarouselCard> createState() => _HomeSmartGradientCarouselCardState();
}

class _HomeSmartGradientCarouselCardState extends State<_HomeSmartGradientCarouselCard> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % 3;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _showQuickNoteEditDialog() {
    final noteCtrl = TextEditingController(text: widget.homeP.todayNote);
    final isDark = widget.isDark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 8),
            Text('ملاحظة ومهمة اليوم 📝', style: GoogleFonts.changa(fontSize: 15.5, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            hintText: 'اكتب ملاحظتك أو مهمتك لليوم هنا...',
            hintStyle: GoogleFonts.tajawal(fontSize: 13),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              widget.homeP.saveTodayNote(noteCtrl.text);
              if (widget.noteController != null) {
                widget.noteController!.text = noteCtrl.text;
              }
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ تم حفظ ملاحظة اليوم بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFF6366F1),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('حفظ الملاحظة ✅', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final homeP = widget.homeP;
    final alertsP = context.watch<AlertsProvider>();

    // Next upcoming group
    GroupModel? nextGroup;
    ActiveSessionInfo? nextActive = homeP.primaryActiveSession;
    if (nextActive != null) {
      nextGroup = nextActive.group;
    } else if (homeP.todaysGroups.isNotEmpty) {
      nextGroup = homeP.todaysGroups.where((g) => !homeP.preparedGroupIds.contains(g.id)).firstOrNull;
    }

    final nextAlert = alertsP.nextUpcomingAlert;

    return Container(
      height: 124,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (idx) {
                setState(() {
                  _currentPage = idx;
                });
              },
              children: [
                // 1. Group / Next Class Slide
                _buildSlideContainer(
                  gradient: isDark
                      ? const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF134E4A)], begin: Alignment.topRight, end: Alignment.bottomLeft)
                      : const LinearGradient(colors: [Color(0xFF0D7377), Color(0xFF14FFEC)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  borderColor: const Color(0xFF14FFEC).withValues(alpha: 0.4),
                  onTap: () {
                    final grp = nextGroup;
                    if (grp != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceScreen(
                            groupId: grp.id,
                            groupName: grp.name,
                          ),
                        ),
                      ).then((_) => widget.onRefreshHome());
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  nextActive != null ? Icons.play_circle_filled_rounded : Icons.schedule_rounded,
                                  color: Colors.white,
                                  size: 11.5,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  nextActive != null
                                      ? 'حصة جارية (${ArabicNumbers.formatTime12(nextActive.time)})'
                                      : (nextGroup != null ? 'المجموعة التالية ⏰' : 'حصص اليوم ✨'),
                                  style: GoogleFonts.tajawal(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 11),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextGroup != null ? nextGroup.name : 'أنجزت جميع حصص اليوم ✨',
                            style: GoogleFonts.changa(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            nextGroup != null
                                ? '📖 ${nextGroup.subject ?? "عام"} · ${ArabicNumbers.formatStudentsCount(homeP.groupStudentCounts[nextGroup.id] ?? 0)}'
                                : 'لا توجد مجموعات متبقية لليوم',
                            style: GoogleFonts.tajawal(fontSize: 10, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(
                        nextGroup != null ? 'اضغط للتحضير ➔' : 'عرض الجدول ➔',
                        style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // 2. Today's Quick Note Slide
                _buildSlideContainer(
                  gradient: isDark
                      ? const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF4C1D95)], begin: Alignment.topRight, end: Alignment.bottomLeft)
                      : const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF7C3AED)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  borderColor: const Color(0xFFA78BFA).withValues(alpha: 0.4),
                  onTap: _showQuickNoteEditDialog,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_note_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'ملاحظة ومهمة اليوم 📝',
                                  style: GoogleFonts.tajawal(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit_rounded, color: Colors.white70, size: 11),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            homeP.todayNote.trim().isNotEmpty
                                ? (homeP.todayNote.trim().length > 30 ? '${homeP.todayNote.trim().substring(0, 30)}...' : homeP.todayNote.trim())
                                : 'سجّل ملاحظة أو مهمة اليوم ✍️',
                            style: GoogleFonts.changa(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            homeP.todayNote.trim().isNotEmpty ? 'اضغط لتعديل الملاحظة' : 'تدوين سريع للمهام والمذكرات',
                            style: GoogleFonts.tajawal(fontSize: 10, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(
                        'كتابة / تعديل ✏️',
                        style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // 3. Next Scheduled Alert Slide
                _buildSlideContainer(
                  gradient: isDark
                      ? const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF047857)], begin: Alignment.topRight, end: Alignment.bottomLeft)
                      : const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                  borderColor: const Color(0xFF6EE7B7).withValues(alpha: 0.4),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'التنبيه القادم 🔔',
                                  style: GoogleFonts.tajawal(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 11),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextAlert != null ? nextAlert.title : 'مركز التنبيهات المجدولة',
                            style: GoogleFonts.changa(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            nextAlert != null ? nextAlert.badgeText : 'كافة المواعيد والحصص منتظمة',
                            style: GoogleFonts.tajawal(fontSize: 10, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(
                        'مركز التنبيهات ➔',
                        style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Indicator Dots at Bottom-Left in RTL (Bottom-Right in LTR)
            Positioned(
              bottom: 8,
              left: 10,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: isActive ? 12 : 4,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideContainer({
    required Gradient gradient,
    required Color borderColor,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          gradient: gradient,
          border: Border.all(color: borderColor, width: 1.0),
        ),
        child: child,
      ),
    );
  }
}

