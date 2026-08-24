import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/group_model.dart';
import '../settings/settings_provider.dart';
import 'groups_provider.dart';

class AddEditGroupScreen extends StatefulWidget {
  final GroupModel? group;

  const AddEditGroupScreen({super.key, this.group});

  @override
  State<AddEditGroupScreen> createState() => _AddEditGroupScreenState();
}

class _AddEditGroupScreenState extends State<AddEditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _customLocationController = TextEditingController();
  final _sessionsCountController = TextEditingController(text: '8');
  final _whatsappLinkController = TextEditingController();
  final _uuid = const Uuid();

  GroupType _type = GroupType.center;
  String? _selectedSubject;
  bool _subjectError = false;
  GroupStatus _status = GroupStatus.active;
  List<GroupDay> _days = [];
  bool _saving = false;
  bool _showAdvancedSettings = false;
  bool _autoDivide = true;
  final _sessionPriceController = TextEditingController();
  final _onlineMeetingUrlController = TextEditingController();
  String _paymentMode = 'monthly'; // 'monthly' | 'per_session'
  String _onlinePlatform = 'zoom'; // 'zoom' | 'teams' | 'meet' | 'custom'
  String _subscriptionPeriod = 'شهر كامل (٤ أسابيع)';

  bool get isEditing => widget.group != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final g = widget.group!;
      _nameController.text = g.name;
      _priceController.text = g.monthlyPrice.toInt().toString();
      _type = g.type;
      _selectedSubject = g.subject;
      _status = g.status;
      _days = List.from(g.days);
      _paymentMode = g.paymentMode;
      _whatsappLinkController.text = g.whatsappLink ?? '';
      _onlinePlatform = g.onlinePlatform ?? 'zoom';
      _onlineMeetingUrlController.text = g.onlineMeetingUrl ?? '';
      if (g.sessionPrice > 0) {
        _sessionPriceController.text = g.sessionPrice.toInt().toString();
      }
    } else {
      _days = [const GroupDay(day: AppStrings.saturday, time: '17:00')];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _customLocationController.dispose();
    _sessionsCountController.dispose();
    _sessionPriceController.dispose();
    _whatsappLinkController.dispose();
    _onlineMeetingUrlController.dispose();
    super.dispose();
  }

  void _addNewSubjectDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة مادة جديدة', style: GoogleFonts.changa(fontSize: 16)),
        content: TextField(
          controller: textController,
          textDirection: TextDirection.rtl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'اسم المادة (مثال: جيولوجيا)',
            labelText: 'المادة الجديدة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newSubject = textController.text.trim();
              if (newSubject.isNotEmpty) {
                await context.read<SettingsProvider>().addSubject(newSubject);
                setState(() {
                  _selectedSubject = newSubject;
                  _subjectError = false;
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة وتحديد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mySubjects = context.watch<SettingsProvider>().mySubjects;

    if (_selectedSubject == null && mySubjects.isNotEmpty && !isEditing) {
      _selectedSubject = mySubjects.first;
    }

    // Auto calculate per session price
    final monthlyPrice = double.tryParse(_priceController.text) ?? 0;
    final sessionsCount = int.tryParse(_sessionsCountController.text) ?? 8;
    final perSessionPrice = (sessionsCount > 0 && monthlyPrice > 0)
        ? (monthlyPrice / sessionsCount)
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل المجموعة' : 'إضافة مجموعة جديدة',
          style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Group Name
            _section('اسم المجموعة *'),
            _buildTextField(
              controller: _nameController,
              label: 'اسم المجموعة',
              hint: 'مثال: ثانوية عامة - سنتر النور',
              icon: Icons.drive_file_rename_outline,
              validator: (v) => AppValidators.required(v, 'اسم المجموعة'),
            ),

            const SizedBox(height: 20),

            // 2. Mandatory Subject Selection
            Row(
              children: [
                _section('المادة الدراسية * (إجباري)'),
                if (_subjectError)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: Text(
                      'يرجى تحديد مادة',
                      style: GoogleFonts.tajawal(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _subjectError
                      ? AppColors.red
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: _subjectError ? 1.5 : 1,
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...mySubjects.map((s) {
                    final isSelected = _selectedSubject == s;
                    return FilterChip(
                      label: Text(s),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSubject = selected ? s : null;
                          if (selected) _subjectError = false;
                        });
                      },
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      backgroundColor: isDark ? AppColors.darkSurface : AppColors.chipTeal,
                      labelStyle: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkText : AppColors.chipTealText),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                    label: Text('➕ مادة جديدة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: _addNewSubjectDialog,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Section Divider: Location ──
            _sectionDivider('📍 المكان والنوع', isDark),
            const SizedBox(height: 12),

            // 3. Type Selector (سنتر / أونلاين / أخرى)
            _section('نوع المجموعة / المكان'),
            _buildTypeSelector(isDark),

            // Optional custom location field when "أخرى" is selected
            if (_type == GroupType.other) ...[
              const SizedBox(height: 12),
              _buildTextField(
                controller: _customLocationController,
                label: 'حدد المكان أو نوع المجموعة',
                hint: 'مثال: درس خصوصي بالمنزل / أكاديمية / مكتبة...',
                icon: Icons.location_on_outlined,
              ),
            ],

            // Online note (simplified - no platform picker)
            if (_type == GroupType.online) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.videocam_rounded, color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مجموعة أونلاين - يمكنك مشاركة رابط الحصة عبر جروب الواتساب',
                        style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Section Divider: Schedule & Payment ──
            _sectionDivider('💰 المواعيد والمالية', isDark),
            const SizedBox(height: 12),

            // 4. Payment Mode & Pricing
            _section('نظام الدفع والمصروفات *'),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentModeTab(
                    title: '📅 دفع شهري',
                    subtitle: 'اشتراك ثابت لكل شهر',
                    mode: 'monthly',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPaymentModeTab(
                    title: '⏱️ دفع بالحصة',
                    subtitle: 'محاسبة بسعر كل حصة',
                    mode: 'per_session',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_paymentMode == 'monthly') ...[
              _buildTextField(
                controller: _priceController,
                label: 'السعر الشهري للطالب (جنيه) *',
                hint: 'مثال: 180',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                validator: (v) => _paymentMode == 'monthly' ? AppValidators.positiveNumber(v) : null,
                onChanged: (_) => setState(() {}),
              ),
            ] else ...[
              _buildTextField(
                controller: _sessionPriceController,
                label: 'سعر الحصة الواحدة للطالب (جنيه) *',
                hint: 'مثال: 25',
                icon: Icons.access_time_filled_rounded,
                keyboardType: TextInputType.number,
                validator: (v) => _paymentMode == 'per_session' ? AppValidators.positiveNumber(v) : null,
                onChanged: (_) => setState(() {}),
              ),
            ],

            const SizedBox(height: 20),

            // 5. Days & Times List
            _section('الأيام والمواعيد 📅'),
            _buildSmartSchedulePresets(isDark),
            ..._buildDaysList(isDark),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _addDay,
              icon: const Icon(Icons.add_rounded),
              label: Text('إضافة موعد آخر ⚡', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),

            // 6. WhatsApp Group Link (رابط جروب الواتساب)
            _section('جروب الواتساب للمجموعة (اختياري)'),
            TextFormField(
              controller: _whatsappLinkController,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.url,
              style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'رابط الانضمام لجروب الواتساب',
                hintText: 'https://chat.whatsapp.com/XXXXX',
                prefixIcon: Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
              ),
            ),

            if (isEditing) ...[
              const SizedBox(height: 20),
              _section('حالة المجموعة'),
              _buildStatusSelector(isDark),
            ],

            const SizedBox(height: 24),

            // 7. Advanced Settings Section (عدد الحصص والتقسيم الشهري)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: ExpansionTile(
                initiallyExpanded: _showAdvancedSettings,
                onExpansionChanged: (v) => setState(() => _showAdvancedSettings = v),
                leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
                title: Text(
                  'إعدادات متقدمة (عدد الحصص والتقسيم)',
                  style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Sessions per month
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'عدد الحصص في الدورة / الشهر:',
                          style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 44,
                        child: TextField(
                          controller: _sessionsCountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.changa(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: '8',
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Subscription Duration / Division dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _subscriptionPeriod,
                    decoration: const InputDecoration(
                      labelText: 'مدة الاشتراك / التقسيم',
                      prefixIcon: Icon(Icons.date_range_rounded, color: AppColors.primary),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'شهر كامل (٤ أسابيع)', child: Text('شهر كامل (٤ أسابيع)')),
                      DropdownMenuItem(value: 'نصف شهر (أسبوعين)', child: Text('نصف شهر (أسبوعين)')),
                      DropdownMenuItem(value: 'دورة مكثفة (محدد بعدد الحصص)', child: Text('دورة مكثفة (محدد بعدد الحصص)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _subscriptionPeriod = val;
                          if (val.contains('نصف')) {
                            _sessionsCountController.text = '4';
                          } else if (val.contains('شهر كامل')) {
                            _sessionsCountController.text = '8';
                          }
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Smart Calculated Session Price Badge
                  if (perSessionPrice > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.chipTeal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'سعر الحصة التقديري: ${ArabicNumbers.convert(perSessionPrice.toStringAsFixed(1))} جنيه / للحصة',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Auto divide checkbox
                  CheckboxListTile(
                    value: _autoDivide,
                    onChanged: (v) => setState(() => _autoDivide = v ?? true),
                    title: Text(
                      'تقسيم المبلغ تلقائيًا',
                      style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'حساب سعر الحصة بقسمة السعر الشهري على عدد الحصص',
                      style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                    ),
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Manual Session Price
                  if (!_autoDivide) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'سعر الحصة (جنيه):',
                            style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 44,
                          child: TextField(
                            controller: _sessionPriceController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.changa(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '20',
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
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
                    label: isEditing ? 'حفظ التعديلات' : 'إضافة المجموعة',
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

  Widget _sectionDivider(String title, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.changa(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkText : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPaymentModeTab({
    required String title,
    required String subtitle,
    required String mode,
    required bool isDark,
  }) {
    final isSelected = _paymentMode == mode;
    return InkWell(
      onTap: () => setState(() => _paymentMode = mode),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
              : (Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.changa(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.ink),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.changa(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Row(
      children: GroupType.values.map((t) {
        final selected = _type == t;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _type = t),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : (Theme.of(context).cardColor),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    t.label,
                    style: GoogleFonts.changa(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelector(bool isDark) {
    return Row(
      children: GroupStatus.values.map((s) {
        final selected = _status == s;
        final isAct = s == GroupStatus.active;
        final color = isAct ? AppColors.green : AppColors.muted;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _status = s),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? color
                      : (Theme.of(context).cardColor),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? color
                        : (isDark ? AppColors.darkBorder : AppColors.border),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    s.label,
                    style: GoogleFonts.changa(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSmartPairedDay(String primaryDay) {
    switch (primaryDay) {
      case 'السبت':
        return 'الثلاثاء';
      case 'الأحد':
        return 'الأربعاء';
      case 'الاثنين':
        return 'الخميس';
      case 'الثلاثاء':
        return 'السبت';
      case 'الأربعاء':
        return 'الأحد';
      case 'الخميس':
        return 'الاثنين';
      case 'الجمعة':
        return 'الثلاثاء';
      default:
        return 'الثلاثاء';
    }
  }

  String _getSmartThirdDay(String firstDay, String secondDay) {
    if ((firstDay == 'السبت' && secondDay == 'الثلاثاء') || (firstDay == 'الثلاثاء' && secondDay == 'السبت')) {
      return 'الخميس';
    }
    if ((firstDay == 'السبت' && secondDay == 'الاثنين') || (firstDay == 'الاثنين' && secondDay == 'السبت')) {
      return 'الأربعاء';
    }
    if ((firstDay == 'الأحد' && secondDay == 'الأربعاء') || (firstDay == 'الأربعاء' && secondDay == 'الأحد')) {
      return 'الجمعة';
    }
    if ((firstDay == 'الأحد' && secondDay == 'الثلاثاء') || (firstDay == 'الثلاثاء' && secondDay == 'الأحد')) {
      return 'الخميس';
    }
    return 'السبت';
  }

  void _onDayChanged(int index, String newDay) {
    if (index == 0) {
      final oldDay = _days[0].day;
      _days[0] = GroupDay(day: newDay, time: _days[0].time, durationMinutes: _days[0].durationMinutes);

      // If Day 2 exists and was paired with oldDay, automatically adjust it to the smart pair of newDay
      if (_days.length >= 2) {
        final expectedOldSecond = _getSmartPairedDay(oldDay);
        if (_days[1].day == expectedOldSecond) {
          _days[1] = GroupDay(day: _getSmartPairedDay(newDay), time: _days[1].time, durationMinutes: _days[1].durationMinutes);
        }
      }
    } else {
      _days[index] = GroupDay(day: newDay, time: _days[index].time, durationMinutes: _days[index].durationMinutes);
    }
    setState(() {});
  }

  void _applySchedulePreset(List<String> daysList) {
    final baseTime = _days.isNotEmpty ? _days[0].time : '17:00';
    final baseDuration = _days.isNotEmpty ? _days[0].durationMinutes : 60;
    setState(() {
      _days = daysList.map((d) => GroupDay(day: d, time: baseTime, durationMinutes: baseDuration)).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ تم تطبيق جدول (${daysList.join(' + ')}) بتوقيت ${ArabicNumbers.formatTime12(baseTime)}', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        duration: const Duration(milliseconds: 1400),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSmartSchedulePresets(bool isDark) {
    final presets = [
      {'label': 'السبت والثلاثاء ⚡', 'days': ['السبت', 'الثلاثاء']},
      {'label': 'الأحد والأربعاء ⚡', 'days': ['الأحد', 'الأربعاء']},
      {'label': 'الاثنين والخميس ⚡', 'days': ['الاثنين', 'الخميس']},
      {'label': 'سبت + اثنين + أربعاء ⚡', 'days': ['السبت', 'الاثنين', 'الأربعاء']},
      {'label': 'أحد + ثلاثاء + خميس ⚡', 'days': ['الأحد', 'الثلاثاء', 'الخميس']},
      {'label': 'حصة واحدة (السبت) ⚡', 'days': ['السبت']},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFD97706)),
            const SizedBox(width: 6),
            Text(
              'جداول ذكية مقترحة:',
              style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkMuted : AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final daysList = p['days'] as List<String>;
              final isCurrent = _days.length == daysList.length &&
                  _days.asMap().entries.every((e) => e.value.day == daysList[e.key]);

              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ActionChip(
                  label: Text(p['label'] as String),
                  backgroundColor: isCurrent
                      ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                      : (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9)),
                  labelStyle: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    color: isCurrent
                        ? (isDark ? AppColors.darkBg : Colors.white)
                        : (isDark ? Colors.white70 : AppColors.ink),
                  ),
                  side: BorderSide(
                    color: isCurrent
                        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                        : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onPressed: () => _applySchedulePreset(daysList),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  bool _hasIntraGroupConflict(int index) {
    if (index >= _days.length) return false;
    final target = _days[index];
    for (int j = 0; j < _days.length; j++) {
      if (j == index) continue;
      final other = _days[j];
      if (target.day == other.day) {
        if (target.time == other.time || target.overlapsWith(other)) {
          return true;
        }
      }
    }
    return false;
  }

  List<String> _findConflictsForDay(GroupDay day) {
    final groupsP = context.read<GroupsProvider>();
    final currentGroupId = widget.group?.id;
    final conflicts = <String>[];

    for (final other in groupsP.groups) {
      if (other.id == currentGroupId || other.status != GroupStatus.active) continue;
      for (final otherDay in other.days) {
        if (day.overlapsWith(otherDay)) {
          conflicts.add('${other.name} (${otherDay.day} ${otherDay.time})');
        }
      }
    }
    return conflicts;
  }

  List<Widget> _buildDaysList(bool isDark) {
    return _days.asMap().entries.map((entry) {
      final i = entry.key;
      final day = entry.value;
      final externalConflicts = _findConflictsForDay(day);
      final hasInternalConflict = _hasIntraGroupConflict(i);
      final hasAnyConflict = externalConflicts.isNotEmpty || hasInternalConflict;

      final cardBgColor = hasInternalConflict
          ? (isDark ? const Color(0xFF452B04) : const Color(0xFFFEF3C7))
          : (externalConflicts.isNotEmpty
              ? (isDark ? const Color(0xFF382305) : const Color(0xFFFFFBEB))
              : (isDark ? AppColors.darkSurface : Colors.white));

      final cardBorderColor = hasInternalConflict
          ? const Color(0xFFF59E0B)
          : (externalConflicts.isNotEmpty
              ? AppColors.orange
              : (isDark ? AppColors.darkBorder : AppColors.border));

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cardBorderColor,
            width: hasAnyConflict ? 1.8 : 1,
          ),
          boxShadow: [
            if (hasInternalConflict)
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
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
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: day.day,
                    isExpanded: true,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    items: AppStrings.arabicDays
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        _onDayChanged(i, v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: () => _pickTime(i, day.time),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF7F9FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            ArabicNumbers.formatTime12(day.time),
                            style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: [30, 45, 60, 75, 90, 120, 150, 180].contains(day.durationMinutes) ? day.durationMinutes : 60,
                    isExpanded: true,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('٣٠ دقيقة', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 45, child: Text('٤٥ دقيقة', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 60, child: Text('ساعة واحدة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      DropdownMenuItem(value: 75, child: Text('ساعة وربع', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 90, child: Text('ساعة ونصف', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 120, child: Text('ساعتان', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 150, child: Text('ساعتان ونصف', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 180, child: Text('٣ ساعات', style: TextStyle(fontSize: 11))),
                    ],
                    onChanged: (dur) {
                      if (dur != null) {
                        setState(() => _days[i] = GroupDay(day: day.day, time: day.time, durationMinutes: dur));
                      }
                    },
                  ),
                ),
                if (_days.length > 1) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.red, size: 20),
                    onPressed: () => setState(() => _days.removeAt(i)),
                  ),
                ],
              ],
            ),
            if (hasInternalConflict) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '⚠️ تنبيه: موعد مكرر أو متداخل في نفس اليوم (${day.day}) بنفس التوقيت!',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (externalConflicts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '⚠️ يوجد تعارض في الموعد مع مجموعات أخرى: ${externalConflicts.join('، ')}',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF856404),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType == TextInputType.number || keyboardType == TextInputType.phone
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      textDirection: TextDirection.rtl,
      style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Future<void> _pickTime(int index, String currentTime) async {
    final parts = currentTime.split(':');
    final h = int.tryParse(parts[0]) ?? 17;
    final m = int.tryParse(parts[1]) ?? 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    );
    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _days[index] = GroupDay(
          day: _days[index].day,
          time: newTime,
          durationMinutes: _days[index].durationMinutes,
        );
      });
    }
  }

  void _addDay() {
    setState(() {
      if (_days.isEmpty) {
        _days.add(const GroupDay(day: AppStrings.saturday, time: '17:00', durationMinutes: 60));
      } else if (_days.length == 1) {
        final first = _days[0];
        final paired = _getSmartPairedDay(first.day);
        _days.add(GroupDay(day: paired, time: first.time, durationMinutes: first.durationMinutes));
      } else if (_days.length == 2) {
        final third = _getSmartThirdDay(_days[0].day, _days[1].day);
        _days.add(GroupDay(day: third, time: _days[0].time, durationMinutes: _days[0].durationMinutes));
      } else {
        _days.add(GroupDay(day: AppStrings.saturday, time: _days[0].time, durationMinutes: _days[0].durationMinutes));
      }
    });
  }

  Future<void> _save() async {
    // 1. Mandatory subject check
    if (_selectedSubject == null || _selectedSubject!.trim().isEmpty) {
      setState(() => _subjectError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ يرجى اختيار المادة الدراسية للمجموعة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أضف موعد واحد على الأقل', style: GoogleFonts.tajawal())),
      );
      return;
    }

    // 2. Check for intra-group duplicate / same day & time conflicts
    final intraConflicts = <String>[];
    for (int i = 0; i < _days.length; i++) {
      for (int j = i + 1; j < _days.length; j++) {
        if (_days[i].day == _days[j].day) {
          if (_days[i].time == _days[j].time || _days[i].overlapsWith(_days[j])) {
            intraConflicts.add('${_days[i].day} (تكرار نفس الموعد: ${ArabicNumbers.formatTime12(_days[i].time)})');
          }
        }
      }
    }

    if (intraConflicts.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
              const SizedBox(width: 8),
              Text(
                'تنبيه: تكرار موعد في نفس اليوم',
                style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFD97706)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم رصد مواعيد متكررة بنفس التوقيت لنفس المجموعة:',
                style: GoogleFonts.tajawal(fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...intraConflicts.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(c, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Text(
                'يرجى التأكد من المواعيد، هل ترغب في المتابعة والحفظ؟',
                style: GoogleFonts.tajawal(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('تعديل المواعيد', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('متابعة وحفظ', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    if (!mounted) return;

    // 3. Check for external group schedule conflicts
    final allConflicts = <String>[];
    for (final d in _days) {
      final conf = _findConflictsForDay(d);
      if (conf.isNotEmpty) {
        allConflicts.addAll(conf);
      }
    }

    if (allConflicts.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            '⚠️ تنبيه تعارض المواعيد',
            style: GoogleFonts.changa(fontWeight: FontWeight.bold, color: AppColors.orange),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم رصد تعارض في المواعيد مع المجموعات التالية:',
                style: GoogleFonts.tajawal(fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...allConflicts.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.orange),
                    const SizedBox(width: 6),
                    Expanded(child: Text(c, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Text(
                'هل أنت متأكد من حفظ المجموعة في نفس التوقيت؟',
                style: GoogleFonts.tajawal(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('تعديل الموعد', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('متابعة وحفظ', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<GroupsProvider>();

      final monthlyPriceVal = double.tryParse(_priceController.text) ?? 0;
      final sessionsCountVal = int.tryParse(_sessionsCountController.text) ?? 8;
      
      double sessionPriceVal = 0;
      if (_autoDivide) {
        if (sessionsCountVal > 0) {
          sessionPriceVal = monthlyPriceVal / sessionsCountVal;
        }
      } else {
        sessionPriceVal = double.tryParse(_sessionPriceController.text) ?? 0;
      }

      final settingsP = context.read<SettingsProvider>();
      final finalSubject = (_selectedSubject != null && _selectedSubject!.trim().isNotEmpty)
          ? _selectedSubject!.trim()
          : (settingsP.mySubjects.isNotEmpty ? settingsP.mySubjects.first : 'عام');

      final group = GroupModel(
        id: isEditing ? widget.group!.id : _uuid.v4(),
        name: _nameController.text.trim(),
        type: _type,
        subject: finalSubject,
        days: _days,
        paymentMode: _paymentMode,
        monthlyPrice: _paymentMode == 'monthly' ? monthlyPriceVal : (sessionPriceVal * 8),
        sessionPrice: _paymentMode == 'per_session' ? (double.tryParse(_sessionPriceController.text) ?? 0) : sessionPriceVal,
        whatsappLink: _whatsappLinkController.text.trim(),
        onlinePlatform: _type == GroupType.online ? _onlinePlatform : null,
        onlineMeetingUrl: _type == GroupType.online ? _onlineMeetingUrlController.text.trim() : null,
        status: _status,
        createdAt: isEditing ? widget.group!.createdAt : DateTime.now(),
      );

      if (isEditing) {
        await provider.updateGroup(group);
      } else {
        await provider.addGroup(group);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? '✅ تم تحديث المجموعة' : '✅ تم إضافة المجموعة',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ المجموعة: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

