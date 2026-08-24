import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../data/models/note_model.dart';
import '../groups/groups_provider.dart';
import '../students/students_provider.dart';
import 'notes_provider.dart';

class AddNoteScreen extends StatefulWidget {
  final String? initialStudentId;
  final String? initialGroupId;
  final NoteModel? editingNote;
  final NoteModel? existingNote;

  const AddNoteScreen({
    super.key,
    this.initialStudentId,
    this.initialGroupId,
    this.editingNote,
    this.existingNote,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _contentController = TextEditingController();
  final _uuid = const Uuid();

  String _noteType = 'general'; // 'general', 'student', 'group'
  String? _selectedStudentId;
  String? _selectedGroupId;
  String _selectedColor = '#FEF3C7';
  bool _isPinned = false;
  String _selectedCategory = 'general';

  bool _reminderEnabled = false;
  String _reminderTimingType = 'specific_time';
  DateTime _reminderDateTime = DateTime.now().add(const Duration(hours: 1));
  String? _reminderGroupId;

  bool _saving = false;

  final List<Map<String, String>> _palette = const [
    {'hex': '#FEF3C7', 'name': 'أصفر كلاسيكي'},
    {'hex': '#DCFCE7', 'name': 'أخضر نعناعي'},
    {'hex': '#DBEAFE', 'name': 'أزرق سماوي'},
    {'hex': '#FCE7F3', 'name': 'وردي هادئ'},
    {'hex': '#EDE9FE', 'name': 'بنفسجي لافندر'},
    {'hex': '#F3F4F6', 'name': 'رمادي حيادي'},
  ];

  NoteModel? get activeNote => widget.editingNote ?? widget.existingNote;

  @override
  void initState() {
    super.initState();
    final note = activeNote;
    if (note != null) {
      _contentController.text = note.content;
      _noteType = note.type;
      _selectedColor = note.color;
      _isPinned = note.isPinned;
      _selectedCategory = note.category;
      _reminderEnabled = note.reminderEnabled;
      if (note.reminderTime != null) {
        _reminderDateTime = note.reminderTime!;
      }
      _reminderTimingType = note.reminderTimingType ?? 'specific_time';
      _reminderGroupId = note.reminderGroupId;

      if (note.type == 'student') {
        _selectedStudentId = note.targetId;
      } else if (note.type == 'group') {
        _selectedGroupId = note.targetId;
      }
    } else {
      if (widget.initialStudentId != null) {
        _noteType = 'student';
        _selectedStudentId = widget.initialStudentId;
      } else if (widget.initialGroupId != null) {
        _noteType = 'group';
        _selectedGroupId = widget.initialGroupId;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentsProvider>().loadStudents();
      context.read<GroupsProvider>().loadGroups();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFFFEF3C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studentsP = context.watch<StudentsProvider>();
    final groupsP = context.watch<GroupsProvider>();

    final students = studentsP.allStudents;
    final groups = groupsP.groups;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          activeNote != null ? 'تعديل الملاحظة' : 'تدوين ملاحظة جديدة',
          style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.orange : null,
            ),
            tooltip: _isPinned ? 'مثبتة بالأعلى' : 'تثبيت للأعلى',
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            tooltip: 'حفظ',
            onPressed: _saving ? null : _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Note Type Selector (عام / طالب / مجموعة)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                children: [
                  _buildTypeTab('general', '💡 عامة وخواطر', Icons.lightbulb_outline_rounded),
                  _buildTypeTab('student', '👨‍🎓 خاصة بطالب', Icons.school_rounded),
                  _buildTypeTab('group', '👥 خاصة بمجموعة', Icons.groups_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Conditional Target Dropdown (Student / Group)
            if (_noteType == 'student') ...[
              _buildDropdownContainer(
                isDark: isDark,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedStudentId,
                    hint: Text('اختر الطالب المعني بالملاحظة...', style: GoogleFonts.tajawal(color: AppColors.muted)),
                    items: students.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(s.name, style: GoogleFonts.tajawal(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStudentId = val),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ] else if (_noteType == 'group') ...[
              _buildDropdownContainer(
                isDark: isDark,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGroupId,
                    hint: Text('اختر المجموعة المعنية بالملاحظة...', style: GoogleFonts.tajawal(color: AppColors.muted)),
                    items: groups.map((g) {
                      return DropdownMenuItem<String>(
                        value: g.id,
                        child: Text(
                          g.name + (g.subject != null ? ' (📖 ${g.subject})' : ''),
                          style: GoogleFonts.tajawal(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedGroupId = val),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. Note Content Text Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : _parseColor(_selectedColor),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : _parseColor(_selectedColor).withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 8,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? AppColors.darkText : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب نص الملاحظة هنا بكل حرية...\n(مثال: مراجعة واجبات الفصل، أو متابعة مستوى الطالب في النحو)',
                  hintStyle: GoogleFonts.tajawal(
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Color Palette
            Text(
              'لون بطاقة الملاحظة',
              style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _palette.map((p) {
                final isSelected = _selectedColor == p['hex'];
                final c = _parseColor(p['hex']!);
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = p['hex']!),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.4),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected ? const Icon(Icons.check_rounded, size: 20, color: AppColors.primary) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 5. Smart Reminder Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.alarm_rounded, color: AppColors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'تذكير ذكي بالإشعار ⏰',
                            style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Switch(
                        value: _reminderEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _reminderEnabled = val),
                      ),
                    ],
                  ),
                  if (_reminderEnabled) ...[
                    const Divider(height: 20),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'موعد التذكير:',
                              style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
                            ),
                            Text(
                              ArabicNumbers.convert(DateFormat('yyyy/MM/dd - hh:mm a').format(_reminderDateTime)),
                              style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. Save Button
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveNote,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                activeNote != null ? 'حفظ التعديلات' : 'حفظ الملاحظة',
                style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String id, String label, IconData icon) {
    final isSelected = _noteType == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _noteType = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContainer({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: child,
    );
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderDateTime),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _reminderDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى كتابة نص الملاحظة أولاً', style: GoogleFonts.tajawal())),
      );
      return;
    }

    String? targetId;
    if (_noteType == 'student') {
      targetId = _selectedStudentId;
    } else if (_noteType == 'group') {
      targetId = _selectedGroupId;
    }

    setState(() => _saving = true);

    final note = NoteModel(
      id: activeNote?.id ?? _uuid.v4(),
      type: _noteType,
      targetId: targetId,
      content: content,
      color: _selectedColor,
      isPinned: _isPinned,
      category: _selectedCategory,
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderEnabled ? _reminderDateTime : null,
      reminderTimingType: _reminderTimingType,
      reminderGroupId: _reminderGroupId,
      createdAt: activeNote?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success;
    if (activeNote != null) {
      success = await context.read<NotesProvider>().updateNote(note);
    } else {
      success = await context.read<NotesProvider>().addNote(note);
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }
}

