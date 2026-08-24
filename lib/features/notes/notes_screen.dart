import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/note_model.dart';
import '../groups/groups_provider.dart';
import '../students/students_provider.dart';
import 'add_note_screen.dart';
import 'notes_provider.dart';

class NotesScreen extends StatefulWidget {
  final String? initialStudentId;
  final String? initialGroupId;

  const NotesScreen({
    super.key,
    this.initialStudentId,
    this.initialGroupId,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _tabs = const [
    {'id': 'class', 'label': 'ملاحظات الحصص', 'icon': Icons.menu_book_rounded},
    {'id': 'reminders', 'label': 'تنبيهات وتذكيرات', 'icon': Icons.notifications_active_rounded},
    {'id': 'general', 'label': 'أفكار وعامة', 'icon': Icons.lightbulb_rounded},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notesP = context.read<NotesProvider>();
      if (widget.initialStudentId != null || widget.initialGroupId != null) {
        notesP.setCategory('class');
      }
      notesP.loadNotes();
      context.read<StudentsProvider>().loadStudents();
      context.read<GroupsProvider>().loadGroups();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesP = context.watch<NotesProvider>();
    final studentsP = context.watch<StudentsProvider>();
    final groupsP = context.watch<GroupsProvider>();

    final studentNames = {for (final s in studentsP.allStudents) s.id: s.name};
    final groupNames = {for (final g in groupsP.groups) g.id: g.name};
    final displayedNotes = notesP.filteredNotes;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'دفتر الملاحظات والتنبيهات',
          style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateAndRefresh(
          AddNoteScreen(
            initialStudentId: widget.initialStudentId,
            initialGroupId: widget.initialGroupId,
          ),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
        label: Text(
          'تدوين ملاحظة',
          style: GoogleFonts.changa(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & 3 Slots Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.8)),
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2836) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => context.read<NotesProvider>().setSearchQuery(val),
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: isDark ? AppColors.darkText : AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث في الملاحظات والتدوينات...',
                      hintStyle: GoogleFonts.tajawal(
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 18,
                                color: isDark ? AppColors.darkMuted : AppColors.muted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<NotesProvider>().setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 3 Slots Segmented Row
                Row(
                  children: _tabs.map((tab) {
                    final isSelected = notesP.activeCategory == tab['id'];
                    int count = 0;
                    if (tab['id'] == 'class') count = notesP.classNotesCount;
                    if (tab['id'] == 'reminders') count = notesP.remindersNotesCount;
                    if (tab['id'] == 'general') count = notesP.generalNotesCount;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AppScaleButton(
                          onTap: () => context.read<NotesProvider>().setCategory(tab['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkCard : const Color(0xFFF0F4F5)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.transparent),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      tab['icon'] as IconData,
                                      size: 14,
                                      color: isSelected ? Colors.white : AppColors.muted,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        tab['label'] as String,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.tajawal(
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.ink),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? AppColors.darkSurface : const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ArabicNumbers.convert(count),
                                    style: GoogleFonts.changa(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Content list
          Expanded(
            child: notesP.loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : displayedNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              size: 64,
                              color: AppColors.muted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد ملاحظات مسجلة',
                              style: GoogleFonts.changa(fontSize: 16, color: AppColors.muted, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'اضغط على زر تدوين ملاحظة بالأسفل للبدء',
                              style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                        itemCount: displayedNotes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final note = displayedNotes[idx];
                          return _buildNoteCard(note, isDark, studentNames, groupNames);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(
    NoteModel note,
    bool isDark,
    Map<String, String> studentNames,
    Map<String, String> groupNames,
  ) {
    Color cardColor;
    Color accentColor;
    String typeLabel;
    IconData typeIcon;

    switch (note.type) {
      case 'student':
        typeLabel = 'طالب: ${studentNames[note.targetId] ?? "طالب"}';
        typeIcon = Icons.person_rounded;
        accentColor = AppColors.primary;
        cardColor = isDark ? AppColors.darkCard : const Color(0xFFF0FDF4);
        break;
      case 'group':
        typeLabel = 'مجموعة: ${groupNames[note.targetId] ?? "مجموعة"}';
        typeIcon = Icons.groups_rounded;
        accentColor = const Color(0xFF2563EB);
        cardColor = isDark ? AppColors.darkCard : const Color(0xFFEFF6FF);
        break;
      case 'general':
      default:
        typeLabel = 'عام وخاطرة';
        typeIcon = Icons.lightbulb_outline_rounded;
        accentColor = AppColors.orange;
        cardColor = isDark ? AppColors.darkCard : const Color(0xFFFFFBEB);
        break;
    }

    final dateStr = DateFormat('yyyy/MM/dd - hh:mm a').format(note.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: note.isPinned ? AppColors.orange : accentColor.withValues(alpha: 0.25),
          width: note.isPinned ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(typeIcon, size: 13, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      typeLabel,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (note.reminderEnabled)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.alarm_on_rounded, size: 16, color: AppColors.orange),
                ),
              AppScaleButton(
                onTap: () => context.read<NotesProvider>().togglePin(note.id),
                child: Icon(
                  note.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 18,
                  color: note.isPinned ? AppColors.orange : AppColors.muted,
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.muted),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _navigateAndRefresh(AddNoteScreen(editingNote: note));
                  } else if (val == 'share') {
                    SharePlus.instance.share(
                      ShareParams(
                        text: note.content,
                        subject: 'ملاحظة من مساعد المعلم',
                      ),
                    );
                  } else if (val == 'copy') {
                    Clipboard.setData(ClipboardData(text: note.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم نسخ الملاحظة ✅', style: GoogleFonts.tajawal())),
                    );
                  } else if (val == 'delete') {
                    _confirmDeleteNote(context, note.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('تعديل الملاحظة ✏️')),
                  const PopupMenuItem(value: 'share', child: Text('مشاركة عبر الواتساب 📲')),
                  const PopupMenuItem(value: 'copy', child: Text('نسخ النص 📋')),
                  const PopupMenuItem(value: 'delete', child: Text('حذف الملاحظة 🗑️', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Content
          Text(
            note.content,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.darkText : AppColors.ink,
            ),
          ),

          const SizedBox(height: 8),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ArabicNumbers.convert(dateStr),
                style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
              ),
              if (note.reminderEnabled && note.reminderTime != null)
                Text(
                  '⏰ تذكير: ${ArabicNumbers.convert(DateFormat('MM/dd hh:mm a').format(note.reminderTime!))}',
                  style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNote(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('حذف الملاحظة', style: GoogleFonts.changa(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف هذه الملاحظة نهائياً؟', style: GoogleFonts.tajawal()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dCtx);
              context.read<NotesProvider>().deleteNote(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: Text('حذف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    context.read<NotesProvider>().loadNotes();
  }
}
