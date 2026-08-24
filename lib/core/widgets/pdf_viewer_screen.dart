import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

/// شاشة مستعرض وقارئ ملفات PDF المتكاملة داخل التطبيق
class PdfViewerScreen extends StatefulWidget {
  final String? filePath;
  final File? file;
  final Uint8List? bytes;
  final String title;
  final String? defaultFileName;

  const PdfViewerScreen({
    super.key,
    this.filePath,
    this.file,
    this.bytes,
    this.title = 'مستعرض PDF',
    this.defaultFileName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  Uint8List? _pdfBytes;
  String? _currentPath;
  String _currentTitle = 'مستعرض PDF';
  String _fileName = 'document.pdf';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
    _currentPath = widget.filePath ?? widget.file?.path;
    _fileName = widget.defaultFileName ??
        (_currentPath != null ? _currentPath!.split(Platform.pathSeparator).last : 'document.pdf');
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.bytes != null) {
        _pdfBytes = widget.bytes;
      } else if (widget.file != null) {
        _pdfBytes = await widget.file!.readAsBytes();
      } else if (widget.filePath != null && widget.filePath!.isNotEmpty) {
        final f = File(widget.filePath!);
        if (await f.exists()) {
          _pdfBytes = await f.readAsBytes();
        } else {
          _errorMessage = 'الملف غير موجود في المسار المحدد: ${widget.filePath}';
        }
      }
    } catch (e) {
      _errorMessage = 'تعذر فتح ملف الـ PDF: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final bytes = await file.readAsBytes();
        final name = result.files.single.name;

        setState(() {
          _currentPath = path;
          _fileName = name;
          _currentTitle = name;
          _pdfBytes = bytes;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في اختيار الملف: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareCurrentPdf() async {
    if (_pdfBytes == null) return;
    try {
      if (_currentPath != null && await File(_currentPath!).exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(_currentPath!)],
            text: 'مشاركة ملف PDF: $_fileName',
          ),
        );
      } else {
        await Printing.sharePdf(
          bytes: _pdfBytes!,
          filename: _fileName,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء المشاركة: $e', style: GoogleFonts.tajawal()),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currentTitle,
              style: GoogleFonts.changa(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_pdfBytes != null)
              Text(
                _fileName,
                style: GoogleFonts.tajawal(fontSize: 11, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'فتح ملف PDF آخر',
            icon: const Icon(Icons.folder_open_rounded, size: 22),
            onPressed: _pickPdfFile,
          ),
          if (_pdfBytes != null)
            IconButton(
              tooltip: 'مشاركة الملف',
              icon: const Icon(Icons.share_rounded, size: 20),
              onPressed: _shareCurrentPdf,
            ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'جارٍ تحميل واستعراض الملف...',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'تعذر فتح الملف',
                style: GoogleFonts.changa(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _pickPdfFile,
                icon: const Icon(Icons.file_open_rounded, size: 20),
                label: Text('اختيار ملف PDF من الهاتف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 54),
              ),
              const SizedBox(height: 20),
              Text(
                'مستعرض وقارئ الـ PDF 📄',
                style: GoogleFonts.changa(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'يمكنك فتح واستعراض أي ملف PDF أو تقرير أو مذكرة مخزنة في هاتفك وقراءتها وطباعتها بسهولة.',
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _pickPdfFile,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(
                  'اختيار وفتح ملف PDF من الهاتف 📂',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PdfPreview(
      build: (format) async => _pdfBytes!,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      allowPrinting: true,
      allowSharing: true,
      maxPageWidth: 720,
      pdfFileName: _fileName,
      loadingWidget: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text('جارٍ تحضير الصفحات...', style: GoogleFonts.tajawal(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      ),
      scrollViewDecoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : const Color(0xFFE2E8F0),
      ),
      actions: [
        PdfPreviewAction(
          icon: const Icon(Icons.file_open_outlined),
          onPressed: (ctx, fn, format) async {
            await _pickPdfFile();
          },
        ),
      ],
    );
  }
}
