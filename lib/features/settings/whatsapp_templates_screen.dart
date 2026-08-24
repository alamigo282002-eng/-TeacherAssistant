import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_scale_button.dart';
import 'settings_provider.dart';

class WhatsAppTemplatesScreen extends StatefulWidget {
  const WhatsAppTemplatesScreen({super.key});

  @override
  State<WhatsAppTemplatesScreen> createState() => _WhatsAppTemplatesScreenState();
}

class _WhatsAppTemplatesScreenState extends State<WhatsAppTemplatesScreen> {
  late TextEditingController _absenceCtrl;
  late TextEditingController _paymentCtrl;
  late TextEditingController _examCtrl;
  late TextEditingController _cancelSessionCtrl;
  late TextEditingController _welcomeCtrl;
  late TextEditingController _generalNoteCtrl;

  @override
  void initState() {
    super.initState();
    final prov = context.read<SettingsProvider>();
    _absenceCtrl = TextEditingController(text: prov.templateAbsence);
    _paymentCtrl = TextEditingController(text: prov.templatePayment);
    _examCtrl = TextEditingController(text: prov.templateExam);
    _cancelSessionCtrl = TextEditingController(text: prov.templateCancelSession);
    _welcomeCtrl = TextEditingController(text: prov.templateWelcome);
    _generalNoteCtrl = TextEditingController(text: prov.templateGeneralNote);
  }

  @override
  void dispose() {
    _absenceCtrl.dispose();
    _paymentCtrl.dispose();
    _examCtrl.dispose();
    _cancelSessionCtrl.dispose();
    _welcomeCtrl.dispose();
    _generalNoteCtrl.dispose();
    super.dispose();
  }

