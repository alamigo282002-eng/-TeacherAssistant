import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/mock_data_generator.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../data/database/database_helper.dart';
import '../auth/lock_provider.dart';
import '../groups/groups_provider.dart';
import '../home/home_provider.dart';
import '../reports/alerts_provider.dart';
import '../students/students_provider.dart';
import 'settings_provider.dart';
import 'trash_screen.dart';
import 'whatsapp_templates_screen.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExam = settings.examMode;

    return Scaffold(
      backgroundColor: isExam ? AppColors.examBg : (isDark ? AppColors.darkBg : AppColors.bg),
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('👤 الحساب والبيانات الشخصية', isDark),
          _buildTeacherNameTile(context, settings, isDark),
          _buildTeacherPhoneTile(context, settings, isDark),
          _buildTeacherSubjectsTile(context, settings, isDark),
          const SizedBox(height: 16),

          _section('🎨 المظهر وتصميم الواجهة', isDark),
          _buildThemeModeTile(context, settings, isDark),
          _buildFontScaleTile(context, settings, isDark),
          _buildHomeDesignTile(context, settings, isDark),
          _buildBoldFontTile(context, settings, isDark),
          _buildSplashThemeTile(context, settings, isDark),
          _buildDateFormatTypeTile(context, settings, isDark),
          const SizedBox(height: 16),

          _section('💬 التواصل ورسائل الواتساب', isDark),
          _buildContactMethodTile(context, settings, isDark),
          _card(
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
              title: Text('قوالب رسائل الواتساب', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WhatsAppTemplatesScreen()),
                );
              },
            ),
            isDark,
          ),
          const SizedBox(height: 16),

          _section('🔒 الأمان وقفل التطبيق', isDark),
          _buildSecuritySection(context, context.watch<LockProvider>(), isDark),
          const SizedBox(height: 16),

          _section('💾 البيانات والنسخ الاحتياطي', isDark),
          _buildBackupTile(context, isDark),
          _buildRestoreTile(context, isDark),
          _buildTrashTile(context, isDark),
          const SizedBox(height: 16),

          _section('🛠️ خيارات المطور والبيانات التجريبية', isDark),
          _buildDeveloperOptionsTile(context, isDark),
          const SizedBox(height: 16),

          _section('ℹ️ عن التطبيق والاتفاقية', isDark),
          _buildAboutTile(context, settings, isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: GoogleFonts.changa(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _card(Widget child, bool isDark) {
    final isExam = context.read<SettingsProvider>().examMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExam ? AppColors.examBorder : (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: child,
    );
  }

  Widget _buildContactMethodTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    String getLabel() {
      switch (settings.defaultContactMethod) {
        case 'student': return 'الطالب';
        case 'parent': return 'ولي الأمر';
        default: return 'دائماً اسأل';
      }
    }
    
    return _card(
      ListTile(
        leading: const Icon(Icons.perm_contact_calendar_rounded, color: AppColors.primary),
        title: Text('التواصل الافتراضي', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          getLabel(),
          style: GoogleFonts.tajawal(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down_rounded, size: 24),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('التواصل الافتراضي', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in [
                    {'value': 'ask', 'label': 'دائماً اسأل'},
                    {'value': 'student', 'label': 'الطالب'},
                    {'value': 'parent', 'label': 'ولي الأمر'},
                  ])
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        settings.setDefaultContactMethod(item['value']!);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              settings.defaultContactMethod == item['value']
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: settings.defaultContactMethod == item['value']
                                  ? AppColors.primary
                                  : AppColors.muted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item['label']!,
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: settings.defaultContactMethod == item['value']
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      isDark,
    );
  }

  Widget _buildThemeModeTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    final currentMode = settings.appThemeMode; // 'light', 'dark', 'exam'

    Widget themeOption({
      required String modeKey,
      required String title,
      required String subtitle,
      required IconData icon,
      required Color iconColor,
      required Color activeBorderColor,
      LinearGradient? activeGradient,
      Widget? badge,
    }) {
      final isSelected = currentMode == modeKey;

      return InkWell(
        onTap: () async {
          await settings.setAppThemeMode(modeKey);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? activeGradient : null,
            color: isSelected && activeGradient == null
                ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.1)
                : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? activeBorderColor
                  : (isDark ? AppColors.darkBorder : AppColors.border),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected && modeKey == 'exam'
                ? [
                    BoxShadow(
                      color: const Color(0xFF00E5CC).withValues(alpha: 0.22),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? iconColor.withValues(alpha: 0.18)
                      : (isDark ? AppColors.darkCard : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected && modeKey == 'exam'
                      ? Border.all(color: const Color(0xFF00E5CC).withValues(alpha: 0.5))
                      : null,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.changa(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected && modeKey == 'exam'
                                ? const Color(0xFF00E5CC)
                                : (isDark ? Colors.white : AppColors.ink),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge,
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        color: isSelected && modeKey == 'exam'
                            ? const Color(0xFF6B9E9A)
                            : (isDark ? AppColors.darkMuted : AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: isSelected ? activeBorderColor : (isDark ? AppColors.darkMuted : Colors.grey),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }

    return _card(
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر المظهر المفضل (Theme)',
              style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            // Option 1: Light Mode
            themeOption(
              modeKey: 'light',
              title: 'الوضع الفاتح (Light Mode) 🌞',
              subtitle: 'خلفية ناصعة أنيقة بنقاء الزمرد',
              icon: Icons.light_mode_rounded,
              iconColor: AppColors.primary,
              activeBorderColor: AppColors.primary,
            ),
            // Option 2: Dark Mode
            themeOption(
              modeKey: 'dark',
              title: 'الوضع الداكن (Dark Mode) 🌙',
              subtitle: 'خلفية ليلية زمردية عميقة ومريحة للعين',
              icon: Icons.dark_mode_rounded,
              iconColor: AppColors.darkPrimary,
              activeBorderColor: AppColors.darkPrimary,
            ),
            // Option 3: Exam Mode
            themeOption(
              modeKey: 'exam',
              title: 'وضع الاختبار (Exam Mode) 🧪',
              subtitle: 'أسود فضائي عميق · نيون تيل كهربائي · ذهبي كهرماني',
              icon: Icons.science_rounded,
              iconColor: const Color(0xFF00E5CC),
              activeBorderColor: const Color(0xFF00E5CC),
              activeGradient: const LinearGradient(
                colors: [Color(0xFF050C0E), Color(0xFF0D2320)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00E5CC), Color(0xFFFFC84A)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'مميز ⚡',
                  style: GoogleFonts.tajawal(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF050C0E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isDark,
    );
  }

  Widget _buildFontScaleTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    final currentScale = settings.fontScale;

    Widget scaleChip(String label, double scale, String desc) {
      final isSelected = (currentScale - scale).abs() < 0.05;
      return Expanded(
        child: InkWell(
          onTap: () => settings.setFontScale(scale),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
              ),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  style: GoogleFonts.changa(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.ink),
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.tajawal(
                    fontSize: 10,
                    color: isSelected ? Colors.white70 : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _card(
      Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_size_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'حجم خطوط ونصوص التطبيق 🔍',
                  style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'تحكم في حجم الخط لحماية الواجهة ومنع تداخل النصوص عند تكبير خط الهاتف',
              style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                scaleChip('مدمج', 0.85, '85%'),
                const SizedBox(width: 6),
                scaleChip('قياسي', 1.0, '100%'),
                const SizedBox(width: 6),
                scaleChip('مكبّر', 1.12, '112%'),
                const SizedBox(width: 6),
                scaleChip('كبير', 1.22, '122%'),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.preview_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'معاينة: مساعد المعلم يضمن وضوح النصوص وحمايتها من التداخل.',
                      style: GoogleFonts.tajawal(
                        fontSize: 12.5 * currentScale,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      isDark,
    );
  }

  Widget _buildBoldFontTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    return _card(
      Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.format_bold_rounded,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
            title: Text('خط عريض مميز (Bold Font)', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(
              settings.boldFont ? 'مفعل (خط عريض وواضح جداً في كل التطبيق)' : 'قياسي (الخط القياسي المتوازن)',
              style: GoogleFonts.tajawal(
                color: isDark ? AppColors.darkMuted : AppColors.muted,
                fontSize: 12,
              ),
            ),
            value: settings.boldFont,
            activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            onChanged: (val) async {
              await settings.setBoldFont(val);
            },
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_rounded, size: 16, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'معاينة الخط: أهلاً بك يا أستاذنا في مساعد المعلم 🌟',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: settings.boldFont ? FontWeight.w900 : FontWeight.normal,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      isDark,
    );
  }

  Widget _buildSplashThemeTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    final themes = [
      {'value': 'emerald', 'label': 'الزمردي الكلاسيكي', 'desc': 'تدرج زمردي فخم وشعار المدرسة', 'icon': Icons.eco_rounded, 'color': AppColors.primary},
      {'value': 'modern', 'label': 'الحديث المضيء', 'desc': 'أسود ليلي ووهج نيون مستقبلي 🚀', 'icon': Icons.auto_stories_rounded, 'color': const Color(0xFF10B981)},
      {'value': 'gold', 'label': 'الذهبي الملكي', 'desc': 'كحلي داكن مع وسام ذهبي أكاديمي', 'icon': Icons.workspace_premium_rounded, 'color': const Color(0xFFF59E0B)},
      {'value': 'minimal', 'label': 'المبسّط الأنيق', 'desc': 'تصميم بسيط مع اقتباسات تعليمية', 'icon': Icons.school_outlined, 'color': const Color(0xFF38BDF8)},
    ];

    final currentTheme = themes.firstWhere(
      (t) => t['value'] == settings.splashTheme,
      orElse: () => themes[0],
    );

    return _card(
      ListTile(
        leading: Icon(currentTheme['icon'] as IconData, color: currentTheme['color'] as Color),
        title: Text('مظهر شاشة البداية (Splash Screen)', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          currentTheme['label'] as String,
          style: GoogleFonts.tajawal(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down_rounded, size: 24),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('اختر مظهر شاشة البداية', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: themes.map((theme) {
                    final isSelected = settings.splashTheme == theme['value'];
                    final color = theme['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await settings.setSplashTheme(theme['value'] as String);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.border),
                              width: isSelected ? 1.8 : 0.8,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(theme['icon'] as IconData, size: 20, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      theme['label'] as String,
                                      style: GoogleFonts.changa(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? (isDark ? Colors.white : AppColors.ink) : null,
                                      ),
                                    ),
                                    Text(
                                      theme['desc'] as String,
                                      style: GoogleFonts.tajawal(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: color, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
      isDark,
    );
  }

  Widget _buildHomeDesignTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    final isModern = settings.homeDesignStyle == 'modern';
    return _card(
      ListTile(
        leading: const Icon(Icons.dashboard_customize_rounded, color: AppColors.primary),
        title: Text('تصميم الصفحة الرئيسية', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          isModern ? '⚡ النمط العصري المطور (المجموعة التالية + المستطيلات)' : '🏛️ النمط الكلاسيكي التقليدي',
          style: GoogleFonts.tajawal(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down_rounded, size: 24),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('اختر تصميم الصفحة الرئيسية', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in [
                    {'value': 'modern', 'label': '⚡ النمط العصري المطور', 'desc': 'تصميم ذكي وفسيح مع كارت المجموعة التالية ومستطيلات إحصاء الطلاب'},
                    {'value': 'classic', 'label': '🏛️ النمط الكلاسيكي', 'desc': 'التصميم التقليدي السابق لشبكة الإحصاءات والأزرار'},
                  ])
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        settings.setHomeDesignStyle(item['value']!);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              settings.homeDesignStyle == item['value']
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: settings.homeDesignStyle == item['value']
                                  ? AppColors.primary
                                  : AppColors.muted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['label']!,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 13.5,
                                      fontWeight: settings.homeDesignStyle == item['value']
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    item['desc']!,
                                    style: GoogleFonts.tajawal(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      isDark,
    );
  }

  Widget _buildDeveloperOptionsTile(BuildContext context, bool isDark) {
    return _card(
      ListTile(
        leading: const Icon(Icons.developer_mode_rounded, color: Color(0xFFD97706)),
        title: Text(
          'توليد وتجربة بيانات وهمية 🛠️',
          style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'توليد مجموعات وطلاب ودرجات وحصص لاختبار التطبيق كاملاً',
          style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 22),
        onTap: () => _showDeveloperOptionsDialog(isDark),
      ),
      isDark,
    );
  }

  void _showDeveloperOptionsDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(modalCtx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🛠️ خيارات المطور والبيانات التجريبية',
                style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'يمكنك ضخ حزمة بيانات ضخمة وواقعية لاختبار الحضور، الدرجات، الشهادات، والماليات فوراً.',
                style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Button 1: Generate Full Rich Scenario
              AppScaleButton(
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('جارٍ توليد سيناريو تجريبي كامل...', style: GoogleFonts.tajawal()),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  await MockDataGenerator.generateFullScenario();

                  if (!mounted) return;
                  context.read<StudentsProvider>().loadStudents();
                  context.read<GroupsProvider>().loadGroups();
                  context.read<HomeProvider>().loadHomeData();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ تم توليد مجموعات وطلاب وامتحانات وسجلات مالية تجريبية بنجاح!', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D7377), Color(0xFF14FFEC)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'توليد سيناريو بيانات تجريبية كامل 🚀',
                        style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Button 1.5: Generate Notification Test Batch (46 groups every 31m)
              AppScaleButton(
                onTap: () async {
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('جارٍ توليد حزمة اختبار الإشعارات (46 مجموعة متتابعة كل 31 دقيقة)...', style: GoogleFonts.tajawal()),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  final count = await MockDataGenerator.generateNotificationTestBatch(
                    startFromCurrentTime: true,
                    count: 46,
                  );

                  if (!mounted) return;
                  context.read<StudentsProvider>().loadStudents();
                  context.read<GroupsProvider>().loadGroups();
                  context.read<HomeProvider>().loadHomeData();
                  final settings = context.read<SettingsProvider>();
                  final alertsP = context.read<AlertsProvider>();
                  await alertsP.refreshAlerts(settings: settings);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ تم توليد $count مجموعة بنجاح وجدولة إشعاراتها بدقة!', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'حزمة اختبار الإشعارات (46 مجموعة كل 31 د) ⏰',
                        style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Button 2: Clear Notification Test Batch
              OutlinedButton.icon(
                onPressed: () async {
                  final deleted = await MockDataGenerator.clearNotificationTestBatch();
                  if (!mounted) return;
                  context.read<StudentsProvider>().loadStudents();
                  context.read<GroupsProvider>().loadGroups();
                  context.read<HomeProvider>().loadHomeData();
                  final settings = context.read<SettingsProvider>();
                  await context.read<AlertsProvider>().refreshAlerts(settings: settings);

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🧹 تم حذف $deleted مجموعة اختبار بنجاح', style: GoogleFonts.tajawal())),
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.orange, size: 20),
                label: Text(
                  'حذف مجموعات اختبار الإشعارات فقط 🧹',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.orange),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 12),

              // Button 3: Clear All Data
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (dCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Text('مسح كافة البيانات؟', style: GoogleFonts.changa(fontWeight: FontWeight.bold)),
                      content: Text('سيتم مسح جميع الطلاب والمجموعات والحصص المسجلة نهائياً.', style: GoogleFonts.tajawal()),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text('إلغاء', style: GoogleFonts.tajawal())),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: Text('مسح البيانات', style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    await MockDataGenerator.clearAllData();
                    if (!mounted) return;
                    context.read<StudentsProvider>().loadStudents();
                    context.read<GroupsProvider>().loadGroups();
                    context.read<HomeProvider>().loadHomeData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم مسح وتصفير كافة البيانات', style: GoogleFonts.tajawal())),
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.red, size: 20),
                label: Text(
                  'مسح وتصفير كافة البيانات 🧹',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFormatTypeTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    String getLabel() {
      switch (settings.dateFormatType) {
        case 'hijri': return 'تاريخ هجري فقط';
        case 'gregorian': return 'تاريخ ميلادي فقط';
        default: return 'تاريخ هجري وميلادي';
      }
    }
    
    return _card(
      ListTile(
        leading: const Icon(Icons.date_range_rounded, color: AppColors.primary),
        title: Text('تنسيق التاريخ', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          getLabel(),
          style: GoogleFonts.tajawal(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down_rounded, size: 24),
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('تنسيق التاريخ', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in [
                    {'value': 'both', 'label': 'تاريخ هجري وميلادي'},
                    {'value': 'hijri', 'label': 'تاريخ هجري فقط'},
                    {'value': 'gregorian', 'label': 'تاريخ ميلادي فقط'},
                  ])
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        settings.setDateFormatType(item['value']!);
                        Navigator.pop(ctx);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              settings.dateFormatType == item['value']
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: settings.dateFormatType == item['value']
                                  ? AppColors.primary
                                  : AppColors.muted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item['label']!,
                              style: GoogleFonts.tajawal(
                                fontSize: 14,
                                fontWeight: settings.dateFormatType == item['value']
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      isDark,
    );
  }

  Widget _buildTeacherNameTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    return _card(
      ListTile(
        leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
        title: Text('اسم المعلم', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          'أ. ${settings.teacherName}',
          style: GoogleFonts.tajawal(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
        ),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: () => _editTeacherName(context, settings),
      ),
      isDark,
    );
  }

  void _editTeacherName(BuildContext context, SettingsProvider settings) {
    final ctrl = TextEditingController(text: settings.teacherName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل اسم المعلم', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'أدخل اسمك...',
            labelText: 'الاسم',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                settings.setTeacherName(ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherPhoneTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    final phone = settings.teacherPhone.isNotEmpty ? settings.teacherPhone : 'لم يتم تسجيل رقم';
    return _card(
      ListTile(
        leading: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
        title: Text('رقم الهاتف', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          phone,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          style: GoogleFonts.tajawal(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
        ),
        trailing: const Icon(Icons.edit_outlined, size: 18),
        onTap: () => _editTeacherPhone(context, settings),
      ),
      isDark,
    );
  }

  Widget _buildSecuritySection(BuildContext context, LockProvider lockP, bool isDark) {
    return Column(
      children: [
        // Security Overview & Status Card
        _card(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (lockP.isLockEnabled
                                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)))
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            lockP.isLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                            color: lockP.isLockEnabled
                                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                                : (isDark ? AppColors.darkMuted : AppColors.muted),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'قفل التطبيق وحماية البيانات',
                              style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              lockP.isLockEnabled ? 'البيانات محمية برمز PIN / البصمة' : 'التطبيق غير محمي برمز مرور',
                              style: GoogleFonts.tajawal(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkMuted : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: lockP.isLockEnabled
                            ? (isDark ? AppColors.darkGreenSoft : AppColors.chipTeal)
                            : (isDark ? const Color(0xFF263342) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lockP.isLockEnabled ? '🔒 مفعّل' : '🔓 معطّل',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: lockP.isLockEnabled
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : (isDark ? AppColors.darkMuted : AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!lockP.isLockEnabled) ...[
                  const SizedBox(height: 14),
                  Text(
                    'قم بتعيين رمز PIN مكوّن من 4 أرقام لمنع المتطفلين من الاطلاع على درجات الطلاب وسجلات الحضور والمالية، مع إمكانية الفتح ببصمة الإصبع أو Face ID.',
                    style: GoogleFonts.tajawal(fontSize: 12, height: 1.4, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  ),
                  const SizedBox(height: 14),
                  AppScaleButton(
                    onTap: () => _showSetupPinDialog(context, lockP),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_rounded, color: isDark ? AppColors.darkBg : Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'إعداد وتفعيل رمز PIN والبصمة',
                            style: GoogleFonts.changa(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkBg : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          isDark,
        ),

        // Controls when lock is enabled
        if (lockP.isLockEnabled) ...[
          const SizedBox(height: 10),
          _card(
            Column(
              children: [
                // Biometric Toggle Switch
                ListTile(
                  leading: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 24),
                  title: Text(
                    'الفتح ببصمة الإصبع / الوجه',
                    style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'فتح فوري للتطبيق دون الحاجة لكتابة الرمز',
                    style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  ),
                  trailing: Switch(
                    value: lockP.useBiometric,
                    activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    onChanged: (v) => _toggleBiometrics(context, lockP, v),
                  ),
                ),
                const Divider(height: 1),
                // Change PIN
                ListTile(
                  leading: const Icon(Icons.password_rounded, color: AppColors.primary, size: 22),
                  title: Text(
                    'تغيير رمز PIN',
                    style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'تحديث الرمز السري المكوّن من 4 أرقام',
                    style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded, size: 22),
                  onTap: () => _showChangePinDialog(context, lockP),
                ),
                const Divider(height: 1),
                // Disable Lock
                ListTile(
                  leading: const Icon(Icons.lock_open_rounded, color: AppColors.red, size: 22),
                  title: Text(
                    'تعطيل قفل التطبيق',
                    style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.red),
                  ),
                  subtitle: Text(
                    'إلغاء حماية التطبيق بالرمز والبصمة',
                    style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  ),
                  trailing: const Icon(Icons.chevron_left_rounded, size: 22),
                  onTap: () => _showDisableLockDialog(context, lockP),
                ),
              ],
            ),
            isDark,
          ),
        ],
      ],
    );
  }

  Future<void> _toggleBiometrics(BuildContext context, LockProvider lockP, bool enable) async {
    if (enable) {
      final localAuth = LocalAuthentication();
      try {
        final canBio = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
        if (!canBio) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ جهازك لا يدعم التحقق البيومتري أو لم يتم تسجيل بصمة في إعدادات النظام', style: GoogleFonts.tajawal()),
                backgroundColor: AppColors.orange,
              ),
            );
          }
          return;
        }

        final authenticated = await localAuth.authenticate(
          localizedReason: 'التحقق من الهوية لتفعيل الفتح بالبصمة لتطبيق مساعد المعلم',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );

        if (authenticated) {
          await lockP.setBiometric(true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ تم تفعيل الفتح بالبصمة بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ فشل التحقق من البصمة، لم يتم التفعيل', style: GoogleFonts.tajawal()),
                backgroundColor: AppColors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ تعذر تشغيل مستشعر البصمة: $e', style: GoogleFonts.tajawal()),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    } else {
      await lockP.setBiometric(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إيقاف الفتح بالبصمة', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.ink,
          ),
        );
      }
    }
  }

  void _showSetupPinDialog(BuildContext context, LockProvider lockP) async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool enableBiometric = true;
    String? errorText;

    final localAuth = LocalAuthentication();
    bool canBio = false;
    try {
      canBio = await localAuth.canCheckBiometrics || await localAuth.isDeviceSupported();
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('تعيين رمز PIN الجديد', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أدخل رمز PIN مكوّن من 4 أرقام لتأمين بياناتك:',
                  style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.changa(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'رمز PIN الجديد (4 أرقام)',
                    hintText: '••••',
                    prefixIcon: Icon(Icons.pin_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.changa(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'تأكيد رمز PIN',
                    hintText: '••••',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded, color: AppColors.primary),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            errorText!,
                            style: GoogleFonts.tajawal(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (canBio) ...[
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: enableBiometric,
                    onChanged: (v) => setDialogState(() => enableBiometric = v),
                    title: Text('تفعيل البصمة أيضاً', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text('فتح سريع ببصمة الإصبع أو Face ID', style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted)),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final p1 = pinCtrl.text.trim();
                final p2 = confirmCtrl.text.trim();
                if (p1.length != 4) {
                  setDialogState(() => errorText = 'يجب أن يتكون الرمز من 4 أرقام بالضبط');
                  return;
                }
                if (p1 != p2) {
                  setDialogState(() => errorText = 'الرمزان غير متطابقين، تأكد من كتابتهما بشكل صحيح');
                  return;
                }

                await lockP.enableLock(pin: p1, useBiometric: canBio ? enableBiometric : false);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔒 تم تفعيل قفل التطبيق بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              },
              child: const Text('تفعيل القفل'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisableLockDialog(BuildContext context, LockProvider lockP) {
    final pinCtrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.no_encryption_gmailerrorred_rounded, color: AppColors.red, size: 24),
              const SizedBox(width: 8),
              Text('إلغاء قفل التطبيق', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أدخل رمز PIN الحالي للتأكيد وإلغاء حماية التطبيق:',
                style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                obscureText: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.changa(fontSize: 22, letterSpacing: 10, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'رمز PIN الحالي',
                  hintText: '••••',
                  prefixIcon: Icon(Icons.pin_rounded, color: AppColors.primary),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorText!,
                  style: GoogleFonts.tajawal(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final pin = pinCtrl.text.trim();
                if (lockP.currentPin != null && pin != lockP.currentPin) {
                  setDialogState(() => errorText = 'رمز PIN غير صحيح');
                  return;
                }
                await lockP.disableLock();
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🔓 تم إلغاء قفل التطبيق بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.ink,
                    ),
                  );
                }
              },
              child: const Text('إلغاء القفل'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, LockProvider lockP) {
    final oldPinCtrl = TextEditingController();
    final newPinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.password_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('تغيير رمز PIN', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.changa(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'الرمز الحالي',
                    hintText: '••••',
                    prefixIcon: Icon(Icons.lock_clock_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPinCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.changa(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'الرمز الجديد (4 أرقام)',
                    hintText: '••••',
                    prefixIcon: Icon(Icons.pin_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.changa(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'تأكيد الرمز الجديد',
                    hintText: '••••',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded, color: AppColors.primary),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorText!,
                    style: GoogleFonts.tajawal(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final oldP = oldPinCtrl.text.trim();
                final newP = newPinCtrl.text.trim();
                final confP = confirmCtrl.text.trim();

                if (lockP.currentPin != null && oldP != lockP.currentPin) {
                  setDialogState(() => errorText = 'الرمز الحالي غير صحيح');
                  return;
                }
                if (newP.length != 4) {
                  setDialogState(() => errorText = 'الرمز الجديد يجب أن يتكون من 4 أرقام');
                  return;
                }
                if (newP != confP) {
                  setDialogState(() => errorText = 'الرمز الجديد وتأكيده غير متطابقين');
                  return;
                }

                await lockP.updatePin(newP);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ تم تحديث رمز PIN بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                      backgroundColor: AppColors.green,
                    ),
                  );
                }
              },
              child: const Text('حفظ الرمز'),
            ),
          ],
        ),
      ),
    );
  }

  void _editTeacherPhone(BuildContext context, SettingsProvider settings) {
    final ctrl = TextEditingController(text: settings.teacherPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تعديل رقم الهاتف', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            hintText: '010XXXXXXXX',
            labelText: 'رقم الهاتف',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setTeacherPhone(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherSubjectsTile(
      BuildContext context, SettingsProvider settings, bool isDark) {
    return _card(
      ListTile(
        leading: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
        title: Text('المواد الدراسية الخاصة بي', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(
          settings.mySubjects.join(' · '),
          style: GoogleFonts.tajawal(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.add_rounded, size: 20),
        onTap: () => _addSubjectDialog(context, settings),
      ),
      isDark,
    );
  }

  void _addSubjectDialog(BuildContext context, SettingsProvider settings) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إضافة مادة دراسية جديدة', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'اسم المادة (مثال: جيولوجيا)',
            labelText: 'المادة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                settings.addSubject(ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupTile(BuildContext context, bool isDark) {
    return _card(
      ListTile(
        leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
        title: Text('نسخ احتياطي للبيانات', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text('حفظ نسخة كاملة في ذاكرة الهاتف بصيغة JSON ومشاركتها', style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted)),
        trailing: const Icon(Icons.save_alt_rounded, size: 20),
        onTap: () => _backup(context),
      ),
      isDark,
    );
  }

  Widget _buildRestoreTile(BuildContext context, bool isDark) {
    return _card(
      ListTile(
        leading: const Icon(Icons.cloud_download_outlined, color: AppColors.primary),
        title: Text('استعادة البيانات', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text('استيراد البيانات من ملف نسخ احتياطي سابق', style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted)),
        trailing: const Icon(Icons.file_open_outlined, size: 20),
        onTap: () => _restore(context),
      ),
      isDark,
    );
  }

  Widget _buildTrashTile(BuildContext context, bool isDark) {
    return _card(
      ListTile(
        leading: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
        title: Text('سلة المهملات', style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text('العناصر والمجموعات المحذوفة مؤخراً', style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen())),
      ),
      isDark,
    );
  }

  Widget _buildAboutTile(BuildContext context, SettingsProvider settings, bool isDark) {
    return _card(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Text(
                  'مساعد المعلم — الإصدار المميز',
                  style: GoogleFonts.changa(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'نظام إدارة متكامل وشامل للمعلمين مصمم لدعم وتيسير إدارة الحصص، رصد الحضور، متابعة الدرجات، والماليات بأعلى كفاءة وبشكل أوفلاين 100%.',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                height: 1.5,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
      isDark,
    );
  }

  Future<Directory> _getBackupDirectory() async {
    if (Platform.isAndroid) {
      try {
        final publicDownloadDir = Directory('/storage/emulated/0/Download/TeacherAssistant_Backups');
        if (!await publicDownloadDir.exists()) {
          await publicDownloadDir.create(recursive: true);
        }
        return publicDownloadDir;
      } catch (_) {}

      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final backupFolder = Directory('${extDir.path}/Backups');
          if (!await backupFolder.exists()) {
            await backupFolder.create(recursive: true);
          }
          return backupFolder;
        }
      } catch (_) {}
    }

    final docDir = await getApplicationDocumentsDirectory();
    final backupFolder = Directory('${docDir.path}/Backups');
    if (!await backupFolder.exists()) {
      await backupFolder.create(recursive: true);
    }
    return backupFolder;
  }

  Future<void> _backup(BuildContext context) async {
    try {
      final db = DatabaseHelper();
      final data = <String, dynamic>{
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'groups': await db.query(AppConstants.tableGroups),
        'students': await db.query(AppConstants.tableStudents),
        'attendance': await db.query(AppConstants.tableAttendance),
        'exams': await db.query(AppConstants.tableExams),
        'exam_results': await db.query(AppConstants.tableExamResults),
        'payments': await db.query(AppConstants.tablePayments),
        'notes': await db.query(AppConstants.tableNotes),
      };

      final jsonStr = jsonEncode(data);
      final backupDir = await _getBackupDirectory();
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'teacher_assistant_backup_$dateStr.json';
      final file = File('${backupDir.path}/$fileName');
      await file.writeAsString(jsonStr);

      final fileSizeKb = (await file.length()) / 1024;

      if (!context.mounted) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تم الحفظ في الهاتف بنجاح 💾',
                          style: GoogleFonts.changa(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                        Text(
                          'تم إنشاء النسخة الاحتياطية وتخزينها في جهازك',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: isDark ? AppColors.darkMuted : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            fileName,
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${fileSizeKb.toStringAsFixed(1)} KB',
                            style: GoogleFonts.tajawal(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📂 مسار المجلد:',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SelectableText(
                      file.path,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text('حسناً', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(file.path)],
                            text: 'نسخة احتياطية لتطبيق مساعد المعلم - $dateStr',
                          ),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text('مشاركة أو إرسال 📤', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل النسخ الاحتياطي: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      if (!context.mounted) return;

      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'استعادة البيانات',
        message: 'سيتم استبدال البيانات الحالية بالبيانات المستوردة. هل تريد المتابعة؟',
        confirmLabel: 'استعادة',
        danger: true,
      );

      if (confirmed != true) return;

      final db = DatabaseHelper();
      await db.importAll(data);

      if (context.mounted) {
        context.read<GroupsProvider>().loadGroups();
        context.read<StudentsProvider>().loadStudents();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تمت استعادة البيانات بنجاح', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل استعادة البيانات: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }
}


