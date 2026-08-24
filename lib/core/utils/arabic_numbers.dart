import 'package:intl/intl.dart';

class ArabicNumbers {
  static const Map<String, String> _westernToArabic = {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  };

  /// Converts any number or string containing digits to Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩)
  static String convert(dynamic input) {
    if (input == null) return '';
    final str = input.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final char = str[i];
      buffer.write(_westernToArabic[char] ?? char);
    }
    return buffer.toString();
  }

  /// Formats currency in EGP with Arabic digits: "١٥٠ ج.م"
  static String formatCurrency(num amount) {
    final formatted = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : NumberFormat('#,##0.##', 'en_US').format(amount);
    return '${convert(formatted)} ج.م';
  }

  /// Formats percentage: "٨٥٪"
  static String formatPercent(num percent) {
    final p = percent.round();
    return '${convert(p)}٪';
  }

  /// Formats time in hh:mm ص/م with Arabic digits from DateTime
  static String formatTime(DateTime time) {
    int hour = time.hour;
    final isPm = hour >= 12;
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final period = isPm ? 'م' : 'ص';
    return '${convert(hour)}:${convert(minuteStr)} $period';
  }

  /// Formats HH:mm string (like "17:00") into 12-hour Arabic string (like "٥:٠٠ م")
  static String formatTime12(String timeStr) {
    if (timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length < 2) return convert(timeStr);
    int hour = int.tryParse(parts[0]) ?? 0;
    final min = parts[1];
    final isPm = hour >= 12;
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    final period = isPm ? 'م' : 'ص';
    return '${convert(hour)}:${convert(min)} $period';
  }

  /// Formats student count with accurate Arabic grammar:
  /// 0 -> "٠ طالب"
  /// 1 -> "طالب واحد"
  /// 2 -> "طالبان"
  /// 3-10 -> "٣ طلاب" .. "١٠ طلاب"
  /// 11+ -> "١١ طالب"
  static String formatStudentsCount(int count) {
    final countStr = convert(count);
    if (count == 0) return '$countStr طالب';
    if (count == 1) return 'طالب واحد';
    if (count == 2) return 'طالبان';
    if (count >= 3 && count <= 10) return '$countStr طلاب';
    return '$countStr طالب';
  }
}
