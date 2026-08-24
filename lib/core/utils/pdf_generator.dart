import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/group_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/attendance_model.dart';
import '../../features/certificates/certificate_model.dart';

class PdfGenerator {
  /// Generate a PDF report for a student
  static Future<File> generateStudentReport(
    StudentModel student,
    List<AttendanceModel> attendance,
    List<Map<String, dynamic>> exams,
    List<NoteModel> notes,
  ) async {
    final pdf = pw.Document();
    
    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.tajawalRegular();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          final presentCount = attendance.where((a) => a.status.name == 'present').length;
          final absentCount = attendance.where((a) => a.status.name == 'absent').length;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('تقرير أداء الطالب', style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.teal)),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الاسم: ${student.name}', style: pw.TextStyle(font: fontBold, fontSize: 16)),
                  pw.Text('النقاط: ${student.points}', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.orange)),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text('الهاتف: ${student.phone.isNotEmpty ? student.phone : "-"}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('هاتف ولي الأمر: ${student.parentPhone.isNotEmpty ? student.parentPhone : "-"}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              
              // Attendance stats
              pw.Text('إحصائيات الحضور والغياب:', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.grey700)),
              pw.SizedBox(height: 5),
              pw.Text('إجمالي أيام الحضور: $presentCount', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('إجمالي أيام الغياب: $absentCount', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              
              // Exams
              if (exams.isNotEmpty) ...[
                pw.Text('نتائج الاختبارات:', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 5),
                pw.TableHelper.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(font: fontBold),
                  cellStyle: pw.TextStyle(font: font),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  data: [
                    ['الاختبار', 'الدرجة', 'النسبة'],
                    ...exams.map((e) {
                      final examName = e['name']?.toString() ?? 'اختبار';
                      final num? rawMarks = e['marks'] as num?;
                      final num? rawTotal = (e['total_marks'] as num?) ?? (e['total'] as num?);
                      final total = rawTotal?.toDouble() ?? 100.0;
                      
                      String marksStr = '-';
                      String percentStr = '-';
                      if (rawMarks != null) {
                        final marks = rawMarks.toDouble();
                        marksStr = '$marks / ${total.toInt()}';
                        if (total > 0) {
                          percentStr = '${((marks / total) * 100).toStringAsFixed(1)}%';
                        }
                      }
                      return [examName, marksStr, percentStr];
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              // Notes
              if (notes.isNotEmpty) ...[
                pw.Text('الملاحظات:', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 5),
                ...notes.map((n) => pw.Bullet(text: n.content, style: const pw.TextStyle(fontSize: 12))),
              ],

              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('تم إنشاء هذا التقرير بواسطة تطبيق مُساعِد المُعلِّم', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/student_report_${student.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate a PDF report for a group
  static Future<File> generateGroupReport(
    GroupModel group,
    List<StudentModel> students,
  ) async {
    final pdf = pw.Document();
    
    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.tajawalRegular();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('تقرير المجموعة', style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.teal)),
              ),
              pw.SizedBox(height: 16),
              pw.Text('المجموعة: ${group.name}', style: pw.TextStyle(font: fontBold, fontSize: 16)),
              if (group.subject != null && group.subject!.isNotEmpty)
                pw.Text('المادة: ${group.subject!}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('إجمالي الطلاب: ${students.length}', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text('قائمة الطلاب:', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(font: fontBold),
                cellStyle: pw.TextStyle(font: font),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                data: [
                  ['#', 'الاسم', 'الهاتف', 'النقاط'],
                  ...students.asMap().entries.map((e) => [
                        (e.key + 1).toString(),
                        e.value.name,
                        e.value.phone.isNotEmpty ? e.value.phone : '-',
                        e.value.points.toString(),
                      ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('تم إنشاء هذا التقرير بواسطة تطبيق مُساعِد المُعلِّم', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/group_report_${group.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate a Printable PDF of the Classic School Timetable Matrix
  static Future<File> generateWeeklyTimetablePdf(List<GroupModel> groups) async {
    final pdf = pw.Document();

    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.tajawalRegular();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    const days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    final activeGroups = groups.where((g) => g.status.name == 'active').toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('الجدول الأسبوعي للحصص والمجموعات', style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.teal)),
                    pw.Text('تطبيق مُساعد المُعلِّم', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.white),
                cellStyle: pw.TextStyle(font: font, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                headers: ['اليوم', 'عدد الحصص', 'المجموعات والمواعيد'],
                data: days.map((day) {
                  final dayGroups = activeGroups.where((g) => g.isScheduledOn(day)).toList();
                  dayGroups.sort((a, b) {
                    final ta = a.timeForDay(day) ?? '00:00';
                    final tb = b.timeForDay(day) ?? '00:00';
                    return ta.compareTo(tb);
                  });

                  final sessionsSummary = dayGroups.isEmpty
                      ? '— لا توجد حصص —'
                      : dayGroups.map((g) {
                          final time = g.timeForDay(day) ?? '';
                          final subject = (g.subject != null && g.subject!.isNotEmpty) ? ' (${g.subject!})' : '';
                          return '• [ $time ]  ${g.name}$subject';
                        }).join('\n');

                  return [
                    day,
                    dayGroups.length.toString(),
                    sessionsSummary,
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 14),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('تم إنشاء وطباعة الجدول بواسطة تطبيق مُساعِد المُعلِّم', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/weekly_timetable.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate a Printable PDF of the Monthly Calendar with enlarged cells
  static Future<File> generateMonthlyCalendarPdf(List<GroupModel> groups, DateTime month) async {
    final pdf = pw.Document();

    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.tajawalRegular();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final monthName = '${month.year}/${month.month.toString().padLeft(2, '0')}';
    const days = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
    final activeGroups = groups.where((g) => g.status.name == 'active').toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('التقويم الشهري للحصص والمجموعات ($monthName)', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.teal)),
                    pw.Text('تطبيق مُساعد المُعلِّم', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white),
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                headers: ['اليوم', 'عدد الحصص', 'المجموعات والحصص المجدولة بالتفصيل'],
                data: days.map((day) {
                  final dayGroups = activeGroups.where((g) => g.isScheduledOn(day)).toList();
                  final sessions = dayGroups.isEmpty
                      ? '— لا توجد حصص —'
                      : dayGroups.map((g) {
                          final time = g.timeForDay(day) ?? '';
                          final subject = (g.subject != null && g.subject!.isNotEmpty) ? ' [${g.subject}]' : '';
                          return '• [ $time ]  ${g.name}$subject';
                        }).join('\n');
                  return [day, dayGroups.length.toString(), sessions];
                }).toList(),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('تم إنشاء وطباعة التقويم بواسطة تطبيق مُساعِد المُعلِّم', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/monthly_calendar.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generate High-Resolution Egyptian School Certificate PDF as Uint8List (for Printing & Preview)
  static Future<Uint8List> generateCertificatePdfBytes(CertificateData cert) async {
    final pdf = pw.Document();

    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.tajawalRegular();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // Theme color palette
    PdfColor primaryColor;
    PdfColor secondaryColor;
    PdfColor bgColor;

    switch (cert.themeKey) {
      case 'navy':
        primaryColor = PdfColor.fromHex('#1E3A8A'); // Royal Navy
        secondaryColor = PdfColor.fromHex('#D97706'); // Gold Accent
        bgColor = PdfColor.fromHex('#F8FAFC');
        break;
      case 'emerald':
        primaryColor = PdfColor.fromHex('#065F46'); // Deep Emerald
        secondaryColor = PdfColor.fromHex('#D4AF37'); // Gold Accent
        bgColor = PdfColor.fromHex('#F0FDF4');
        break;
      case 'burgundy':
        primaryColor = PdfColor.fromHex('#881337'); // Burgundy Crimson
        secondaryColor = PdfColor.fromHex('#D4AF37'); // Gold Accent
        bgColor = PdfColor.fromHex('#FFF5F5');
        break;
      case 'gold':
      default:
        primaryColor = PdfColor.fromHex('#92660A'); // Egyptian Antique Gold
        secondaryColor = PdfColor.fromHex('#0D7377'); // Egyptian Teal
        bgColor = PdfColor.fromHex('#FFFDF5');
        break;
    }

    PdfColor withAlpha(PdfColor c, double a) => PdfColor(c.red, c.green, c.blue, a);

    String cleanText(String t) {
      return t
          .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '')
          .replaceAll('❖', '')
          .replaceAll('★', '')
          .replaceAll('«', '"')
          .replaceAll('»', '"')
          .trim();
    }

    final safeStudentName = cleanText(cert.studentName.isNotEmpty ? cert.studentName : 'اسم الطالب المتفوق');
    final safeTitle = cleanText(cert.certificateTitle.isNotEmpty ? cert.certificateTitle : 'شـهـادة شـكـر وتـقـديـر وتـفـوّق');
    final safeInstitution = cleanText(cert.institutionName.isNotEmpty ? cert.institutionName : 'جمهورية مصر العربية - وزارة التربية والتعليم');
    final safeGroup = cleanText(cert.groupName);
    final safeSubject = cleanText(cert.subject);
    final safeReason = cleanText(cert.reason.isNotEmpty ? cert.reason : 'تقديراً لتميزه وتفوقه الدراسي الباهر وحصوله على أعلى المراتب.');
    final safeQuran = cleanText(cert.quranVerse);
    final safeRank = cleanText(cert.rankOrGrade);
    final safeTeacher = cleanText(cert.teacherName.isNotEmpty ? cert.teacherName : 'المعلم');
    final safeDate = cleanText(cert.dateStr.isNotEmpty ? cert.dateStr : '${DateTime.now().year}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().day.toString().padLeft(2, '0')}');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(18),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: bgColor,
              border: pw.Border.all(color: primaryColor, width: 4),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            padding: const pw.EdgeInsets.all(12),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: secondaryColor, width: 1.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Header (Ministry / Republic / Center Title)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Right header
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            safeInstitution,
                            style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            safeGroup.isNotEmpty ? 'مجموعة: $safeGroup' : 'إدارة التعليم والتفوق',
                            style: pw.TextStyle(font: font, fontSize: 9.5, color: PdfColors.grey700),
                          ),
                        ],
                      ),

                      // Center Crest / Insignia Emblem
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: withAlpha(primaryColor, 0.1),
                          border: pw.Border.all(color: primaryColor, width: 1),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                        ),
                        child: pw.Text(
                          'شهادة تكريم وتفوق معتمدة',
                          style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor),
                        ),
                      ),

                      // Left header
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'تطبيق مُساعِد المُعلِّم',
                            style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            safeSubject.isNotEmpty ? 'المادة: $safeSubject' : 'سجل الشرف والريادة',
                            style: pw.TextStyle(font: font, fontSize: 9.5, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 4),

                  // 2. Quranic Verse / Motto
                  if (safeQuran.isNotEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: withAlpha(secondaryColor, 0.08),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        safeQuran,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          color: primaryColor,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                  pw.SizedBox(height: 6),

                  // 3. Main Certificate Title Banner (Calligraphic Egyptian School Style)
                  pw.Container(
                    width: 380,
                    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        safeTitle,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 20,
                          color: PdfColors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  // 4. Introductory Statement
                  pw.Text(
                    'يسر إدارة المركز وأستاذ المادة أن يمنحوا هذه الشهادة بكل فخر واعتزاز إلى الطالب / الطالبة:',
                    style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey800),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 6),

                  // 5. Highlighted Student Name (Large & Prominent)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: secondaryColor, width: 2),
                      ),
                    ),
                    child: pw.Text(
                      safeStudentName,
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 26,
                        color: primaryColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),

                  pw.SizedBox(height: 6),

                  // 6. Reason and Achievement Description
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                    child: pw.Text(
                      safeReason,
                      style: pw.TextStyle(font: font, fontSize: 11.5, height: 1.4, color: PdfColors.grey900),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),

                  // Rank Badge if exists
                  if (safeRank.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: withAlpha(secondaryColor, 0.15),
                        border: pw.Border.all(color: secondaryColor, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      ),
                      child: pw.Text(
                        'التقدير: $safeRank',
                        style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor),
                      ),
                    ),
                  ],

                  pw.SizedBox(height: 8),

                  // 7. Footer: Date, Official Stamp Seal, Teacher Signature
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      // Date on right
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('تحريراً في:', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            safeDate,
                            style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor),
                          ),
                        ],
                      ),

                      // Golden Seal in center
                      pw.Container(
                        width: 76,
                        height: 76,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: secondaryColor, width: 2),
                          color: withAlpha(secondaryColor, 0.08),
                        ),
                        child: pw.Center(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Text('خاتم التميز', style: pw.TextStyle(font: fontBold, fontSize: 9, color: primaryColor)),
                              pw.Text('والتفوق', style: pw.TextStyle(font: fontBold, fontSize: 8, color: primaryColor)),
                              pw.Text('معتمد رسمياً', style: pw.TextStyle(font: fontBold, fontSize: 7, color: secondaryColor)),
                            ],
                          ),
                        ),
                      ),

                      // Teacher Signature on left
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('أستاذ المادة:', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'أ. $safeTeacher',
                            style: pw.TextStyle(font: fontBold, fontSize: 12, color: primaryColor),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Container(width: 80, height: 1, color: primaryColor),
                          pw.SizedBox(height: 2),
                          pw.Text('التوقيع والاعتماد', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Generate a PDF timetable schedule (daily or weekly)
  static Future<Uint8List> generateSchedulePdf({
    required List<GroupModel> groups,
    required String teacherName,
    required String teacherPhone,
    DateTime? selectedDate,
    required bool isWeekly,
  }) async {
    final pdf = pw.Document();

    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.tajawalRegular();
      fontBold = await PdfGoogleFonts.tajawalBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    const weekDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isWeekly ? 'الجدول الأسبوعي العام للحصص' : 'جدول حصص اليوم',
                      style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.teal800),
                    ),
                    pw.Text(
                      'أ. $teacherName',
                      style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              ...weekDays.map((day) {
                final dayGroups = groups.where((g) => g.isScheduledOn(day)).toList();
                if (dayGroups.isEmpty) return pw.SizedBox.shrink();

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.teal300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(day, style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.teal900)),
                      pw.SizedBox(height: 4),
                      ...dayGroups.map((g) {
                        final time = g.timeForDay(day) ?? '';
                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('• ${g.name} (${g.subject ?? "عام"})', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                              pw.Text(time, style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Generate certificate as temporary file for direct WhatsApp sharing
  static Future<File> generateCertificatePdfFile(CertificateData cert) async {
    final bytes = await generateCertificatePdfBytes(cert);
    final dir = await getTemporaryDirectory();
    final safeName = cert.studentName.replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]'), '_');
    final file = File('${dir.path}/certificate_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}

