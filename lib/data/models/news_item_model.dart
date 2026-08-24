import 'dart:convert';

enum NewsCategory {
  ministry('قرارات الوزارة 🏛️', 'ministry'),
  exams('الامتحانات والتقييم 📝', 'exams'),
  curriculum('المناهج والتوزيع 📚', 'curriculum'),
  announcements('إعلانات المعلم 📢', 'announcements'),
  tips('نصائح تربوية 💡', 'tips');

  final String label;
  final String code;
  const NewsCategory(this.label, this.code);

  static NewsCategory fromCode(String code) {
    switch (code) {
      case 'ministry': return NewsCategory.ministry;
      case 'exams': return NewsCategory.exams;
      case 'curriculum': return NewsCategory.curriculum;
      case 'announcements': return NewsCategory.announcements;
      case 'tips': return NewsCategory.tips;
      default: return NewsCategory.ministry;
    }
  }
}

class NewsItemModel {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String category; // 'ministry', 'exams', 'curriculum', 'announcements', 'tips'
  final String source;
  final DateTime publishedAt;
  final bool isUrgent;
  final bool isPinned;
  final List<String> tags;
  final String? author;
  final String? externalUrl;

  NewsItemModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    this.category = 'ministry',
    this.source = 'وزارة التربية والتعليم',
    required this.publishedAt,
    this.isUrgent = false,
    this.isPinned = false,
    this.tags = const [],
    this.author,
    this.externalUrl,
  });

  NewsCategory get newsCategory => NewsCategory.fromCode(category);

  NewsItemModel copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? category,
    String? source,
    DateTime? publishedAt,
    bool? isUrgent,
    bool? isPinned,
    List<String>? tags,
    String? author,
    String? externalUrl,
  }) {
    return NewsItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      category: category ?? this.category,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      isUrgent: isUrgent ?? this.isUrgent,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      author: author ?? this.author,
      externalUrl: externalUrl ?? this.externalUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'category': category,
      'source': source,
      'published_at': publishedAt.toIso8601String(),
      'is_urgent': isUrgent ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'tags': jsonEncode(tags),
      'author': author,
      'external_url': externalUrl,
    };
  }

  factory NewsItemModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      try {
        final decoded = jsonDecode(map['tags'] as String);
        if (decoded is List) {
          parsedTags = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return NewsItemModel(
      id: map['id'] as String,
      title: map['title'] as String,
      summary: (map['summary'] as String?) ?? '',
      content: map['content'] as String,
      category: (map['category'] as String?) ?? 'ministry',
      source: (map['source'] as String?) ?? 'وزارة التربية والتعليم',
      publishedAt: DateTime.tryParse(map['published_at'] as String? ?? '') ?? DateTime.now(),
      isUrgent: (map['is_urgent'] as int? ?? 0) == 1,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      tags: parsedTags,
      author: map['author'] as String?,
      externalUrl: map['external_url'] as String?,
    );
  }
}
