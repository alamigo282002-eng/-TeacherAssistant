import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helper/core/widgets/educational_pattern_background.dart';
import 'package:helper/features/onboarding/onboarding_screen.dart';
import 'package:helper/features/onboarding/registration_screen.dart';
import 'package:helper/features/onboarding/widgets/specialties_bottom_sheet.dart';
import 'package:helper/features/settings/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('EducationalPatternBackground renders child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EducationalPatternBackground(
            child: Text('Test Child'),
          ),
        ),
      ),
    );

    expect(find.text('Test Child'), findsOneWidget);
    expect(find.byType(EducationalPatternBackground), findsOneWidget);
  });

  testWidgets('OnboardingScreen displays 3-step setup (Data -> WhatsApp -> Subjects)', (tester) async {
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settingsProvider,
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Step 1: Teacher data
    expect(find.text('أهلاً بك 👋'), findsOneWidget);
    expect(find.text('اسم المعلم *'), findsOneWidget);
    expect(find.text('رقم الهاتف (اختياري / للتواصل)'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);

    // Enter name & phone and tap next
    await tester.enterText(find.byType(TextFormField).first, 'أحمد علي');
    await tester.enterText(find.byType(TextFormField).last, '01012345678');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('التالي'));
    await tester.pump(const Duration(seconds: 1));

    // Step 2: WhatsApp Community
    expect(find.text('مجتمع معلمي مصر 🇪🇬'), findsOneWidget);
    expect(find.text('انضم لجروب الواتساب الآن 📲'), findsOneWidget);
    expect(find.text('التالي (المواد)'), findsOneWidget);

    // Tap next to go to step 3
    await tester.tap(find.text('التالي (المواد)'));
    await tester.pump(const Duration(seconds: 1));

    // Step 3: Subjects selection
    expect(find.text('اختر موادك'), findsOneWidget);
    expect(find.text('اللغة العربية'), findsOneWidget);
    expect(find.text('ابدأ الاستخدام 🚀'), findsOneWidget);
  });

  testWidgets('RegistrationScreen displays form fields', (tester) async {
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settingsProvider,
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: RegistrationScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('تسجيل بيانات المعلم'), findsOneWidget);
    expect(find.text('الاسم بالكامل *'), findsOneWidget);
    expect(find.text('رقم الهاتف *'), findsOneWidget);
    expect(find.text('التخصصات الأكاديمية'), findsOneWidget);
    expect(find.text('التالي والبدء'), findsOneWidget);
  });

  testWidgets('SpecialtiesBottomSheet allows filtering and multiple custom specialties', (tester) async {
    List<String>? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  selected = await SpecialtiesBottomSheet.show(
                    context,
                    initialSelected: ['الرياضيات'],
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('التخصصات الأكاديمية'), findsOneWidget);
    expect(find.text('الرياضيات'), findsOneWidget);
    expect(find.text('الفيزياء'), findsOneWidget);
    expect(find.text('تأكيد الاختيار'), findsOneWidget);

    // Search for "تخصص" to bring "تخصص آخر" to the top
    await tester.enterText(find.byType(TextField).first, 'تخصص');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تخصص آخر'));
    await tester.pumpAndSettle();

    // Add first custom specialty: "علم النفس"
    final customField = find.byType(TextField).last;
    await tester.enterText(customField, 'علم النفس');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('علم النفس'), findsWidgets);

    // Add second custom specialty: "جيولوجيا"
    await tester.enterText(customField, 'جيولوجيا');
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();

    expect(find.text('جيولوجيا'), findsWidgets);

    // Tap confirm
    await tester.tap(find.text('تأكيد الاختيار'));
    await tester.pumpAndSettle();

    expect(selected, contains('الرياضيات'));
    expect(selected, contains('علم النفس'));
    expect(selected, contains('جيولوجيا'));
  });
}
