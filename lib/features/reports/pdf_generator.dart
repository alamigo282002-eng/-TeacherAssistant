import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/student_model.dart';
import '../../core/utils/date_helper.dart';

class PdfGenerator {
  static Future<void> generateStudentReport({
    required StudentModel student,
    required List<AttendanceModel> attendance,
    required List<Map<String, dynamic>> examHistory,
    required BuildContext context,
  }) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.cairoRegular(),
        bold: await PdfGoogleFonts.cairoBold(),
      ),
    );

    final presentCount = attendance.where((a) => a.isPresent).length;
    final absentCount = attendance.where((a) => a.isAbsent).length;
    final hwNotDone =
        attendance.where((a) => a.isPresent && !a.homeworkDone).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('0D7377'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            padding: const pw.EdgeInsets.all(20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      student.name,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'تقرير الطالب',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('B3FFFFFF'),
                        fontSize: 14,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
                pw.Text(
                  AppDateUtils.formatArabicDate(DateTime.now()),
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('B3FFFFFF'),
                    fontSize: 11,
                  ),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary stats
          pw.Row(
            children: [
              _pdfStatCard('$presentCount', 'حضور',
                  PdfColor.fromHex('2ECC71')),
              pw.SizedBox(width: 8),
              _pdfStatCard('$absentCount', 'غياب',
                  PdfColor.fromHex('E74C3C')),
              pw.SizedBox(width: 8),
              _pdfStatCard('$hwNotDone', 'بدون واجب',
                  PdfColor.fromHex('F39C12')),
            ],
          ),
          pw.SizedBox(height: 20),

          // Attendance table
          pw.Text(
            'سجل الحضور',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          _pdfAttendanceTable(attendance),
          pw.SizedBox(height: 20),

          // Exam results
          if (examHistory.isNotEmpty) ...[
            pw.Text(
              'نتائج الاختبارات',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.SizedBox(height: 8),
            _pdfExamsTable(examHistory),
          ],
        ],
      ),
    );

    // Save to temp file and share
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_${student.name}.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'تقرير ${student.name}',
      ),
    );
  }

  static pw.Widget _pdfStatCard(String value, String label, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
            pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColor.fromHex('B3FFFFFF'),
                fontSize: 11,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pdfAttendanceTable(List<AttendanceModel> records) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('E2E8F0'),
        width: 0.5,
      ),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('0D7377')),
          children: [
            _pdfCell('التاريخ', isHeader: true),
            _pdfCell('الحضور', isHeader: true),
            _pdfCell('الواجب', isHeader: true),
            _pdfCell('ملاحظة', isHeader: true),
          ],
        ),
        ...records.map(
          (a) => pw.TableRow(
            children: [
              _pdfCell(AppDateUtils.formatArabicShortDate(a.date)),
              _pdfCell(a.isPresent ? 'حاضر ✓' : 'غائب ✗'),
              _pdfCell(a.isPresent
                  ? (a.homeworkDone ? 'نعم ✓' : 'لا ✗')
                  : '-'),
              _pdfCell(a.note),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfExamsTable(List<Map<String, dynamic>> exams) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('E2E8F0'),
        width: 0.5,
      ),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F4A261')),
          children: [
            _pdfCell('الاختبار', isHeader: true),
            _pdfCell('التاريخ', isHeader: true),
            _pdfCell('الدرجة', isHeader: true),
            _pdfCell('%', isHeader: true),
          ],
        ),
        ...exams.map((e) {
          final marks = e['marks'] as double?;
          final total = (e['total_marks'] as num).toDouble();
          final pct =
              marks != null ? '${(marks / total * 100).round()}%' : '-';
          return pw.TableRow(
            children: [
              _pdfCell(e['name'] as String),
              _pdfCell(AppDateUtils.formatArabicShortDate(
                  DateTime.parse(e['date'] as String))),
              _pdfCell(marks != null
                  ? '${marks.toInt()} / ${total.toInt()}'
                  : 'لم تُدخل'),
              _pdfCell(pct),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _pdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: isHeader ? PdfColors.white : PdfColors.black,
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
