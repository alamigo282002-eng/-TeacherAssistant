import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/finance_pdf_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/contact_helper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/dot_grid_pattern.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/group_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/student_repository.dart';
import '../attendance/attendance_screen.dart';
import '../exams/exams_screen.dart';
import '../students/add_edit_student_screen.dart';
import '../students/student_detail_screen.dart';
import 'add_edit_group_screen.dart';
import 'groups_provider.dart';
import 'widgets/cancel_session_sheet.dart';
import 'widgets/whatsapp_qr_dialog.dart';

class GroupProfileScreen extends StatefulWidget {
  final GroupModel group;

  const GroupProfileScreen({super.key, required this.group});

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  late GroupModel _group;
  List<StudentModel> _students = [];
  bool _isLoading = true;
  String _studentSearchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadGroupData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);
    final repo = StudentRepository();
    final list = await repo.getByGroup(_group.id);
    if (mounted) {
      setState(() {
        _students = list;
        _isLoading = false;
      });
    }
  }

  List<StudentModel> get _filteredStudents {
    if (_studentSearchQuery.trim().isEmpty) return _students;
    final q = _studentSearchQuery.trim().toLowerCase();
    return _students.where((s) => s.name.toLowerCase().contains(q) || s.phone.contains(q) || s.parentPhone.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupsP = context.watch<GroupsProvider>();
    final isPaused = _group.status == GroupStatus.paused;
    final totalExpected = _students.length * _group.monthlyPrice;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'بروفايل المجموعة',
          style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل المجموعة',
            onPressed: () => _openEditGroup(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'تصدير تقرير PDF',
            onPressed: () => _exportGroupToPdf(_group),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'المزيد',
            onSelected: (val) => _handleMenuAction(val, groupsP, isPaused),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'cancel_session',
                child: Row(children: [
                  const Icon(Icons.event_busy_rounded, size: 18, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Text('إلغاء حصة وإشعار الطلاب', style: GoogleFonts.tajawal()),
                ]),
              ),
              PopupMenuItem(
                value: 'toggle_pause',
                child: Row(children: [
                  Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Text(isPaused ? 'تنشيط المجموعة ▶️' : 'إيقاف مؤقت ⏸️', style: GoogleFonts.tajawal()),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text('حذف المجموعة', style: GoogleFonts.tajawal(color: AppColors.error)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadGroupData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Group Hero Overview Card
                    _buildGroupHeroCard(isDark, isPaused),
                    const SizedBox(height: 16),

                    // 2. Main Attendance Action Button
                    _buildPrimaryAttendanceButton(isDark, isPaused),
                    const SizedBox(height: 16),

                    // 3. Quick Action Buttons Grid (Exams, WhatsApp, PDF, Cancel, Add Student)
                    _buildQuickActionsGrid(isDark),
                    const SizedBox(height: 20),

                    // 4. Statistics Widget (Students, Price, Expected Revenue)
                    _buildStatsRow(isDark, totalExpected),
                    const SizedBox(height: 22),

                    // 5. Students Section (List & Search)
                    _buildStudentsSection(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  // ── 1. Hero Card ──
  Widget _buildGroupHeroCard(bool isDark, bool isPaused) {
    final daysSummary = _group.days.map((d) => '${d.day} (${ArabicNumbers.formatTime12(d.time)})').join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPaused
              ? AppColors.orange.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          DotGridSurface(
            gradient: isPaused
                ? LinearGradient(colors: [AppColors.orange.withValues(alpha: 0.8), AppColors.darkOrange])
                : (isDark ? AppColors.darkHeaderGradient : AppColors.headerGradient),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _group.type == GroupType.online
                          ? Icons.videocam_rounded
                          : (_group.type == GroupType.center ? Icons.domain_rounded : Icons.groups_rounded),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _group.name,
                          style: GoogleFonts.changa(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_group.subject != null && _group.subject!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '📖 المادة: ${_group.subject!}',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isPaused ? '⏸️ متوقفة' : '🟢 نشطة',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Schedule & Details line
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppColors.darkMuted : AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            _group.type.label,
                            style: GoogleFonts.tajawal(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkText : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_outlined, size: 14, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${ArabicNumbers.formatCurrency(_group.monthlyPrice)} / شهر',
                            style: GoogleFonts.tajawal(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (daysSummary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          daysSummary,
                          style: GoogleFonts.tajawal(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkMuted : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Primary Attendance Button ──
  Widget _buildPrimaryAttendanceButton(bool isDark, bool isPaused) {
    return AppScaleButton(
      onTap: isPaused
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceScreen(
                    groupId: _group.id,
                    groupName: _group.name,
                  ),
                ),
              ).then((_) => _loadGroupData());
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: isPaused
              ? LinearGradient(colors: [Colors.grey.shade600, Colors.grey.shade700])
              : (isDark
                  ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                  : const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)])),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isPaused)
              BoxShadow(
                color: (isDark ? const Color(0xFF10B981) : const Color(0xFF0D9488)).withValues(alpha: 0.38),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.how_to_reg_rounded, size: 26, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رصد التحضير والغياب للحصة',
                    style: GoogleFonts.changa(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'تسجيل حضور الطلاب وغيابهم وملاحظات الحصة',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  // ── 3. Quick Actions Grid ──
  Widget _buildQuickActionsGrid(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFF59E0B)),
            const SizedBox(width: 6),
            Text(
              'أوامر وإجراءات المجموعة',
              style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.quiz_rounded,
                color: const Color(0xFF0284C7),
                bgColor: isDark ? const Color(0xFF075985) : const Color(0xFFE0F2FE),
                title: 'الاختبارات والدرجات',
                subtitle: 'إدارة ورصد الدرجات',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExamsScreen(groupId: _group.id, groupName: _group.name),
                    ),
                  );
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.event_busy_rounded,
                color: const Color(0xFFEA580C),
                bgColor: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFFEDD5),
                title: 'إلغاء حصة',
                subtitle: 'إشعار سريع للطلاب',
                onTap: () => CancelSessionSheet.show(context, group: _group),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.forum_rounded,
                color: const Color(0xFF16A34A),
                bgColor: isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7),
                title: 'جروب الواتساب',
                subtitle: _group.hasWhatsAppLink ? 'مشاركة و QR كود' : 'إضافة رابط',
                onTap: () {
                  if (_group.hasWhatsAppLink) {
                    WhatsAppQrDialog.show(context, _group);
                  } else {
                    _openEditGroup(context);
                  }
                },
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.person_add_alt_1_rounded,
                color: isDark ? AppColors.darkPrimary : const Color(0xFF0D9488),
                bgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFCCFBF1),
                title: 'إضافة طالب',
                subtitle: 'تسجيل طالب جديد',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditStudentScreen(preselectedGroupId: _group.id),
                    ),
                  ).then((_) => _loadGroupData());
                },
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return AppScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2620) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? color.withValues(alpha: 0.35) : color.withValues(alpha: 0.25),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.changa(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }

  // ── 4. Stats Row ──
  Widget _buildStatsRow(bool isDark, double totalExpected) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            title: 'إجمالي الطلاب',
            value: '${ArabicNumbers.convert(_students.length)} طالب',
            icon: Icons.people_alt_rounded,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatBox(
            title: 'الدخل المتوقع',
            value: ArabicNumbers.formatCurrency(totalExpected),
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFF16A34A),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.changa(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Students Section ──
  Widget _buildStudentsSection(bool isDark) {
    final filtered = _filteredStudents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'طلاب المجموعة',
                  style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ArabicNumbers.convert(_students.length),
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditStudentScreen(preselectedGroupId: _group.id),
                  ),
                ).then((_) => _loadGroupData());
              },
              icon: const Icon(Icons.add, size: 16),
              label: Text('إضافة طالب', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Search within group students
        if (_students.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _studentSearchQuery = v),
              style: GoogleFonts.tajawal(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'بحث في طلاب هذه المجموعة...',
                hintStyle: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _studentSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _studentSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),

        if (_students.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.person_add_rounded, size: 40, color: isDark ? AppColors.darkMuted : AppColors.muted),
                  const SizedBox(height: 10),
                  Text(
                    'لا يوجد طلاب مسجلون في هذه المجموعة بعد',
                    style: GoogleFonts.changa(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  AppButton(
                    label: 'إضافة أول طالب للمجموعة',
                    icon: Icons.add,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditStudentScreen(preselectedGroupId: _group.id),
                        ),
                      ).then((_) => _loadGroupData());
                    },
                  ),
                ],
              ),
            ),
          )
        else if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'لا توجد نتائج بحث مطابقة',
                style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final student = filtered[index];
              return _buildStudentItemTile(student, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildStudentItemTile(StudentModel student, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.15),
          child: Text(
            student.name.isNotEmpty ? student.name[0] : 'ط',
            style: GoogleFonts.changa(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: GoogleFonts.changa(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkText : AppColors.ink,
          ),
        ),
        subtitle: (student.phone.isNotEmpty || student.parentPhone.isNotEmpty)
            ? Text(
                student.phone.isNotEmpty ? student.phone : student.parentPhone,
                style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (student.phone.isNotEmpty || student.parentPhone.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 18),
                tooltip: 'واتساب',
                onPressed: () => ContactHelper.showContactOptions(
                  context,
                  student,
                  isWhatsApp: true,
                  whatsappText: 'السلام عليكم، رسالة بخصوص الطالب ${student.name} في مجموعة ${_group.name}',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call_outlined, color: AppColors.primary, size: 18),
                tooltip: 'اتصال',
                onPressed: () => ContactHelper.showContactOptions(context, student, isWhatsApp: false),
              ),
            ],
            const Icon(Icons.chevron_left_rounded, color: Colors.grey),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDetailScreen(studentId: student.id),
            ),
          ).then((_) => _loadGroupData());
        },
      ),
    );
  }

  void _openEditGroup(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => AddEditGroupScreen(group: _group)),
    ).then((_) {
      if (mounted) {
        context.read<GroupsProvider>().loadGroups();
        _loadGroupData();
      }
    });
  }

  Future<void> _exportGroupToPdf(GroupModel group) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('جاري التصدير إلى PDF...', style: GoogleFonts.tajawal())),
      );

      final db = DatabaseHelper();
      final studentsData = await db.query(AppConstants.tableStudents, where: 'group_id = ?', whereArgs: [group.id]);
      final students = studentsData.map((s) => StudentModel.fromMap(s)).toList();

      final attendanceData = await db.query(AppConstants.tableAttendance, where: 'group_id = ?', whereArgs: [group.id]);
      final attendance = attendanceData.map((a) => AttendanceModel.fromMap(a)).toList();

      final examsData = await db.query(AppConstants.tableExams, where: 'group_id = ?', whereArgs: [group.id]);
      final exams = examsData.map((e) => ExamModel.fromMap(e)).toList();

      final List<ExamResultModel> examResults = [];
      for (final exam in exams) {
        final resultsData = await db.query(AppConstants.tableExamResults, where: 'exam_id = ?', whereArgs: [exam.id]);
        examResults.addAll(resultsData.map((r) => ExamResultModel.fromMap(r)));
      }

      final paymentsData = await db.query(AppConstants.tablePayments, where: 'group_id = ?', whereArgs: [group.id]);
      final payments = paymentsData.map((p) => PaymentModel.fromMap(p)).toList();

      await FinancePdfService().exportGroupToPdf(
        group: group,
        students: students,
        attendanceRecords: attendance,
        exams: exams,
        examResults: examResults,
        payments: payments,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التصدير: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleMenuAction(String val, GroupsProvider groupsP, bool isPaused) async {
    if (val == 'toggle_pause') {
      if (isPaused) {
        await groupsP.restoreGroup(_group.id);
        if (!mounted) return;
        setState(() => _group = _group.copyWith(status: GroupStatus.active));
      } else {
        await groupsP.pauseGroup(_group.id);
        if (!mounted) return;
        setState(() => _group = _group.copyWith(status: GroupStatus.paused));
      }
    } else if (val == 'cancel_session') {
      CancelSessionSheet.show(context, group: _group);
    } else if (val == 'delete') {
      final deleted = await _confirmDelete(groupsP);
      if (!mounted) return;
      if (deleted) Navigator.pop(context);
    }
  }

  Future<bool> _confirmDelete(GroupsProvider provider) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'حذف المجموعة',
      message: 'هل أنت متأكد من حذف مجموعة "${_group.name}"؟ سيتم حذف جميع بياناتها وسجلاتها.',
      confirmLabel: 'حذف نهائي',
      danger: true,
    );
    if (confirmed == true) {
      await provider.deleteGroup(_group.id);
      return true;
    }
    return false;
  }
}

