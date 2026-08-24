class CertificateData {
  final String studentName;
  final String certificateTitle; // e.g. "شـهـادة تـقـديـر وتـفـوّق"
  final String groupName;
  final String subject;
  final String reason;
  final String quranVerse;
  final String rankOrGrade; // e.g. "المركز الأول 🥇", "الدرجة النهائية 💯", "امتياز مع مرتبة الشرف"
  final String teacherName;
  final String institutionName; // e.g. "جمهورية مصر العربية - وزارة التربية والتعليم"
  final String dateStr;
  final String themeKey; // 'gold', 'navy', 'emerald', 'burgundy'

  const CertificateData({
    required this.studentName,
    this.certificateTitle = 'شـهـادة تـقـديـر وتـفـوّق',
    this.groupName = '',
    this.subject = '',
    this.reason = 'تقديراً لتميزه وتفوقه الدراسي الباهر وحصوله على أعلى الدرجات والالتزام بالأخلاق والواجبات المدرسية',
    this.quranVerse = '﴿ يَرْفَعِ اللَّهُ الَّذِينَ آمَنُوا مِنكُمْ وَالَّذِينَ أُوتُوا الْعِلْمَ دَرَجَاتٍ ﴾',
    this.rankOrGrade = 'المركز الأول 🥇',
    this.teacherName = 'المعلم',
    this.institutionName = 'جمهورية مصر العربية - وزارة التربية والتعليم',
    this.dateStr = '',
    this.themeKey = 'gold',
  });

  CertificateData copyWith({
    String? studentName,
    String? certificateTitle,
    String? groupName,
    String? subject,
    String? reason,
    String? quranVerse,
    String? rankOrGrade,
    String? teacherName,
    String? institutionName,
    String? dateStr,
    String? themeKey,
  }) {
    return CertificateData(
      studentName: studentName ?? this.studentName,
      certificateTitle: certificateTitle ?? this.certificateTitle,
      groupName: groupName ?? this.groupName,
      subject: subject ?? this.subject,
      reason: reason ?? this.reason,
      quranVerse: quranVerse ?? this.quranVerse,
      rankOrGrade: rankOrGrade ?? this.rankOrGrade,
      teacherName: teacherName ?? this.teacherName,
      institutionName: institutionName ?? this.institutionName,
      dateStr: dateStr ?? this.dateStr,
      themeKey: themeKey ?? this.themeKey,
    );
  }
}
