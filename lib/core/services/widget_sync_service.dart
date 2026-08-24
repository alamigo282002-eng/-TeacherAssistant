import 'package:shared_preferences/shared_preferences.dart';
import '../utils/arabic_numbers.dart';

/// خدمة مزامنة بيانات ودجت سطح المكتب والشاشة الرئيسية لنظام أندرويد
class WidgetSyncService {
  static Future<void> syncWidgetData({
    required String teacherName,
    String? nextGroupName,
    String? nextGroupTime,
    int todayGroupsCount = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('widget_teacher_name', teacherName);
      await prefs.setString(
        'widget_next_group',
        nextGroupName != null && nextGroupName.isNotEmpty
            ? nextGroupName
            : 'لا توجد حصص حالياً',
      );
      await prefs.setString(
        'widget_next_time',
        nextGroupTime != null && nextGroupTime.isNotEmpty
            ? ArabicNumbers.convert(nextGroupTime)
            : 'جاهز للتحضير',
      );
      await prefs.setString(
        'widget_today_count',
        ArabicNumbers.convert(todayGroupsCount),
      );
    } catch (_) {}
  }
}
