import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/news_item_model.dart';
import '../../data/repositories/news_repository.dart';

class NewsSyncService {
  final NewsRepository _newsRepo;

  NewsSyncService({NewsRepository? newsRepo})
      : _newsRepo = newsRepo ?? NewsRepository();

  static const List<String> _feedUrls = [
    // 1. Google News RSS for Egyptian Ministry of Education
    'https://news.google.com/rss/search?q=%D9%88%D8%B2%D8%A7%D8%B1%D8%A9+%D8%A7%D9%84%D8%AA%D8%B1%D8%A8%D9%8A%D8%A9+%D9%88%D8%A7%D9%84%D8%AA%D8%B9%D9%84%D9%8A%D9%85+%D9%85%D8%B5%D8%B1&hl=ar&gl=EG&ceid=EG:ar',
    // 2. Google News RSS for Egyptian High School & Education Exams
    'https://news.google.com/rss/search?q=%D8%A7%D9%85%D8%AA%D8%AD%D8%A7%D9%86%D8%A7%D8%AA+%D8%A7%D9%84%D8%AB%D8%A7%D9%86%D9%88%D9%8A%D8%A9+%D8%A7%D9%84%D8%B9%D8%A7%D9%85%D8%A9+%D9%85%D8%B5%D8%B1&hl=ar&gl=EG&ceid=EG:ar',
  ];

  Future<int> syncLatestNews() async {
    int newItemsCount = 0;

    for (final url in _feedUrls) {
      try {
        final items = await _fetchRssFeed(url);
        for (final item in items) {
          final existing = await _newsRepo.getById(item.id);
          if (existing == null) {
            await _newsRepo.insert(item);
            newItemsCount++;
          }
        }
      } catch (e) {
        debugPrint('Error syncing news from $url: $e');
      }
    }

    return newItemsCount;
  }

  Future<List<NewsItemModel>> _fetchRssFeed(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    client.badCertificateCallback = (cert, host, port) => true;

    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (compatible; TeacherAssistantApp/1.0)');
      request.headers.set(HttpHeaders.acceptHeader, 'application/rss+xml, application/xml, text/xml, */*');

      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return [];
      }

      final body = await response.transform(utf8.decoder).join();
      client.close();

