import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/news_item_model.dart';
import 'news_provider.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItemModel news;

  const NewsDetailScreen({super.key, required this.news});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'ministry': return const Color(0xFF1E40AF); // Blue
      case 'exams': return const Color(0xFFD97706); // Amber
      case 'curriculum': return const Color(0xFF059669); // Emerald
      case 'announcements': return const Color(0xFF7C3AED); // Purple
      case 'tips': return const Color(0xFFEA580C); // Orange
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(news.category);
    final dateStr = DateFormat('EEEE، d MMMM yyyy - hh:mm a', 'ar').format(news.publishedAt);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          news.newsCategory.label,
          style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'مشاركة عبر واتساب',
            onPressed: () => context.read<NewsProvider>().shareNewsOnWhatsApp(news),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge and Urgent Tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: catColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    news.newsCategory.label,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                ),
                if (news.isUrgent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'عاجل 🚨',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  news.source,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Title
            Text(
              news.title,
              style: GoogleFonts.changa(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),

            // Date & Metadata row
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: isDark ? AppColors.darkMuted : AppColors.muted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    dateStr,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Summary Card
            if (news.summary.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        news.summary,
                        style: GoogleFonts.tajawal(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          height: 1.45,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Content Body
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                news.content,
                style: GoogleFonts.tajawal(
                  fontSize: 14.5,
                  height: 1.7,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            if (news.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: news.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // 1. Open in Browser Button (if source link exists)
            if (news.externalUrl != null && news.externalUrl!.isNotEmpty) ...[
              AppScaleButton(
                onTap: () async {
                  try {
                    final uri = Uri.parse(news.externalUrl!);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    debugPrint('Error launching url: $e');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.open_in_browser_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'قراءة التغطية الكاملة من المصدر الأصلي 🌐',
                        style: GoogleFonts.changa(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 2. WhatsApp Share Action Button
            AppScaleButton(
              onTap: () => context.read<NewsProvider>().shareNewsOnWhatsApp(news),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25D366).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'مشاركة الخبر مع الطلاب عبر واتساب 📲',
                      style: GoogleFonts.changa(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
  }
}
