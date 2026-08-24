import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/exam_model.dart';
import '../../data/repositories/exam_repository.dart';
import '../groups/groups_provider.dart';

class AddEditExamScreen extends StatefulWidget {
  final ExamModel? exam;
  final String? preselectedGroupId;

  const AddEditExamScreen({
    super.key,
    this.exam,
    this.preselectedGroupId,
  });

  @override
  State<AddEditExamScreen> createState() => _AddEditExamScreenState();
}

class _AddEditExamScreenState extends State<AddEditExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '20');
  final _uuid = const Uuid();
  final _examRepo = ExamRepository();

  String? _selectedGroupId;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  bool get isEditing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final e = widget.exam!;
      _nameCtrl.text = e.name;
      _marksCtrl.text = e.totalMarks.toInt().toString();
      _selectedGroupId = e.groupId;
      _selectedDate = e.date;
    } else {
      _selectedGroupId = widget.preselectedGroupId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>().groups;
    if (_selectedGroupId == null && groups.isNotEmpty) {
      _selectedGroupId = groups.first.id;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل الاختبار' : 'إنشاء اختبار جديد',
          style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Exam Name
            TextFormField(
              controller: _nameCtrl,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'عنوان / اسم الاختبار *',
                hintText: 'مثال: امتحان شهر أكتوبر - الوحدة الأولى',
                prefixIcon: Icon(Icons.quiz_rounded, color: AppColors.primary),
              ),
              validator: (v) => AppValidators.required(v, 'اسم الاختبار'),
            ),

            const SizedBox(height: 16),

            // Group Picker with Subject
            DropdownButtonFormField<String>(
              initialValue: _selectedGroupId,
              decoration: const InputDecoration(
                labelText: 'المجموعة *',
                prefixIcon: Icon(Icons.groups_rounded, color: AppColors.primary),
              ),
              items: groups
                  .map((g) => DropdownMenuItem(
                        value: g.id,
                        child: Text(
                          g.subject != null ? '${g.name} (📖 ${g.subject!})' : g.name,
                          style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedGroupId = v),
              validator: (v) => v == null ? 'يرجى اختيار مجموعة' : null,
            ),

            const SizedBox(height: 16),

            // Total Marks
            TextFormField(
              controller: _marksCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'الدرجة النهائية للاختبار *',
                hintText: 'مثال: 20 أو 50 أو 100',
                prefixIcon: Icon(Icons.grade_rounded, color: AppColors.primary),
              ),
              validator: AppValidators.positiveNumber,
            ),

            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ الاختبار',
                  prefixIcon: Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                ),
                child: Text(
                  ArabicNumbers.convert(DateFormat('yyyy/MM/dd').format(_selectedDate)),
                  style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'إلغاء',
                    outlined: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: isEditing ? 'حفظ التعديلات' : 'إنشاء الاختبار',
                    loading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) return;

    setState(() => _saving = true);

    final exam = ExamModel(
      id: isEditing ? widget.exam!.id : _uuid.v4(),
      groupId: _selectedGroupId!,
      name: _nameCtrl.text.trim(),
      totalMarks: double.tryParse(_marksCtrl.text) ?? 20,
      date: _selectedDate,
    );

    if (isEditing) {
      await _examRepo.update(exam);
    } else {
      await _examRepo.insert(exam);
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}
