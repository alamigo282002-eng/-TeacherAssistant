import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/student_model.dart';
import '../../data/repositories/exam_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../certificates/certificate_editor_screen.dart';
import '../settings/settings_provider.dart';

class ExamMarksScreen extends StatefulWidget {
  final ExamModel exam;

  const ExamMarksScreen({super.key, required this.exam});

  @override
  State<ExamMarksScreen> createState() => _ExamMarksScreenState();
}

class _ExamMarksScreenState extends State<ExamMarksScreen> {
  final ExamRepository _examRepo = ExamRepository();
  final StudentRepository _studentRepo = StudentRepository();
  final _uuid = const Uuid();

  List<StudentModel> _students = [];
  Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExamData() async {
    setState(() => _loading = true);
    final students = await _studentRepo.getByGroup(widget.exam.groupId);
    final results = await _examRepo.getResults(widget.exam.id);
    final resultMap = {for (final r in results) r.studentId: r.marks};

    final controllers = <String, TextEditingController>{};
    for (final s in students) {
      final marks = resultMap[s.id];
      controllers[s.id] = TextEditingController(
        text: marks != null ? marks.toInt().toString() : '',
      );
    }

    if (mounted) {
      setState(() {
        _students = students;
        _controllers = controllers;
        _loading = false;
      });
    }
  }

  double? _parseMark(String text) {
    if (text.trim().isEmpty) return null;
    return double.tryParse(text.trim());
  }

  Future<void> _sendWhatsAppResult(StudentModel student, double marks) async {
    final phone = student.parentPhone.isNotEmpty ? student.parentPhone : student.phone;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يوجد رقم هاتف مسجل للطالب ${student.name}', style: GoogleFonts.tajawal()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cleaned = AppValidators.cleanPhone(phone);
    final total = widget.exam.totalMarks;
    final percent = (marks / total * 100).round();
    
    final settings = context.read<SettingsProvider>();
    final template = settings.templateExam;
    final messageText = template
        .replaceAll('{student}', student.name)
        .replaceAll('{exam}', widget.exam.name)
        .replaceAll('{mark}', ArabicNumbers.convert(marks.toInt()))
        .replaceAll('{total}', ArabicNumbers.convert(total.toInt()))
        .replaceAll('{percent}', ArabicNumbers.convert(percent));

    final message = Uri.encodeComponent(messageText);
    final url = Uri.parse('https://wa.me/$cleaned?text=$message');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate Stats: High, Low, Average, Pass Rate
    final marksList = <double>[];
    for (final s in _students) {
      final m = _parseMark(_controllers[s.id]?.text ?? '');
      if (m != null) marksList.add(m);
    }

    double? highest;
    double? lowest;
    double average = 0;
    double passRate = 0;

    if (marksList.isNotEmpty) {
      highest = marksList.reduce((a, b) => a > b ? a : b);
      lowest = marksList.reduce((a, b) => a < b ? a : b);
      average = marksList.reduce((a, b) => a + b) / marksList.length;
      final passCount = marksList.where((m) => (m / widget.exam.totalMarks) >= 0.5).length;
      passRate = (passCount / marksList.length) * 100;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'رصد درجات: ${widget.exam.name}',
          style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Stats Summary Cards Header
                if (marksList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.border,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildMiniStat('أعلى درجة', highest != null ? ArabicNumbers.convert(highest.toInt()) : '-', AppColors.green, isDark),
                        const SizedBox(width: 8),
                        _buildMiniStat('أدنى درجة', lowest != null ? ArabicNumbers.convert(lowest.toInt()) : '-', AppColors.red, isDark),
                        const SizedBox(width: 8),
                        _buildMiniStat('المتوسط', ArabicNumbers.convert(average.toStringAsFixed(1)), AppColors.primary, isDark),
                        const SizedBox(width: 8),
                        _buildMiniStat('نسبة النجاح', '${ArabicNumbers.convert(passRate.round())}٪', AppColors.orange, isDark),
                      ],
                    ),
                  ),

