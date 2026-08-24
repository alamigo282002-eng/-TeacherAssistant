import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/arabic_numbers.dart';
import '../../../core/utils/contact_helper.dart';
import '../../../core/widgets/app_scale_button.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/student_repository.dart';

class CancelSessionSheet extends StatefulWidget {
  final GroupModel group;
  final DateTime? initialDate;

  const CancelSessionSheet({
    super.key,
    required this.group,
    this.initialDate,
  });

  static Future<void> show(BuildContext context, {required GroupModel group, DateTime? initialDate}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelSessionSheet(group: group, initialDate: initialDate),
    );
  }

  @override
  State<CancelSessionSheet> createState() => _CancelSessionSheetState();
}

class _CancelSessionSheetState extends State<CancelSessionSheet> {
  late DateTime _selectedDate;
  final TextEditingController _messageController = TextEditingController();
  final StudentRepository _studentRepo = StudentRepository();
  final AttendanceRepository _attendanceRepo = AttendanceRepository();

  List<StudentModel> _students = [];
  bool _loading = true;
  bool _savingAttendance = false;
  bool _hasCompensation = false;
  DateTime _compensationDate = DateTime.now().add(const Duration(days: 2));
  TimeOfDay _compensationTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _generateDefaultMessage();
    _loadStudents();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _getDayName(DateTime date) {
    const days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[date.weekday - 1];
  }

  void _generateDefaultMessage() {
    final dateStr = DateFormat('yyyy/MM/dd').format(_selectedDate);
    final dayName = _getDayName(_selectedDate);
    
    if (_hasCompensation) {
      final compDateStr = DateFormat('yyyy/MM/dd').format(_compensationDate);
      final compDayName = _getDayName(_compensationDate);
      final compTimeStr = _formatTimeOfDay(_compensationTime);
      _messageController.text =
          'السلام عليكم ورحمة الله وبركاته،\n'
          'نود إبلاغكم بأنه تم إلغاء حصة مجموعة (${widget.group.name}) المقررة يوم $dayName ($dateStr) لظرف طارئ.\n\n'
          '🔄 الموعد البديل والتعويضي سيكون بإذن الله:\n'
          '🗓️ يوم $compDayName الموافق $compDateStr\n'
          '⏰ الساعة: $compTimeStr\n\n'
          'نعتذر عن أي إزعاج ونتمنى لكم التوفيق والتميز.';
    } else {
      _messageController.text =
          'السلام عليكم ورحمة الله وبركاته،\n'
          'نود إبلاغكم بأنه تم إلغاء حصة مجموعة (${widget.group.name}) المقررة يوم $dayName ($dateStr) لظرف طارئ.\n'
          'سيتم إبلاغكم بالموعد البديل والتعويضي لاحقاً. نعتذر عن أي إزعاج.';
    }
  }

  Future<void> _loadStudents() async {
    try {
      final list = await _studentRepo.getByGroup(widget.group.id);
      if (mounted) {
        setState(() {
          _students = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _shareToWhatsAppGroup() async {
    final text = _messageController.text.trim();
    if (widget.group.hasWhatsAppLink) {
      final uri = Uri.parse(widget.group.whatsappLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    // Also share via system share
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'إلغاء حصة ${widget.group.name}',
      ),
    );
  }

  Future<void> _recordCancelledAttendance() async {
    setState(() => _savingAttendance = true);
    final uuid = const Uuid();

    try {
      final records = _students.map((s) => AttendanceModel(
        id: uuid.v4(),
        studentId: s.id,
        groupId: widget.group.id,
        date: _selectedDate,
        status: AttendanceStatus.cancelled,
        note: 'حصة ملغاة باعتذار',
      )).toList();

      await _attendanceRepo.upsertBatch(records);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم تسجيل إلغاء الحصة في سجل التحضير بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e', style: GoogleFonts.tajawal()), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAttendance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('yyyy/MM/dd').format(_selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.redSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event_busy_rounded, color: AppColors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إبلاغ عن إلغاء الحصة 📢',
                        style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'مجموعة: ${widget.group.name}',
                        style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Date Picker Chip
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                    _generateDefaultMessage();
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.chipTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'تاريخ الحصة الملغاة: ${ArabicNumbers.convert(dateStr)} (${_getDayName(_selectedDate)})',
                      style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const Spacer(),
                    Text('تغيير', style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 🔄 Compensation / Substitute Session Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasCompensation
                    ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                    : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasCompensation
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: _hasCompensation ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.update_rounded,
                        color: _hasCompensation ? AppColors.primary : AppColors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تحديد موعد حصة تعويضية / بديلة 🔄',
                              style: GoogleFonts.changa(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: _hasCompensation ? AppColors.primary : (isDark ? Colors.white : AppColors.ink),
                              ),
                            ),
                            Text(
                              'إضافة تفاصيل الموعد البديل بالساعة لرسالة الواتساب',
                              style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _hasCompensation,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _hasCompensation = val;
                            _generateDefaultMessage();
                          });
                        },
                      ),
                    ],
                  ),
                  if (_hasCompensation) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        // Date Picker Button
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _compensationDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _compensationDate = picked;
                                  _generateDefaultMessage();
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('يوم التعويض', style: GoogleFonts.tajawal(fontSize: 10, color: AppColors.muted)),
                                        Text(
                                          '${_getDayName(_compensationDate)} ${DateFormat('MM/dd').format(_compensationDate)}',
                                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Time Picker Button
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _compensationTime,
                                builder: (ctx, child) => MediaQuery(
                                  data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
                                  child: Directionality(textDirection: TextDirection.rtl, child: child!),
                                ),
                              );
                              if (picked != null) {
                                setState(() {
                                  _compensationTime = picked;
                                  _generateDefaultMessage();
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('الساعة / التوقيت', style: GoogleFonts.tajawal(fontSize: 10, color: AppColors.muted)),
                                        Text(
                                          _formatTimeOfDay(_compensationTime),
                                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
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
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Message Editor
            Text(
              'نص رسالة الإلغاء / الاعتذار:',
              style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _messageController,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.tajawal(fontSize: 13.5, height: 1.4),
              decoration: InputDecoration(
                fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 18),

            // Main Broadcast Actions
            Row(
              children: [
                // 1. Share to WhatsApp Group
                Expanded(
                  child: AppScaleButton(
                    onTap: _shareToWhatsAppGroup,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF25D366).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.group_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'نشر في الجروب 📲',
                            style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Mark Cancelled in Attendance DB
                Expanded(
                  child: AppScaleButton(
                    onTap: _savingAttendance ? null : _recordCancelledAttendance,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.chipTeal,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'تسجيل في السجل 📝',
                            style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Individual Student Send List
            Text(
              'أو إرسال فردي للطلاب وأولياء الأمور (${_students.length}):',
              style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.muted),
            ),
            const SizedBox(height: 8),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_students.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('لا يوجد طلاب مسجلين في هذه المجموعة', style: GoogleFonts.tajawal(color: AppColors.muted)),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _students.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final s = _students[i];
                    return ListTile(
                      dense: true,
                      title: Text(s.name, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(s.phone.isNotEmpty ? s.phone : s.parentPhone, style: GoogleFonts.tajawal(fontSize: 11)),
                      trailing: AppScaleButton(
                        onTap: () => ContactHelper.showContactOptions(
                          context,
                          s,
                          isWhatsApp: true,
                          whatsappText: _messageController.text,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F9EE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.send_rounded, color: Color(0xFF1E7E34), size: 14),
                              const SizedBox(width: 4),
                              Text('إرسال', style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1E7E34))),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

