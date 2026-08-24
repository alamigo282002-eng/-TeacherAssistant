import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/mock_data_generator.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/alert_item_model.dart';
import '../groups/groups_provider.dart';
import '../home/home_provider.dart';
import '../settings/settings_provider.dart';
import '../students/students_provider.dart';
import 'alerts_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _notifPermissionGranted = true;
  bool _exactAlarmGranted = true;

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'الكل 🔔'},
    {'id': 'session', 'label': '⏰ تذكير الحصص'},
    {'id': 'sessionEnd', 'label': '📋 انتهاء الحصص'},
    {'id': 'note', 'label': '📝 الملاحظات'},
    {'id': 'payment', 'label': '💰 الاشتراكات'},
  ];

  final List<Map<String, dynamic>> _notifSounds = [
    {
      'id': 'bell',
      'title': '⏰ منبه الحصص الواضح (افتراضي)',
      'desc': 'جرس واضح ونبضات اهتزازية للتنبيه قبل موعد الحصة',
      'icon': Icons.notifications_active_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'id': 'gentle',
      'title': '🎵 رنين هادئ وخفيف',
      'desc': 'نغمة لطيفة وغير مزعجة أثناء الشرح أو الحصص',
      'icon': Icons.music_note_rounded,
      'color': Color(0xFF0284C7),
    },
    {
      'id': 'school',
      'title': '📢 نغمة السنتر والمدرسة',
      'desc': 'نغمة جرس الحصة المدرسية التقليدي',
      'icon': Icons.campaign_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'id': 'vibrate_only',
      'title': '📳 اهتزاز فقط (صامت)',
      'desc': 'نبضات اهتزاز بدون إصدار صوت',
      'icon': Icons.vibration_rounded,
      'color': Color(0xFFEA580C),
    },
    {
      'id': 'default',
      'title': '🔔 نغمة النظام القياسية',
      'desc': 'نغمة الإشعارات الافتراضية لهاتفك',
      'icon': Icons.settings_suggest_rounded,
      'color': Color(0xFF475569),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissionsStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      context.read<AlertsProvider>().refreshAlerts(settings: settings);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsStatus() async {
    try {
      final notifStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      if (mounted) {
        setState(() {
          _notifPermissionGranted = notifStatus.isGranted;
          _exactAlarmGranted = alarmStatus.isGranted;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestPermissions() async {
    try {
      await NotificationService().requestNotificationPermission();
      await NotificationService().requestExactAlarmPermission();
      try {
        await Permission.notification.request();
        await Permission.scheduleExactAlarm.request();
      } catch (_) {}

      try {
        final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
        if (!batteryStatus.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      } catch (_) {}

      await _checkPermissionsStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ تم تفعيل جميع صلاحيات الإشعارات والمنبه والعمل في الخلفية',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى تفعيل الصلاحيات من إعدادات الهاتف: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.orange,
          ),
        );
      }
    }
  }

  String _formatDateTimeArabic(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;

    final timeStr = DateFormat('hh:mm a', 'ar').format(dt);
    if (isToday) return 'اليوم في $timeStr';
    if (isTomorrow) return 'غداً في $timeStr';
    return DateFormat('EEEE d MMMM - hh:mm a', 'ar').format(dt);
  }

  void _showTestBatchDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'حزمة اختبار الإشعارات (46 مجموعة) 🚀',
                style: GoogleFonts.changa(fontSize: 15.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'كيف تُحسب المجموعات في اليوم؟',
                          style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• اليوم = 24 ساعة = 1440 دقيقة.\n• عند إضافة حصة مدتها 30 دقيقة كل 31 دقيقة:\n  1440 ÷ 31 = 46.45 ➔ 46 مجموعة يومياً!\n• ستبدأ الحصص من اللحظة الحالية بتتابع مباشر، لترى وصول الإشعارات والتنبيهات أمامك بشكل حي.',
                      style: GoogleFonts.tajawal(fontSize: 12, height: 1.45, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'ماذا سيحدث عند التوليد؟',
                style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '✅ إنشاء 46 مجموعة متتابعة مع طلاب تجريبيين.\n✅ جدولة تنبيهات الحصص وانتهاء المواعيد تلقائياً.\n✅ يمكنك حذف الحزمة بضغطة زر واحدة في أي وقت.',
                style: GoogleFonts.tajawal(fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_task_rounded, size: 18),
            label: Text('توليد الحزمة الآن (46 مجموعة)', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('جارٍ توليد 46 مجموعة متتالية كل 31 دقيقة...', style: GoogleFonts.tajawal()),
                  duration: const Duration(seconds: 2),
                ),
              );

              final count = await MockDataGenerator.generateNotificationTestBatch(
                startFromCurrentTime: true,
                count: 46,
              );

              if (!mounted) return;
              context.read<GroupsProvider>().loadGroups();
              context.read<StudentsProvider>().loadStudents();
              context.read<HomeProvider>().loadHomeData();
              final settings = context.read<SettingsProvider>();
              final alertsP = context.read<AlertsProvider>();
              await alertsP.refreshAlerts(settings: settings);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ تم توليد $count مجموعة بنجاح وجدولة إشعاراتها بدقة!', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  backgroundColor: AppColors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSoundSelectionBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<SettingsProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(sheetCtx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'اختر نغمة وصوت التنبيه 🎵',
                    style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._notifSounds.map((sound) {
                final isSelected = settings.notifSound == sound['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (sound['color'] as Color).withValues(alpha: 0.1)
                        : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? (sound['color'] as Color) : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (sound['color'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(sound['icon'] as IconData, color: sound['color'] as Color, size: 20),
                    ),
                    title: Text(
                      sound['title'] as String,
                      style: GoogleFonts.tajawal(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? (sound['color'] as Color) : (isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                    subtitle: Text(
                      sound['desc'] as String,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, size: 20),
                          tooltip: 'تجربة الصوت',
                          onPressed: () {
                            SystemSound.play(SystemSoundType.alert);
                            HapticFeedback.vibrate();
                          },
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? (sound['color'] as Color) : Colors.grey.shade400,
                              width: 2,
                            ),
                            color: isSelected ? (sound['color'] as Color) : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                    onTap: () {
                      settings.setNotifSound(sound['id'] as String);
                      setSheetState(() {});
                    },
                  ),
                );
              }),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('حفظ واختيار النغمة ✅', style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertsP = context.watch<AlertsProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'مركز التنبيهات والإشعارات 🔔',
          style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: Color(0xFF10B981)),
            tooltip: 'حزمة اختبار 46 مجموعة',
            onPressed: _showTestBatchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'مزامنة وتحديث التنبيهات',
            onPressed: () async {
              await alertsP.refreshAlerts(settings: settings);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🔄 تم تحديث وجدولة كافة التنبيهات بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: isDark ? AppColors.darkBg : Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkMuted : const Color(0xFF64748B),
              labelStyle: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 12.5),
              unselectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600, fontSize: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'التنبيهات المجدولة 📋'),
                Tab(text: 'إعدادات الإشعارات ⚙️'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Live & Upcoming Scheduled Alerts
          _buildAlertsListTab(alertsP, settings, isDark),

          // Tab 2: Settings, Sounds & Instant Tests
          _buildSettingsTab(alertsP, settings, isDark),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: SCHEDULED & ACTIVE ALERTS LIST
  // ==========================================
  Widget _buildAlertsListTab(AlertsProvider alertsP, SettingsProvider settings, bool isDark) {
    final nextAlert = alertsP.nextUpcomingAlert;
    final alerts = alertsP.filteredAlerts;

    return RefreshIndicator(
      onRefresh: () => alertsP.refreshAlerts(settings: settings),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // 1. Next Upcoming Hero Card
          if (nextAlert != null) ...[
            _buildNextAlertHeroCard(nextAlert, isDark),
            const SizedBox(height: 14),
          ],

          // 2. Filters
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (ctx, idx) {
                final f = _filters[idx];
                final isSelected = alertsP.selectedFilter == f['id'];
                final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

                return GestureDetector(
                  onTap: () => alertsP.setFilter(f['id'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryCol
                          : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? primaryCol
                            : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        f['label'] as String,
                        style: GoogleFonts.tajawal(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? AppColors.darkBg : Colors.white)
                              : (isDark ? Colors.white70 : AppColors.ink),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 3. Alerts Count Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'قائمة التنبيهات المجدولة (${alerts.length})',
                style: GoogleFonts.changa(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                ),
              ),
              if (alerts.any((a) => a.id.startsWith('test_notif_')))
                TextButton.icon(
                  onPressed: () async {
                    final deleted = await MockDataGenerator.clearNotificationTestBatch();
                    if (!mounted) return;
                    context.read<GroupsProvider>().loadGroups();
                    context.read<StudentsProvider>().loadStudents();
                    final s = context.read<SettingsProvider>();
                    final aP = context.read<AlertsProvider>();
                    await aP.refreshAlerts(settings: s);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('🧹 تم حذف $deleted مجموعة اختبار بنجاح', style: GoogleFonts.tajawal())),
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.red, size: 16),
                  label: Text('حذف حزمة الاختبار 🧹', style: GoogleFonts.tajawal(fontSize: 11.5, color: AppColors.red, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 4. Alerts List
          if (alertsP.loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (alerts.isEmpty)
            _buildEmptyAlertsState(isDark)
          else
            ...alerts.map((a) => _buildAlertItemCard(a, isDark)),
        ],
      ),
    );
  }

  Widget _buildNextAlertHeroCard(AlertItemModel nextAlert, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              )
            : const LinearGradient(
                colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white70,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_outlined, color: Color(0xFF059669), size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'التنبيه القادم المُجدول:',
                style: GoogleFonts.changa(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF065F46),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  nextAlert.badgeText,
                  style: GoogleFonts.tajawal(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            nextAlert.title,
            style: GoogleFonts.changa(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF064E3B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nextAlert.body,
            style: GoogleFonts.tajawal(
              fontSize: 12.5,
              color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.access_time_filled_rounded, size: 14, color: Color(0xFF059669)),
              const SizedBox(width: 4),
              Text(
                'موعد الإشعار: ${_formatDateTimeArabic(nextAlert.scheduledTime)}',
                style: GoogleFonts.tajawal(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF064E3B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItemCard(AlertItemModel alert, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: alert.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(alert.icon, color: alert.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: GoogleFonts.changa(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: alert.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.badgeText,
                        style: GoogleFonts.tajawal(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: alert.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.body,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTimeArabic(alert.scheduledTime),
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAlertsState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد تنبيهات مجدولة حالياً',
              style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'أضف مجموعات بمواعيد حصص أو ملاحظات بتذكير، أو قم بتوليد حزمة الاختبار فوراً.',
              style: GoogleFonts.tajawal(fontSize: 12.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showTestBatchDialog,
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: Text('توليد حزمة اختبار 46 مجموعة 🚀', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: NOTIFICATION SETTINGS, SOUNDS & TESTS
  // ==========================================
  Widget _buildSettingsTab(AlertsProvider alertsP, SettingsProvider settings, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // 1. Permission & Alarm Status Card
        _buildPermissionStatusCard(isDark),
        const SizedBox(height: 16),

        // 2. Notification Sounds Card
        _buildSectionTitle('نغمات وأصوات التنبيه 🎵', Icons.music_note_rounded, isDark),
        const SizedBox(height: 8),
        _buildSoundCard(settings, isDark),
        const SizedBox(height: 18),

        // 3. Test Batch Generator Card (46 groups every 31 mins)
        _buildSectionTitle('حزمة اختبار الإشعارات المباشرة 🚀', Icons.bolt_rounded, isDark),
        const SizedBox(height: 8),
        _buildTestBatchActionCard(alertsP, settings, isDark),
        const SizedBox(height: 18),

        // 4. Instant Test Notifications Section
        _buildSectionTitle('تجربة فورية للإشعارات ⚡', Icons.flash_on_rounded, isDark),
        const SizedBox(height: 8),
        _buildTestNotificationsSection(alertsP, isDark),
        const SizedBox(height: 18),

        // 5. Class Session Reminder Timing Section
        _buildSectionTitle('تنبيهات مواعيد الحصص المجدولة ⏰', Icons.alarm_rounded, isDark),
        const SizedBox(height: 8),
        _buildClassSessionReminderCard(settings, isDark),
        const SizedBox(height: 18),

        // 6. Switches for active alerts
        _buildSectionTitle('تخصيص أنواع التنبيهات 🎛️', Icons.tune_rounded, isDark),
        const SizedBox(height: 8),
        _buildSwitchCard(
          title: 'تنبيهات مواعيد الحصص القادمة',
          subtitle: 'إشعار قبل الحصة بالوقت المحدد لتجهيز كشف الحضور',
          icon: Icons.alarm_on_rounded,
          value: settings.notifSession,
          onChanged: (v) => settings.setNotifSession(v),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildSwitchCard(
          title: 'تنبيه انتهاء الحصة',
          subtitle: 'إشعار فور انتهاء الحصة لرصد الغياب والدرجات والواجبات',
          icon: Icons.fact_check_rounded,
          value: true,
          onChanged: (_) {},
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildSwitchCard(
          title: 'تنبيهات سداد الاشتراكات الشهرية',
          subtitle: 'تذكير دوري في يوم محدد من كل شهر لمتابعة الاشتراكات',
          icon: Icons.payments_rounded,
          value: settings.notifPayment,
          onChanged: (v) => settings.setNotifPayment(v),
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildSwitchCard(
          title: 'ملخص الغياب اليومي',
          subtitle: 'إشعار بملخص الطلاب الغائبين في نهاية اليوم لمتابعتهم',
          icon: Icons.summarize_outlined,
          value: settings.notifAbsence,
          onChanged: (v) => settings.setNotifAbsence(v),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.changa(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSoundCard(SettingsProvider settings, bool isDark) {
    final currentSound = _notifSounds.firstWhere(
      (s) => s['id'] == settings.notifSound,
      orElse: () => _notifSounds.first,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (currentSound['color'] as Color).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(currentSound['icon'] as IconData, color: currentSound['color'] as Color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSound['title'] as String,
                  style: GoogleFonts.tajawal(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  currentSound['desc'] as String,
                  style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.muted),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: _showSoundSelectionBottomSheet,
            child: Text('تغيير النغمة', style: GoogleFonts.tajawal(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTestBatchActionCard(AlertsProvider alertsP, SettingsProvider settings, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 6),
              Text(
                'حزمة 46 مجموعة (كل 31 دقيقة مدتها 30 دقيقة)',
                style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'حساب دقيق: 1440 دقيقة ÷ 31 = 46 مجموعة يومياً تبدأ من الآن لاختبار الإشعارات بشكل متواصل.',
            style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: _showTestBatchDialog,
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: Text('توليد الحزمة 🚀', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                ),
                onPressed: () async {
                  final deleted = await MockDataGenerator.clearNotificationTestBatch();
                  if (!mounted) return;
                  context.read<GroupsProvider>().loadGroups();
                  context.read<StudentsProvider>().loadStudents();
                  final aP = context.read<AlertsProvider>();
                  await aP.refreshAlerts(settings: settings);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🧹 تم حذف $deleted مجموعة اختبار بنجاح', style: GoogleFonts.tajawal())),
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.red, size: 16),
                label: Text('حذف الحزمة 🧹', style: GoogleFonts.tajawal(fontSize: 11.5, color: AppColors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusCard(bool isDark) {
    final allGranted = _notifPermissionGranted && _exactAlarmGranted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allGranted
              ? (isDark ? AppColors.darkPrimary.withValues(alpha: 0.4) : AppColors.green.withValues(alpha: 0.3))
              : AppColors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allGranted ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: allGranted ? AppColors.green : AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                allGranted ? 'صلاحيات الإشعارات والمنبه مفعلة ✅' : 'يرجى مراجعة الصلاحيات ⚠️',
                style: GoogleFonts.changa(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!allGranted)
                TextButton(
                  onPressed: _requestPermissions,
                  child: Text('تفعيل الآن', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: AppColors.orange)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotificationsSection(AlertsProvider alertsP, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildTestChip(
            label: '⏰ تذكير حصة (15 دقيقة)',
            color: const Color(0xFF10B981),
            onTap: () => alertsP.sendTestNotification(AlertCategory.session),
          ),
          _buildTestChip(
            label: '📋 انتهاء وقت الحصة',
            color: const Color(0xFF8B5CF6),
            onTap: () => alertsP.sendTestNotification(AlertCategory.sessionEnd),
          ),
          _buildTestChip(
            label: '📝 تذكير بملاحظة',
            color: const Color(0xFFF59E0B),
            onTap: () => alertsP.sendTestNotification(AlertCategory.note),
          ),
          _buildTestChip(
            label: '💰 سداد اشتراك',
            color: const Color(0xFFD97706),
            onTap: () => alertsP.sendTestNotification(AlertCategory.payment),
          ),
        ],
      ),
    );
  }

  Widget _buildTestChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_rounded, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSessionReminderCard(SettingsProvider settings, bool isDark) {
    final current = settings.sessionReminderMinutes;
    final options = [5, 10, 15, 30];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'وقت التنبيه قبل موعد الحصة:',
            style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: options.map((mins) {
              final isSelected = current == mins;
              final color = isSelected ? (isDark ? AppColors.darkPrimary : AppColors.primary) : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9));

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AppScaleButton(
                    onTap: () {
                      settings.setSessionReminderMinutes(mins);
                      context.read<AlertsProvider>().refreshAlerts(settings: settings);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? (isDark ? AppColors.darkPrimary : AppColors.primary) : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$mins د',
                          style: GoogleFonts.changa(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? (isDark ? AppColors.darkBg : Colors.white) : (isDark ? Colors.white70 : AppColors.ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? AppColors.darkPrimary : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
