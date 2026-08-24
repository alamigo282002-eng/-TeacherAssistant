import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';
import '../groups/groups_provider.dart';
import '../settings/settings_provider.dart';
import '../students/students_provider.dart';
import 'certificate_editor_screen.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  String? _selectedGroupId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsProvider>().loadStudents();
      context.read<GroupsProvider>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsP = context.watch<StudentsProvider>();
    final groupsP = context.watch<GroupsProvider>();
    final settingsP = context.watch<SettingsProvider>();

    final students = studentsP.allStudents;
    final groups = groupsP.groups;

    final filteredStudents = students.where((s) {
      final matchesGroup = _selectedGroupId == null || s.groupId == _selectedGroupId;
      final matchesQuery = _searchQuery.isEmpty || s.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesGroup && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'شهادات التقدير والتفوق 🎓',
          style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: studentsP.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Custom Creation Quick Button
                  AppScaleButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CertificateEditorScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D7377), Color(0xFF14FFEC)],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D7377).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.palette_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'صمم شهادة مخصصة فورية 🎨',
                                  style: GoogleFonts.changa(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'تخصيص الاسم، المادة، الآيات، والقالب',
                                  style: GoogleFonts.tajawal(fontSize: 12, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 2. Quick Student Selection Header & Search
                  Text(
                    'إصدار شهادة سريعة لطالب:',
                    style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Filter Row (Search + Group Dropdown)
                  Row(
                    children: [
                      // Search field
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: GoogleFonts.tajawal(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن طالب...',
                              hintStyle: GoogleFonts.tajawal(color: AppColors.muted, fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Group Dropdown
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedGroupId,
                            hint: Text('كل المجموعات', style: GoogleFonts.tajawal(fontSize: 12)),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('كل المجموعات', style: GoogleFonts.tajawal(fontSize: 12)),
                              ),
                              ...groups.map((g) => DropdownMenuItem<String?>(
                                    value: g.id,
                                    child: Text(g.name, style: GoogleFonts.tajawal(fontSize: 12)),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedGroupId = val),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3. Students List
                  if (filteredStudents.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            const Icon(Icons.person_off_outlined, size: 40, color: AppColors.muted),
                            const SizedBox(height: 8),
                            Text('لا يوجد طلاب مطابقين للبحث', style: GoogleFonts.tajawal(color: AppColors.muted)),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final student = filteredStudents[idx];
                        final group = groups.where((g) => g.id == student.groupId).firstOrNull;
                        return _buildStudentCertificateCard(
                          student: student,
                          group: group,
                          teacherName: settingsP.teacherName,
                          isDark: isDark,
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentCertificateCard({
    required StudentModel student,
    GroupModel? group,
    required String teacherName,
    required bool isDark,
  }) {
    final groupName = group?.name ?? 'عامة';
    final hasSubject = group?.subject != null && group!.subject!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.chipTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                student.name.isNotEmpty ? student.name[0] : 'ط',
                style: GoogleFonts.changa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and Group
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  'مجموعة: $groupName${hasSubject ? " (📖 ${group.subject})" : ""}',
                  style: GoogleFonts.tajawal(fontSize: 11.5, color: AppColors.muted),
                ),
              ],
            ),
          ),

          // Dedicated Certificate Button
          AppScaleButton(
            onTap: () {
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2E1A04)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                  width: 1.1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    'تصميم الشهادة',
                    style: GoogleFonts.changa(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92660A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

