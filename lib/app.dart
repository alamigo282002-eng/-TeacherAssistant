import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/in_app_notification_manager.dart';
import 'core/services/live_session_foreground_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/activity_log_repository.dart';
import 'data/repositories/attendance_repository.dart';
import 'data/repositories/exam_repository.dart';
import 'data/repositories/group_repository.dart';
import 'data/repositories/news_repository.dart';
import 'data/repositories/note_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/student_repository.dart';
import 'features/attendance/attendance_provider.dart';
import 'features/auth/lock_provider.dart';
import 'features/exams/exams_provider.dart';
import 'features/finance/finance_provider.dart';
import 'features/groups/groups_provider.dart';
import 'features/home/home_provider.dart';
import 'features/news/news_provider.dart';
import 'features/notes/notes_provider.dart';
import 'features/reports/activity_log_provider.dart';
import 'features/reports/alerts_provider.dart';
import 'features/reports/reports_provider.dart';
import 'features/settings/settings_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/students/students_provider.dart';

class TeacherAssistantApp extends StatelessWidget {
  const TeacherAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // -------------------------------------------------------------
        // 1. DATA LAYER (REPOSITORIES & SERVICES INJECTION)
        // -------------------------------------------------------------
        Provider(create: (_) => StudentRepository()),
        Provider(create: (_) => GroupRepository()),
        Provider(create: (_) => NoteRepository()),
        Provider(create: (_) => ExamRepository()),
        Provider(create: (_) => AttendanceRepository()),
        Provider(create: (_) => PaymentRepository()),
        Provider(create: (_) => NotificationService()),
        Provider(create: (_) => LiveSessionForegroundService()),
        ChangeNotifierProvider(create: (_) => InAppNotificationManager()),
        Provider(create: (_) => ActivityLogRepository()),
        Provider(create: (_) => NewsRepository()),

        // -------------------------------------------------------------
        // 2. PRESENTATION / STATE MANAGEMENT LAYER (DEPENDENCY INJECTION)
        // -------------------------------------------------------------
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => LockProvider()..loadSettings()),
        ChangeNotifierProvider(
          create: (ctx) => NewsProvider(
            repo: ctx.read<NewsRepository>(),
          )..loadNews(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ActivityLogProvider(
            repo: ctx.read<ActivityLogRepository>(),
          )..loadLogs(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AlertsProvider(
            notifService: ctx.read<NotificationService>(),
            groupRepo: ctx.read<GroupRepository>(),
            noteRepo: ctx.read<NoteRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => GroupsProvider(
            repo: ctx.read<GroupRepository>(),
            studentRepo: ctx.read<StudentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => StudentsProvider(
            repo: ctx.read<StudentRepository>(),
            attendanceRepo: ctx.read<AttendanceRepository>(),
            examRepo: ctx.read<ExamRepository>(),
            noteRepo: ctx.read<NoteRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AttendanceProvider(
            repo: ctx.read<AttendanceRepository>(),
            studentRepo: ctx.read<StudentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => HomeProvider(
            groupRepo: ctx.read<GroupRepository>(),
            studentRepo: ctx.read<StudentRepository>(),
            attendanceRepo: ctx.read<AttendanceRepository>(),
            noteRepo: ctx.read<NoteRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ExamsProvider(
            examRepo: ctx.read<ExamRepository>(),
            studentRepo: ctx.read<StudentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => FinanceProvider(
            paymentRepo: ctx.read<PaymentRepository>(),
            groupRepo: ctx.read<GroupRepository>(),
            studentRepo: ctx.read<StudentRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => NotesProvider(
            noteRepo: ctx.read<NoteRepository>(),
            notificationService: ctx.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ReportsProvider(
            groupRepo: ctx.read<GroupRepository>(),
            studentRepo: ctx.read<StudentRepository>(),
            examRepo: ctx.read<ExamRepository>(),
          ),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          if (!settings.initialized) {
            return MaterialApp(
              home: const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              debugShowCheckedModeBanner: false,
            );
          }
          return MaterialApp(
            title: 'مُساعِد المُعلِّم',
            debugShowCheckedModeBanner: false,
            theme: settings.examMode
                ? AppTheme.examTheme(isBold: settings.boldFont)
                : AppTheme.lightTheme(isBold: settings.boldFont),
            darkTheme: settings.examMode
                ? AppTheme.examTheme(isBold: settings.boldFont)
                : AppTheme.darkTheme(isBold: settings.boldFont),
            themeMode: (settings.darkMode || settings.examMode) ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('ar', 'EG'),
            builder: (context, child) {
              // Safe font scaling: user preferred multiplier clamped within safe range
              final effectiveScale = (settings.fontScale).clamp(0.8, 1.25);
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(effectiveScale),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: child!,
                ),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