      return _parseRssXml(body);
    } catch (e) {
      client.close();
      debugPrint('RSS Fetch Error: $e');
      return [];
    }
  }

  List<NewsItemModel> _parseRssXml(String xml) {
    final items = <NewsItemModel>[];
    final itemRegex = RegExp(r'<item>([\s\S]*?)<\/item>', caseSensitive: false);
    final matches = itemRegex.allMatches(xml);

    for (final match in matches) {
      final itemBlock = match.group(1) ?? '';

      final rawTitle = _extractTag(itemBlock, 'title');
      final link = _extractTag(itemBlock, 'link');
      final pubDateStr = _extractTag(itemBlock, 'pubDate');
      final rawSource = _extractTag(itemBlock, 'source');

      if (rawTitle.isEmpty) continue;

      // 1. Clean headline and extract clean publisher source
      final parsed = _extractCleanTitleAndSource(rawTitle, rawSource);
      final cleanTitle = parsed['title']!;
      final cleanSource = parsed['source']!;

      DateTime pubDate;
      try {
        pubDate = _parseRssDate(pubDateStr);
      } catch (_) {
        pubDate = DateTime.now();
      }

      final category = _detectCategory(cleanTitle);
      final isUrgent = cleanTitle.contains('عاجل') ||
          cleanTitle.contains('رسمياً') ||
          cleanTitle.contains('قرار وزير') ||
          cleanTitle.contains('الخريطة الزمنية');

      final tags = _generateTags(cleanTitle);

      // 2. Build structured, beautifully formatted Arabic educational article (ZERO raw URLs or HTML)
      final structuredContent = _buildStructuredContent(
        title: cleanTitle,
        source: cleanSource,
        category: category,
        pubDate: pubDate,
      );

      final cleanSummary = _buildSummary(cleanTitle);
      final id = 'rss_${cleanTitle.hashCode.abs()}';

      items.add(
        NewsItemModel(
          id: id,
          title: cleanTitle,
          summary: cleanSummary,
          content: structuredContent,
          category: category,
          source: cleanSource,
          publishedAt: pubDate,
          isUrgent: isUrgent,
          isPinned: false,
          tags: tags,
          externalUrl: link.isNotEmpty ? link.trim() : null,
        ),
      );
    }

    return items;
  }

  Map<String, String> _extractCleanTitleAndSource(String rawTitle, String rawSource) {
    String cleanTitle = _cleanHtml(rawTitle);
    String cleanSource = _cleanHtml(rawSource);

    // Google News titles format: "العنوان الرئيسي للخبر - اسم الجريدة أو الموقع"
    if (cleanTitle.contains(' - ')) {
      final parts = cleanTitle.split(' - ');
      if (parts.length >= 2) {
        cleanTitle = parts.sublist(0, parts.length - 1).join(' - ').trim();
        if (cleanSource.isEmpty || cleanSource == 'وزارة التربية والتعليم') {
          cleanSource = parts.last.trim();
        }
      }
    }

    if (cleanSource.isEmpty) {
      cleanSource = 'وزارة التربية والتعليم والتعليم الفني';
    }

    return {
      'title': cleanTitle,
      'source': cleanSource,
    };
  }

  String _buildSummary(String title) {
    return 'متابعة أحدث القرارات والتوجيهات الرسمية الصادرة بشأن $title، وما تتضمنه من تعليمات للمدارس والطلاب والمعلمين.';
  }

  String _buildStructuredContent({
    required String title,
    required String source,
    required String category,
    required DateTime pubDate,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('📌 موجز القرار والبيان الرسمي:');
    buffer.writeln('$title.');
    buffer.writeln();

    buffer.writeln('🏛️ الجهة المصدرة:');
    buffer.writeln('$source.');
    buffer.writeln();

    buffer.writeln('📋 أهم النقاط والتوجيهات للمعلم والطلاب:');
    if (category == 'exams') {
      buffer.writeln('• الالتزام بمواصفات الورقة الامتحانية وتوزيع الدرجات المعتمد.');
      buffer.writeln('• تدريب الطلاب على الأسئلة التفاعلية والنماذج الاسترشادية المتكافئة.');
      buffer.writeln('• متابعة رصد درجات أعمال السنة والتقييمات الدورية في مواعيدها.');
    } else if (category == 'curriculum') {
      buffer.writeln('• الالتزام بالخطة الزمنية لتوزيع المناهج الدراسية لكافة المراحل.');
      buffer.writeln('• استيفاء نواتج التعلم الأساسية وحل التدريبات والأنشطة المقررة.');
    } else {
      buffer.writeln('• متابعة تنفيذ القرارات الصادرة للإدارات التعليمية والمدارس والسناتر.');
      buffer.writeln('• الالتزام بالتعليمات والضوابط الصادرة لضمان انتظام العملية التعليمية.');
      buffer.writeln('• إحاطة أولياء الأمور والطلاب بأي تحديثات أو مواعيد هامة.');
    }
    buffer.writeln();

    buffer.writeln('🔗 يمكنك الاطلاع على التغطية الكاملة للخبر عبر زر «فتح المقال في المصدر الأصلي» بالأسفل.');

    return buffer.toString();
  }

  String _extractTag(String xml, String tagName) {
    final regex = RegExp('<$tagName[^>]*>([\\s\\S]*?)<\\/$tagName>', caseSensitive: false);
    final match = regex.firstMatch(xml);
    if (match != null) {
      String val = match.group(1) ?? '';
      val = val.replaceAll('<![CDATA[', '').replaceAll(']]>', '');
      return val.trim();
    }
    return '';
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _detectCategory(String title) {
    final text = title.toLowerCase();

    if (text.contains('امتحان') ||
        text.contains('امتحانات') ||
        text.contains('درجات') ||
        text.contains('أعمال السنة') ||
        text.contains('شهادة') ||
        text.contains('نتيجة') ||
        text.contains('تقييم')) {
      return 'exams';
    }

    if (text.contains('منهج') ||
        text.contains('مناهج') ||
        text.contains('كتاب') ||
        text.contains('نماذج') ||
        text.contains('تدريب') ||
        text.contains('استرشاد')) {
      return 'curriculum';
    }

    if (text.contains('نصائح') ||
        text.contains('طريقة') ||
        text.contains('استراتيجية') ||
        text.contains('معلم')) {
      return 'tips';
    }

    return 'ministry';
  }

  List<String> _generateTags(String title) {
    final tags = <String>[];
    if (title.contains('الثانوية العامة')) tags.add('الثانوية العامة');
    if (title.contains('الإعدادية')) tags.add('الشهادة الإعدادية');
    if (title.contains('الابتدائية')) tags.add('المرحلة الابتدائية');
    if (title.contains('امتحانات') || title.contains('امتحان')) tags.add('امتحانات');
    if (title.contains('قرار') || title.contains('رسمي')) tags.add('قرارات رسمية');
    if (title.contains('الوزير') || title.contains('الوزارة')) tags.add('وزارة التعليم');
    if (title.contains('المناهج')) tags.add('المناهج الدراسية');
    if (tags.isEmpty) tags.add('أخبار التعليم');
    return tags;
  }

  DateTime _parseRssDate(String dateStr) {
    try {
      return HttpDate.parse(dateStr);
    } catch (_) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }
}
