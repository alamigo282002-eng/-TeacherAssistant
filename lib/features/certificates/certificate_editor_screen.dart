import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_scale_button.dart';
import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';
import '../groups/groups_provider.dart';
import '../settings/settings_provider.dart';
import '../students/students_provider.dart';
import 'certificate_model.dart';

class CertificateEditorScreen extends StatefulWidget {
  final StudentModel? initialStudent;
  final GroupModel? initialGroup;
  final String? initialReason;
  final String? initialRank;

  const CertificateEditorScreen({
    super.key,
    this.initialStudent,
    this.initialGroup,
    this.initialReason,
    this.initialRank,
  });

  @override
  State<CertificateEditorScreen> createState() => _CertificateEditorScreenState();
}

class _CertificateEditorScreenState extends State<CertificateEditorScreen> {
  List<StudentModel> _students = [];
  List<GroupModel> _groups = [];
  bool _loading = true;

  late TextEditingController _studentNameCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _reasonCtrl;
  late TextEditingController _quranCtrl;
  late TextEditingController _rankCtrl;
  late TextEditingController _teacherCtrl;
  late TextEditingController _institutionCtrl;
  late TextEditingController _dateCtrl;

  String? _selectedGroupId;
  String _selectedSubject = '';
  String _selectedTheme = 'gold'; // 'gold', 'navy', 'emerald', 'burgundy'

  final List<Map<String, String>> _quranPresets = [
    {
      'title': 'يرفع الله الذين آمنوا',
      'text': '﴿ يَرْفَعِ اللَّهُ الَّذِينَ آمَنُوا مِنكُمْ وَالَّذِينَ أُوتُوا الْعِلْمَ دَرَجَاتٍ ﴾',
    },
    {
      'title': 'وقل اعملوا',
      'text': '﴿ وَقُلِ اعْمَلُوا فَسَيَرَى اللَّهُ عَمَلَكُمْ وَرَسُولُهُ وَالْمُؤْمِنُونَ ﴾',
    },
    {
      'title': 'إنا لا نضيع أجر من أحسن عملا',
      'text': '﴿ إِنَّا لَا نُضِيعُ أَجْرَ مَنْ أَحْسَنَ عَمَلًا ﴾',
    },
    {
      'title': 'وقل رب زدني علما',
      'text': '﴿ وَقُل رَّبِّ زِدْنِي عِلْمًا ﴾',
    },
    {
      'title': 'حكمة (من جد وجد)',
      'text': '« مَن جَدَّ وَجَدَ، وَمَن زَرَعَ حَصَدَ، وَمَن سَارَ عَلَى الدَّرْبِ وَصَلَ »',
    },
  ];

  final List<String> _reasonPresets = [
    'تقديراً لتفوقه الباهر وحصوله على أعلى الدرجات والالتزام بالأخلاق والواجبات المدرسية.',
    'تقديراً لحصوله على المركز الأول في الاختبار الشهري والتميز العلمي المشرف.',
    'تقديراً لحصوله على الدرجة النهائية 100% في الاختبار والاجتهاد الدائم.',
    'تقديراً لالتزامه التام بالحضور والمواظبة والمشاركة الفعالة والأداء المثالي.',
    'تقديراً لحفظ ومراجعة الأجزاء المقررة بإتقان وسلوك تربوي متميز.',
  ];

  final List<String> _rankPresets = [
    'المركز الأول 🥇',
    'المركز الثاني 🥈',
    'المركز الثالث 🥉',
    'الدرجة النهائية 💯',
    'امتياز مع مرتبة الشرف 🌟',
    'طالب الشهر المثالي 🏆',
  ];

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    final teacher = settings.teacherName.isNotEmpty && settings.teacherName != 'المعلم'
        ? settings.teacherName
        : 'أحمد علي';

    final now = DateTime.now();
    final dateFormatted = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';

    _studentNameCtrl = TextEditingController(text: widget.initialStudent?.name ?? '');
    _titleCtrl = TextEditingController(text: 'شـهـادة شـكـر وتـقـديـر وتـفـوّق');
    _reasonCtrl = TextEditingController(
        text: widget.initialReason ?? _reasonPresets.first);
    _quranCtrl = TextEditingController(text: _quranPresets.first['text']);
    _rankCtrl = TextEditingController(text: widget.initialRank ?? 'المركز الأول 🥇');
    _teacherCtrl = TextEditingController(text: teacher);
    _institutionCtrl = TextEditingController(text: 'جمهورية مصر العربية - وزارة التربية والتعليم');
    _dateCtrl = TextEditingController(text: dateFormatted);