                // Students Marks Entry List
                Expanded(
                  child: _students.isEmpty
                      ? Center(
                          child: Text(
                            'لا يوجد طلاب في هذه المجموعة',
                            style: GoogleFonts.changa(fontSize: 15, color: AppColors.muted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final student = _students[idx];
                            final ctrl = _controllers[student.id];
                            final currentMark = _parseMark(ctrl?.text ?? '');
                            final isOverLimit = currentMark != null && (currentMark > widget.exam.totalMarks || currentMark < 0);
                            final percent = (currentMark != null && !isOverLimit)
                                ? (currentMark / widget.exam.totalMarks * 100)
                                : null;

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isOverLimit
                                      ? AppColors.red
                                      : (isDark ? AppColors.darkBorder : AppColors.border),
                                  width: isOverLimit ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isOverLimit
                                        ? AppColors.red.withValues(alpha: 0.15)
                                        : AppColors.chipTeal,
                                    child: Text(
                                      student.name.isNotEmpty ? student.name[0] : 'ط',
                                      style: GoogleFonts.changa(
                                        fontWeight: FontWeight.bold,
                                        color: isOverLimit ? AppColors.red : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: GoogleFonts.changa(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.darkText : AppColors.ink,
                                          ),
                                        ),
                                        if (isOverLimit)
                                          Text(
                                            '⚠️ الدرجة تتجاوز ${ArabicNumbers.convert(widget.exam.totalMarks.toInt())}',
                                            style: GoogleFonts.tajawal(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.red,
                                            ),
                                          )
                                        else if (percent != null)
                                          Text(
                                            'النسبة: ${ArabicNumbers.convert(percent.round())}٪ (${percent >= 50 ? "ناجح" : "راسب"})',
                                            style: GoogleFonts.tajawal(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: percent >= 50 ? AppColors.green : AppColors.red,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Marks Input Field
                                  SizedBox(
                                    width: 80,
                                    height: 44,
                                    child: TextField(
                                      controller: ctrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.changa(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isOverLimit ? AppColors.red : null,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '/${widget.exam.totalMarks.toInt()}',
                                        contentPadding: EdgeInsets.zero,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: isOverLimit ? AppColors.red : AppColors.border,
                                            width: isOverLimit ? 1.5 : 1.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: isOverLimit ? AppColors.red : AppColors.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Actions: Certificate & WhatsApp
                                  if (currentMark != null && !isOverLimit) ...[
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
                                              initialReason: 'تقديراً لتفوقه واجتهاده في ${widget.exam.name} وحصوله على درجة (${currentMark.toInt()} من ${widget.exam.totalMarks.toInt()})',
                                              initialRank: (currentMark >= widget.exam.totalMarks * 0.9)
                                                  ? 'الدرجة النهائية / امتياز 🌟'
                                                  : 'تفوق ونجاح 👏',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 20),
                                      tooltip: 'إرسال النتيجة لولي الأمر',
                                      onPressed: () => _sendWhatsAppResult(student, currentMark),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Save All Marks Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: AppScaleButton(
                        onTap: _saveResults,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.cardGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: _saving
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : Text(
                                    'حفظ جميع الدرجات',
                                    style: GoogleFonts.changa(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : const Color(0xFFF7F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: GoogleFonts.tajawal(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.changa(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveResults() async {
    // Check for any invalid marks
    for (final s in _students) {
      final marks = _parseMark(_controllers[s.id]?.text ?? '');
      if (marks != null && (marks > widget.exam.totalMarks || marks < 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ توجد درجات غير صحيحة تتجاوز الدرجة الكلية (${widget.exam.totalMarks.toInt()}) للطالب ${s.name}',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);

    final results = <ExamResultModel>[];
    for (final s in _students) {
      final marks = _parseMark(_controllers[s.id]?.text ?? '');
      if (marks != null) {
        results.add(ExamResultModel(
          id: _uuid.v4(),
          examId: widget.exam.id,
          studentId: s.id,
          marks: marks,
        ));

        // Award 0.5 points per exam mark
        final awardedPoints = (marks * 0.5).round();
        if (awardedPoints > 0) {
          await _studentRepo.addPoints(s.id, awardedPoints);
        }
      }
    }

    await _examRepo.saveResults(widget.exam.id, results);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ الدرجات وتحديث نقاط الطلاب بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }
}