  void _insertVariable(TextEditingController controller, String variable) {
    final text = controller.text;
    final selection = controller.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, variable);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + variable.length),
      );
    } else {
      controller.text = '$text $variable';
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
    setState(() {});
  }

  void _resetToDefault(String type) {
    setState(() {
      if (type == 'absence') {
        _absenceCtrl.text = 'السلام عليكم، نود إبلاغكم بأن الطالب {student} غاب النهاردة عن حصة {group} بتاريخ {date}.';
      } else if (type == 'payment') {
        _paymentCtrl.text = 'السلام عليكم، نود تذكيركم بتسديد اشتراك شهر {month} للطالب {student}.';
      } else if (type == 'exam') {
        _examCtrl.text = 'السلام عليكم، جاب {student} {mark} من {total} في اختبار {exam}.';
      } else if (type == 'cancel') {
        _cancelSessionCtrl.text = 'السلام عليكم ورحمة الله، نود إبلاغكم بإلغاء حصة {group} بتاريخ {date}. {compensation}';
      } else if (type == 'welcome') {
        _welcomeCtrl.text = 'أهلاً بك يا {student} في مجموعة {group} مع الأستاذ {teacher}. نتمنى لك تفوقاً دائماً 🌟';
      } else if (type == 'note') {
        _generalNoteCtrl.text = 'السلام عليكم، رسالة هامة بخصوص الطالب {student}: {note}';
      }
    });
  }

  void _save(SettingsProvider prov) {
    prov.setTemplateAbsence(_absenceCtrl.text.trim());
    prov.setTemplatePayment(_paymentCtrl.text.trim());
    prov.setTemplateExam(_examCtrl.text.trim());
    prov.setTemplateCancelSession(_cancelSessionCtrl.text.trim());
    prov.setTemplateWelcome(_welcomeCtrl.text.trim());
    prov.setTemplateGeneralNote(_generalNoteCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم حفظ كافة قوالب الرسائل بنجاح', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'قوالب رسائل الواتساب',
          style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(isDark),
            const SizedBox(height: 16),
            _buildTemplateCard(
              title: '📩 رسالة إشعار الغياب',
              description: 'تُرسل لولي الأمر تلقائياً عند تسجيل غياب الطالب أو من شيت الغائبين.',
              controller: _absenceCtrl,
              variables: const ['{student}', '{group}', '{date}'],
              variableLabels: const {
                '{student}': 'اسم الطالب',
                '{group}': 'المجموعة',
                '{date}': 'التاريخ',
              },
              onReset: () => _resetToDefault('absence'),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTemplateCard(
              title: '💳 رسالة التذكير بالدفع / المصاريف',
              description: 'تُرسل لتذكير ولي الأمر باشتراك الشهر المتأخر.',
              controller: _paymentCtrl,
              variables: const ['{student}', '{month}'],
              variableLabels: const {
                '{student}': 'اسم الطالب',
                '{month}': 'اسم الشهر',
              },
              onReset: () => _resetToDefault('payment'),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTemplateCard(
              title: '📝 رسالة نتيجة الاختبار / الدرجات',
              description: 'تُرسل لولي الأمر بنتيجة الطالب في الاختبار فور رصد الدرجة.',
              controller: _examCtrl,
              variables: const ['{student}', '{exam}', '{mark}', '{total}'],
              variableLabels: const {
                '{student}': 'اسم الطالب',
                '{exam}': 'اسم الامتحان',
                '{mark}': 'درجة الطالب',
                '{total}': 'الدرجة النهائية',
              },
              onReset: () => _resetToDefault('exam'),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTemplateCard(
              title: '📢 رسالة إلغاء الحصة والموعد البديل',
              description: 'تُرسل لجروب المجموعة أو الطلاب عند إلغاء حصة مع تحديد الموعد البديل.',
              controller: _cancelSessionCtrl,
              variables: const ['{group}', '{date}', '{compensation}'],
              variableLabels: const {
                '{group}': 'اسم المجموعة',
                '{date}': 'تاريخ الحصة',
                '{compensation}': 'الموعد البديل والتعويضي',
              },
              onReset: () => _resetToDefault('cancel'),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTemplateCard(
              title: '👋 رسالة الترحيب بالطالب الجديد',
              description: 'تُرسل للطالب أو ولي الأمر عند إضافته لمجموعة جديدة.',
              controller: _welcomeCtrl,
              variables: const ['{student}', '{group}', '{teacher}'],
              variableLabels: const {
                '{student}': 'اسم الطالب',
                '{group}': 'اسم المجموعة',
                '{teacher}': 'اسم الأستاذ',
              },
              onReset: () => _resetToDefault('welcome'),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            _buildTemplateCard(
              title: '💬 رسالة الملاحظات والمتابعة الفردية',
              description: 'تُرسل لولي الأمر لمشاركة ملاحظة أو سلوك بخصوص الطالب.',
              controller: _generalNoteCtrl,
              variables: const ['{student}', '{note}'],
              variableLabels: const {
                '{student}': 'اسم الطالب',
                '{note}': 'نص الملاحظة',
              },
              onReset: () => _resetToDefault('note'),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'حفظ جميع القوالب',
              onPressed: () => _save(prov),
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المتغيرات الذكية في القوالب',
                  style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'اضغط على أي زر متغير لإدراجه في نص الرسالة، وسيتم تعويضه تلقائياً ببيانات الطالب الفعلية عند الإرسال.',
                  style: GoogleFonts.tajawal(
                    fontSize: 12.5,
                    height: 1.4,
                    color: isDark ? AppColors.darkMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard({
    required String title,
    required String description,
    required TextEditingController controller,
    required List<String> variables,
    required Map<String, String> variableLabels,
    required VoidCallback onReset,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.changa(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? AppColors.darkText : AppColors.ink,
                ),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.orange),
                label: Text(
                  'استعادة الافتراضي',
                  style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.orange),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.tajawal(
              fontSize: 11.5,
              color: isDark ? AppColors.darkMuted : AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            style: GoogleFonts.tajawal(
              fontSize: 13.5,
              color: isDark ? AppColors.darkText : AppColors.ink,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: variables.map((v) {
              final label = variableLabels[v] ?? v;
              return AppScaleButton(
                onTap: () => _insertVariable(controller, v),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.chipTeal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$label $v',
                        style: GoogleFonts.tajawal(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Live Simulation Preview
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.visibility_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      'معاينة حية لشكل الرسالة في واتساب:',
                      style: GoogleFonts.tajawal(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _simulatePreview(controller.text),
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _simulatePreview(String template) {
    if (template.isEmpty) return 'اكتب نص الرسالة أعلاه للمعاينة...';
    return template
        .replaceAll('{student}', 'أحمد مصطفى')
        .replaceAll('{group}', 'مجموعة النخبة (الأحد)')
        .replaceAll('{date}', '٢٠٢٦/٠٨/٢٢')
        .replaceAll('{month}', 'أكتوبر')
        .replaceAll('{exam}', 'الشامل الأول')
        .replaceAll('{mark}', '٢٨')
        .replaceAll('{total}', '٣٠');
  }
}

