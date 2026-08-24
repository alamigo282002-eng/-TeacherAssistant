import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

enum InAppNotificationType {
  liveSession,   // الحصة الجارية (ID ثابت: 1001)
  sessionAlert,  // تنبيه قبل الحصة (معرف محدد من Group ID)
  paymentAlert,  // سداد الاشتراكات (ID ثابت: 2001)
  noteAlert,     // تذكير ملاحظة (معرف محدد من Note ID)
  generalAlert,  // تنبيه عام
}

class InAppNotificationItem {
  final String id;
  final int notifId;
  final InAppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? payload;
  bool isRead;

  InAppNotificationItem({
    required this.id,
    required this.notifId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.expiresAt,
    this.payload,
    this.isRead = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() => {
        'id': id,
        'notifId': notifId,
        'type': type.index,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'payload': payload,
        'isRead': isRead ? 1 : 0,
      };
}

/// مدير التنبيهات الداخلية واستراتيجية منع تراكم الإشعارات
class InAppNotificationManager extends ChangeNotifier {
  static final InAppNotificationManager _instance =
      InAppNotificationManager._internal();
  factory InAppNotificationManager() => _instance;
  InAppNotificationManager._internal();

  final NotificationService _osNotifService = NotificationService();
  final List<InAppNotificationItem> _internalList = [];

  List<InAppNotificationItem> get activeNotifications =>
      _internalList.where((item) => !item.isExpired).toList();

  List<InAppNotificationItem> get allNotifications => _internalList;

  int get unreadCount =>
      _internalList.where((i) => !i.isRead && !i.isExpired).length;

  /// 1. استراتيجية المعرفات الثابتة (Deterministic Notification ID Strategy)
  /// تمنع تكرار الإشعارات لنفس الحدث وتحدث الإشعار في مكانه (In-Place Update)
  static int generateDeterministicId(String uniqueKey, InAppNotificationType type) {
    switch (type) {
      case InAppNotificationType.liveSession:
        return 1001; // معرّف الإشعار الدائم الثابت
      case InAppNotificationType.paymentAlert:
        return 2001; // معرّف تذكير الدفع الشهري
      case InAppNotificationType.sessionAlert:
        // تجزئة معرف المجموعة ليصبح Integer ثابت ومحدد
        return 10000 + (uniqueKey.hashCode.abs() % 40000);
      case InAppNotificationType.noteAlert:
        return 50000 + (uniqueKey.hashCode.abs() % 40000);
      case InAppNotificationType.generalAlert:
        return 90000 + (uniqueKey.hashCode.abs() % 9000);
    }
  }

  /// 2. إرسال أو جدولة إشعار مع تحديث القائمة الداخلية واستبدال القديم
  Future<void> dispatchNotification({
    required String uniqueKey,
    required InAppNotificationType type,
    required String title,
    required String body,
    required DateTime expiresAt,
    DateTime? scheduleAt,
    String? payload,
    bool ongoing = false,
  }) async {
    final notifId = generateDeterministicId(uniqueKey, type);

    // استبدال الإشعار القديم في القائمة الداخلية فوراً
    _internalList.removeWhere((item) => item.notifId == notifId || item.id == uniqueKey);
    _internalList.insert(
      0,
      InAppNotificationItem(
        id: uniqueKey,
        notifId: notifId,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        payload: payload,
      ),
    );

    // إرسال الإشعار لنظام أندرويد
    if (scheduleAt != null && scheduleAt.isAfter(DateTime.now())) {
      await _osNotifService.scheduleNotification(
        id: notifId,
        title: title,
        body: body,
        scheduledDate: scheduleAt,
        payload: payload,
      );
    } else {
      await _osNotifService.showNotification(
        id: notifId,
        title: title,
        body: body,
        payload: payload,
        ongoing: ongoing,
      );
    }

    notifyListeners();
  }

  /// 3. التنظيف التلقائي الدوري للإشعارات المنتهية (Auto-Purge Strategy)
  /// يُنفذ عند فتح التطبيق لإلغاء أي إشعار معلق من النظام وحذفه من القائمة الداخلية
  Future<int> runPeriodicCleanup() async {
    final now = DateTime.now();

    // البحث عن الإشعارات التي انتهى وقتها
    final expiredItems =
        _internalList.where((item) => item.expiresAt.isBefore(now)).toList();

    for (final exp in expiredItems) {
      // إلغاء الإشعار من درج النظام في حال كان ما يزال موجوداً
      await _osNotifService.cancelNotification(exp.notifId);
    }

    // إزالة المنتهية من القائمة
    _internalList.removeWhere((item) => item.expiresAt.isBefore(now));

    // حفظ طابع وقت التنظيف
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_cleanup_timestamp', now.toIso8601String());
    } catch (_) {}

    debugPrint('🧹 اكتمل تنظيف الإشعارات: تم حذف ${expiredItems.length} إشعار منتهي.');
    notifyListeners();
    return expiredItems.length;
  }

  /// تحديد إشعار كمقروء
  void markAsRead(String id) {
    final index = _internalList.indexWhere((i) => i.id == id);
    if (index != -1) {
      _internalList[index].isRead = true;
      notifyListeners();
    }
  }

  /// تحديد الكل كمقروء
  void markAllAsRead() {
    for (final item in _internalList) {
      item.isRead = true;
    }
    notifyListeners();
  }

  /// حذف إشعار محدد يدوياً
  Future<void> dismiss(int notifId) async {
    _internalList.removeWhere((i) => i.notifId == notifId);
    await _osNotifService.cancelNotification(notifId);
    notifyListeners();
  }

  /// حذف كافة الإشعارات
  Future<void> clearAll() async {
    _internalList.clear();
    await _osNotifService.cancelAll();
    notifyListeners();
  }
}
