import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Top-level callback for Flutter Foreground Task Isolate
@pragma('vm:entry-point')
void liveSessionTaskCallback() {
  FlutterForegroundTask.setTaskHandler(LiveSessionTaskHandler());
}

/// معالج المهام المنفصل الذي يعمل في خلفية أندرويد
class LiveSessionTaskHandler extends TaskHandler {
  int _secondsElapsed = 0;
  String _groupName = 'حصة جارية';
  String _subject = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final groupData = await FlutterForegroundTask.getData<String>(key: 'live_group_name');
    final subjectData = await FlutterForegroundTask.getData<String>(key: 'live_subject');
    if (groupData != null && groupData.isNotEmpty) {
      _groupName = groupData;
    }
    if (subjectData != null && subjectData.isNotEmpty) {
      _subject = subjectData;
    }
    _secondsElapsed = 0;
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    _secondsElapsed += 5; // يتكرر كل 5 ثوانٍ
    final minutes = _secondsElapsed ~/ 60;
    final seconds = _secondsElapsed % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final subtitle = _subject.isNotEmpty
        ? 'مادة $_subject • الوقت المنقضي: $formattedTime دقيقة ⏳'
        : 'الوقت المنقضي: $formattedTime دقيقة • تسجيل الحضور متاح 📝';

    // تحديث الإشعار الثابت في مكانه بالضبط دون إنشاء إشعار جديد
    await FlutterForegroundTask.updateService(
      notificationTitle: '🔴 حصة جارية: $_groupName',
      notificationText: subtitle,
    );

    // إرسال البيانات اللحظية إلى واجهة التطبيق
    FlutterForegroundTask.sendDataToMain({
      'event': 'timer_tick',
      'seconds': _secondsElapsed,
      'group': _groupName,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _secondsElapsed = 0;
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map<String, dynamic>) {
      if (data['action'] == 'stop') {
        FlutterForegroundTask.stopService();
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'finish_session_btn') {
      FlutterForegroundTask.sendDataToMain({'action': 'finish_session'});
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {}
}

/// خدمة إدارة الحصة الحية والإشعار الثابت
class LiveSessionForegroundService {
  static final LiveSessionForegroundService _instance =
      LiveSessionForegroundService._internal();
  factory LiveSessionForegroundService() => _instance;
  LiveSessionForegroundService._internal();

  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'active_live_session_channel',
        channelName: 'الحصص الجارية والنشطة 🔴',
        channelDescription: 'إشعار ثابت يوضح استمرار الحصة والوقت المنقضي',
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
        enableVibration: false,
        playSound: false,
        showWhen: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // كل 5 ثوانٍ
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
  }

  /// بدء الحصة وتشغيل الخدمة الخلفية والإشعار الثابت
  Future<bool> startLiveSession({
    required String groupId,
    required String groupName,
    String? subject,
  }) async {
    init();

    // 1. فحص إذن الإشعارات
    final permission = await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // 2. فحص تجاهل قيود توفير البطارية (لضمان عدم إيقاف الخدمة في الخلفية)
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // 3. تخزين بيانات الحصة
    await FlutterForegroundTask.saveData(key: 'live_group_id', value: groupId);
    await FlutterForegroundTask.saveData(key: 'live_group_name', value: groupName);
    await FlutterForegroundTask.saveData(key: 'live_subject', value: subject ?? '');

    // 4. إعادة التشغيل لو كانت تعمل مسبقاً، أو البدء لأول مرة
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
      return true;
    }

    final serviceResult = await FlutterForegroundTask.startService(
      serviceId: 1001, // معرف ثابت لخدمة الحصة الحية
      notificationTitle: '🔴 حصة جارية: $groupName',
      notificationText: 'جاري احتساب وقت الحصة وتسجيل الحضور...',
      callback: liveSessionTaskCallback,
      notificationButtons: [
        NotificationButton(id: 'finish_session_btn', text: 'إنهاء الحصة ⏹️'),
      ],
    );

    return serviceResult is ServiceRequestSuccess;
  }

  /// إيقاف الحصة وإلغاء الإشعار الثابت فوراً
  Future<bool> stopLiveSession() async {
    if (await FlutterForegroundTask.isRunningService) {
      final res = await FlutterForegroundTask.stopService();
      return res is ServiceRequestSuccess;
    }
    return true;
  }

  /// فحص حالة الحصة الحالية
  Future<bool> isSessionRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}
