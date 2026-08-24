import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/finance_pdf_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/pdf_viewer_screen.dart';
import '../../core/widgets/shared_widgets.dart';
import '../settings/settings_provider.dart';
import 'discounts_list_screen.dart';
import 'finance_provider.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with AutomaticKeepAliveClientMixin {
  final Set<String> _expandedGroups = {};
  String _selectedTab = 'all'; // 'all', 'unpaid', 'paid', 'discounts'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _exporting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<FinanceProvider>().loadForMonth(now.month, now.year);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<FinanceProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter summaries based on tab and search
    final summaries = _getFilteredSummaries(provider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'المالية والاشتراكات 💰',
          style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Export PDF
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'تصدير PDF ومشاركة',
            onPressed: _exporting ? null : () => _exportToPdf(provider),
          ),
          // Discounts Screen
          IconButton(
            icon: const Icon(Icons.discount_outlined, color: Colors.white),
            tooltip: 'الخصومات والإعفاءات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiscountsListScreen()),
              );
            },
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => provider.loadForMonth(provider.month, provider.year),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                children: [
                  // 1. Month Selector Bar
                  _buildMonthSelector(provider, isDark),
                  const SizedBox(height: 14),

                  // 2. Summary Card with Gradient & Progress
                  _buildSummaryCard(provider, isDark),
                  const SizedBox(height: 14),

                  // 3. Search Bar
                  _buildSearchBar(isDark),
                  const SizedBox(height: 10),

                  // 4. Filter Tabs Row (الكل / متأخرون / مسددون / خصومات)
                  _buildFilterTabs(provider, isDark),
                  const SizedBox(height: 14),

                  // 5. Group Cards or Filtered List
                  if (summaries.isEmpty)
                    _buildEmptyFilterState(isDark)
                  else
                    ...summaries.map((s) => _buildGroupCard(s, provider, isDark)),
                ],
              ),
            ),
    );
  }

  List<GroupPaymentSummary> _getFilteredSummaries(FinanceProvider provider) {
    final query = _searchQuery.trim().toLowerCase();

    return provider.summaries.map((summary) {
      var filteredStatuses = summary.studentStatuses;

      // Filter by tab
      if (_selectedTab == 'unpaid') {
        filteredStatuses = filteredStatuses
            .where((s) => s.paymentType != PaymentType.full && !s.student.isExempt)
            .toList();
      } else if (_selectedTab == 'paid') {
        filteredStatuses = filteredStatuses
            .where((s) => s.paymentType == PaymentType.full || s.student.isExempt)
            .toList();
      } else if (_selectedTab == 'discounts') {
        filteredStatuses = filteredStatuses
            .where((s) => s.student.hasDiscount || s.student.isExempt)
            .toList();
      }

      // Filter by search query
      if (query.isNotEmpty) {
        filteredStatuses = filteredStatuses.where((s) {
          final nameMatch = s.student.name.toLowerCase().contains(query);
          final phoneMatch = s.student.phone.contains(query) || s.student.parentPhone.contains(query);
          final groupMatch = summary.groupName.toLowerCase().contains(query);
          return nameMatch || phoneMatch || groupMatch;
        }).toList();
      }

      return GroupPaymentSummary(
        groupId: summary.groupId,
        groupName: summary.groupName,
        paymentMode: summary.paymentMode,
        monthlyPrice: summary.monthlyPrice,
        sessionPrice: summary.sessionPrice,
        studentStatuses: filteredStatuses,
      );
    }).where((s) => s.studentStatuses.isNotEmpty || (_selectedTab == 'all' && query.isEmpty)).toList();
  }

  Widget _buildMonthSelector(FinanceProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.primary),
            tooltip: 'الشهر السابق',
            onPressed: provider.prevMonth,
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                '${AppDateUtils.arabicMonth(provider.month)} ${ArabicNumbers.convert(provider.year)}',
                style: GoogleFonts.changa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkText : AppColors.ink,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.primary),
            tooltip: 'الشهر التالي',
            onPressed: () {
              final now = DateTime.now();
              if (provider.year < now.year ||
                  (provider.year == now.year && provider.month < now.month + 1)) {
                provider.nextMonth();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(FinanceProvider provider, bool isDark) {
    final rate = provider.overallRate;
    final percent = (rate * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)]
              : const [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF134E4A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 3 Metric Boxes with High Contrast & Clear Text
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  title: 'المتوقع',
                  amount: provider.totalExpected,
                  textColor: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryBox(
                  title: 'المحصّل',
                  amount: provider.totalCollected,
                  textColor: const Color(0xFF6EE7B7),
                  bgColor: const Color(0xFF064E3B).withValues(alpha: 0.7),
                  borderColor: const Color(0xFF34D399).withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryBox(
                  title: 'المتبقي',
                  amount: provider.totalRemaining,
                  textColor: const Color(0xFFFCA5A5),
                  bgColor: const Color(0xFF7F1D1D).withValues(alpha: 0.45),
                  borderColor: const Color(0xFFF87171).withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar with Vibrant Color
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              backgroundColor: Colors.black38,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 1.0 ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'نسبة التحصيل: ${ArabicNumbers.convert(percent)}٪',
                  style: GoogleFonts.changa(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                percent >= 100
                    ? '🎉 اكتمل التحصيل بالكامل'
                    : 'متبقي: ${ArabicNumbers.formatCurrency(provider.totalRemaining)}',
                style: GoogleFonts.tajawal(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox({
    required String title,
    required double amount,
    required Color textColor,
    required Color bgColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.tajawal(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ArabicNumbers.formatCurrency(amount),
            style: GoogleFonts.changa(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.tajawal(fontSize: 13.5, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'ابحث باسم الطالب أو رقم الهاتف أو المجموعة...',
          hintStyle: GoogleFonts.tajawal(fontSize: 12.5, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val.trim().toLowerCase());
        },
      ),
    );
  }

  Widget _buildFilterTabs(FinanceProvider provider, bool isDark) {
    final summaries = provider.summaries;
    int unpaidCount = 0;
    int paidCount = 0;
    int discountsCount = 0;

    for (final summary in summaries) {
      for (final s in summary.studentStatuses) {
        if (s.paymentType == PaymentType.unpaid || s.paymentType == PaymentType.partial) {
          unpaidCount++;
        } else if (s.paymentType == PaymentType.full || s.student.isExempt) {
          paidCount++;
        }
        if (s.student.hasDiscount || s.student.isExempt) {
          discountsCount++;
        }
      }
    }

    final tabs = [
      {'key': 'all', 'label': 'الكل', 'icon': Icons.groups_rounded, 'count': null, 'color': AppColors.primary},
      {'key': 'unpaid', 'label': 'غير مسدد', 'icon': Icons.error_outline_rounded, 'count': unpaidCount, 'color': AppColors.red},
      {'key': 'paid', 'label': 'مسدد', 'icon': Icons.check_circle_outline_rounded, 'count': paidCount, 'color': AppColors.green},
      {'key': 'discounts', 'label': 'خصومات وإعفاءات', 'icon': Icons.percent_rounded, 'count': discountsCount, 'color': AppColors.orange},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final isSelected = _selectedTab == t['key'];
          final count = t['count'] as int?;
          final color = t['color'] as Color;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () {
                setState(() => _selectedTab = t['key'] as String);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color
                      : (Theme.of(context).cardColor),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkMuted : AppColors.muted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t['label'] as String,
                      style: GoogleFonts.tajawal(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? AppColors.darkText : AppColors.ink),
                      ),
                    ),
                    if (count != null && count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white24 : color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ArabicNumbers.convert(count),
                          style: GoogleFonts.changa(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGroupCard(
    GroupPaymentSummary summary,
    FinanceProvider provider,
    bool isDark,
  ) {
    final isExpanded = _expandedGroups.contains(summary.groupId) || _selectedTab != 'all' || _searchQuery.isNotEmpty;
    // Always use the group summary from provider to calculate true group rate & counts
    final realGroup = provider.summaries.where((s) => s.groupId == summary.groupId).firstOrNull ?? summary;
    final rate = realGroup.collectionRate;
    final percent = (rate * 100).round();
    final paidCount = realGroup.paidCount;
    final unpaidCount = realGroup.unpaidCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rate >= 1.0
              ? (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: rate >= 1.0 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Card
          InkWell(
            onTap: () {
              setState(() {
                if (_expandedGroups.contains(summary.groupId)) {
                  _expandedGroups.remove(summary.groupId);
                } else {
                  _expandedGroups.add(summary.groupId);
                }
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: (rate >= 1.0 ? AppColors.green : AppColors.primary).withValues(alpha: 0.14),
                        child: Text(
                          summary.groupName.isNotEmpty ? summary.groupName[0] : 'م',
                          style: GoogleFonts.changa(
                            fontWeight: FontWeight.bold,
                            color: rate >= 1.0 ? AppColors.green : AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.groupName,
                              style: GoogleFonts.changa(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? AppColors.darkText : AppColors.ink,
                              ),
                            ),
                            Text(
                              summary.paymentMode == 'per_session'
                                  ? '${ArabicNumbers.convert(summary.sessionPrice.toInt())} ج.م / حصة · ${ArabicNumbers.formatStudentsCount(realGroup.totalCount)}'
                                  : '${ArabicNumbers.convert(summary.monthlyPrice.toInt())} ج.م / شهر · ${ArabicNumbers.formatStudentsCount(realGroup.totalCount)}',
                              style: GoogleFonts.tajawal(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkMuted : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Prominent Collection Rate Badge & Money Sum
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: rate >= 1.0
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : (rate >= 0.5 ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: rate >= 1.0
                                    ? const Color(0xFF10B981)
                                    : (rate >= 0.5 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                                width: 1.1,
                              ),
                            ),
                            child: Text(
                              'نسبة التحصيل: ${ArabicNumbers.convert(percent)}٪',
                              style: GoogleFonts.changa(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: rate >= 1.0
                                    ? const Color(0xFF059669)
                                    : (rate >= 0.5 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ArabicNumbers.convert(realGroup.collected.toInt())} / ${ArabicNumbers.convert(realGroup.expected.toInt())} ج.م',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? AppColors.darkMuted : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Enhanced Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: rate.clamp(0.0, 1.0),
                      backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        rate >= 1.0
                            ? const Color(0xFF10B981)
                            : (rate >= 0.5 ? const Color(0xFF0D7377) : const Color(0xFFF59E0B)),
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Paid vs Remaining Students Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تم سداد: ${ArabicNumbers.formatStudentsCount(paidCount)}',
                        style: GoogleFonts.tajawal(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      Text(
                        unpaidCount > 0
                            ? 'متبقي: ${ArabicNumbers.formatStudentsCount(unpaidCount)}'
                            : '🎉 الكل مسدد',
                        style: GoogleFonts.tajawal(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: unpaidCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Students Sub-List
          if (isExpanded) ...[
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
            if (summary.studentStatuses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'لا يوجد طلاب مطابقين للفلتر في هذه المجموعة',
                  style: GoogleFonts.tajawal(color: AppColors.muted, fontSize: 12.5),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summary.studentStatuses.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, idx) {
                  final status = summary.studentStatuses[idx];
                  return _buildStudentPaymentRow(status, summary, provider, isDark);
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentPaymentRow(
    StudentPaymentStatus status,
    GroupPaymentSummary summary,
    FinanceProvider provider,
    bool isDark,
  ) {
    final student = status.student;
    final dueAmount = student.calculateDueAmount(summary.basePrice);
    final remaining = (dueAmount - status.amountPaid).clamp(0.0, double.infinity);

    final Color statusColor;
    final String statusLabel;

    if (student.isExempt) {
      statusColor = AppColors.darkPrimary;
      statusLabel = 'معفي ✨';
    } else {
      switch (status.paymentType) {
        case PaymentType.full:
          statusColor = AppColors.darkPrimary;
          statusLabel = 'تم الدفع ✅';
          break;
        case PaymentType.partial:
          statusColor = AppColors.darkOrange;
          statusLabel = 'دفع جزئي 💛';
          break;
        case PaymentType.unpaid:
          statusColor = AppColors.darkRed;
          statusLabel = 'ادفع 💳';
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          StudentAvatar(name: student.name, radius: 18),
          const SizedBox(width: 10),

          // Student Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        student.name,
                        style: GoogleFonts.tajawal(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkText : AppColors.ink,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (student.hasDiscount) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          student.isExempt ? 'إعفاء' : 'خصم',
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  status.paymentType == PaymentType.partial
                      ? 'دفع ${ArabicNumbers.convert(status.amountPaid.toInt())} من ${ArabicNumbers.convert(dueAmount.toInt())} ج.م (باقي ${ArabicNumbers.convert(remaining.toInt())})'
                      : 'المطلوب: ${ArabicNumbers.convert(dueAmount.toInt())} ج.م',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    color: status.paymentType == PaymentType.partial
                        ? AppColors.orange
                        : (isDark ? AppColors.darkMuted : AppColors.muted),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // WhatsApp Reminder Button (If Unpaid / Partial)
          if (remaining > 0 && !student.isExempt) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
              tooltip: 'إرسال تذكير عبر واتساب',
              onPressed: () => _sendWhatsAppReminder(student, summary, dueAmount, remaining),
            ),
          ],

          // Payment Status Toggle Button
          InkWell(
            onTap: () => _handlePaymentTap(status, summary, provider),
            onLongPress: () => _showPartialDialog(status, summary, provider),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.tajawal(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePaymentTap(
    StudentPaymentStatus status,
    GroupPaymentSummary summary,
    FinanceProvider provider,
  ) {
    final next = provider.cyclePayment(status.paymentType);
    final dueAmount = status.student.calculateDueAmount(summary.basePrice);
    final amount = next == PaymentType.full ? dueAmount : 0.0;

    provider.updatePayment(
      status.student.id,
      summary.groupId,
      next,
      amount,
      dueAmount,
    );
    HapticFeedback.lightImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next == PaymentType.full
                ? '✅ تم تسجيل سداد الطالب (${status.student.name}) بنجاح'
                : 'تم إلغاء سداد الطالب (${status.student.name})',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
          backgroundColor: next == PaymentType.full ? AppColors.primary : const Color(0xFF334155),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showPartialDialog(
    StudentPaymentStatus status,
    GroupPaymentSummary summary,
    FinanceProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = TextEditingController(
      text: status.amountPaid > 0 ? status.amountPaid.toInt().toString() : '',
    );
    final due = status.student.calculateDueAmount(summary.basePrice);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تسجيل دفع جزئي للطالب',
          style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'الطالب: ${status.student.name}',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'المطلوب بعد الخصم: ${ArabicNumbers.convert(due.toInt())} ج.م (من أصل ${ArabicNumbers.convert(summary.basePrice.toInt())} ج.م)',
              style: GoogleFonts.tajawal(
                color: isDark ? AppColors.darkMuted : AppColors.muted,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              textAlign: TextAlign.center,
              autofocus: true,
              style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'المبلغ المدفوع حالياً',
                hintText: 'مثال: 50',
                suffixText: 'ج.م',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text) ?? 0;
              if (val > 0) {
                provider.updatePayment(
                  status.student.id,
                  summary.groupId,
                  PaymentType.partial,
                  val,
                  due,
                );
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('حفظ المبلغ', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsAppReminder(
    dynamic student,
    GroupPaymentSummary summary,
    double dueAmount,
    double remainingAmount,
  ) async {
    final phone = student.parentPhone.isNotEmpty ? student.parentPhone : student.phone;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ لا يوجد رقم هاتف مسجل للطالب أو ولي أمره', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    final cleaned = AppValidators.cleanPhone(phone);
    final settings = context.read<SettingsProvider>();
    final provider = context.read<FinanceProvider>();

    final template = settings.templatePayment;
    final messageText = template
        .replaceAll('{student}', student.name)
        .replaceAll('{group}', summary.groupName)
        .replaceAll('{month}', AppDateUtils.arabicMonth(provider.month));

    final msg = Uri.encodeComponent(messageText);
    final url = Uri.parse('https://wa.me/$cleaned?text=$msg');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _exportToPdf(FinanceProvider provider) async {
    setState(() => _exporting = true);
    try {
      final file = await FinancePdfService().exportFinanceReport(
        month: provider.month,
        year: provider.year,
        summaries: provider.summaries,
        totalExpected: provider.totalExpected,
        totalCollected: provider.totalCollected,
        totalRemaining: provider.totalRemaining,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              file: file,
              title: 'التقرير المالي - شهر ${provider.month} / ${provider.year}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تصدير PDF: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Widget _buildEmptyFilterState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 54, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج مطابقة',
              style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'جرّب تغيير كلمات البحث أو التبديل بين الفلاتر',
              style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

