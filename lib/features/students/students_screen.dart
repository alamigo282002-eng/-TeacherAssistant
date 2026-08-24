import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/contact_helper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/models/student_model.dart';
import '../groups/groups_provider.dart';
import 'add_edit_student_screen.dart';
import 'student_detail_screen.dart';
import 'students_provider.dart';

class StudentsScreen extends StatefulWidget {
  final String? initialGroupId;

  const StudentsScreen({super.key, this.initialGroupId});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isFabVisible = true;
  bool _tutorialDismissed = false;

  // Multi-Selection State
  bool _isSelectionMode = false;
  final Set<String> _selectedStudentIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _checkTutorialStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentsP = context.read<StudentsProvider>();
      studentsP.loadStudents();
      context.read<GroupsProvider>().loadGroups();
      if (widget.initialGroupId != null) {
        studentsP.setGroupFilter(widget.initialGroupId);
      }
    });
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('students_tutorial_seen') ?? false;
    if (mounted) {
      setState(() => _tutorialDismissed = seen);
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('students_tutorial_seen', true);
    if (mounted) {
      setState(() => _tutorialDismissed = true);
    }
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) setState(() => _isFabVisible = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabVisible) setState(() => _isFabVisible = true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
        if (_selectedStudentIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _selectAll(List<StudentModel> students) {
    setState(() {
      if (_selectedStudentIds.length == students.length) {
        _selectedStudentIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedStudentIds.clear();
        _selectedStudentIds.addAll(students.map((s) => s.id));
      }
    });
  }

  Future<void> _confirmBulkDelete(BuildContext context, StudentsProvider studentsP) async {
    if (_selectedStudentIds.isEmpty) return;

    final count = _selectedStudentIds.length;
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'حذف جماعي للطلاب',
      message: 'هل أنت متأكد من حذف ($count) طالب ونقلهم للأرشيف؟',
      confirmLabel: 'حذف المحدد ($count)',
      danger: true,
    );

    if (confirmed == true && mounted) {
      await studentsP.deleteBulkStudents(_selectedStudentIds.toList());
      setState(() {
        _selectedStudentIds.clear();
        _isSelectionMode = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ تم حذف ($count) طالب بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final studentsP = context.watch<StudentsProvider>();
    final groupsP = context.watch<GroupsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedStudentIds.clear();
                  });
                },
                tooltip: 'إلغاء التحديد',
              ),
              title: Text(
                'تم تحديد ${ArabicNumbers.convert(_selectedStudentIds.length)} طالب',
                style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedStudentIds.length == studentsP.students.length
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    color: Colors.white,
                  ),
                  tooltip: _selectedStudentIds.length == studentsP.students.length ? 'إلغاء تحديد الكل' : 'تحديد الكل',
                  onPressed: () => _selectAll(studentsP.students),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
                  tooltip: 'حذف الطلاب المحددين',
                  onPressed: () => _confirmBulkDelete(context, studentsP),
                ),
              ],
            )
          : AppBar(
              title: Text(
                'سجل الطلاب',
                style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              actions: [
                // Selection Mode button
                if (studentsP.students.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist_rounded),
                    tooltip: 'تحديد متعدد وحذف',
                    onPressed: () {
                      setState(() => _isSelectionMode = true);
                    },
                  ),
                // Sort button
                PopupMenuButton<StudentSortType>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'ترتيب الطلاب',
                  onSelected: (val) => studentsP.setSortType(val),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: StudentSortType.alphabetical,
                      child: Row(children: [
                        Icon(Icons.sort_by_alpha, size: 18,
                            color: studentsP.sortType == StudentSortType.alphabetical
                                ? AppColors.primary : AppColors.muted),
                        const SizedBox(width: 8),
                        Text('أبجدي (A-Z)', style: GoogleFonts.tajawal(
                          fontWeight: studentsP.sortType == StudentSortType.alphabetical
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                      ]),
                    ),
                    PopupMenuItem(
                      value: StudentSortType.dateAdded,
                      child: Row(children: [
                        Icon(Icons.access_time_rounded, size: 18,
                            color: studentsP.sortType == StudentSortType.dateAdded
                                ? AppColors.primary : AppColors.muted),
                        const SizedBox(width: 8),
                        Text('تاريخ الإضافة (الأحدث)', style: GoogleFonts.tajawal(
                          fontWeight: studentsP.sortType == StudentSortType.dateAdded
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                      ]),
                    ),
                    PopupMenuItem(
                      value: StudentSortType.points,
                      child: Row(children: [
                        Icon(Icons.stars_rounded, size: 18,
                            color: studentsP.sortType == StudentSortType.points
                                ? AppColors.primary : AppColors.muted),
                        const SizedBox(width: 8),
                        Text('حسب النقاط (الأعلى)', style: GoogleFonts.tajawal(
                          fontWeight: studentsP.sortType == StudentSortType.points
                              ? FontWeight.bold : FontWeight.normal,
                        )),
                      ]),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  onPressed: () => _openAddStudent(context, groupsP),
                  tooltip: 'إضافة طالب',
                ),
              ],
            ),
      body: Column(
        children: [
          _buildSearchBar(studentsP, isDark),
          _buildGroupFilter(studentsP, groupsP, isDark),
          if (!_tutorialDismissed && !_isSelectionMode) _buildInteractiveTutorial(isDark),
          Expanded(
            child: studentsP.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : studentsP.students.isEmpty
                    ? EmptyState(
                        message: studentsP.searchQuery.isNotEmpty
                            ? 'لا توجد نتائج مطابقة للبحث'
                            : 'لا يوجد طلاب مسجلون بعد',
                        subtitle: studentsP.searchQuery.isEmpty
                            ? 'أضف طالبك الأول للبدء في المتابعة ورصد الدرجات'
                            : null,
                        icon: Icons.school_outlined,
                        action: studentsP.searchQuery.isEmpty
                            ? AppButton(
                                label: 'إضافة طالب',
                                icon: Icons.add,
                                onPressed: () => _openAddStudent(context, groupsP),
                              )
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () => studentsP.loadStudents(),
                        color: AppColors.primary,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          itemCount: studentsP.students.length,
                          itemBuilder: (ctx, i) => _buildStudentCard(
                            ctx,
                            studentsP.students[i],
                            groupsP,
                            studentsP,
                            isDark,
                          )
                              .animate()
                              .fadeIn(duration: 250.ms, delay: Duration(milliseconds: (20 * (i % 10))))
                              .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                        ),
                      ),
          ),
        ],
      ),
      // Elevated FAB to sit properly above MainShell bottom navigation bar (only visible when at least 1 student exists)
      floatingActionButton: (_isSelectionMode || studentsP.students.isEmpty)
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 96),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 250),
                offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isFabVisible ? 1.0 : 0.0,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openAddStudent(context, groupsP),
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    icon: Icon(Icons.person_add_rounded, color: isDark ? AppColors.darkBg : Colors.white),
                    label: Text(
                      'طالب جديد',
                      style: GoogleFonts.changa(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkBg : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInteractiveTutorial(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEFFDF5), const Color(0xFFF0FDF4)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkPrimary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: Color(0xFFEAB308), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '💡 نصائح سريعة لإدارة الطلاب',
                  style: GoogleFonts.changa(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.ink),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _dismissTutorial,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• انقر مطولاً على أي طالب للدخول في وضع التحديد المتعدد والحذف.\n• اسحب بطاقة الطالب لليسار لحذفه سريعاً.\n• استخدم أزرار التواصل للمراسلة الفورية عبر واتساب أو الاتصال.',
            style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? AppColors.darkMuted : AppColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(StudentsProvider studentsP, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.tajawal(
          fontSize: 13.5,
          color: isDark ? Colors.white : AppColors.ink,
        ),
        onChanged: (val) => studentsP.setSearchQuery(val),
        decoration: InputDecoration(
          hintText: 'ابحث باسم الطالب أو رقم الهاتف...',
          hintStyle: GoogleFonts.tajawal(
            fontSize: 12.5,
            color: isDark ? AppColors.darkMuted : AppColors.muted,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 20),
          suffixIcon: studentsP.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    studentsP.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  Widget _buildGroupFilter(StudentsProvider studentsP, GroupsProvider groupsP, bool isDark) {
    final groups = groupsP.groups;

    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length + 1,
        itemBuilder: (ctx, i) {
          final isAll = i == 0;
          final isSelected = isAll
              ? studentsP.selectedGroupId == null
              : studentsP.selectedGroupId == groups[i - 1].id;
          final label = isAll ? 'جميع المجموعات' : groups[i - 1].name;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AppScaleButton(
              onTap: () {
                if (isAll) {
                  studentsP.setGroupFilter(null);
                } else {
                  studentsP.setGroupFilter(groups[i - 1].id);
                }
              },
              child: AnimatedContainer(
                duration: AppConstants.animFast,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                      : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                        : (isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? (isDark ? AppColors.darkBg : Colors.white)
                          : (isDark ? Colors.white70 : AppColors.ink),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext ctx,
    StudentModel student,
    GroupsProvider groupsP,
    StudentsProvider studentsP,
    bool isDark,
  ) {
    final isSelected = _selectedStudentIds.contains(student.id);
    final group = groupsP.getGroupById(student.groupId);
    final groupName = group?.name ?? 'بدون مجموعة';

    final cardContent = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.8 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedStudentIds.add(student.id);
              });
            }
          },
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(student.id);
            } else {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => StudentDetailScreen(studentId: student.id),
                ),
              ).then((_) => studentsP.loadStudents());
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Selection indicator or Avatar
                    if (_isSelectionMode)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          color: isSelected
                              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                              : Colors.grey,
                          size: 24,
                        ),
                      )
                    else
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.14),
                        ),
                        child: Center(
                          child: Text(
                            student.name.isNotEmpty ? student.name[0] : 'ط',
                            style: GoogleFonts.changa(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    if (!_isSelectionMode) const SizedBox(width: 10),

                    // Student Name & Group
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: GoogleFonts.changa(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkText : AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.groups_outlined, size: 13, color: isDark ? AppColors.darkMuted : AppColors.muted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  groupName,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Points Badge
                    if (student.points > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 3),
                            Text(
                              ArabicNumbers.convert(student.points),
                              style: GoogleFonts.changa(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (!_isSelectionMode) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 0.6),
                  const SizedBox(height: 8),

                  // Bottom Action Bar
                  Row(
                    children: [
                      // View Profile Button
                      Expanded(
                        child: AppScaleButton(
                          onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => StudentDetailScreen(studentId: student.id),
                            ),
                          ).then((_) => studentsP.loadStudents()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.badge_outlined, size: 14, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'الملف الشخصي',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // WhatsApp / Call Actions
                      if (student.phone.isNotEmpty || student.parentPhone.isNotEmpty) ...[
                        AppScaleButton(
                          onTap: () => ContactHelper.showContactOptions(
                            ctx,
                            student,
                            isWhatsApp: true,
                            whatsappText: 'السلام عليكم، رسالة بخصوص الطالب ${student.name}',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF16A34A), size: 16),
                          ),
                        ),
                        const SizedBox(width: 6),
                        AppScaleButton(
                          onTap: () => ContactHelper.showContactOptions(ctx, student, isWhatsApp: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.call_outlined, color: Color(0xFF2563EB), size: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (_isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: cardContent,
      );
    }

    return Dismissible(
      key: ValueKey(student.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await ConfirmationDialog.show(
          ctx,
          title: 'حذف الطالب',
          message: 'هل أنت متأكد من حذف الطالب (${student.name}) ونقله للأرشيف؟',
          confirmLabel: 'حذف',
          danger: true,
        );
      },
      onDismissed: (direction) async {
        await studentsP.deleteStudent(student.id);
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('🗑️ تم حذف الطالب (${student.name})', style: GoogleFonts.tajawal()),
              backgroundColor: AppColors.red,
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(
              'حذف 🗑️',
              style: GoogleFonts.changa(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: cardContent,
      ),
    );
  }

  void _openAddStudent(BuildContext ctx, GroupsProvider groupsP) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const AddEditStudentScreen()),
    ).then((_) {
      if (mounted) context.read<StudentsProvider>().loadStudents();
    });
  }
}

