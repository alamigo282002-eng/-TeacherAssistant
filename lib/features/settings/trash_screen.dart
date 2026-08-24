import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/student_repository.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _studentRepo = StudentRepository();
  final _groupRepo = GroupRepository();

  List<StudentModel> _deletedStudents = [];
  List<GroupModel> _deletedGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final students = await _studentRepo.getDeleted();
      final groups = await _groupRepo.getDeleted();
      if (mounted) {
        setState(() {
          _deletedStudents = students;
          _deletedGroups = groups;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _emptyAllTrash() async {
    final confirm = await _confirmDelete(
      context,
      'هل أنت متأكد من تفريغ سلة المهملات بالكامل؟\nسيتم حذف جميع الطلاب (${ArabicNumbers.formatStudentsCount(_deletedStudents.length)}) وجميع المجموعات (${ArabicNumbers.convert(_deletedGroups.length)}) نهائياً ولا يمكن التراجع!',
    );
    if (!confirm) return;

    for (final s in _deletedStudents) {
      await _studentRepo.hardDelete(s.id);
    }
    for (final g in _deletedGroups) {
      await _groupRepo.hardDelete(g.id);
    }
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تفريغ سلة المهملات نهائياً', style: GoogleFonts.tajawal())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = _deletedStudents.length + _deletedGroups.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('سلة المهملات 🗑️', style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (totalCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.red),
              tooltip: 'تفريغ السلة نهائياً',
              onPressed: _emptyAllTrash,
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: isDark ? Colors.white : AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          labelStyle: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: [
            Tab(text: 'الطلاب (${ArabicNumbers.convert(_deletedStudents.length)})'),
            Tab(text: 'المجموعات (${ArabicNumbers.convert(_deletedGroups.length)})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildStudentsList(isDark),
                _buildGroupsList(isDark),
              ],
            ),
    );
  }

  Widget _buildStudentsList(bool isDark) {
    if (_deletedStudents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded, size: 56, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('سلة الطلاب فارغة', style: GoogleFonts.changa(fontSize: 16, color: AppColors.muted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedStudents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final student = _deletedStudents[i];
        return _buildTrashCard(
          title: student.name,
          subtitle: student.phone.isNotEmpty ? 'هاتف: ${student.phone}' : 'طالب محذوف',
          typeLabel: 'طالب',
          typeIcon: Icons.person_outline_rounded,
          isDark: isDark,
          onRestore: () async {
            await _studentRepo.restore(student.id);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم استرجاع الطالب (${student.name}) بنجاح', style: GoogleFonts.tajawal())),
              );
            }
          },
          onDelete: () async {
            final confirm = await _confirmDelete(
              context,
              'هل أنت متأكد من الحذف النهائي للطالب (${student.name})؟ لا يمكن استرجاع البيانات بعد ذلك.',
            );
            if (confirm) {
              await _studentRepo.hardDelete(student.id);
              _loadData();
            }
          },
        );
      },
    );
  }

  Widget _buildGroupsList(bool isDark) {
    if (_deletedGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline_rounded, size: 56, color: AppColors.muted),
            const SizedBox(height: 12),
            Text('سلة المجموعات فارغة', style: GoogleFonts.changa(fontSize: 16, color: AppColors.muted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedGroups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final group = _deletedGroups[i];
        return _buildTrashCard(
          title: group.name,
          subtitle: 'المادة: ${group.subject ?? "-"} · ${group.type.label}',
          typeLabel: 'مجموعة',
          typeIcon: Icons.groups_rounded,
          isDark: isDark,
          onRestore: () async {
            await _groupRepo.restore(group.id);
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم استرجاع المجموعة (${group.name}) بنجاح', style: GoogleFonts.tajawal())),
              );
            }
          },
          onDelete: () async {
            final confirm = await _confirmDelete(
              context,
              'هل أنت متأكد من الحذف النهائي للمجموعة (${group.name})؟ لا يمكن التراجع!',
            );
            if (confirm) {
              await _groupRepo.hardDelete(group.id);
              _loadData();
            }
          },
        );
      },
    );
  }

  Widget _buildTrashCard({
    required String title,
    required String subtitle,
    required String typeLabel,
    required IconData typeIcon,
    required bool isDark,
    required VoidCallback onRestore,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: AppColors.red, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.changa(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? AppColors.darkText : AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel,
                  style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Two Prominent Action Buttons: Restore & Delete Permanently
          Row(
            children: [
              // 1. Restore Button (Green)
              Expanded(
                child: AppScaleButton(
                  onTap: onRestore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restore_rounded, size: 18, color: Color(0xFF059669)),
                        const SizedBox(width: 6),
                        Text(
                          'استرجاع',
                          style: GoogleFonts.changa(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Delete Permanently Button (Red)
              Expanded(
                child: AppScaleButton(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_forever_rounded, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Text(
                          'حذف نهائياً',
                          style: GoogleFonts.changa(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
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

  Future<bool> _confirmDelete(BuildContext context, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 24),
            const SizedBox(width: 8),
            Text('تأكيد الحذف النهائي', style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(message, style: GoogleFonts.tajawal(fontSize: 13, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف نهائياً', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

