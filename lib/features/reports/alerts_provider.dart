import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/live_session_foreground_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/date_helper.dart';
import '../../data/models/alert_item_model.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/note_repository.dart';
import '../settings/settings_provider.dart';

class AlertsProvider extends ChangeNotifier {
  final NotificationService _notifService;
  final GroupRepository _groupRepo;
  final NoteRepository _noteRepo;

  AlertsProvider({
    NotificationService? notifService,
    GroupRepository? groupRepo,
    NoteRepository? noteRepo,
  })  : _notifService = notifService ?? NotificationService(),
        _groupRepo = groupRepo ?? GroupRepository(),
        _noteRepo = noteRepo ?? NoteRepository();

  List<AlertItemModel> _allAlerts = [];
  bool _loading = false;
  String _selectedFilter = 'all'; // 'all', 'session', 'sessionEnd', 'note', 'payment'

  List<AlertItemModel> get allAlerts => _allAlerts;
  bool get loading => _loading;
  String get selectedFilter => _selectedFilter;

  List<AlertItemModel> get filteredAlerts {
    if (_selectedFilter == 'all') return _allAlerts;
    if (_selectedFilter == 'session') {
      return _allAlerts.where((a) => a.category == AlertCategory.session).toList();
    }
    if (_selectedFilter == 'sessionEnd') {
      return _allAlerts.where((a) => a.category == AlertCategory.sessionEnd).toList();
    }
    if (_selectedFilter == 'note') {
      return _allAlerts.where((a) => a.category == AlertCategory.note).toList();
    }
    if (_selectedFilter == 'payment') {
      return _allAlerts.where((a) => a.category == AlertCategory.payment).toList();
    }
    return _allAlerts;
  }

  AlertItemModel? get nextUpcomingAlert {
    final upcoming = _allAlerts.where((a) => a.isUpcoming).toList();
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  int get upcomingCount => _allAlerts.where((a) => a.isUpcoming).length;
  int get sessionAlertsCount => _allAlerts.where((a) => a.category == AlertCategory.session && a.isUpcoming).length;
  int get noteAlertsCount => _allAlerts.where((a) => a.category == AlertCategory.note && a.isUpcoming).length;

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    notifyListeners();
  }

