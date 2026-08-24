import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/group_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/payment_model.dart';
import '../constants/app_constants.dart';
import '../utils/date_helper.dart';

class FinancePdfService {
  /// Export finance report as PDF and share
  Future<File> exportFinanceReport({
    required int month,
    required int year,
    required List<dynamic> summaries,
    required double totalExpected,
    required double totalCollected,
    required double totalRemaining,
  }) async {
    try {
      pw.Font font;
      pw.Font fontBold;
      try {
        font = await PdfGoogleFonts.tajawalRegular();
        fontBold = await PdfGoogleFonts.tajawalBold();
      } catch (_) {
        font = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      );

      final monthName = AppDateUtils.arabicMonth(month);
      final rate = totalExpected > 0 ? (totalCollected / totalExpected * 100).round() : 0;

      // Build student rows
      final rows = <List<String>>[];
      int index = 1;
      for (final s in summaries) {
        final groupName = s.groupName as String;
        final basePrice = s.basePrice as double;
        final paymentMode = (s.paymentMode == 'per_session') ? 'بالحصة' : 'شهري';
        final studentStatuses = s.studentStatuses as List<dynamic>;

        for (final status in studentStatuses) {
          final student = status.student;
          final due = student.calculateDueAmount(basePrice) as double;
          final paid = status.amountPaid as double;
          final remaining = (due - paid).clamp(0.0, double.infinity);

          String pType = 'لم يدفع';
          try {
            if (status.paymentType is PaymentType) {
              pType = (status.paymentType as PaymentType).label;
            } else if (status.paymentType != null) {
              pType = status.paymentType.label.toString();
            }
          } catch (_) {
            pType = status.paymentType?.toString() ?? 'لم يدفع';
          }

          String discountInfo = '-';
          if (student.isExempt) {
            discountInfo = 'إعفاء';
          } else if (student.discountType == 'fixed') {
            discountInfo = '${student.discountAmount} ج.م';
          } else if (student.discountType == 'percent') {
            discountInfo = '${student.discountAmount}%';
          }

          rows.add([
            index.toString(),
            groupName,
            student.name as String,
            paymentMode,
            basePrice.toInt().toString(),
            discountInfo,
            due.toInt().toString(),
            paid.toInt().toString(),
            remaining.toInt().toString(),
            pType,
          ]);
          index++;
        }
      }

      // Create pages with the table
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => _buildPdfHeader(fontBold, monthName, year, totalExpected, totalCollected, totalRemaining, rate),
          footer: (context) => _buildPdfFooter(font, context),
          build: (context) => [
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
              cellStyle: pw.TextStyle(font: font, fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF275D46)),
              cellHeight: 24,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.center,
                8: pw.Alignment.center,
                9: pw.Alignment.center,
              },
              headers: ['م', 'المجموعة', 'اسم الطالب', 'النظام', 'الأصلي', 'الخصم', 'المستحق', 'المدفوع', 'المتبقي', 'الحالة'],
              data: rows,
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F7F5)),
            ),
          ],
        ),
      );

      final fileBytes = await pdf.save();
      final tempDir = await _getTempDirectory();
      final now = DateTime.now();
      final dateSuffix = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final file = File('${tempDir.path}/Finance_Report_${month}_${year}_$dateSuffix.pdf');
      await file.writeAsBytes(fileBytes);

      return file;
    } catch (e) {
      debugPrint('PDF Finance Export Error: $e');
      rethrow;
    }
  }

  /// Export group data as PDF and share
  Future<File> exportGroupToPdf({
    required GroupModel group,
    required List<StudentModel> students,
    required List<AttendanceModel> attendanceRecords,
    required List<ExamModel> exams,
    required List<ExamResultModel> examResults,
    required List<PaymentModel> payments,
  }) async {
    try {
      pw.Font font;
      pw.Font fontBold;
      try {
        font = await PdfGoogleFonts.tajawalRegular();
        fontBold = await PdfGoogleFonts.tajawalBold();
      } catch (_) {
        font = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      );

      final studentMap = {for (final s in students) s.id: s};

      // Page 1: Students List
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(24),
          header: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('تقرير مجموعة: ${group.name}', style: pw.TextStyle(font: fontBold, fontSize: 16, color: const PdfColor.fromInt(0xFF022B22))),
                pw.Text(group.type.label, style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey600)),
              ],
            ),
          ),
          build: (context) => [
            pw.Text('بيانات الطلاب', style: pw.TextStyle(font: fontBold, fontSize: 13, color: const PdfColor.fromInt(0xFF275D46))),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
              cellStyle: pw.TextStyle(font: font, fontSize: 8.5),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF275D46)),
              cellHeight: 22,
              headers: ['م', 'الاسم', 'الهاتف', 'ولي الأمر', 'النقاط', 'الحالة', 'الخصم', 'النظام'],
              data: students.asMap().entries.map((e) {
                final s = e.value;
                return [
                  (e.key + 1).toString(),
                  s.name,
                  s.phone.isNotEmpty ? s.phone : '-',
                  s.parentPhone.isNotEmpty ? s.parentPhone : '-',
                  s.points.toString(),
                  s.status.label,
                  s.discountAmount > 0 ? '${s.discountAmount}' : '-',
                  s.paymentMode == 'per_session' ? 'بالحصة' : 'شهري',
                ];
              }).toList(),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F7F5)),
            ),
            pw.SizedBox(height: 20),

            // Attendance Table
            if (attendanceRecords.isNotEmpty) ...[
              pw.Text('سجل الحضور', style: pw.TextStyle(font: fontBold, fontSize: 13, color: const PdfColor.fromInt(0xFF275D46))),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
                cellStyle: pw.TextStyle(font: font, fontSize: 8.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF275D46)),
                cellHeight: 22,
                headers: ['التاريخ', 'اسم الطالب', 'الحالة', 'الواجب', 'التسميع', 'ملاحظات'],
                data: attendanceRecords.map((a) {
                  final student = studentMap[a.studentId];
                  return [
                    a.date.toIso8601String().split('T').first,
                    student?.name ?? 'غير معروف',
                    a.status.label,
                    a.homeworkDone ? 'نعم' : 'لا',
                    (a.recitationPoints ?? 0.0).toString(),
                    a.note,
                  ];
                }).toList(),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F7F5)),
              ),
              pw.SizedBox(height: 20),
            ],

            // Exams Table
            if (examResults.isNotEmpty) ...[
              pw.Text('نتائج الامتحانات', style: pw.TextStyle(font: fontBold, fontSize: 13, color: const PdfColor.fromInt(0xFF275D46))),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
                cellStyle: pw.TextStyle(font: font, fontSize: 8.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF275D46)),
                cellHeight: 22,
                headers: ['الامتحان', 'التاريخ', 'العظمى', 'الطالب', 'الدرجة', 'النسبة'],
                data: examResults.map((r) {
                  final exam = exams.firstWhere((e) => e.id == r.examId, orElse: () => exams.first);
                  final student = studentMap[r.studentId];
                  final marks = r.marks;
                  final percentage = (marks != null && exam.totalMarks > 0)
                      ? '${((marks / exam.totalMarks) * 100).toStringAsFixed(1)}%'
                      : '-';
                  return [
                    exam.name,
                    exam.date.toIso8601String().split('T').first,
                    exam.totalMarks.toString(),
                    student?.name ?? 'غير معروف',
                    marks?.toString() ?? 'لم يرصد',
                    percentage,
                  ];
                }).toList(),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F7F5)),
              ),
              pw.SizedBox(height: 20),
            ],

            // Payments Table
            if (payments.isNotEmpty) ...[
              pw.Text('سجل المدفوعات', style: pw.TextStyle(font: fontBold, fontSize: 13, color: const PdfColor.fromInt(0xFF275D46))),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
                cellStyle: pw.TextStyle(font: font, fontSize: 8.5),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF275D46)),
                cellHeight: 22,
                headers: ['التاريخ', 'الطالب', 'الشهر', 'السنة', 'المدفوع', 'المطلوب', 'الحالة'],
                data: payments.map((p) {
                  final student = studentMap[p.studentId];
                  return [
                    p.date.toIso8601String().split('T').first,
                    student?.name ?? 'غير معروف',
                    p.month.toString(),
                    p.year.toString(),
                    p.amount.toInt().toString(),
                    p.totalDue.toInt().toString(),
                    p.type.label,
                  ];
                }).toList(),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F7F5)),
              ),
            ],
          ],
        ),
      );

      final fileBytes = await pdf.save();
      final tempDir = await _getTempDirectory();
      final safeGroupName = group.name.replaceAll(RegExp(r'[^a-zA-Z0-9\u0600-\u06FF]'), '_');
      final now = DateTime.now();
      final dateSuffix = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final file = File('${tempDir.path}/${safeGroupName}_$dateSuffix.pdf');
      await file.writeAsBytes(fileBytes);

      return file;
    } catch (e) {
      debugPrint('PDF Group Export Error: $e');
      rethrow;
    }
  }

  pw.Widget _buildPdfHeader(pw.Font fontBold, String monthName, int year, double expected, double collected, double remaining, int rate) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF0D7377),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'التقرير المالي ومتابعة الاشتراكات — $monthName $year',
                style: pw.TextStyle(font: fontBold, fontSize: 15, color: PdfColors.white),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF095255),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  'نسبة التحصيل: $rate٪',
                  style: pw.TextStyle(font: fontBold, fontSize: 11, color: const PdfColor.fromInt(0xFFFDE047)),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _summaryBox(fontBold, 'إجمالي المتوقع', '${expected.toInt()} ج.م', PdfColors.white),
              _summaryBox(fontBold, 'المحصّل الفعلي', '${collected.toInt()} ج.م', const PdfColor.fromInt(0xFF6EE7B7)),
              _summaryBox(fontBold, 'المتبقي والمتأخرات', '${remaining.toInt()} ج.م', const PdfColor.fromInt(0xFFFCA5A5)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryBox(pw.Font fontBold, String title, String value, PdfColor valueColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0x33000000),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 12, color: valueColor)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Font font, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'مُساعِد المُعلِّم',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  Future<Directory> _getTempDirectory() async {
    try {
      return await getTemporaryDirectory();
    } catch (_) {
      try {
        return await getApplicationDocumentsDirectory();
      } catch (_) {
        return Directory.systemTemp;
      }
    }
  }
}