    _selectedGroupId = widget.initialGroup?.id ?? widget.initialStudent?.groupId;
    _selectedSubject = widget.initialGroup?.subject ?? '';

    _loadData();
  }

  Future<void> _loadData() async {
    final studentsP = context.read<StudentsProvider>();
    final groupsP = context.read<GroupsProvider>();
    await studentsP.loadStudents();
    await groupsP.loadGroups();
    final students = studentsP.allStudents;
    final groups = groupsP.groups;
    if (mounted) {
      setState(() {
        _students = students;
        _groups = groups;
        if (_selectedGroupId != null && _selectedSubject.isEmpty && groups.isNotEmpty) {
          final g = _groups.firstWhere((element) => element.id == _selectedGroupId, orElse: () => groups.first);
          _selectedSubject = g.subject ?? '';
        }
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _studentNameCtrl.dispose();
    _titleCtrl.dispose();
    _reasonCtrl.dispose();
    _quranCtrl.dispose();
    _rankCtrl.dispose();
    _teacherCtrl.dispose();
    _institutionCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  CertificateData _buildCertificateData() {
    final group = _groups.where((g) => g.id == _selectedGroupId).firstOrNull;

    return CertificateData(
      studentName: _studentNameCtrl.text.trim().isNotEmpty ? _studentNameCtrl.text.trim() : 'اسم الطالب المتفوق',
      certificateTitle: _titleCtrl.text.trim(),
      groupName: group?.name ?? (widget.initialGroup?.name ?? ''),
      subject: _selectedSubject.isNotEmpty ? _selectedSubject : (group?.subject ?? ''),
      reason: _reasonCtrl.text.trim(),
      quranVerse: _quranCtrl.text.trim(),
      rankOrGrade: _rankCtrl.text.trim(),
      teacherName: _teacherCtrl.text.trim(),
      institutionName: _institutionCtrl.text.trim(),
      dateStr: _dateCtrl.text.trim(),
      themeKey: _selectedTheme,
    );
  }

  final GlobalKey _certificateKey = GlobalKey();

  Future<File?> _captureCertificateFile() async {
    final cert = _buildCertificateData();
    try {
      final boundary = _certificateKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('عنصر الشهادة غير جاهز');

      final image = await boundary.toImage(pixelRatio: 3.2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('تعذر ترميز الصورة');
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final safeName = cert.studentName.replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]'), '_');
      final file = File('${dir.path}/شهادة_تقدير_${safeName}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تجهيز الصورة: $e', style: GoogleFonts.tajawal()), backgroundColor: AppColors.red),
        );
      }
      return null;
    }
  }

  Future<void> _shareAsHdImage() async {
    final file = await _captureCertificateFile();
    if (file == null) return;
    final cert = _buildCertificateData();

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '🎓 شهادة تقدير وتفوق للطالب المتميز (${cert.studentName})\nمع خالص التمنيات بدوام التفوق والنجاح! 🌟\nأستاذ المادة: أ. ${cert.teacherName}',
        subject: 'شهادة تقدير للطالب ${cert.studentName}',
      ),
    );
  }

  StudentModel? _findCurrentStudent() {
    if (widget.initialStudent != null) return widget.initialStudent;
    final name = _studentNameCtrl.text.trim();
    if (name.isEmpty) return null;
    return _students.where((s) => s.name == name).firstOrNull;
  }

  void _showShareOptionsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final student = _findCurrentStudent();
    final cert = _buildCertificateData();

    final hasParent = student != null && student.parentPhone.isNotEmpty;
    final hasStudent = student != null && student.phone.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'مشاركة شهادة التقدير 🎓',
              style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'اختر جهة استلام الشهادة للطالب (${cert.studentName})',
              style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),

            // Option 1: Share with Parent
            if (hasParent) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final file = await _captureCertificateFile();
                  if (file != null) {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(file.path, mimeType: 'image/png')],
                        text: 'السلام عليكم ورحمة الله وبركاته،\nنهنئكم بتفوق نجلكم/ابنتكم (${cert.studentName}) وحصوله على شهادة تقدير وتميز 🎓🌟\nأستاذ المادة: أ. ${cert.teacherName}',
                        subject: 'شهادة تقدير للطالب ${cert.studentName}',
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 20),
                label: Text(
                  'مشاركة مع ولي الأمر (${student.parentPhone})',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Option 2: Share with Student
            if (hasStudent) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final file = await _captureCertificateFile();
                  if (file != null) {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(file.path, mimeType: 'image/png')],
                        text: 'ألف مبروك يا بطل (${cert.studentName}) على تفوقك المستحق وهذه شهادة تقدير وشكر لجهودك الرائعة 🎓✨\nأستاذك: أ. ${cert.teacherName}',
                        subject: 'شهادة تقدير وتفوق',
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                label: Text(
                  'مشاركة مع الطالب (${student.phone})',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Option 3: General Share / Other apps
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _shareAsHdImage();
              },
              icon: const Icon(Icons.share_rounded, size: 20),
              label: Text(
                'مشاركة عامة (واتساب / أي تطبيق آخر)',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                side: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickFieldEditor({
    required String title,
    required TextEditingController controller,
    int maxLines = 1,
    List<String>? presets,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tempCtrl = TextEditingController(text: controller.text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'تعديل $title',
              style: GoogleFonts.changa(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: tempCtrl,
                maxLines: maxLines,
                autofocus: true,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.tajawal(fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: title,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (presets != null && presets.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('نماذج سريعة:', style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presets.map((p) {
                    return ActionChip(
                      label: Text(p, style: GoogleFonts.tajawal(fontSize: 11)),
                      onPressed: () => tempCtrl.text = p,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                controller.text = tempCtrl.text;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('حفظ التعديل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'تصميم شهادة التقدير',
          style: GoogleFonts.changa(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'مشاركة الشهادة',
            onPressed: _showShareOptionsDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Helper Notice for Direct Tap-To-Edit
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '💡 يمكنك الضغط مباشرة على أي نص في الشهادة لتعديله فوراً',
                          style: GoogleFonts.tajawal(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1. Live Interactive Visual Certificate Card (High-Resolution Capture Ready)
                  RepaintBoundary(
                    key: _certificateKey,
                    child: _buildLiveCertificateCard(isDark),
                  ),

                  const SizedBox(height: 16),

                  // Actions Row (2 Export Options: HD Image & WhatsApp Modal)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareAsHdImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.image_rounded, color: Colors.white, size: 20),
                          label: Text(
                            'حفظ ومشاركة صورة HD',
                            style: GoogleFonts.changa(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showShareOptionsDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                          label: Text(
                            'إرسال ومشاركة واتساب',
                            style: GoogleFonts.changa(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Customization Controls Section
                  Text(
                    '🎨 تخصيص بيانات وقالب الشهادة',
                    style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Theme Palette Selector
                  _buildThemeSelector(isDark),

                  const SizedBox(height: 16),

                  // Student Picker / Autocomplete
                  _buildStudentPickerSection(isDark),

                  const SizedBox(height: 14),

                  // Group & Subject Pickers
                  _buildGroupAndSubjectSection(isDark),

                  const SizedBox(height: 14),

                  // Certificate Title & Rank Badge
                  _buildTitleAndRankSection(isDark),

                  const SizedBox(height: 14),

                  // Quranic Verse / Slogan Picker
                  _buildQuranVerseSection(isDark),

                  const SizedBox(height: 14),

                  // Reason / Appreciation Presets & Text
                  _buildReasonSection(isDark),

                  const SizedBox(height: 14),

                  // Teacher & Institution & Date
                  _buildFooterMetaSection(isDark),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // --- Live Interactive Certificate Preview Widget (Aspect-Ratio A4 Matching) ---
  Widget _buildLiveCertificateCard(bool isDark) {
    Color borderCol;
    Color accentCol;
    Color cardBg;

    switch (_selectedTheme) {
      case 'navy':
        borderCol = const Color(0xFF1E3A8A); // Royal Navy
        accentCol = const Color(0xFFD97706); // Gold Accent
        cardBg = isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC);
        break;
      case 'emerald':
        borderCol = const Color(0xFF065F46); // Islamic Emerald
        accentCol = const Color(0xFFD4AF37); // Gold Accent
        cardBg = isDark ? const Color(0xFF062E25) : const Color(0xFFF0FDF4);
        break;
      case 'gold':
      default:
        borderCol = const Color(0xFF92660A); // Antique Gold
        accentCol = const Color(0xFF0D7377); // Egyptian Teal Accent
        cardBg = isDark ? const Color(0xFF1C1917) : const Color(0xFFFFFDF5);
        break;
    }

    final group = _groups.where((g) => g.id == _selectedGroupId).firstOrNull;
    final studentName = _studentNameCtrl.text.trim().isNotEmpty ? _studentNameCtrl.text.trim() : 'اسم الطالب المتفوق';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: borderCol.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentCol, width: 1.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Republic / Ministry (Interactive)
            InkWell(
              onTap: () => _showQuickFieldEditor(title: 'اسم المؤسسة / المدرسة', controller: _institutionCtrl),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Text(
                  _institutionCtrl.text.trim().isNotEmpty ? _institutionCtrl.text.trim() : 'جمهورية مصر العربية - وزارة التربية والتعليم',
                  style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold, color: borderCol),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quranic verse (Interactive)
            if (_quranCtrl.text.trim().isNotEmpty)
              InkWell(
                onTap: () => _showQuickFieldEditor(
                  title: 'الآية القرآنية / الشعار',
                  controller: _quranCtrl,
                  presets: _quranPresets.map((q) => q['text']!).toList(),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentCol.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _quranCtrl.text.trim(),
                    style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold, color: borderCol),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Main Title Banner (Interactive)
            Center(
              child: InkWell(
                onTap: () => _showQuickFieldEditor(title: 'عنوان الشهادة', controller: _titleCtrl),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  decoration: BoxDecoration(
                    color: borderCol,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: borderCol.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    _titleCtrl.text.trim(),
                    style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'يسر إدارة المركز وأستاذ المادة أن يمنحوا هذه الشهادة بكل فخر واعتزاز إلى الطالب / الطالبة:',
              style: GoogleFonts.tajawal(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.black87),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // Highlighted Student Name (Interactive)
            Center(
              child: InkWell(
                onTap: () => _showQuickFieldEditor(title: 'اسم الطالب', controller: _studentNameCtrl),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: accentCol, width: 2.2)),
                  ),
                  child: Text(
                    '❖  $studentName  ❖',
                    style: GoogleFonts.changa(fontSize: 21, fontWeight: FontWeight.bold, color: borderCol),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Reason & Group Details (Interactive)
            Text(
              'بالصف / المجموعة: ${group?.name ?? "-"} · مادة: ${_selectedSubject.isNotEmpty ? _selectedSubject : (group?.subject ?? "-")}',
              style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.muted, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _showQuickFieldEditor(
                title: 'نص التقدير وسبب التكريم',
                controller: _reasonCtrl,
                maxLines: 3,
                presets: _reasonPresets,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  _reasonCtrl.text.trim(),
                  style: GoogleFonts.tajawal(fontSize: 11.5, height: 1.4, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            if (_rankCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: InkWell(
                  onTap: () => _showQuickFieldEditor(
                    title: 'التقدير أو الرتبة',
                    controller: _rankCtrl,
                    presets: _rankPresets,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentCol.withValues(alpha: 0.15),
                      border: Border.all(color: accentCol, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _rankCtrl.text.trim(),
                      style: GoogleFonts.changa(fontSize: 11.5, fontWeight: FontWeight.bold, color: borderCol),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Clean Balanced Footer (Date & Teacher Signature - Stamp Removed as Requested)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _showQuickFieldEditor(title: 'تاريخ التحرير', controller: _dateCtrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تحريراً في:', style: GoogleFonts.tajawal(fontSize: 9.5, color: isDark ? AppColors.darkMuted : AppColors.muted)),
                        Text(ArabicNumbers.convert(_dateCtrl.text), style: GoogleFonts.changa(fontSize: 11.5, fontWeight: FontWeight.bold, color: borderCol)),
                      ],
                    ),
                  ),
                ),

                InkWell(
                  onTap: () => _showQuickFieldEditor(title: 'اسم أستاذ المادة', controller: _teacherCtrl),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('أستاذ المادة:', style: GoogleFonts.tajawal(fontSize: 9.5, color: isDark ? AppColors.darkMuted : AppColors.muted)),
                        Text('أ. ${_teacherCtrl.text.trim()}', style: GoogleFonts.changa(fontSize: 11.5, fontWeight: FontWeight.bold, color: borderCol)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Theme / Template Selector ---
  Widget _buildThemeSelector(bool isDark) {
    final templates = [
      {
        'key': 'gold',
        'title': 'الملكي الذهبي',
        'subtitle': 'كلاسيكي مصري فخم',
        'icon': Icons.military_tech_rounded,
        'primary': const Color(0xFF92660A),
        'accent': const Color(0xFFD97706),
      },
      {
        'key': 'emerald',
        'title': 'الإسلامي الزمردي',
        'subtitle': 'تراثي قرآني وأخلاقي',
        'icon': Icons.stars_rounded,
        'primary': const Color(0xFF065F46),
        'accent': const Color(0xFF10B981),
      },
      {
        'key': 'navy',
        'title': 'الأكاديمي العصري',
        'subtitle': 'كحلي شرفي مودرن',
        'icon': Icons.workspace_premium_rounded,
        'primary': const Color(0xFF1E3A8A),
        'accent': const Color(0xFF3B82F6),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('اختر قالب الشهادة (3 قوالب جاهزة):', style: GoogleFonts.changa(fontSize: 13.5, fontWeight: FontWeight.bold)),
            Text('نسبة A4 عرضي', style: GoogleFonts.tajawal(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.muted)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: templates.map((t) {
            final key = t['key'] as String;
            final isSelected = _selectedTheme == key;
            final primary = t['primary'] as Color;

            return Expanded(
              child: AppScaleButton(
                onTap: () => setState(() => _selectedTheme = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? primary.withValues(alpha: 0.35) : primary.withValues(alpha: 0.12))
                        : (Theme.of(context).cardColor),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? primary : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: isSelected ? 2.2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        t['icon'] as IconData,
                        color: isSelected ? primary : (isDark ? AppColors.darkMuted : AppColors.muted),
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t['title'] as String,
                        style: GoogleFonts.changa(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? (isDark ? Colors.white : primary) : (isDark ? Colors.white70 : AppColors.ink),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        t['subtitle'] as String,
                        style: GoogleFonts.tajawal(
                          fontSize: 9.5,
                          color: isSelected ? primary : (isDark ? AppColors.darkMuted : AppColors.muted),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Student Picker ---
  Widget _buildStudentPickerSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('بيانات الطالب المتفوق', style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold)),
              if (_students.isNotEmpty)
                DropdownButton<String>(
                  hint: Text('اختر من الطلاب المسجلين', style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.primary)),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                  items: _students.map((s) {
                    return DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name, style: GoogleFonts.tajawal(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      final s = _students.firstWhere((element) => element.id == id);
                      setState(() {
                        _studentNameCtrl.text = s.name;
                        _selectedGroupId = s.groupId;
                        final g = _groups.where((element) => element.id == s.groupId).firstOrNull;
                        if (g != null && g.subject != null) {
                          _selectedSubject = g.subject!;
                        }
                      });
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _studentNameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'اسم الطالب *',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
        ],
      ),
    );
  }

  // --- Group & Subject ---
  Widget _buildGroupAndSubjectSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('المجموعة والمادة التعليمية', style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedGroupId,
                  decoration: const InputDecoration(labelText: 'المجموعة'),
                  items: _groups.map((g) {
                    return DropdownMenuItem(value: g.id, child: Text(g.name, style: GoogleFonts.tajawal(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedGroupId = val;
                      final g = _groups.where((element) => element.id == val).firstOrNull;
                      if (g?.subject != null && g!.subject!.isNotEmpty) {
                        _selectedSubject = g.subject!;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: _selectedSubject,
                  onChanged: (val) => setState(() => _selectedSubject = val),
                  decoration: const InputDecoration(labelText: 'المادة (مثال: اللغة العربية)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Title & Rank ---
  Widget _buildTitleAndRankSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'عنوان الشهادة',
              prefixIcon: Icon(Icons.military_tech_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rankCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'التقدير أو الرتبة (شارة الشرف)',
              prefixIcon: Icon(Icons.star_border_rounded),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _rankPresets.map((r) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ActionChip(
                    label: Text(r, style: GoogleFonts.tajawal(fontSize: 11)),
                    onPressed: () {
                      setState(() => _rankCtrl.text = r);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Quran Verse Section ---
  Widget _buildQuranVerseSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الآية القرآنية أو الشعار التقديري', style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _quranCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'الآية / العبارة التحفيزية',
              prefixIcon: Icon(Icons.format_quote_rounded),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quranPresets.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ActionChip(
                    label: Text(q['title']!, style: GoogleFonts.tajawal(fontSize: 11)),
                    onPressed: () {
                      setState(() => _quranCtrl.text = q['text']!);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reason Section ---
  Widget _buildReasonSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نص وسبب التكريم والتقدير', style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'نص التقدير المكتوب في الشهادة',
            ),
          ),
          const SizedBox(height: 8),
          Text('نماذج جاهزة للاختيار السريع:', style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 4),
          ..._reasonPresets.map((r) {
            return InkWell(
              onTap: () => setState(() => _reasonCtrl.text = r),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right_rounded, color: AppColors.primary, size: 18),
                    Expanded(
                      child: Text(
                        r,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.tajawal(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- Footer Meta Section ---
  Widget _buildFooterMetaSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات التوقيع والاعتماد', style: GoogleFonts.changa(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _teacherCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'اسم المعلم / أستاذ المادة',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _institutionCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'اسم المؤسسة / المدرسة / السنتر',
              prefixIcon: Icon(Icons.account_balance_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _dateCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'تاريخ التحرير',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

