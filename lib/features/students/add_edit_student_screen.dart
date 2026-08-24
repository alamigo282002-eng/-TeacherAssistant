import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/student_repository.dart';
import '../groups/groups_provider.dart';
import 'import_contacts_sheet.dart';
import 'students_provider.dart';

class AddEditStudentScreen extends StatefulWidget {
  final StudentModel? student;
  final String? preselectedGroupId;
  final List<GroupModel>? groups;

  const AddEditStudentScreen({
    super.key,
    this.student,
    this.preselectedGroupId,
    this.groups,
  });

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _discountAmountCtrl = TextEditingController();
  final _discountReasonCtrl = TextEditingController();
  final _specialNoteCtrl = TextEditingController();
  final _uuid = const Uuid();

  int _level = 5;
  String? _selectedGroupId;
  String _discountType = 'none'; // 'none' | 'fixed' | 'percent' | 'exempt' | 'sibling'
  String? _selectedSiblingId;
  String? _selectedSiblingName;
  bool _isAdvancedExpanded = false;
  bool _saving = false;
  List<StudentModel> _otherStudents = [];

  bool get isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _loadOtherStudents();
    if (isEditing) {
      final s = widget.student!;
      _nameCtrl.text = s.name;
      _phoneCtrl.text = s.phone;
      _parentPhoneCtrl.text = s.parentPhone;
      _level = s.level;
      _selectedGroupId = s.groupId;
      _discountType = s.discountType;
      _discountAmountCtrl.text = s.discountAmount > 0
          ? (s.discountAmount % 1 == 0 ? s.discountAmount.toInt().toString() : s.discountAmount.toString())
          : '';
      _discountReasonCtrl.text = s.discountReason;
      _selectedSiblingId = s.siblingId;
      _selectedSiblingName = s.siblingName;
      _specialNoteCtrl.text = s.specialNote;
      // Auto-expand if student has advanced data
      if (s.hasDiscount || s.specialNote.isNotEmpty || s.siblingId != null) {
        _isAdvancedExpanded = true;
      }
    } else {
      _selectedGroupId = widget.preselectedGroupId;
    }
  }

  Future<void> _loadOtherStudents() async {
    try {
      final all = await StudentRepository().getAll();
      if (mounted) {
        setState(() {
          _otherStudents = isEditing
              ? all.where((s) => s.id != widget.student!.id).toList()
              : all;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _discountAmountCtrl.dispose();
    _discountReasonCtrl.dispose();
    _specialNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableGroups = widget.groups ?? context.watch<GroupsProvider>().groups;
    if (_selectedGroupId == null && availableGroups.isNotEmpty) {
      _selectedGroupId = availableGroups.first.id;
    }

    final currentGroup = availableGroups.where((g) => g.id == _selectedGroupId).firstOrNull;
    final groupPrice = currentGroup?.monthlyPrice ?? 0.0;
    final discountAmount = double.tryParse(_discountAmountCtrl.text) ?? 0.0;

    double calculatedDue = groupPrice;
    if (_discountType == 'exempt') {
      calculatedDue = 0.0;
    } else if (_discountType == 'fixed' || _discountType == 'sibling') {
      calculatedDue = (groupPrice - discountAmount).clamp(0.0, double.infinity);
    } else if (_discountType == 'percent') {
      calculatedDue = (groupPrice * (1.0 - (discountAmount / 100.0))).clamp(0.0, double.infinity);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل بيانات الطالب' : 'إضافة طالب جديد',
          style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Basic Info Card
            _field(_nameCtrl, 'اسم الطالب *', Icons.person_outline_rounded,
                validator: (v) => AppValidators.required(v, 'اسم الطالب')),
            const SizedBox(height: 14),

            _field(_phoneCtrl, 'رقم هاتف الطالب', Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) => AppValidators.phone(v),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.contacts_outlined),
                  tooltip: 'استيراد من جهات الاتصال',
                  onPressed: () async {
                    final contact = await ImportContactsSheet.show(context);
                    if (contact != null) {
                      setState(() {
                        if (_nameCtrl.text.isEmpty) {
                          _nameCtrl.text = contact['name'] ?? '';
                        }
                        _phoneCtrl.text = contact['phone'] ?? '';
                      });
                    }
                  },
                )),
            const SizedBox(height: 14),

            _field(_parentPhoneCtrl, 'رقم هاتف ولي الأمر', Icons.phone_in_talk_rounded,
                keyboardType: TextInputType.phone,
                validator: (v) => AppValidators.phone(v),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.contacts_outlined),
                  tooltip: 'استيراد من جهات الاتصال',
                  onPressed: () async {
                    final contact = await ImportContactsSheet.show(context);
                    if (contact != null) {
                      setState(() {
                        _parentPhoneCtrl.text = contact['phone'] ?? '';
                      });
                    }
                  },
                )),
            const SizedBox(height: 20),

            // Group Picker with Subject
            _sectionLabel('المجموعة التابع لها *'),
            DropdownButtonFormField<String>(
              initialValue: _selectedGroupId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.groups_rounded, color: AppColors.primary),
              ),
              items: availableGroups
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

            const SizedBox(height: 20),

            // Level Slider
            _sectionLabel('المستوى التقديري'),
            Row(
              children: [
                Text('مبتدئ', style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.error)),
                Expanded(
                  child: Slider(
                    value: _level.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: _levelColor(_level),
                    label: _levelLabel(_level),
                    onChanged: (v) => setState(() => _level = v.round()),
                  ),
                ),
                Text('ممتاز', style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.green)),
              ],
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _levelColor(_level).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_levelLabel(_level)} (${ArabicNumbers.convert(_level)}/١٠)',
                  style: GoogleFonts.changa(
                    color: _levelColor(_level),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -------------------------------------------------------------
            // ADVANCED SETTINGS SECTION (الإعدادات المتقدمة للطالب)
            // -------------------------------------------------------------
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isAdvancedExpanded ? AppColors.primary.withValues(alpha: 0.3) : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Expand / Collapse Header
                  InkWell(
                    onTap: () => setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.chipTeal,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الإعدادات المتقدمة للطالب',
                                  style: GoogleFonts.changa(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'خصومات الأخوة، ملاحظة خاصة تحت الاسم، طريقة الدفع',
                                  style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _isAdvancedExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isAdvancedExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Special Note (ملاحظة خاصة تظهر في الكارت الخارجي)
                          _field(
                            _specialNoteCtrl,
                            'ملاحظة خاصة (تظهر تحت اسم الطالب)',
                            Icons.edit_note_rounded,
                            hint: 'مثال: ممتاز في النحو / يحتاج تذكير بالواجب / دفع مقدم...',
                          ),
                          const SizedBox(height: 16),

                          // 3. Discount & Exemption Section with Sibling Discount
                          _sectionLabel('الخصومات والإعفاءات المالية'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildDiscountTypeChip('بدون خصم', 'none'),
                              _buildDiscountTypeChip('خصم الأخوة 👨‍👩‍👧', 'sibling'),
                              _buildDiscountTypeChip('خصم مبلغ ثابت', 'fixed'),
                              _buildDiscountTypeChip('خصم نسبة %', 'percent'),
                              _buildDiscountTypeChip('إعفاء كامل', 'exempt'),
                            ],
                          ),

                          // Sibling Selector dropdown when 'sibling' is chosen
                          if (_discountType == 'sibling') ...[
                            const SizedBox(height: 14),
                            if (_otherStudents.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.orangeSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'لا يوجد طلاب آخرون مسجلون لاختيار الأخ/القريب منهم',
                                  style: GoogleFonts.tajawal(fontSize: 12, color: const Color(0xFF856404), fontWeight: FontWeight.bold),
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSiblingId,
                                decoration: const InputDecoration(
                                  labelText: 'اختر الأخ أو القريب من الطلاب *',
                                  prefixIcon: Icon(Icons.family_restroom_rounded, color: AppColors.primary),
                                ),
                                items: _otherStudents
                                    .map((s) => DropdownMenuItem(
                                          value: s.id,
                                          child: Text(
                                            s.name,
                                            style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedSiblingId = v;
                                    final sib = _otherStudents.where((s) => s.id == v).firstOrNull;
                                    _selectedSiblingName = sib?.name;
                                    if (_discountReasonCtrl.text.isEmpty) {
                                      _discountReasonCtrl.text = 'خصم أخوة مع الطالب (${sib?.name ?? ""})';
                                    }
                                  });
                                },
                              ),
                            const SizedBox(height: 12),
                            _field(
                              _discountAmountCtrl,
                              'قيمة خصم الأخوة (جنيه)',
                              Icons.discount_rounded,
                              keyboardType: TextInputType.number,
                              hint: 'أدخل المبلغ المخصوم للأخوة',
                              onChanged: (_) => setState(() {}),
                            ),
                          ],

                          if (_discountType == 'fixed' || _discountType == 'percent') ...[
                            const SizedBox(height: 14),
                            _field(
                              _discountAmountCtrl,
                              _discountType == 'fixed' ? 'قيمة الخصم (جنيه)' : 'نسبة الخصم (%)',
                              Icons.discount_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],

                          if (_discountType != 'none') ...[
                            const SizedBox(height: 14),
                            _field(
                              _discountReasonCtrl,
                              'سبب أو تفاصيل الخصم (اختياري)',
                              Icons.note_alt_outlined,
                              hint: 'مثال: خصم أخوة / حالة خاصة / متفوق / أبناء معلمين...',
                            ),
                            const SizedBox(height: 12),

                            // Real-time Preview Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: _discountType == 'exempt' ? AppColors.greenSoft : AppColors.chipTeal,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _discountType == 'exempt' ? Icons.check_circle_rounded : Icons.calculate_outlined,
                                    color: _discountType == 'exempt' ? AppColors.green : AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _discountType == 'exempt'
                                          ? '🎉 الطالب معفى تماماً من الدفع الشهري'
                                          : 'المطلوب بعد الخصم: ${ArabicNumbers.convert(calculatedDue.toStringAsFixed(1))} جنيه (من أصل ${ArabicNumbers.convert(groupPrice.round())} ج)',
                                      style: GoogleFonts.tajawal(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _discountType == 'exempt' ? AppColors.green : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
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
                    label: isEditing ? 'حفظ التعديلات' : 'إضافة الطالب',
                    loading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }



  Widget _buildDiscountTypeChip(String label, String type) {
    final selected = _discountType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.chipTeal,
      labelStyle: GoogleFonts.tajawal(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: selected ? Colors.white : (isDark ? AppColors.darkText : AppColors.chipTealText),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (val) {
        if (val) {
          setState(() {
            _discountType = type;
            if (type == 'exempt') {
              _discountAmountCtrl.text = '100';
            }
            if (type == 'sibling' && _discountAmountCtrl.text.isEmpty) {
              _discountAmountCtrl.text = '20';
            }
          });
        }
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number || keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.changa(
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Color _levelColor(int level) {
    if (level <= 3) return AppColors.error;
    if (level <= 6) return AppColors.orange;
    return AppColors.green;
  }

  String _levelLabel(int level) {
    if (level <= 3) return 'يحتاج دعم';
    if (level <= 6) return 'متوسط';
    if (level <= 8) return 'جيد جداً';
    return 'ممتاز ومتميز';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اختر مجموعة أولاً', style: GoogleFonts.tajawal())),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<StudentsProvider>();

    final student = StudentModel(
      id: isEditing ? widget.student!.id : _uuid.v4(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      parentPhone: _parentPhoneCtrl.text.trim(),
      level: _level,
      groupId: _selectedGroupId!,
      points: isEditing ? widget.student!.points : 0,
      discountAmount: double.tryParse(_discountAmountCtrl.text) ?? 0.0,
      discountType: _discountType,
      discountReason: _discountReasonCtrl.text.trim(),
      siblingId: _discountType == 'sibling' ? _selectedSiblingId : null,
      siblingName: _discountType == 'sibling' ? _selectedSiblingName : null,
      specialNote: _specialNoteCtrl.text.trim(),
      status: isEditing ? widget.student!.status : StudentStatus.active,
      createdAt: isEditing ? widget.student!.createdAt : DateTime.now(),
    );

    if (isEditing) {
      await provider.updateStudent(student);
    } else {
      await provider.addStudent(student);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? '✅ تم تحديث بيانات الطالب' : '✅ تم إضافة الطالب بنجاح',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }
}

