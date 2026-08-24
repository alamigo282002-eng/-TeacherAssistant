import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../data/models/activity_log_model.dart';
import 'activity_log_provider.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'label': 'الكل', 'icon': Icons.list_alt_rounded},
    {'id': 'student', 'label': '👨‍🎓 الطلاب', 'icon': Icons.person_rounded},
    {'id': 'attendance', 'label': '📋 الحضور والغياب', 'icon': Icons.fact_check_rounded},
    {'id': 'group', 'label': '👥 المجموعات', 'icon': Icons.groups_rounded},
    {'id': 'payment', 'label': '💰 الماليات', 'icon': Icons.account_balance_wallet_rounded},
    {'id': 'exam', 'label': '📝 الاختبارات', 'icon': Icons.quiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityLogProvider>().loadLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmClearLogs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: AppColors.red, size: 24),
            const SizedBox(width: 8),
            Text('مسح سجل النشاطات', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من مسح جميع السجلات التاريخية للعمليات؟ لا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.tajawal(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final logProvider = context.read<ActivityLogProvider>();
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              await logProvider.clearAll();
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('✅ تم مسح السجلات بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: Text('مسح الكل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAction(String action) {
    if (action.startsWith('student_add')) return Icons.person_add_alt_1_rounded;
    if (action.startsWith('student_edit')) return Icons.edit_note_rounded;
    if (action.startsWith('student_delete')) return Icons.person_remove_rounded;
    if (action.startsWith('student_')) return Icons.person_rounded;
    if (action.startsWith('attendance_')) return Icons.fact_check_rounded;
    if (action.startsWith('group_add')) return Icons.group_add_rounded;
    if (action.startsWith('group_edit')) return Icons.groups_rounded;
    if (action.startsWith('group_delete')) return Icons.delete_outline_rounded;
    if (action.startsWith('group_')) return Icons.groups_rounded;
    if (action.startsWith('payment_')) return Icons.account_balance_wallet_rounded;
    if (action.startsWith('exam_')) return Icons.quiz_rounded;
    return Icons.history_rounded;
  }

  Color _getColorForAction(String action, bool isDark) {
    if (action.startsWith('student_add')) return const Color(0xFF10B981);
    if (action.startsWith('student_delete')) return const Color(0xFFEF4444);
    if (action.startsWith('student_')) return isDark ? AppColors.darkPrimary : AppColors.primary;
    if (action.startsWith('attendance_')) return const Color(0xFF0D9488);
    if (action.startsWith('group_add')) return const Color(0xFF3B82F6);
    if (action.startsWith('group_delete')) return const Color(0xFFDC2626);
    if (action.startsWith('group_')) return const Color(0xFF2563EB);
    if (action.startsWith('payment_')) return const Color(0xFFF59E0B);
    if (action.startsWith('exam_')) return const Color(0xFF8B5CF6);
    return isDark ? AppColors.darkPrimary : AppColors.primary;
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${ArabicNumbers.convert(diff.inMinutes)} دقيقة';
    if (diff.inHours < 24) return 'منذ ${ArabicNumbers.convert(diff.inHours)} ساعة';
    if (diff.inDays == 1) return 'أمس ${DateFormat('hh:mm a', 'ar').format(dt)}';
    if (diff.inDays < 7) return 'منذ ${ArabicNumbers.convert(diff.inDays)} أيام';
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logP = context.watch<ActivityLogProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'سجل العمليات والنشاطات 📋',
          style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (logP.logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'مسح السجلات',
              onPressed: () => _confirmClearLogs(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (v) => logP.setSearch(v),
                  style: GoogleFonts.tajawal(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'بحث في السجلات (اسم الطالب، المجموعة، العملية)...',
                    hintStyle: GoogleFonts.tajawal(fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              logP.setSearch('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),

                // Category Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 6),
                    itemBuilder: (ctx, idx) {
                      final cat = _categories[idx];
                      final isSelected = logP.selectedCategory == cat['id'];
                      final primaryCol = isDark ? AppColors.darkPrimary : AppColors.primary;

                      return GestureDetector(
                        onTap: () => logP.setCategory(cat['id'] as String),
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
                              cat['label'] as String,
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
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
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: logP.loading
                ? const Center(child: CircularProgressIndicator())
                : logP.logs.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: () => logP.loadLogs(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: logP.logs.length,
                          itemBuilder: (ctx, index) {
                            final log = logP.logs[index];
                            return _buildLogItemCard(log, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.12),
              child: Icon(
                Icons.history_rounded,
                size: 38,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد سجلات حالياً',
              style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'سيتم تسجيل وتوثيق أي عملية تجريها في التطبيق (إضافة طلاب، رصد حضور، إنشاء مجموعات، ماليات) تلقائياً هنا.',
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(fontSize: 12.5, color: isDark ? AppColors.darkMuted : AppColors.muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItemCard(ActivityLogModel log, bool isDark) {
    final icon = _getIconForAction(log.actionType);
    final color = _getColorForAction(log.actionType, isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        log.title,
                        style: GoogleFonts.changa(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      _formatRelativeTime(log.createdAt),
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log.description,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
