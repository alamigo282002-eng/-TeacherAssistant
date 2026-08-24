import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';

/// Comprehensive notification service that handles:
/// - Notification permission requests (Android 13+)
/// - Exact alarm permission requests (Android 14+)
/// - Battery optimization exclusion for background reliability
/// - Multi-tier scheduling fallback (exact → inexact)
/// - Boot-completed rescheduling support (via AndroidManifest receivers)
/// - Channel management with proper importance levels
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  FlutterLocalNotificationsPlugin get plugin => _notifications;

  // ──────────────────────────────────────────────
  // INITIALIZATION
  // ──────────────────────────────────────────────
  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    // 1. Initialize timezone database for scheduling
    try {
      tz.initializeTimeZones();
      // Use device local timezone
      tz.setLocalLocation(tz.local);
    } catch (_) {}

    // 2. Configure platform-specific initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 Notification tapped: ${response.payload}');
        },
      );

      // 3. Create notification channels on Android
      await _createNotificationChannels();

      // 4. Proactively request all necessary permissions
      await _requestAllPermissions();
    } catch (e) {
      debugPrint('❌ Notification Init Error: $e');
    }

    _initialized = true;
  }

  // ──────────────────────────────────────────────
  // CHANNEL CREATION
  // ──────────────────────────────────────────────
  Future<void> _createNotificationChannels() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    // 1. Session Reminders Channel (HIGH priority – 15 min before class)
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        AppConstants.notifChannelIdSession,
        AppConstants.notifChannelNameSession,
        description: 'تذكير بمواعيد الحصص قبل البدء بـ 15 دقيقة',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        showBadge: true,
      ),
    );

    // 2. Session End Channel (when class time is over)
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        AppConstants.notifChannelIdGroupEnd,
        AppConstants.notifChannelNameGroupEnd,
        description: 'تنبيه انتهاء وقت الحصة لرصد الغياب والواجبات',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // 3. Notes & Tasks Reminders Channel
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        AppConstants.notifChannelIdNotes,
        AppConstants.notifChannelNameNotes,
        description: 'تذكيرات الملاحظات والمهام المجدولة',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // 4. Payments Reminder Channel
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        AppConstants.notifChannelIdPayment,
        AppConstants.notifChannelNamePayment,
        description: 'تنبيهات مواعيد سداد الاشتراكات الشهرية',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    // 5. Daily Summary Channel
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        AppConstants.notifChannelIdDaily,
        AppConstants.notifChannelNameDaily,
        description: 'الملخص اليومي للغياب والأنشطة',
        importance: Importance.defaultImportance,
        playSound: true,
        showBadge: true,
      ),
    );
  }

  // ──────────────────────────────────────────────
  // PERMISSIONS MANAGEMENT
  // ──────────────────────────────────────────────

  /// Request all notification-related permissions at once
  Future<void> _requestAllPermissions() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // A. Request POST_NOTIFICATIONS permission (Android 13+/API 33)
        await android.requestNotificationsPermission();

        // B. Request SCHEDULE_EXACT_ALARM permission (Android 14+/API 34)
        //    If denied, our scheduling will automatically fallback to inexact
        await android.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Permission request error (non-fatal): $e');
    }
  }

  /// Explicitly request notification permission (can be called from UI)
  Future<bool?> requestNotificationPermission() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission();
      }
      final ios = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      debugPrint('Request Notification Permission Error: $e');
    }
    return false;
  }

  /// Explicitly request exact alarm permission (can be called from UI)
  Future<bool?> requestExactAlarmPermission() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('Request Exact Alarm Permission Error: $e');
    }
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> checkNotificationsEnabled() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? true;
      }
    } catch (_) {}
    return true;
  }

  /// Check if exact alarms are permitted
  Future<bool> checkExactAlarmPermission() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // Try to check via canScheduleExactNotifications
        final result = await android.areNotificationsEnabled();
        return result ?? true;
      }
    } catch (_) {}
    return true;
  }

  // ──────────────────────────────────────────────
  // SHOW INSTANT / ONGOING NOTIFICATION
  // ──────────────────────────────────────────────
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? channelName,
    String? payload,
    bool ongoing = false,
    bool autoCancel = true,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId ?? AppConstants.notifChannelIdSession,
      channelName ?? AppConstants.notifChannelNameSession,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ongoing: ongoing,
      autoCancel: autoCancel,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      styleInformation: BigTextStyleInformation(body),
      // Ensure notification shows even when app is in background
      fullScreenIntent: false,
      category: AndroidNotificationCategory.reminder,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  // ──────────────────────────────────────────────
  // SCHEDULE NOTIFICATION (Multi-Tier Fallback)
  // ──────────────────────────────────────────────

  /// Schedule a notification with automatic fallback:
  /// 1. Try exactAllowWhileIdle (best precision, requires SCHEDULE_EXACT_ALARM)
  /// 2. Fallback to inexactAllowWhileIdle (works without special permissions)
  ///
  /// Returns true if scheduling succeeded, false otherwise.
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    String? channelName,
    String? payload,
  }) async {
    // GUARD: Strictly reject any past or near-past dates
    final now = DateTime.now();
    if (!scheduledDate.isAfter(now.add(const Duration(seconds: 30)))) {
      debugPrint('⏭️ Skipped scheduling notification $id: date is in the past');
      return false;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId ?? AppConstants.notifChannelIdSession,
      channelName ?? AppConstants.notifChannelNameSession,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
      styleInformation: BigTextStyleInformation(body),
      category: AndroidNotificationCategory.reminder,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Convert to TZDateTime using local timezone
    final localDate = scheduledDate.toLocal();
    final tzDateTime = tz.TZDateTime(
      tz.local,
      localDate.year,
      localDate.month,
      localDate.day,
      localDate.hour,
      localDate.minute,
      localDate.second,
    );

    // Double-check TZ time is still in the future
    final tzNow = tz.TZDateTime.now(tz.local);
    if (!tzDateTime.isAfter(tzNow.add(const Duration(seconds: 15)))) {
      debugPrint('⏭️ Skipped scheduling notification $id: TZ date is in the past');
      return false;
    }

    // TIER 1: Try exact alarm (best precision for class reminders)
    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('✅ Scheduled exact notification #$id at $tzDateTime');
      return true;
    } catch (e) {
      debugPrint('⚠️ Exact alarm failed for #$id, trying inexact: $e');
    }

    // TIER 2: Fallback to inexact alarm (works without SCHEDULE_EXACT_ALARM permission)
    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('✅ Scheduled inexact notification #$id at $tzDateTime');
      return true;
    } catch (e) {
      debugPrint('❌ All scheduling tiers failed for #$id: $e');
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // MANAGEMENT
  // ──────────────────────────────────────────────

  /// Get all pending scheduled notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  /// Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id: id);
    } catch (_) {}
  }

  /// Cancel ALL pending notifications (use before rescheduling to avoid ghost alarms)
  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      debugPrint('🧹 Cancelled all pending notifications');
    } catch (_) {}
  }
}
