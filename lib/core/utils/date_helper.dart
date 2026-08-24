import 'package:intl/intl.dart';

class AppDateUtils {
  static final List<String> _arabicMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static final List<String> _arabicDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];


  /// Returns Arabic full date: "الأربعاء، 11 أغسطس 2026"
  static String formatArabicDate(DateTime date) {
    final dayName = _arabicDays[date.weekday - 1];
    final monthName = _arabicMonths[date.month - 1];
    return '$dayName، ${date.day} $monthName ${date.year}';
  }

  /// Returns Arabic short date: "11 أغسطس"
  static String formatArabicShortDate(DateTime date) {
    final monthName = _arabicMonths[date.month - 1];
    return '${date.day} $monthName';
  }

  /// Returns Arabic day name for a given DateTime
  static String arabicDayName(DateTime date) {
    return _arabicDays[date.weekday - 1];
  }

  /// Returns Arabic day name for index (0=Monday ... 6=Sunday)
  static String arabicDayNameByIndex(int weekday) {
    // weekday: 1=Monday ... 7=Sunday (Dart)
    return _arabicDays[(weekday - 1) % 7];
  }

  /// Returns weekday index (1-7, Monday=1) for Arabic day name
  static int weekdayFromArabicName(String name) {
    const map = {
      'الاثنين': 1,
      'الثلاثاء': 2,
      'الأربعاء': 3,
      'الخميس': 4,
      'الجمعة': 5,
      'السبت': 6,
      'الأحد': 7,
    };
    return map[name] ?? 1;
  }

  /// Format time as HH:MM
  static String formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  /// Format time as HH:MM am/pm in Arabic
  static String formatTimeArabic(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:$minute $period';
  }

  /// Format month/year for finance: "08-2026"
  static String formatMonthYear(int month, int year) {
    return '${month.toString().padLeft(2, '0')}-$year';
  }

  /// Arabic month name
  static String arabicMonth(int month) => _arabicMonths[month - 1];

  /// Returns today's Arabic day name
  static String todayArabicDayName() => arabicDayName(DateTime.now());

  /// Format date as yyyy-MM-dd for DB storage
  static String toDbDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  /// Parse yyyy-MM-dd from DB
  static DateTime fromDbDate(String s) => DateTime.parse(s);

  /// Returns true if two dates are the same calendar day
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Calculate minutes until next occurrence of a time on a specific weekday
  static int? minutesUntilNextSession(int weekday, String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;

    // Try today first, then next 7 days
    for (int offset = 0; offset <= 7; offset++) {
      final candidate = DateTime(now.year, now.month, now.day + offset, h, m);
      if (candidate.weekday == weekday && candidate.isAfter(now)) {
        return candidate.difference(now).inMinutes;
      }
    }
    return null;
  }

  /// Returns the closest upcoming session across all groups
  /// Returns (groupId, minutesUntil)
  static Map<String, dynamic>? nextSession(
    List<Map<String, dynamic>> groupDays,
  ) {
    int? minMinutes;
    Map<String, dynamic>? result;

    for (final entry in groupDays) {
      final weekday = entry['weekday'] as int;
      final time = entry['time'] as String;
      final minutes = minutesUntilNextSession(weekday, time);
      if (minutes != null && (minMinutes == null || minutes < minMinutes)) {
        minMinutes = minutes;
        result = {...entry, 'minutesUntil': minutes};
      }
    }
    return result;
  }

  /// Format countdown: "45 دقيقة" or "2 ساعة 15 دقيقة"
  static String formatCountdown(int minutes) {
    if (minutes <= 0) return 'جارية الآن 🟢';
    if (minutes < 60) return '$minutes دقيقة';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h ساعة';
    return '$h ساعة $m دقيقة';
  }

  /// Check if a session on a given weekday and time is currently running (or within a ±45 min window)
  static bool isSessionCurrentlyRunning(int weekday, String time, {int durationMinutes = 90}) {
    final now = DateTime.now();
    if (now.weekday != weekday) return false;
    final parts = time.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final start = DateTime(now.year, now.month, now.day, h, m);
    final end = start.add(Duration(minutes: durationMinutes));
    // Window: from 10 mins before start to session end
    return now.isAfter(start.subtract(const Duration(minutes: 10))) && now.isBefore(end);
  }
}
