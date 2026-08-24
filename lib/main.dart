import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app.dart';
import 'core/services/in_app_notification_manager.dart';
import 'core/services/live_session_foreground_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Arabic locale date formatting for Intl
  try {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('ar_EG', null);
  } catch (_) {}

  // Friendly Arabic Error Widget
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFF8F9FA),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC3545), size: 56),
                const SizedBox(height: 16),
                Text(
                  '⚠️ عذراً، حدث خطأ غير متوقع',
                  style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى مراسلة المطور لحل المشكلة فوراً',
                  style: GoogleFonts.tajawal(fontSize: 13, color: const Color(0xFF718096)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/201000000000?text=${Uri.encodeComponent("مرحباً، واجهت مشكلة في تطبيق مساعد المعلم: ${details.exceptionAsString()}")}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: Text('مراسلة المطور على واتساب', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6E6E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Initialize notifications & foreground service
  await NotificationService().init();
  LiveSessionForegroundService().init();

  // Run periodic cleanup for expired notifications
  try {
    await InAppNotificationManager().runPeriodicCleanup();
  } catch (_) {}

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const TeacherAssistantApp());
}
