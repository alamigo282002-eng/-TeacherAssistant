import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/student_model.dart';
import '../../features/settings/settings_provider.dart';
import '../theme/app_theme.dart';
import 'arabic_numbers.dart';

class ContactHelper {
  static Future<void> makeCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openWhatsApp(String phone, {String text = ''}) async {
    if (phone.isEmpty) return;
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '2$cleanPhone';
    }
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static void executeContact(String phone, bool isWhatsApp, {String? text}) {
    if (isWhatsApp) {
      openWhatsApp(phone, text: text ?? '');
    } else {
      makeCall(phone);
    }
  }

  static void showContactOptions(
    BuildContext context,
    StudentModel student, {
    required bool isWhatsApp,
    String? whatsappText,
  }) {
    final hasStudentPhone = student.phone.isNotEmpty;
    final hasParentPhone = student.parentPhone.isNotEmpty;

    if (!hasStudentPhone && !hasParentPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا توجد أرقام مسجلة للطالب', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (hasStudentPhone && !hasParentPhone) {
      executeContact(student.phone, isWhatsApp, text: whatsappText);
      return;
    }

    if (!hasStudentPhone && hasParentPhone) {
      executeContact(student.parentPhone, isWhatsApp, text: whatsappText);
      return;
    }

    // Both exist, check settings
    final settings = context.read<SettingsProvider>();
    final method = settings.defaultContactMethod;

    if (method == 'student') {
      executeContact(student.phone, isWhatsApp, text: whatsappText);
      return;
    } else if (method == 'parent') {
      executeContact(student.parentPhone, isWhatsApp, text: whatsappText);
      return;
    }

    // method == 'ask' -> Show Bottom Sheet
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isWhatsApp ? 'تواصل عبر واتساب' : 'إجراء مكالمة',
              style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                executeContact(student.phone, isWhatsApp, text: whatsappText);
              },
              icon: Icon(isWhatsApp ? Icons.forum_rounded : Icons.phone),
              label: Text('الطالب: ${ArabicNumbers.convert(student.phone)}', style: GoogleFonts.tajawal()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                executeContact(student.parentPhone, isWhatsApp, text: whatsappText);
              },
              icon: Icon(isWhatsApp ? Icons.forum_rounded : Icons.phone),
              label: Text('ولي الأمر: ${ArabicNumbers.convert(student.parentPhone)}', style: GoogleFonts.tajawal()),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWhatsApp ? const Color(0xFF25D366) : AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'يمكنك تغيير خيار التواصل الافتراضي من الإعدادات',
              style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
