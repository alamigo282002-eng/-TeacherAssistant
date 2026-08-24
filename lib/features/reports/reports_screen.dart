import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../core/widgets/pdf_viewer_screen.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';
import '../certificates/certificate_editor_screen.dart';
import '../certificates/certificates_screen.dart';
import '../exams/add_edit_exam_screen.dart';
import '../exams/exam_marks_screen.dart';
import '../finance/finance_screen.dart';
import '../news/news_screen.dart';
import '../notes/notes_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/trash_screen.dart';
import '../settings/whatsapp_templates_screen.dart';
import '../students/student_detail_screen.dart';
import 'activity_logs_screen.dart';
import 'alerts_screen.dart';
import 'reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().loadReportsData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    context.read<ReportsProvider>().loadReportsData();
  }

  Future<void> _openReport(String title, Widget content, bool isDark) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkCard : AppColors.primary,
            foregroundColor: Colors.white,
            title: Text(title, style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          body: content,
        ),
      ),
    );
    if (!mounted) return;
    context.read<ReportsProvider>().loadReportsData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportsP = context.watch<ReportsProvider>();

    final List<Map<String, dynamic>> items = [
      {
        'id': 'pdf_viewer',
        'title': 'مستعرض وقارئ الـ PDF 📄',
        'badge': 'عارض ملفات',
        'line1': 'فتح وتصفح أي ملف PDF من الهاتف',
        'line2': 'تقارير، مذكرات، وطباعة فورية',
        'icon': Icons.picture_as_pdf_rounded,
        'accentColor': const Color(0xFFEA580C),
        'bgGradient': isDark
            ? [const Color(0xFF431407), const Color(0xFF7C2D12)]
            : [const Color(0xFFFFEDD5), const Color(0xFFFED7AA)],
        'onTap': () => _navigateAndRefresh(const PdfViewerScreen()),
      },
      {
        'id': 'activity_logs',
        'title': 'سجل العمليات والنشاطات 📋',
        'badge': 'سجل فوري',
        'line1': 'تتبع إضافة الطلاب، الغياب والماليات',
        'line2': 'سجل زمني لجميع عمليات النظام',
        'icon': Icons.history_edu_rounded,
        'accentColor': const Color(0xFF6366F1),
        'bgGradient': isDark
            ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
            : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
        'onTap': () => _navigateAndRefresh(const ActivityLogsScreen()),
      },
      {
        'id': 'certificates',
        'title': 'شهادات التقدير 🎓',
        'badge': 'تكريم رسمي',
        'line1': 'نماذج HD وتصميم مخصص',
        'line2': 'تكريم الطلاب المتفوقين',
        'icon': Icons.workspace_premium_rounded,
        'accentColor': const Color(0xFFD97706),
        'bgGradient': isDark
            ? [const Color(0xFF2E1A04), const Color(0xFF4D2C08)]
            : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
        'onTap': () => _navigateAndRefresh(const CertificatesScreen()),
      },
      {
        'id': 'leaderboard',
        'title': 'لوحة الشرف والمتفوقين ⭐',
        'badge': 'الأوائل',
        'line1': 'النقاط: ${ArabicNumbers.convert(reportsP.totalPointsCount)} ⭐',
        'line2': 'ترتيب المتفوقين ومكافآت',
        'icon': Icons.emoji_events_rounded,
        'accentColor': const Color(0xFF0D9488),
        'bgGradient': isDark
            ? [const Color(0xFF042F2E), const Color(0xFF115E59)]
            : [const Color(0xFFCCFBF1), const Color(0xFF99F6E4)],
        'onTap': () => _openReport(
          'لوحة الشرف والمتفوقين ⭐',
          _buildLeaderboardTab(isDark, reportsP.groups, reportsP.leaderboard),
          isDark,
        ),
      },
      {
        'id': 'finance',
        'title': 'الماليات والاشتراكات 💰',
        'badge': 'متابعة شهرية',
        'line1': 'المجموعات: ${ArabicNumbers.convert(reportsP.totalGroupsCount)}',
        'line2': 'الرسوم والمستحقات والـ PDF',
        'icon': Icons.account_balance_wallet_rounded,
        'accentColor': AppColors.forestGreen,
        'bgGradient': isDark
            ? [const Color(0xFF022B22), const Color(0xFF275D46)]
            : [const Color(0xFFE2F0E8), const Color(0xFFC7E5D6)],
        'onTap': () => _navigateAndRefresh(const FinanceScreen()),
      },
      {
        'id': 'exams',
        'title': 'سجل الاختبارات والتقييم 📊',
        'badge': 'درجات وتقييم',
        'line1': 'الاختبارات: ${ArabicNumbers.convert(reportsP.exams.length)}',
        'line2': 'رصد الدرجات وإحصائيات',
        'icon': Icons.quiz_rounded,
        'accentColor': const Color(0xFF2563EB),
        'bgGradient': isDark
            ? [const Color(0xFF172554), const Color(0xFF1E40AF)]
            : [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)],
        'onTap': () => _openReport(
          'سجل الاختبارات والنتائج',
          _buildExamsTab(isDark, reportsP.groups, reportsP.exams),
          isDark,
        ),
      },
      {
        'id': 'notes',
        'title': 'دفتر الملاحظات والتنبيهات 📝',
        'badge': 'ملاحظات',
        'line1': 'ملاحظات وتذكيرات هامة',
        'line2': 'حصص، واجبات، وأفكار',
        'icon': Icons.menu_book_rounded,
        'accentColor': const Color(0xFF0284C7),
        'bgGradient': isDark
            ? [const Color(0xFF082F49), const Color(0xFF0369A1)]
            : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        'onTap': () => _navigateAndRefresh(const NotesScreen()),
      },
      {
        'id': 'alerts',
        'title': 'مركز التنبيهات والإشعارات 🔔',
        'badge': 'تنبيهات فورية',
        'line1': 'المواعيد: نشطة',
        'line2': 'تنبيهات الحصص والغياب',
        'icon': Icons.notifications_active_rounded,
        'accentColor': const Color(0xFFE11D48),
        'bgGradient': isDark
            ? [const Color(0xFF4C0519), const Color(0xFF9F1239)]
            : [const Color(0xFFFFE4E6), const Color(0xFFFECDD3)],
        'onTap': () => _navigateAndRefresh(const AlertsScreen()),
      },
      {
        'id': 'whatsapp',
        'title': 'قوالب رسائل الواتساب 💬',
        'badge': 'رسائل سريعة',
        'line1': 'قوالب أولياء الأمور',
        'line2': 'غياب، درجات، واشتراكات',
        'icon': Icons.forum_rounded,
        'accentColor': const Color(0xFF16A34A),
        'bgGradient': isDark
            ? [const Color(0xFF052E16), const Color(0xFF166534)]
            : [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)],
        'onTap': () => _navigateAndRefresh(const WhatsAppTemplatesScreen()),
      },
      {
        'id': 'trash',
        'title': 'سلة المحذوفات والأمان 🗑️',
        'badge': 'استرجاع فوري',
        'line1': 'العناصر المحذوفة',
        'line2': 'حماية من الحذف بالخطأ',
        'icon': Icons.delete_outline_rounded,
        'accentColor': const Color(0xFFDC2626),
        'bgGradient': isDark
            ? [const Color(0xFF450A0A), const Color(0xFF991B1B)]
            : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)],
        'onTap': () => _navigateAndRefresh(const TrashScreen()),
      },
      {
        'id': 'news',
        'title': 'أخبار التعليم والوزارة 📰',
        'badge': 'تحديثات حية',
        'line1': 'قرارات رسمية وجداول',
        'line2': 'المناهج وإعلانات المعلم',
        'icon': Icons.newspaper_rounded,
        'accentColor': const Color(0xFF1E40AF),
        'bgGradient': isDark
            ? [const Color(0xFF172554), const Color(0xFF1E40AF)]
            : [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)],
        'onTap': () => _navigateAndRefresh(const NewsScreen()),
      },
      {
        'id': 'settings',
        'title': 'الإعدادات العامة ⚙️',
        'badge': 'النظام',
        'line1': 'النسخ الاحتياطي والأمان',
        'line2': 'تخصيص المظهر والحساب',
        'icon': Icons.settings_rounded,
        'accentColor': const Color(0xFF475569),
        'bgGradient': isDark
            ? [const Color(0xFF0F172A), const Color(0xFF334155)]
            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
        'onTap': () => _navigateAndRefresh(const SettingsScreen()),
      },
    ];

    final filteredItems = items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final title = (item['title'] as String).toLowerCase();
      final line1 = (item['line1'] as String).toLowerCase();
      final line2 = (item['line2'] as String).toLowerCase();
      return title.contains(q) || line1.contains(q) || line2.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.chipTeal,
                        child: Icon(Icons.grid_view_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'المزيد والخدمات (Services)',
                        style: GoogleFonts.changa(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: isDark ? AppColors.darkMuted : AppColors.muted),
                        onPressed: () => _navigateAndRefresh(const AlertsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.tajawal(color: isDark ? Colors.white : AppColors.ink, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'البحث في الخدمات والأقسام...',
                        hintStyle: GoogleFonts.tajawal(color: isDark ? AppColors.darkMuted : AppColors.muted, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: isDark ? AppColors.darkMuted : AppColors.muted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    ),
                  ),
                ],
              ),
            ),

            // 2-Column Grid View
            Expanded(
              child: reportsP.loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد خدمات مطابقة لبحثك',
                            style: GoogleFonts.tajawal(color: isDark ? AppColors.darkMuted : AppColors.muted, fontSize: 14),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.94,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return _buildServiceCard(
                              title: item['title'],
                              badge: item['badge'],
                              line1: item['line1'],
                              line2: item['line2'],
                              icon: item['icon'],
                              accentColor: item['accentColor'],
                              bgGradient: item['bgGradient'],
                              isDark: isDark,
                              onTap: item['onTap'],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String badge,
    required String line1,
    required String line2,
    required IconData icon,
    required Color accentColor,
    required List<Color> bgGradient,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AppScaleButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upper Section: Header with Badge & Icon Box
            Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: bgGradient,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Stack(
                children: [
                  // Corner Badge
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12, width: 0.8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.tajawal(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  ),

                  // Icon Box
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Lower Section: Title + 2 Lines of info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.changa(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkText : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      line1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      line2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.tajawal(
                        fontSize: 10,
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
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

  // =============================================================
  // EXAMS TAB
  // =============================================================
  Widget _buildExamsTab(bool isDark, List<GroupModel> groups, List<ExamModel> exams) {
    final groupMap = {for (final g in groups) g.id: g};

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(const AddEditExamScreen()),
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        foregroundColor: isDark ? AppColors.darkBg : Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'إنشاء اختبار جديد',
          style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: exams.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 56, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  const SizedBox(height: 12),
                  Text('لا توجد اختبارات مسجلة', style: GoogleFonts.changa(fontSize: 16, color: isDark ? AppColors.darkMuted : AppColors.muted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: exams.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final exam = exams[idx];
                final group = groupMap[exam.groupId];
                final dateStr = DateFormat('yyyy/MM/dd').format(exam.date);

                return AppScaleButton(
                  onTap: () => _navigateAndRefresh(ExamMarksScreen(exam: exam)),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exam.name,
                              style: GoogleFonts.changa(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkText : AppColors.ink,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'الدرجة: ${ArabicNumbers.convert(exam.totalMarks.round())}',
                                style: GoogleFonts.changa(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text('مجموعة: ${group?.name ?? "-"}', style: GoogleFonts.tajawal(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.muted)),
                            if (group?.subject != null) ...[
                              const SizedBox(width: 8),
                              Text('📖 ${group!.subject!}', style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkPrimary : AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                            const Spacer(),
                            Text(ArabicNumbers.convert(dateStr), style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'رصد الدرجات وإرسال النتائج ➔',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // =============================================================
  // LEADERBOARD TAB
  // =============================================================
  Widget _buildLeaderboardTab(bool isDark, List<GroupModel> groups, List<StudentModel> leaderboard) {
    if (leaderboard.isEmpty) {
      return Center(
        child: Text('لا توجد بيانات متفوقين بعد', style: GoogleFonts.changa(fontSize: 16, color: isDark ? AppColors.darkMuted : AppColors.muted)),
      );
    }

    final groupMap = {for (final g in groups) g.id: g.name};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Reset Points Banner Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'إدارة نقاط الطلاب',
                      style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.ink),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _confirmResetAllPoints(context, isDark),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.red),
                  label: Text('تصفير النقاط', style: GoogleFonts.tajawal(color: AppColors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.red.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          if (leaderboard.length >= 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPodiumSpot(
                    student: leaderboard[1],
                    medal: '🥈',
                    rank: 2,
                    height: 130,
                    color: const Color(0xFF94A3B8),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildPodiumSpot(
                    student: leaderboard[0],
                    medal: '🥇',
                    rank: 1,
                    height: 160,
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildPodiumSpot(
                    student: leaderboard[2],
                    medal: '🥉',
                    rank: 3,
                    height: 110,
                    color: const Color(0xFFB45309),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaderboard.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (itemCtx, idx) {
              final student = leaderboard[idx];
              final rank = idx + 1;
              final groupName = groupMap[student.groupId] ?? '';

              return AppScaleButton(
                onTap: () {
                  Navigator.push(
                    itemCtx,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailScreen(studentId: student.id),
                    ),
                  ).then((_) {
                    if (mounted) context.read<ReportsProvider>().loadReportsData();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? const Color(0xFFF59E0B)
                              : (rank == 2 ? const Color(0xFF94A3B8) : (rank == 3 ? const Color(0xFFB45309) : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)))),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            ArabicNumbers.convert(rank),
                            style: GoogleFonts.changa(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: rank <= 3 ? Colors.white : (isDark ? AppColors.darkText : AppColors.ink),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    student.name,
                                    style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.ink),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.muted),
                              ],
                            ),
                            Text('مجموعة: $groupName', style: GoogleFonts.tajawal(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⭐ ${ArabicNumbers.convert(student.points)} نقطة',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 22),
                        tooltip: 'إصدار شهادة تقدير 🎓',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CertificateEditorScreen(
                                initialStudent: student,
                                initialReason: 'التفوق في نقاط المشاركة والالتزام',
                                initialRank: 'المركز #${ArabicNumbers.convert(rank)}',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSpot({
    required StudentModel student,
    required String medal,
    required int rank,
    required double height,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: AppScaleButton(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: student.id),
            ),
          ).then((_) {
            if (mounted) context.read<ReportsProvider>().loadReportsData();
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(medal, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              student.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.changa(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.ink),
            ),
            const SizedBox(height: 4),
            Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withValues(alpha: 0.5)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${ArabicNumbers.convert(rank)}',
                      style: GoogleFonts.changa(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '${ArabicNumbers.convert(student.points)} نقطة',
                      style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'عرض الملف ➔',
                      style: GoogleFonts.tajawal(fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold),
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

  void _confirmResetAllPoints(BuildContext ctx, bool isDark) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تصفير نقاط جميع الطلاب',
          style: GoogleFonts.changa(fontWeight: FontWeight.bold, color: isDark ? AppColors.darkText : AppColors.ink),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في إعادة ضبط نقاط جميع الطلاب إلى ٠؟ لا يمكن التراجع عن هذه الخطوة.',
          style: GoogleFonts.tajawal(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('إلغاء', style: GoogleFonts.tajawal(color: isDark ? AppColors.darkMuted : AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              final success = await context.read<ReportsProvider>().resetAllPoints();
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم تصفير نقاط جميع الطلاب بنجاح ✅', style: GoogleFonts.tajawal()),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: Text('تصفير الآن', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

