import 'arabic_numbers.dart';

class HijriDate {
  final int hYear;
  final int hMonth;
  final int hDay;

  const HijriDate({
    required this.hYear,
    required this.hMonth,
    required this.hDay,
  });

  int get year => hYear;
  int get month => hMonth;
  int get day => hDay;

  static const List<String> monthNames = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  String get monthName =>
      (hMonth >= 1 && hMonth <= 12) ? monthNames[hMonth - 1] : '';

  /// Formats in full Arabic: "٢٥ ربيع الأول ١٤٤٨ هـ"
  String toFormattedArabic() {
    return '${ArabicNumbers.convert(hDay)} $monthName ${ArabicNumbers.convert(hYear)} هـ';
  }
}

class HijriHelper {
  /// Converts Gregorian DateTime to HijriDate (Umm al-Qura approximation)
  static HijriDate fromGregorian(DateTime date) {
    int year = date.year;
    int month = date.month;
    int day = date.day;

    if (month < 3) {
      year -= 1;
      month += 12;
    }

    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524;

    final l = jd - 1948440 + 10632;
    final n = ((l - 1) / 10631).floor();
    final l1 = l - 10631 * n + 354;
    final j = ((10985 - l1) / 5316).floor() * ((50 * l1) / 17719).floor() +
        (l1 / 5670).floor() * ((43 * l1) / 15238).floor();
    final l2 = l1 -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;
    final m = ((24 * l2) / 709).floor();
    final d = l2 - ((709 * m) / 24).floor();
    final y = 30 * n + j - 30;

    return HijriDate(hYear: y, hMonth: m, hDay: d);
  }

  /// Format date to Arabic Hijri string
  static String formatHijriDate(DateTime date) {
    return fromGregorian(date).toFormattedArabic();
  }

  /// Returns today's formatted Hijri date string
  static String getTodayFormatted() {
    return fromGregorian(DateTime.now()).toFormattedArabic();
  }
}
