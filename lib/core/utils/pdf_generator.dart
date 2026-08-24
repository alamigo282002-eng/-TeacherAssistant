import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/group_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/attendance_model.dart';
import '../../features/certificates/certificate_model.dart';

class PdfGenerator {
  /// Generate a Premium Executive PDF report for a student
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

    final primaryColor = PdfColor.fromInt(0xFF0D7377);
    final primaryLight = PdfColor.fromInt(0xFFE6F7F7);
    final accentGreen = PdfColor.fromInt(0xFF10B981);
    final accentGreenLight = PdfColor.fromInt(0xFFE8F5E9);
    final accentOrange = PdfColor.fromInt(0xFFF59E0B);
    final accentOrangeLight = PdfColor.fromInt(0xFFFEF3C7);
    final textDark = PdfColor.fromInt(0xFF0F172A);
    final textMuted = PdfColor.fromInt(0xFF64748B);
    final bgLight = PdfColor.fromInt(0xFFF8FAFC);
    final borderCol = PdfColor.fromInt(0xFFE2E8F0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          final presentCount = attendance.where((a) => a.status.name == 'present').length;
          final absentCount = attendance.where((a) => a.status.name == 'absent').length;
          final totalSessions = presentCount + absentCount;
          final attRate = totalSessions > 0 ? ((presentCount / totalSessions) * 100).round() : 100;

          // Calc exam average
          double totalMarksObtained = 0;
          double totalMarksPossible = 0;
          for (final e in exams) {
            final num? m = e['marks'] as num?;
            final num? t = (e['total_marks'] as num?) ?? (e['total'] as num?);
            if (m != null) {
              totalMarksObtained += m.toDouble();
              totalMarksPossible += (t?.toDouble() ?? 100.0);
            }
          }
          final examAvgPercent = totalMarksPossible > 0 ? ((totalMarksObtained / totalMarksPossible) * 100).toStringAsFixed(1) : '-';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Premium Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'تقرير أداء الطالب الشامل',
                          style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.white),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'سجل المتابعة الأكاديمية والسلوكية الرسمية',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF095255),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        'مُساعِد المُعلِّم',
                        style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 2. Student Info Card
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: bgLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  border: pw.Border.all(color: borderCol, width: 1),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('اسم الطالب: ', style: pw.TextStyle(font: fontBold, fontSize: 13, color: textDark)),
                            pw.Text(student.name, style: pw.TextStyle(font: fontBold, fontSize: 14, color: primaryColor)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('هاتف الطالب: ${student.phone.isNotEmpty ? student.phone : "-"}', style: pw.TextStyle(fontSize: 10, color: textMuted)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('هاتف ولي الأمر: ${student.parentPhone.isNotEmpty ? student.parentPhone : "-"}', style: pw.TextStyle(fontSize: 10, color: textMuted)),
                        pw.SizedBox(height: 4),
                        pw.Text('تاريخ التقرير: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: pw.TextStyle(fontSize: 10, color: textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 3. KPI Metric Summary Cards (4 Cards)
              pw.Row(
                children: [
                  // Card 1: Attendance Rate
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: pw.BoxDecoration(
                        color: accentGreenLight,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: accentGreen, width: 0.8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text('نسبة الحضور', style: pw.TextStyle(font: fontBold, fontSize: 10, color: textDark)),
                          pw.SizedBox(height: 2),
                          pw.Text('$attRate%', style: pw.TextStyle(font: fontBold, fontSize: 16, color: accentGreen)),
                          pw.Text('حضور: $presentCount | غياب: $absentCount', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // Card 2: Points & Evaluation
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: pw.BoxDecoration(
                        color: accentOrangeLight,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: accentOrange, width: 0.8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text('نقاط التميز', style: pw.TextStyle(font: fontBold, fontSize: 10, color: textDark)),
                          pw.SizedBox(height: 2),
                          pw.Text('${student.points} ⭐', style: pw.TextStyle(font: fontBold, fontSize: 16, color: accentOrange)),
                          pw.Text('تقييم سلوكي متميز', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // Card 3: Exams Average
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: pw.BoxDecoration(
                        color: primaryLight,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        border: pw.Border.all(color: primaryColor, width: 0.8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text('متوسط الاختبارات', style: pw.TextStyle(font: fontBold, fontSize: 10, color: textDark)),
                          pw.SizedBox(height: 2),
                          pw.Text(examAvgPercent != '-' ? '$examAvgPercent%' : '-', style: pw.TextStyle(font: fontBold, fontSize: 16, color: primaryColor)),
                          pw.Text('عدد الاختبارات: ${exams.length}', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // 4. Exams Table Section
              if (exams.isNotEmpty) ...[
                pw.Text('سجل نتائج الاختبارات والكويزات:', style: pw.TextStyle(font: fontBold, fontSize: 12, color: primaryColor)),
                pw.SizedBox(height: 6),
                pw.TableHelper.fromTextArray(
                  context: context,
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: borderCol, width: 0.8),
                  ),
                  headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
                  cellStyle: pw.TextStyle(font: font, fontSize: 9.5),
                  headerDecoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
                  ),
                  rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                  cellAlignment: pw.Alignment.center,
                  cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  headers: ['اسم الاختبار', 'الدرجة المحصلة', 'الدرجة النهائية', 'النسبة المئوية', 'التقدير'],
                  data: exams.map((e) {
                    final examName = e['name']?.toString() ?? 'اختبار';
                    final num? rawMarks = e['marks'] as num?;
                    final num? rawTotal = (e['total_marks'] as num?) ?? (e['total'] as num?);
                    final total = rawTotal?.toDouble() ?? 100.0;

                    String marksStr = '-';
                    String totalStr = total.toInt().toString();
                    String percentStr = '-';
                    String gradeStr = '-';

                    if (rawMarks != null) {
                      final marks = rawMarks.toDouble();
                      marksStr = marks.toInt().toString();
                      if (total > 0) {
                        final p = (marks / total) * 100;
                        percentStr = '${p.toStringAsFixed(1)}%';
                        if (p >= 90) {
                          gradeStr = 'ممتاز 🌟';
                        } else if (p >= 80) {
                          gradeStr = 'جيد جداً';
                        } else if (p >= 65) {
                          gradeStr = 'جيد';
                        } else if (p >= 50) {
                          gradeStr = 'مقبول';
                        } else {
                          gradeStr = 'يحتاج لمتابعة';
                        }
                      }
                    }
                    return [examName, marksStr, totalStr, percentStr, gradeStr];
                  }).toList(),
                ),
                pw.SizedBox(height: 14),
              ],

              // 5. Notes & Observations
              if (notes.isNotEmpty) ...[
                pw.Text('الملاحظات والتوجيهات السلوكية:', style: pw.TextStyle(font: fontBold, fontSize: 12, color: primaryColor)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: bgLight,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: borderCol, width: 0.8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: notes.map((n) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('• ', style: pw.TextStyle(font: fontBold, color: primaryColor)),
                              pw.Expanded(child: pw.Text(n.content, style: pw.TextStyle(fontSize: 9.5, color: textDark))),
                            ],
                          ),
                        )).toList(),
                  ),
                ),
                pw.SizedBox(height: 14),
              ],

              pw.Spacer(),

              // 6. Signatures & Official Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('توقيع ولي الأمر', style: pw.TextStyle(font: fontBold, fontSize: 10, color: textMuted)),
                      pw.SizedBox(height: 20),
                      pw.Container(width: 120, height: 1, color: borderCol),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('توقيع وختم المعلم', style: pw.TextStyle(font: fontBold, fontSize: 10, color: textMuted)),
                      pw.SizedBox(height: 20),
                      pw.Container(width: 120, height: 1, color: borderCol),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: borderCol, thickness: 0.8),
              pw.Center(
                child: pw.Text(
                  'تم استخراج هذا التقرير تلقائياً بواسطة تطبيق مُساعِد المُعلِّم (Teacher Assistant)',
                  style: pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
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

  /// Generate a Premium Executive PDF report for a group
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

    final primaryColor = PdfColor.fromInt(0xFF0D7377);
    final bgLight = PdfColor.fromInt(0xFFF8FAFC);
    final borderCol = PdfColor.fromInt(0xFFE2E8F0);
    final textDark = PdfColor.fromInt(0xFF0F172A);
    final textMuted = PdfColor.fromInt(0xFF64748B);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const pw.EdgeInsets.only(bottom: 14),
          decoration: pw.BoxDecoration(
            color: primaryColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'كشف وتقرير مجموعة: ${group.name}',
                style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.white),
              ),
              pw.Text(
                'إجمالي الطلاب: ${students.length}',
                style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: borderCol, thickness: 0.8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('تطبيق مُساعِد المُعلِّم', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
                pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(fontSize: 8.5, color: textMuted)),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Group Details Summary
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            margin: const pw.EdgeInsets.only(bottom: 14),
            decoration: pw.BoxDecoration(
              color: bgLight,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: borderCol, width: 0.8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (group.subject != null && group.subject!.isNotEmpty)
                  pw.Text('المادة: ${group.subject}', style: pw.TextStyle(font: fontBold, fontSize: 11, color: textDark)),
                pw.Text('النوع: ${group.type.label}', style: pw.TextStyle(fontSize: 11, color: textMuted)),
                pw.Text('تاريخ التقرير: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: pw.TextStyle(fontSize: 10, color: textMuted)),
              ],
            ),
          ),

          // Students Table
          pw.TableHelper.fromTextArray(
            context: context,
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: borderCol, width: 0.8),
            ),
            headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
            cellStyle: pw.TextStyle(font: font, fontSize: 9.5),
            headerDecoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(6)),
            ),
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
            headers: ['#', 'اسم الطالب', 'هاتف الطالب', 'هاتف ولي الأمر', 'النقاط', 'الحالة'],
            data: students.asMap().entries.map((e) {
              final s = e.value;
              return [
                (e.key + 1).toString(),
                s.name,
                s.phone.isNotEmpty ? s.phone : '-',
                s.parentPhone.isNotEmpty ? s.parentPhone : '-',
                '${s.points} ⭐',
                s.status.name == 'active' ? 'نشط' : 'غير نشط',
              ];
            }).toList(),
          ),
        ],
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

