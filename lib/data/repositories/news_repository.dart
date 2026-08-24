import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/news_item_model.dart';

class NewsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  Future<void> ensureTableAndSeeds() async {
    final db = await _db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${AppConstants.tableNews} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        summary TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'ministry',
        source TEXT NOT NULL DEFAULT 'وزارة التربية والتعليم',
        published_at TEXT NOT NULL,
        is_urgent INTEGER NOT NULL DEFAULT 0,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        tags TEXT,
        author TEXT,
        external_url TEXT
      )
    ''');

    // Clean up all hardcoded dummy seed news ('news_1' .. 'news_5')
    try {
      await db.delete(
        AppConstants.tableNews,
        where: "id IN ('news_1', 'news_2', 'news_3', 'news_4', 'news_5') OR id LIKE 'news_%'",
      );
    } catch (_) {}

    // Clean up any legacy RSS items that contain raw HTML tags
    try {
      await db.delete(
        AppConstants.tableNews,
        where: "id LIKE 'rss_%' AND (content LIKE '%<%' OR content LIKE '%&lt;%')",
      );
    } catch (_) {}
  }

  Future<List<NewsItemModel>> getAll() async {
    await ensureTableAndSeeds();
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableNews,
      orderBy: 'is_pinned DESC, is_urgent DESC, published_at DESC',
    );
    return maps.map(NewsItemModel.fromMap).toList();
  }

  Future<List<NewsItemModel>> getByCategory(String category) async {
    await ensureTableAndSeeds();
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableNews,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'is_pinned DESC, is_urgent DESC, published_at DESC',
    );
    return maps.map(NewsItemModel.fromMap).toList();
  }

  Future<NewsItemModel?> getById(String id) async {
    await ensureTableAndSeeds();
    final db = await _db;
    final maps = await db.query(
      AppConstants.tableNews,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return NewsItemModel.fromMap(maps.first);
  }

  Future<void> insert(NewsItemModel item) async {
    await ensureTableAndSeeds();
    final db = await _db;
    await db.insert(
      AppConstants.tableNews,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(NewsItemModel item) async {
    await ensureTableAndSeeds();
    final db = await _db;
    await db.update(
      AppConstants.tableNews,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(String id) async {
    await ensureTableAndSeeds();
    final db = await _db;
    await db.delete(
      AppConstants.tableNews,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
