import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../../../data/models/group_model.dart';

class WhatsAppQrDialog extends StatelessWidget {
  final GroupModel group;

  const WhatsAppQrDialog({super.key, required this.group});

  static void show(BuildContext context, GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WhatsAppQrDialog(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final link = group.whatsappLink ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : const Color(0xFFD0D7D9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE7F8EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF25D366), size: 26),
              ),
              const SizedBox(width: 10),
              Text(
                'رمز QR لجروب الواتساب',
                style: GoogleFonts.changa(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            group.name,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // QR Box Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: link.isNotEmpty
                ? QrImageView(
                    data: link,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0D6E6E),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Color(0xFF1E293B),
                    ),
                  )
                : Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    child: Text(
                      'لا يوجد رابط واتساب مسجل للمجموعة',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
          ),

          const SizedBox(height: 14),

          Text(
            'وجّه كاميرا هاتف الطالب أو ولي الأمر لمسح الكود والانضمام فوراً',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
          ),

          const SizedBox(height: 20),

          // Actions Row: Share + Open in WhatsApp
          Row(
            children: [
              Expanded(
                child: AppScaleButton(
                  onTap: () async {
                    if (link.isNotEmpty) {
                      await SharePlus.instance.share(
                        ShareParams(
                          text: '📌 رابط الانضمام لجروب ${group.name} على واتساب:\n$link',
                          subject: 'جروب واتساب ${group.name}',
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('يرجى إضافة رابط الواتساب أولاً', style: GoogleFonts.tajawal())),
                      );
                    }
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.chipTeal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.share_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'مشاركة الرابط',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppScaleButton(
                  onTap: () async {
                    if (link.isNotEmpty) {
                      final uri = Uri.parse(link);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'فتح في واتساب',
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

