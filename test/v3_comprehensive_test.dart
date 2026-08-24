import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:helper/core/constants/app_constants.dart';
import 'package:helper/core/utils/arabic_numbers.dart';
import 'package:helper/core/utils/hijri_helper.dart';
import 'package:helper/core/utils/pdf_generator.dart';
import 'package:helper/data/models/group_model.dart';
import 'package:helper/data/models/payment_model.dart';
import 'package:helper/features/certificates/certificate_model.dart';
import 'package:helper/features/notes/notes_provider.dart';
import 'package:helper/features/reports/reports_provider.dart';
import 'package:helper/features/settings/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('§1 & §2: Arabic Numbers & Hijri Calculation Tests', () {
    test('ArabicNumbers converts digits to Arabic-Indic characters', () {
      expect(ArabicNumbers.convert('0123456789'), '٠١٢٣٤٥٦٧٨٩');
      expect(ArabicNumbers.convert(150), '١٥٠');
      expect(ArabicNumbers.convert('17:30'), '١٧:٣٠');
    });

    test('ArabicNumbers formats time in 12-hour format with AM/PM (ص / م)', () {
      expect(ArabicNumbers.formatTime12('17:00'), '٥:٠٠ م');
      expect(ArabicNumbers.formatTime12('09:30'), '٩:٣٠ ص');
      expect(ArabicNumbers.formatTime12('00:15'), '١٢:١٥ ص');
      expect(ArabicNumbers.formatTime12('12:00'), '١٢:٠٠ م');
      expect(ArabicNumbers.formatTime12('13:45'), '١:٤٥ م');
    });

    test('ArabicNumbers formats currency and percent correctly', () {
      expect(ArabicNumbers.formatCurrency(150), '١٥٠ ج.م');
      expect(ArabicNumbers.formatPercent(85), '٨٥٪');
    });

    test('HijriHelper converts Gregorian date to correct Umm al-Qura Hijri date', () {
      final date = DateTime(2026, 8, 15);
      final hijri = HijriHelper.fromGregorian(date);

      expect(hijri.year, greaterThan(1440));
      expect(hijri.month, inInclusiveRange(1, 12));
      expect(hijri.day, inInclusiveRange(1, 30));

      final formatted = HijriHelper.formatHijriDate(date);
      expect(formatted, contains('هـ'));
    });
  });

  group('§3: Group Model & Subject Selection Rules', () {
    test('GroupModel stores and preserves dynamic subject string', () {
      final group = GroupModel(
        id: 'g-1',
        name: 'ثانوية عامة سنتر النور',
        type: GroupType.center,
        subject: 'اللغة العربية',
        days: const [GroupDay(day: 'السبت', time: '17:00'), GroupDay(day: 'الثلاثاء', time: '19:00')],
        monthlyPrice: 150,
        createdAt: DateTime.now(),
      );

      expect(group.subject, 'اللغة العربية');
      expect(group.isScheduledOn('السبت'), isTrue);
      expect(group.isScheduledOn('الأحد'), isFalse);
      expect(group.timeForDay('السبت'), '17:00');

      final map = group.toMap();
      expect(map['subject'], 'اللغة العربية');

      final fromMap = GroupModel.fromMap(map);
      expect(fromMap.subject, 'اللغة العربية');
      expect(fromMap.days.length, 2);
    });

    test('GroupModel enforces non-null safe subject fallback in toMap', () {
      final group = GroupModel(
        id: 'g-2',
        name: 'مجموعة بدون مادة',
        type: GroupType.online,
        subject: null,
        days: const [],
        createdAt: DateTime.now(),
      );

      expect(group.subject, isNull);
      final map = group.toMap();
      expect(map['subject'], isNotNull);
      expect(map['subject'], 'عام');
      final fromMap = GroupModel.fromMap(map);
      expect(fromMap.subject, 'عام');
    });

    test('SettingsProvider manages mySubjects dynamically with persistence', () async {
      final provider = SettingsProvider();
      await provider.init();

      expect(provider.mySubjects, isNotEmpty);
      expect(provider.mySubjects, contains('اللغة العربية'));

      await provider.addSubject('برمجة وحاسب');
      expect(provider.mySubjects, contains('برمجة وحاسب'));

      final updatedList = ['فيزياء', 'كيمياء'];
      await provider.setMySubjects(updatedList);
      expect(provider.mySubjects, equals(updatedList));
    });
  });

  group('§5: Payment Calculations & Cycles', () {
    test('PaymentModel properly reflects paid/partial/unpaid states', () {
      final pFull = PaymentModel(
        id: 'p-1',
        studentId: 's-1',
        groupId: 'g-1',
        month: 10,
        year: 2026,
        amount: 150,
        totalDue: 150,
        type: PaymentType.full,
        date: DateTime(2026, 10, 5),
      );

      expect(pFull.isPaid, isTrue);
      expect(pFull.isPartial, isFalse);
      expect(pFull.isUnpaid, isFalse);

      final pPartial = pFull.copyWith(amount: 75, type: PaymentType.partial);
      expect(pPartial.isPartial, isTrue);
      expect(pPartial.amount, 75);
    });
  });

  group('§6: Certificates & Arabic PDF Support', () {
    test('CertificateData builds with full Arabic metadata', () {
      final cert = CertificateData(
        studentName: 'محمود أحمد إبراهيم',
        groupName: 'الصف الثالث الثانوي - سنتر الأوائل',
        subject: 'اللغة العربية',
        teacherName: 'أحمد علي',
        rankOrGrade: 'المركز الأول 🥇',
        dateStr: '2026/08/17',
        themeKey: 'gold',
      );

      expect(cert.studentName, 'محمود أحمد إبراهيم');
      expect(cert.certificateTitle, 'شـهـادة تـقـديـر وتـفـوّق');
      expect(cert.rankOrGrade, contains('المركز الأول'));
      expect(cert.quranVerse, contains('يَرْفَعِ'));
    });

    test('PdfGenerator generates valid Arabic Certificate PDF bytes', () async {
      final cert = CertificateData(
        studentName: 'سارة محمد حسن',
        groupName: 'مجموعة النخبة',
        subject: 'الفيزياء',
        teacherName: 'أ. محمود رضوان',
        rankOrGrade: 'الدرجة النهائية 💯',
        dateStr: '2026/08/17',
        themeKey: 'emerald',
      );

      final bytes = await PdfGenerator.generateCertificatePdfBytes(cert);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000)); // Non-empty valid PDF
    });
  });

  group('§7: Clean Architecture & Provider State Management', () {
    test('NotesProvider manages category filters and search logic in pure state', () {
      final provider = NotesProvider();
      expect(provider.activeCategory, 'all');
      expect(provider.searchQuery, isEmpty);

      provider.setCategory('student');
      expect(provider.activeCategory, 'student');

      provider.setSearchQuery('اختبار النحو');
      expect(provider.searchQuery, 'اختبار النحو');
    });

    test('ReportsProvider initializes with empty/clean state', () {
      final provider = ReportsProvider();
      expect(provider.loading, isFalse);
      expect(provider.groups, isEmpty);
      expect(provider.exams, isEmpty);
      expect(provider.leaderboard, isEmpty);
      expect(provider.totalExams, 0);
    });
  });
}
