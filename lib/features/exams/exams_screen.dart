import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/models/exam_model.dart';
import 'exam_marks_screen.dart';
import 'exams_provider.dart';

class ExamsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const ExamsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamsProvider>().loadForGroup(widget.groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExamsProvider>();
    final exams = provider.getForGroup(widget.groupId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('اختبارات ${widget.groupName}')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : exams.isEmpty
              ? EmptyState(
                  message: 'لا يوجد اختبارات بعد',
                  icon: Icons.quiz_outlined,
                  action: AppButton(
                    label: 'إضافة اختبار',
                    icon: Icons.add,
                    onPressed: () => _showAddExamDialog(context, provider),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exams.length,
                  itemBuilder: (ctx, i) =>
                      _buildExamCard(ctx, exams[i], provider, isDark),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExamDialog(context, provider),
        icon: const Icon(Icons.add),
        label: Text('اختبار جديد', style: GoogleFonts.cairo()),
      ),
    );
  }

  Widget _buildExamCard(BuildContext ctx, ExamWithResults data,
      ExamsProvider provider, bool isDark) {
    final exam = data.exam;
    final entered = data.results.where((r) => r.marks != null).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${AppDateUtils.formatArabicShortDate(exam.date)} · من ${exam.totalMarks.toInt()}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$entered/${data.students.length}',
                  style: GoogleFonts.cairo(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Stats (if results entered)
          if (data.highest != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(
                      '${data.highest!.toInt()}', 'أعلى', AppColors.success),
                  _statChip(
                      '${data.lowest!.toInt()}', 'أدنى', AppColors.error),
                  _statChip(
                      '${data.average!.toInt()}', 'متوسط', AppColors.info),
                  _statChip(
                      '${(data.passRate * 100).round()}%',
                      'نجاح',
                      AppColors.warning),
                ],
              ),
            ),
          // Actions
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder)),
            ),
            child: Row(
              children: [
                _actionBtn(
                  ctx, Icons.edit_outlined, 'إدخال الدرجات', AppColors.primary,
                  () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ExamMarksScreen(
                        exam: exam,
                      ),
                    ),
                  ).then((_) =>
                      provider.loadForGroup(widget.groupId)),
                ),
                _actionBtn(
                  ctx, Icons.delete_outline, 'حذف', AppColors.error,
                  () async {
                    final ok = await ConfirmationDialog.show(
                      ctx,
                      title: 'حذف الاختبار',
                      message: 'هل أنت متأكد من حذف "${exam.name}"؟',
                      confirmLabel: 'حذف',
                      danger: true,
                    );
                    if (ok == true) {
                      await provider.deleteExam(exam.id, widget.groupId);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color)),
        Text(label,
            style: GoogleFonts.cairo(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _actionBtn(BuildContext ctx, IconData icon, String label, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              Text(label,
                  style: GoogleFonts.cairo(fontSize: 10, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExamDialog(BuildContext ctx, ExamsProvider provider) {
    final nameCtrl = TextEditingController();
    final marksCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();
    final uuid = const Uuid();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إضافة اختبار',
                    style: GoogleFonts.cairo(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'اسم الاختبار'),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الدرجة الكلية'),
                  validator: (v) => AppValidators.positiveNumber(v),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setSheetState(() => selectedDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppDateUtils.formatArabicDate(selectedDate),
                          style: GoogleFonts.cairo(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final exam = ExamModel(
                        id: uuid.v4(),
                        groupId: widget.groupId,
                        name: nameCtrl.text.trim(),
                        totalMarks: double.parse(marksCtrl.text),
                        date: selectedDate,
                      );
                      await provider.addExam(exam);
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('إضافة',
                        style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
