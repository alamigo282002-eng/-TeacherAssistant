import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/registration_screen.dart';
import 'features/settings/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PreviewOnboardingApp());
}

class PreviewOnboardingApp extends StatelessWidget {
  const PreviewOnboardingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
      ],
      child: MaterialApp(
        title: 'مساعد المعلم - تسجيل وبيانات المعلم',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        locale: const Locale('ar', 'EG'),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: const RegistrationScreen(),
      ),
    );
  }
}
