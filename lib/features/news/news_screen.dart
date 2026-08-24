import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/news_item_model.dart';
import '../settings/settings_provider.dart';
import 'news_detail_screen.dart';
import 'news_provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'الكل 📰'},
    {'id': 'ministry', 'label': '🏛️ قرارات الوزارة'},
    {'id': 'exams', 'label': '📝 الامتحانات والتقييم'},
    {'id': 'curriculum', 'label': '📚 المناهج والتوزيع'},
    {'id': 'announcements', 'label': '📢 إعلاناتي'},
    {'id': 'tips', 'label': '💡 نصائح تربوية'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().loadNews();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  String _formatRelativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} ساعة';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} أيام';
    }
    return DateFormat('d MMMM yyyy', 'ar').format(dt);
  }

  void _showAddAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    bool isUrgent = false;
    final settings = context.read<SettingsProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Color(0xFF7C3AED), size: 22),
                ),
                const SizedBox(width: 10),
                Text(
                  'نشر إعلان جديد للطلاب 📢',
                  style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleCtrl,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'عنوان الإعلان أو التنبيه',
                      hintText: 'مثال: موعد مراجعة الفصل الأول لطلاب السنتر',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'تفاصيل الإعلان',
                      hintText: 'اكتب نص الإعلان والتعليمات الموجهة للطلاب أو أولياء الأمور...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تمييز كإعلان هام / عاجل 🚨',
                        style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Switch(
                        value: isUrgent,
                        activeThumbColor: AppColors.red,
                        onChanged: (v) => setDialogState(() => isUrgent = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text('نشر ومشاركة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final content = contentCtrl.text.trim();
                  if (title.isEmpty || content.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('يرجى ملء العنوان وتفاصيل الإعلان', style: GoogleFonts.tajawal())),
                    );
                    return;
                  }

                  await context.read<NewsProvider>().addAnnouncement(
                    title: title,
                    content: content,
                    teacherName: settings.teacherName,
                    isUrgent: isUrgent,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ تم نشر الإعلان بنجاح في قسم الأخبار', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.green,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newsP = context.watch<NewsProvider>();
    final newsList = newsP.filteredNews;
    final urgentList = newsP.urgentNews;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'أخبار التعليم والوزارة 📰',
          style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: newsP.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'مزامنة وتحديث حي من الإنترنت',
            onPressed: () async {
              final newCount = await newsP.syncFromInternet();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      newCount > 0
                          ? '🌐 تم جلب $newCount خبر وقرار جديد من الإنترنت بنجاح!'
                          : '✅ الأخبار محدثة إلى آخر لحظة',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAnnouncementDialog,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(
          'إضافة إعلان 📢',
          style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => newsP.syncFromInternet(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            // Live Internet Sync Banner
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withValues(alpha: isDark ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_rounded, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      newsP.isSyncing
                          ? 'جاري سحب آخر الأخبار والقرارات من الإنترنت مباشرة... 🔄'
                          : 'الموجز الإخباري متصل بالإنترنت ويعمل أوفلاين أيضاً 🌐',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                  if (newsP.isSyncing)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                    ),
                ],
              ),
            ),

            // 1. Search Bar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                onChanged: (v) => newsP.setSearchQuery(v),
                decoration: InputDecoration(
                  hintText: 'ابحث في أخبار الوزارة والقرارات والمناهج...',
                  hintStyle: GoogleFonts.tajawal(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            newsP.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Category Filter Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (ctx, idx) {
                  final cat = _categories[idx];
                  final isSelected = newsP.selectedCategory == cat['id'];
                  final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

                  return GestureDetector(
                    onTap: () => newsP.setCategory(cat['id']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryCol
                            : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? primaryCol
                              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat['label']!,
                          style: GoogleFonts.tajawal(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? AppColors.darkBg : Colors.white)
                                : (isDark ? Colors.white70 : AppColors.ink),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // 3. Urgent / Breaking News Hero Banner
            if (urgentList.isNotEmpty && newsP.searchQuery.isEmpty && newsP.selectedCategory == 'all') ...[
              _buildUrgentNewsCarousel(urgentList.first, isDark),
              const SizedBox(height: 16),
            ],

            // 4. News List
            if (newsP.loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (newsList.isEmpty)
              _buildEmptyNewsState(isDark)
            else
              ...newsList.map((item) => _buildNewsCard(item, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentNewsCarousel(NewsItemModel item, bool isDark) {
    return AppScaleButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(news: item)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF991B1B), Color(0xFFB91C1C)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB91C1C).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFFB91C1C), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'عاجل وهام 🚨',
                        style: GoogleFonts.changa(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  item.source,
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: GoogleFonts.changa(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                height: 1.35,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              item.summary,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatRelativeDate(item.publishedAt),
                  style: GoogleFonts.tajawal(fontSize: 11, color: Colors.white70),
                ),
                Row(
                  children: [
                    Text(
                      'قراءة التفاصيل كاملة',
                      style: GoogleFonts.tajawal(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsItemModel item, bool isDark) {
    final catColor = _getCategoryColor(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewsDetailScreen(news: item)),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag & Source
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.newsCategory.label,
                      style: GoogleFonts.tajawal(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                    ),
                  ),
                  if (item.isUrgent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'عاجل',
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatRelativeDate(item.publishedAt),
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: isDark ? AppColors.darkMuted : AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                item.title,
                style: GoogleFonts.changa(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),

              // Summary
              Text(
                item.summary,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Footer Actions
              Row(
                children: [
                  Icon(Icons.account_balance_outlined, size: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.source,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF25D366)),
                    tooltip: 'مشاركة على واتساب',
                    onPressed: () => context.read<NewsProvider>().shareNewsOnWhatsApp(item),
                  ),
                  if (item.category == 'announcements')
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red),
                      tooltip: 'حذف الإعلان',
                      onPressed: () => context.read<NewsProvider>().deleteNewsItem(item.id),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyNewsState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.newspaper_rounded, size: 48, color: isDark ? AppColors.darkMuted : AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'لا توجد أخبار تطابق البحث',
              style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
