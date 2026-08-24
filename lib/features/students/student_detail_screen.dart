import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/contact_helper.dart';
import '../../core/utils/pdf_generator.dart';
import '../../core/widgets/pdf_viewer_screen.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/student_model.dart';
import '../certificates/certificate_editor_screen.dart';
import '../groups/groups_provider.dart';
import '../notes/add_note_screen.dart';
import '../notes/notes_provider.dart';
import 'add_edit_student_screen.dart';
import 'students_provider.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsProvider>().loadStudentDetail(widget.studentId);
    });
  }

  Future<void> _loadData() async {
    await context.read<StudentsProvider>().loadStudentDetail(widget.studentId);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _generatePdf(StudentDetailData detail) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ إنشاء تقرير PDF...', style: GoogleFonts.tajawal()),
        duration: const Duration(seconds: 1),
      ),
    );
    try {
      final file = await PdfGenerator.generateStudentReport(
        detail.student,
        detail.attendance,
        detail.examHistory,
        detail.notes,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              file: file,
              title: 'تقرير الطالب: ${detail.student.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تصدير التقرير: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsP = context.watch<StudentsProvider>();
    final detail = studentsP.selectedStudentDetail;

    if (studentsP.detailLoading && detail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ملف الطالب')),
        body: Center(
          child: Text('الطالب غير موجود', style: GoogleFonts.changa(fontSize: 16)),
        ),
      );
    }

    final student = detail.student;
    final attendance = detail.attendance;
    final examHistory = detail.examHistory;
    final notes = detail.notes;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groupsP = context.watch<GroupsProvider>();
    final group = groupsP.groups.where((g) => g.id == student.groupId).firstOrNull ??
        groupsP.pausedGroups.where((g) => g.id == student.groupId).firstOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'ملف الطالب',
          style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706)),
            tooltip: 'إصدار شهادة تقدير 🎓',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificateEditorScreen(
                    initialStudent: student,
                    initialGroup: group,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'تصدير تقرير PDF',
            onPressed: () => _generatePdf(detail),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل البيانات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditStudentScreen(
                    student: student,
                    groups: groupsP.groups,
                  ),
                ),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Flexible Student Profile Header Card
          _buildProfileHeader(student, group, isDark),

          // 2. Styled Segmented TabBar
          _buildStyledTabBar(isDark),

          // 3. Tab Views Content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildAttendanceTab(isDark, attendance),
                _buildExamsTab(isDark, examHistory),
                _buildInfoTab(student, group, isDark),
                _buildNotesTab(isDark, notes, student),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. PROFILE HEADER CARD (Adaptive, handles long text without overflow)
  // -------------------------------------------------------------
  Widget _buildProfileHeader(StudentModel student, dynamic group, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar + Name + Group
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Circle
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF149E9E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : 'ط',
                    style: GoogleFonts.changa(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + Group with Wrap support
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.changa(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (group != null)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            group.name,
                            style: GoogleFonts.tajawal(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkMuted : AppColors.muted,
                            ),
                          ),
                          if (group.subject != null && group.subject!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '📖 ${group.subject!}',
                                style: GoogleFonts.tajawal(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Discount / Exemption Banner (if active)
          if (student.hasDiscount) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: student.isExempt ? AppColors.greenSoft : AppColors.orangeSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    student.isExempt ? Icons.verified_rounded : Icons.loyalty_rounded,
                    size: 15,
                    color: student.isExempt ? AppColors.green : const Color(0xFF856404),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      student.isExempt
                          ? 'طالب معفى من المصروفات${student.discountReason.isNotEmpty ? ' (${student.discountReason})' : ''}'
                          : 'خصم خاص: ${student.discountType == 'percent' ? '${ArabicNumbers.convert(student.discountAmount.toInt())}٪' : '${ArabicNumbers.convert(student.discountAmount.toInt())} ج'}${student.discountReason.isNotEmpty ? ' (${student.discountReason})' : ''}',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: student.isExempt ? const Color(0xFF155724) : const Color(0xFF856404),
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Badges & Action Buttons (Wrap layout avoids any overflow)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Points & Level Badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '${ArabicNumbers.convert(student.points)} نقطة',
                          style: GoogleFonts.changa(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF856404),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkGreenSoft : AppColors.chipTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up_rounded, size: 14, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          student.levelLabel,
                          style: GoogleFonts.tajawal(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.chipTealText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action buttons (WhatsApp, Call, Certificate)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 20),
                    tooltip: 'إصدار شهادة تقدير 🎓',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CertificateEditorScreen(
                            initialStudent: student,
                            initialReason: 'التفوق الأكاديمي والالتزام',
                          ),
                        ),
                      );
                    },
                  ),
                  if (student.phone.isNotEmpty || student.parentPhone.isNotEmpty) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.forum_rounded, color: Color(0xFF25D366), size: 20),
                      tooltip: 'رسالة واتساب',
                      onPressed: () => ContactHelper.showContactOptions(
                        context,
                        student,
                        isWhatsApp: true,
                        whatsappText: 'السلام عليكم، رسالة بخصوص الطالب ${student.name}',
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 19),
                      tooltip: 'اتصال هاتفي',
                      onPressed: () => ContactHelper.showContactOptions(
                        context,
                        student,
                        isWhatsApp: false,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. STYLED TAB BAR
  // -------------------------------------------------------------
  Widget _buildStyledTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFE9F0EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: isDark ? AppColors.darkBg : Colors.white,
        unselectedLabelColor: isDark ? AppColors.darkMuted : AppColors.muted,
        labelStyle: GoogleFonts.changa(fontSize: 12.5, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'الحضور'),
          Tab(text: 'الاختبارات'),
          Tab(text: 'البيانات'),
          Tab(text: 'الملاحظات'),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: ATTENDANCE
  // -------------------------------------------------------------
  Widget _buildAttendanceTab(bool isDark, List<AttendanceModel> attendance) {
    if (attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 54, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('لا توجد سجلات حضور مسجلة بعد', style: GoogleFonts.changa(fontSize: 15, color: AppColors.muted)),
          ],
        ),
      );
    }

    final presentCount = attendance.where((a) => a.status == AttendanceStatus.present).length;
    final absentCount = attendance.where((a) => a.status == AttendanceStatus.absent).length;
    final excusedCount = attendance.where((a) => a.status == AttendanceStatus.excused).length;
    final total = attendance.length;
    final rate = total > 0 ? (presentCount / total * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        Row(
          children: [
            _buildStatBox('نسبة الحضور', '$rate٪', AppColors.primary, isDark),
            const SizedBox(width: 8),
            _buildStatBox('حضور', '$presentCount', AppColors.green, isDark),
            const SizedBox(width: 8),
            _buildStatBox('غياب', '$absentCount', AppColors.red, isDark),
            const SizedBox(width: 8),
            _buildStatBox('معذور/تخطي', '$excusedCount', AppColors.orange, isDark),
          ],
        ),
        const SizedBox(height: 14),

        // List
        ...attendance.map((record) {
          final dateStr = DateFormat('yyyy/MM/dd (EEEE)', 'ar').format(record.date);
          Color statusColor;
          String statusText;
          IconData statusIcon;

          switch (record.status) {
            case AttendanceStatus.present:
              statusColor = AppColors.green;
              statusText = 'حاضر';
              statusIcon = Icons.check_circle_rounded;
              break;
            case AttendanceStatus.absent:
              statusColor = AppColors.red;
              statusText = 'غائب';
              statusIcon = Icons.cancel_rounded;
              break;
            case AttendanceStatus.excused:
              statusColor = const Color(0xFF0284C7);
              statusText = 'معذور / تخطي';
              statusIcon = Icons.info_rounded;
              break;
            case AttendanceStatus.cancelled:
              statusColor = AppColors.orange;
              statusText = 'ملغاة';
              statusIcon = Icons.event_busy_rounded;
              break;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ArabicNumbers.convert(dateStr),
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.ink,
                    ),
                    softWrap: true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.tajawal(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              ArabicNumbers.convert(value),
              style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: EXAMS (Flexible layout for long exam titles & marks)
  // -------------------------------------------------------------
  Widget _buildExamsTab(bool isDark, List<Map<String, dynamic>> examHistory) {
    if (examHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 54, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('لا توجد نتائج اختبارات مسجلة', style: GoogleFonts.changa(fontSize: 15, color: AppColors.muted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: examHistory.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final exam = examHistory[idx];
        final examName = exam['name']?.toString() ?? 'اختبار';
        final num? rawMarks = exam['marks'] as num?;
        final num? rawTotal = (exam['total_marks'] as num?) ?? (exam['total'] as num?);
        final totalMarks = rawTotal?.toDouble() ?? 100.0;
        final marks = rawMarks?.toDouble();
        final percent = (marks != null && totalMarks > 0) ? (marks / totalMarks * 100) : null;
        final date = exam['date'] != null ? DateTime.tryParse(exam['date'].toString()) : null;
        final dateStr = date != null ? DateFormat('yyyy/MM/dd').format(date) : '';

        final isPass = (percent ?? 0) >= 50;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPass ? AppColors.greenSoft : AppColors.redSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPass ? Icons.emoji_events_rounded : Icons.warning_amber_rounded,
                  color: isPass ? AppColors.green : AppColors.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      examName,
                      style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold),
                      softWrap: true,
                    ),
                    if (dateStr.isNotEmpty)
                      Text(
                        ArabicNumbers.convert(dateStr),
                        style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Score badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (marks != null) ...[
                    Text(
                      '${ArabicNumbers.convert(marks)} / ${ArabicNumbers.convert(totalMarks.toInt())}',
                      style: GoogleFonts.changa(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPass ? AppColors.green : AppColors.red,
                      ),
                    ),
                    if (percent != null)
                      Text(
                        '${ArabicNumbers.convert(percent.round())}٪ (${isPass ? "ناجح" : "راسب"})',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPass ? AppColors.green : AppColors.red,
                        ),
                      ),
                  ] else ...[
                    Text(
                      'لم تُرصد بعد',
                      style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 3: INFO / DATA (Adaptive multi-line rows for long text)
  // -------------------------------------------------------------
  Widget _buildInfoTab(StudentModel student, dynamic group, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          title: 'معلومات الاتصال',
          icon: Icons.contacts_rounded,
          isDark: isDark,
          children: [
            _buildInfoRow('رقم هاتف الطالب', student.phone, isDark, onTap: student.phone.isNotEmpty ? () => ContactHelper.showContactOptions(context, student, isWhatsApp: false) : null),
            const Divider(height: 16),
            _buildInfoRow('رقم ولي الأمر', student.parentPhone, isDark, onTap: student.parentPhone.isNotEmpty ? () => ContactHelper.showContactOptions(context, student, isWhatsApp: false) : null),
          ],
        ),

        const SizedBox(height: 14),

        _buildInfoCard(
          title: 'المجموعة والدراسة',
          icon: Icons.school_rounded,
          isDark: isDark,
          children: [
            _buildInfoRow('المجموعة', group?.name ?? 'بدون مجموعة', isDark),
            if (group?.subject != null) ...[
              const Divider(height: 16),
              _buildInfoRow('المادة الدراسية', '📖 ${group.subject!}', isDark),
            ],
            const Divider(height: 16),
            _buildInfoRow('المستوى الأكاديمي', student.levelLabel, isDark),
            const Divider(height: 16),
            _buildInfoRow('تاريخ التسجيل', ArabicNumbers.convert(DateFormat('yyyy/MM/dd').format(student.createdAt)), isDark),
          ],
        ),

        const SizedBox(height: 14),

        _buildInfoCard(
          title: 'الماليات والإعدادات المتقدمة',
          icon: Icons.tune_rounded,
          isDark: isDark,
          children: [
            _buildInfoRow('طريقة الدفع للمجموعة', (group?.isPerSession ?? false) ? 'دفع بالحصة (${ArabicNumbers.convert((group?.sessionPrice ?? 0).toInt())} ج.م)' : 'دفع شهري (${ArabicNumbers.convert((group?.monthlyPrice ?? 0).toInt())} ج.م)', isDark),
            if (student.hasDiscount) ...[
              const Divider(height: 16),
              _buildInfoRow(
                'الخصم المالي',
                student.isExempt
                    ? 'إعفاء كامل (مجاني)'
                    : (student.isSiblingDiscount
                        ? 'خصم أخوة (${ArabicNumbers.convert(student.discountAmount.toInt())} ج.م) مع ${student.siblingName ?? "طالب"}'
                        : (student.discountType == 'percent'
                            ? 'خصم ${ArabicNumbers.convert(student.discountAmount.toInt())}٪'
                            : 'خصم ${ArabicNumbers.convert(student.discountAmount.toInt())} ج.م')),
                isDark,
              ),
              if (student.discountReason.isNotEmpty) ...[
                const Divider(height: 16),
                _buildInfoRow('سبب الخصم', student.discountReason, isDark),
              ],
            ],
            if (student.specialNote.isNotEmpty) ...[
              const Divider(height: 16),
              _buildInfoRow('ملاحظة خاصة', student.specialNote, isDark),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value.isNotEmpty ? value : 'غير مسجل',
                      textAlign: TextAlign.end,
                      softWrap: true,
                      textDirection: RegExp(r'^[0-9]').hasMatch(value) ? TextDirection.ltr : null,
                      style: GoogleFonts.changa(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: onTap != null ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.ink),
                      ),
                    ),
                  ),
                  if (onTap != null && value.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.call_rounded, size: 14, color: AppColors.primary),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: NOTES
  // -------------------------------------------------------------
  Widget _buildNotesTab(bool isDark, List<NoteModel> notes, StudentModel student) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
        icon: Icon(Icons.add_rounded, color: isDark ? AppColors.darkBg : Colors.white),
        label: Text(
          'إضافة ملاحظة',
          style: GoogleFonts.changa(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkBg : Colors.white,
          ),
        ),
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.note_alt_outlined, size: 54, color: AppColors.muted),
                  const SizedBox(height: 12),
                  Text('لا توجد ملاحظات مسجلة لهذا الطالب', style: GoogleFonts.changa(fontSize: 15, color: AppColors.muted)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: notes.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final note = notes[idx];
                final dateStr = DateFormat('yyyy/MM/dd hh:mm a').format(note.createdAt);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ArabicNumbers.convert(dateStr),
                            style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red),
                            onPressed: () async {
                              await context.read<NotesProvider>().deleteNote(note.id);
                              _loadData();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.content,
                        style: GoogleFonts.tajawal(fontSize: 13, height: 1.4),
                        softWrap: true,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showAddNoteDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNoteScreen(
          initialStudentId: widget.studentId,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }
}

