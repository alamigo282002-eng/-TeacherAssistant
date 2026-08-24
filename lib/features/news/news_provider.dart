import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/news_sync_service.dart';
import '../../data/models/news_item_model.dart';
import '../../data/repositories/news_repository.dart';

class NewsProvider extends ChangeNotifier {
  final NewsRepository _repo;
  final NewsSyncService _syncService;

  NewsProvider({
    NewsRepository? repo,
    NewsSyncService? syncService,
  })  : _repo = repo ?? NewsRepository(),
        _syncService = syncService ?? NewsSyncService(newsRepo: repo);

  List<NewsItemModel> _allNews = [];
  bool _loading = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String _selectedCategory = 'all'; // 'all', 'ministry', 'exams', 'curriculum', 'announcements', 'tips'
  String _searchQuery = '';

  List<NewsItemModel> get allNews => _allNews;
  bool get loading => _loading;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<NewsItemModel> get filteredNews {
    var list = _allNews;

    if (_selectedCategory != 'all') {
      list = list.where((item) => item.category == _selectedCategory).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.summary.toLowerCase().contains(q) ||
            item.content.toLowerCase().contains(q) ||
            item.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    return list;
  }

  List<NewsItemModel> get urgentNews =>
      _allNews.where((item) => item.isUrgent || item.isPinned).take(3).toList();

  NewsItemModel? get latestUrgentNews {
    if (_allNews.isEmpty) return null;
    final urgent = _allNews.where((item) => item.isUrgent).firstOrNull;
    if (urgent != null) return urgent;
    return _allNews.firstOrNull;
  }

  Future<void> loadNews({bool syncOnline = true}) async {
    _loading = true;
    notifyListeners();

    try {
      _allNews = await _repo.getAll();
    } catch (e) {
      debugPrint('Error loading news from db: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }

    // Trigger internet sync in background if requested
    if (syncOnline) {
      syncFromInternet();
    }
  }

  Future<int> syncFromInternet() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    notifyListeners();

    int newItems = 0;
    try {
      newItems = await _syncService.syncLatestNews();
      _lastSyncTime = DateTime.now();
      _allNews = await _repo.getAll();
    } catch (e) {
      debugPrint('Error syncing live news from internet: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return newItems;
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addAnnouncement({
    required String title,
    required String content,
    String? teacherName,
    bool isUrgent = false,
  }) async {
    final newItem = NewsItemModel(
      id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      summary: content.length > 80 ? '${content.substring(0, 80)}...' : content,
      content: content,
      category: 'announcements',
      source: teacherName != null && teacherName.isNotEmpty ? 'الأستاذ: $teacherName' : 'إعلان المعلم',
      publishedAt: DateTime.now(),
      isUrgent: isUrgent,
      isPinned: true,
      tags: ['إعلان خاص', 'تنبيه مهم'],
    );

    await _repo.insert(newItem);
    _allNews = await _repo.getAll();
    notifyListeners();
  }

  Future<void> deleteNewsItem(String id) async {
    await _repo.delete(id);
    _allNews = await _repo.getAll();
    notifyListeners();
  }

  Future<void> shareNewsOnWhatsApp(NewsItemModel news) async {
    final text = '''📢 *${news.title}*

${news.summary}

📌 *المصدر:* ${news.source}
📅 *التاريخ:* ${news.publishedAt.year}/${news.publishedAt.month}/${news.publishedAt.day}

══════════════════
✨ مُرسَل عبر تطبيق مُساعِد المُعلِّم الذكي''';

    final uri = Uri.parse('${AppConstants.whatsappUrl}${AppConstants.whatsappTextPrefix}${Uri.encodeComponent(text)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
    }
  }
}