  DateTime? _getNextSessionDateTime(GroupDay day) {
    final now = DateTime.now();
    final targetWeekday = AppDateUtils.weekdayFromArabicName(day.day);
    final parts = day.time.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 17;
    final m = int.tryParse(parts[1]) ?? 0;

    // Check today first if the time hasn't passed
    final todayCandidate = DateTime(now.year, now.month, now.day, h, m);
    if (todayCandidate.weekday == targetWeekday && todayCandidate.isAfter(now)) {
      return todayCandidate;
    }

    // Otherwise find the next occurrence in the coming 7 days
    for (int offset = 1; offset <= 7; offset++) {
      final candidate = DateTime(now.year, now.month, now.day + offset, h, m);
      if (candidate.weekday == targetWeekday) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> refreshAlerts({SettingsProvider? settings}) async {
    _loading = true;
    notifyListeners();

    try {
      // Cancel previous scheduled alarms before re-scheduling to avoid old ghost notifications
      await _notifService.cancelAll();

      final groups = await _groupRepo.getActive();
      final notes = await _noteRepo.getAll();
      final reminderMinutes = settings?.sessionReminderMinutes ?? 15;
      final sessionNotifEnabled = settings?.notifSession ?? true;
      final paymentNotifEnabled = settings?.notifPayment ?? true;

      final generatedAlerts = <AlertItemModel>[];
      final now = DateTime.now();
      final minFutureThreshold = now.add(const Duration(seconds: 45));

      // 1. Generate Group Session Alerts (15 min before & session end)
      for (final group in groups) {
        for (final day in group.days) {
          final sessionTime = _getNextSessionDateTime(day);
          if (sessionTime == null) continue;

          final sessionEndTime = sessionTime.add(Duration(minutes: day.durationMinutes));

          // A. 15 Minutes (or configured minutes) before session start
          final alert15mTime = sessionTime.subtract(Duration(minutes: reminderMinutes));
          if (alert15mTime.isAfter(minFutureThreshold)) {
            final notifId = (group.id.hashCode + day.day.hashCode + 101).abs() % 100000;
            final alert = AlertItemModel(
              id: 'sess_${group.id}_${day.day}',
              notifId: notifId,
              category: AlertCategory.session,
              title: '⏰ موعد الحصة بعد قليل (${group.name})',
              body: 'حصة مادة ${group.subject ?? ''} ستبدأ بعد $reminderMinutes دقيقة في تمام الساعة ${ArabicNumbers.formatTime12(day.time)}. جهّز كشف الحضور 📚',
              scheduledTime: alert15mTime,
              eventTime: sessionTime,
              targetId: group.id,
              targetName: group.name,
              badgeText: 'قبل الحصة بـ $reminderMinutes دقيقة',
              icon: Icons.alarm_on_rounded,
              color: const Color(0xFF10B981),
            );
            generatedAlerts.add(alert);

            if (sessionNotifEnabled) {
              _notifService.scheduleNotification(
                id: notifId,
                title: alert.title,
                body: alert.body,
                scheduledDate: alert15mTime,
                channelId: AppConstants.notifChannelIdSession,
                channelName: AppConstants.notifChannelNameSession,
                payload: 'group_${group.id}',
              );
            }
          }

          // B. Session End Alert (عند انتهاء وقت الحصة لرصد الغياب والواجب)
          if (sessionEndTime.isAfter(minFutureThreshold)) {
            final notifId = (group.id.hashCode + day.day.hashCode + 303).abs() % 100000;
            final alert = AlertItemModel(
              id: 'end_${group.id}_${day.day}',
              notifId: notifId,
              category: AlertCategory.sessionEnd,
              title: '📋 انتهت حصة مجموعة ${group.name}',
              body: 'انتهت الحصة الآن. يرجى رصد كشف الحضور والغياب والدرجات والواجبات ✍️',
              scheduledTime: sessionEndTime,
              eventTime: sessionEndTime,
              targetId: group.id,
              targetName: group.name,
              badgeText: 'عند انتهاء الحصة',
              icon: Icons.fact_check_rounded,
              color: const Color(0xFF8B5CF6),
            );
            generatedAlerts.add(alert);

            if (sessionNotifEnabled) {
              _notifService.scheduleNotification(
                id: notifId,
                title: alert.title,
                body: alert.body,
                scheduledDate: sessionEndTime,
                channelId: AppConstants.notifChannelIdSession,
                channelName: AppConstants.notifChannelNameSession,
                payload: 'attendance_${group.id}',
              );
            }
          }
        }
      }

      // 2. Generate Note Reminders
      for (final note in notes) {
        if (note.reminderEnabled && note.reminderTime != null) {
          if (note.reminderTime!.isAfter(minFutureThreshold)) {
            final notifId = note.id.hashCode.abs() % 100000;
            final noteTitle = note.content.length > 35
                ? '${note.content.substring(0, 35)}...'
                : note.content;
            final alert = AlertItemModel(
              id: 'note_${note.id}',
              notifId: notifId,
              category: AlertCategory.note,
              title: '📝 تذكير بملاحظة',
              body: note.content,
              scheduledTime: note.reminderTime!,
              eventTime: note.reminderTime!,
              targetId: note.id,
              targetName: noteTitle,
              badgeText: 'تذكير بملاحظة',
              icon: Icons.edit_note_rounded,
              color: const Color(0xFFF59E0B),
            );
            generatedAlerts.add(alert);

            _notifService.scheduleNotification(
              id: notifId,
              title: alert.title,
              body: alert.body,
              scheduledDate: note.reminderTime!,
              channelId: AppConstants.notifChannelIdNotes,
              channelName: AppConstants.notifChannelNameNotes,
              payload: 'note_${note.id}',
            );
          }
        }
      }

      // 3. Generate Monthly Payment Reminder
      if (paymentNotifEnabled) {
        final reminderDay = settings?.paymentReminderDay ?? 5;
        DateTime payTarget = DateTime(now.year, now.month, reminderDay, 10, 0);
        if (payTarget.isBefore(minFutureThreshold)) {
          payTarget = DateTime(now.year, now.month + 1, reminderDay, 10, 0);
        }
        final payNotifId = 88888;
        final alert = AlertItemModel(
          id: 'pay_monthly',
          notifId: payNotifId,
          category: AlertCategory.payment,
          title: '💰 موعد سداد الاشتراكات الشهرية',
          body: 'حان موعد متابعة سداد الاشتراكات والمصروفات للطلاب لشهر ${payTarget.month}/${payTarget.year} 💳',
          scheduledTime: payTarget,
          eventTime: payTarget,
          badgeText: 'يوم $reminderDay من الشهر',
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFFD97706),
        );
        generatedAlerts.add(alert);

        _notifService.scheduleNotification(
          id: payNotifId,
          title: alert.title,
          body: alert.body,
          scheduledDate: payTarget,
          channelId: AppConstants.notifChannelIdPayment,
          channelName: AppConstants.notifChannelNamePayment,
          payload: 'finance',
        );
      }

      // Sort all alerts chronologically (soonest first)
      generatedAlerts.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      _allAlerts = generatedAlerts;
    } catch (e) {
      debugPrint('Error refreshing alerts: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendTestNotification(AlertCategory category) async {
    switch (category) {
      case AlertCategory.session:
        await _notifService.showNotification(
          id: 9001,
          title: '⏰ موعد الحصة بعد قليل (مجموعة تالتة ثانوي أ)',
          body: 'حصة مادة الفيزياء ستبدأ بعد 15 دقيقة في تمام الساعة 5:00 م. كشف الحضور جاهز 📚',
          channelId: AppConstants.notifChannelIdSession,
          channelName: AppConstants.notifChannelNameSession,
        );
        break;
      case AlertCategory.sessionEnd:
        await _notifService.showNotification(
          id: 9003,
          title: '📋 انتهت حصة مجموعة تالتة ثانوي أ',
          body: 'انتهى وقت الحصة الآن. اضغط لتسجيل كشف الغياب ورصد درجات وتسميع الطلاب ✍️',
          channelId: AppConstants.notifChannelIdSession,
          channelName: AppConstants.notifChannelNameSession,
        );
        break;
      case AlertCategory.note:
        await _notifService.showNotification(
          id: 9004,
          title: '📝 تذكير بملاحظة: تحضير مذكرة المراجعة',
          body: 'تذكير: طباعة 25 نسخة من مذكرة المراجعة النهائية لمجموعة الأحد 📄',
          channelId: AppConstants.notifChannelIdNotes,
          channelName: AppConstants.notifChannelNameNotes,
        );
        break;
      case AlertCategory.payment:
        await _notifService.showNotification(
          id: 9005,
          title: '💰 موعد سداد الاشتراكات الشهرية',
          body: 'تذكير بمتابعة سداد الاشتراكات الشهرية وإرسال رسائل التذكير لأولياء الأمور 💳',
          channelId: AppConstants.notifChannelIdPayment,
          channelName: AppConstants.notifChannelNamePayment,
        );
        break;
      default:
        await _notifService.showNotification(
          id: 9000,
          title: '🔔 إشعار تجريبي من مُساعِد المُعلِّم',
          body: 'نظام التنبيهات والإشعارات يعمل بنجاح وبأعلى كفاءة على جهازك! 🚀',
        );
    }
  }

  /// اختبار إشعار الحصة الحية الدائم (Ongoing Foreground Service)
  Future<bool> startLiveSessionTest({String groupName = 'مجموعة تجريبية (أولى ثانوي)'}) async {
    return await LiveSessionForegroundService().startLiveSession(
      groupId: 'test_live_session_101',
      groupName: groupName,
      subject: 'الرياضيات',
    );
  }

  /// إيقاف إشعار الحصة الحية
  Future<bool> stopLiveSessionTest() async {
    return await LiveSessionForegroundService().stopLiveSession();
  }

  /// فحص هل خدمة الحصة الحية نشطة حالياً
  Future<bool> isLiveSessionRunning() async {
    return await LiveSessionForegroundService().isSessionRunning();
  }
}
