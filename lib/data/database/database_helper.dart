import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final String path;
    if (kIsWeb) {
      path = AppConstants.dbName;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, AppConstants.dbName);
    }

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        // Run safe column migrations for existing databases
        try {
          await db.execute('ALTER TABLE ${AppConstants.tableGroups} ADD COLUMN session_price REAL NOT NULL DEFAULT 0');
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE ${AppConstants.tableGroups} ADD COLUMN whatsapp_link TEXT NOT NULL DEFAULT ''");
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE ${AppConstants.tableGroups} ADD COLUMN online_platform TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE ${AppConstants.tableGroups} ADD COLUMN online_meeting_url TEXT');
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE ${AppConstants.tableGroups} ADD COLUMN subject TEXT NOT NULL DEFAULT 'عام'");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE ${AppConstants.tableGroups} ADD COLUMN payment_mode TEXT NOT NULL DEFAULT 'monthly'");
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE ${AppConstants.tableAttendance} ADD COLUMN recitation_points REAL');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE ${AppConstants.tableStudents} ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0');
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE ${AppConstants.tableStudents} ADD COLUMN discount_type TEXT NOT NULL DEFAULT 'none'");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE ${AppConstants.tableStudents} ADD COLUMN discount_reason TEXT NOT NULL DEFAULT ''");
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE ${AppConstants.tableStudents} ADD COLUMN sibling_id TEXT');
        } catch (_) {}
        try {
          await db.execute('ALTER TABLE ${AppConstants.tableStudents} ADD COLUMN sibling_name TEXT');
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE ${AppConstants.tableStudents} ADD COLUMN special_note TEXT NOT NULL DEFAULT ''");
        } catch (_) {}
        try {
          await db.execute("ALTER TABLE ${AppConstants.tableStudents} ADD COLUMN payment_mode TEXT NOT NULL DEFAULT 'monthly'");
        } catch (_) {}
        try {
          final tables = await db.query('sqlite_master', where: 'name = ?', whereArgs: [AppConstants.tableNotes]);
          if (tables.isEmpty) {
            await db.execute('''
              CREATE TABLE ${AppConstants.tableNotes} (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                target_id TEXT,
                content TEXT NOT NULL,
                color TEXT DEFAULT '#FEF3C7',
                is_pinned INTEGER NOT NULL DEFAULT 0,
                category TEXT DEFAULT 'general',
                reminder_enabled INTEGER NOT NULL DEFAULT 0,
                reminder_time TEXT,
                reminder_timing_type TEXT,
                reminder_group_id TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT
              )
            ''');
            
            final oldTables = await db.query('sqlite_master', where: 'name = ?', whereArgs: ['student_notes']);
            if (oldTables.isNotEmpty) {
              await db.execute('''
                INSERT INTO ${AppConstants.tableNotes} (id, type, target_id, content, created_at, updated_at)
                SELECT id, 'student', student_id, content, created_at, updated_at FROM student_notes
              ''');
              await db.execute('DROP TABLE student_notes');
            }
          } else {
            try {
              await db.execute('ALTER TABLE ${AppConstants.tableNotes} ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 0');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.tableNotes} ADD COLUMN reminder_time TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.tableNotes} ADD COLUMN reminder_timing_type TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.tableNotes} ADD COLUMN reminder_group_id TEXT');
            } catch (_) {}
            try {
              await db.execute("ALTER TABLE ${AppConstants.tableNotes} ADD COLUMN color TEXT DEFAULT '#FEF3C7'");
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.tableNotes} ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0');
            } catch (_) {}
            try {
              await db.execute("ALTER TABLE ${AppConstants.tableNotes} ADD COLUMN category TEXT DEFAULT 'general'");
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.tableAppLock} ADD COLUMN use_biometric INTEGER NOT NULL DEFAULT 0');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.tableAppLock} ADD COLUMN security_question TEXT');
            } catch (_) {}
            try {
              await db.execute('ALTER TABLE ${AppConstants.tableAppLock} ADD COLUMN security_answer TEXT');
            } catch (_) {}
          }
        } catch (e) {
          // ignore
        }

        try {
          final logTables = await db.query('sqlite_master', where: 'name = ?', whereArgs: [AppConstants.tableActivityLogs]);
          if (logTables.isEmpty) {
            await db.execute('''
              CREATE TABLE ${AppConstants.tableActivityLogs} (
                id TEXT PRIMARY KEY,
                action_type TEXT NOT NULL,
                title TEXT NOT NULL,
                description TEXT NOT NULL,
                entity_id TEXT,
                entity_type TEXT,
                extra_data TEXT,
                created_at TEXT NOT NULL
              )
            ''');
          }
        } catch (_) {}

        try {
          final annTables = await db.query('sqlite_master', where: 'name = ?', whereArgs: [AppConstants.tableAnnouncements]);
          if (annTables.isEmpty) {
            await db.execute('''
              CREATE TABLE ${AppConstants.tableAnnouncements} (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                type TEXT NOT NULL DEFAULT 'general',
                target_type TEXT NOT NULL DEFAULT 'all',
                group_id TEXT,
                group_name TEXT,
                attachment_path TEXT,
                attachment_name TEXT,
                is_pinned INTEGER NOT NULL DEFAULT 0,
                reads_count INTEGER NOT NULL DEFAULT 0,
                reactions TEXT DEFAULT '{}',
                created_at TEXT NOT NULL,
                expires_at TEXT
              )
            ''');
          }
        } catch (_) {}
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableGroups} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        subject TEXT NOT NULL,
        days TEXT NOT NULL DEFAULT '[]',
        monthly_price REAL NOT NULL DEFAULT 0,
        session_price REAL NOT NULL DEFAULT 0,
        payment_mode TEXT NOT NULL DEFAULT 'monthly',
        whatsapp_link TEXT NOT NULL DEFAULT '',
        online_platform TEXT,
        online_meeting_url TEXT,
        status TEXT NOT NULL DEFAULT 'نشطة',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableStudents} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        parent_phone TEXT NOT NULL DEFAULT '',
        level INTEGER NOT NULL DEFAULT 5,
        group_id TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        points INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'نشط',
        discount_amount REAL NOT NULL DEFAULT 0,
        discount_type TEXT NOT NULL DEFAULT 'none',
        discount_reason TEXT NOT NULL DEFAULT '',
        sibling_id TEXT,
        sibling_name TEXT,
        special_note TEXT NOT NULL DEFAULT '',
        payment_mode TEXT NOT NULL DEFAULT 'monthly',
        created_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES ${AppConstants.tableGroups}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableAttendance} (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'حاضر',
        homework_done INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        recitation_points REAL,
        FOREIGN KEY (student_id) REFERENCES ${AppConstants.tableStudents}(id),
        FOREIGN KEY (group_id) REFERENCES ${AppConstants.tableGroups}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableExams} (
        id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        name TEXT NOT NULL,
        total_marks REAL NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES ${AppConstants.tableGroups}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableExamResults} (
        id TEXT PRIMARY KEY,
        exam_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        marks REAL,
        FOREIGN KEY (exam_id) REFERENCES ${AppConstants.tableExams}(id),
        FOREIGN KEY (student_id) REFERENCES ${AppConstants.tableStudents}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tablePayments} (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        group_id TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        total_due REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL DEFAULT 'لم يدفع',
        date TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES ${AppConstants.tableStudents}(id),
        FOREIGN KEY (group_id) REFERENCES ${AppConstants.tableGroups}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotes} (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        target_id TEXT,
        content TEXT NOT NULL,
        reminder_enabled INTEGER NOT NULL DEFAULT 0,
        reminder_time TEXT,
        reminder_timing_type TEXT,
        reminder_group_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableAppLock} (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_locked INTEGER NOT NULL DEFAULT 0,
        lock_type TEXT NOT NULL DEFAULT 'pin',
        pin_hash TEXT,
        use_biometric INTEGER NOT NULL DEFAULT 0,
        security_question TEXT,
        security_answer TEXT,
        last_unlocked TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableAutoBackup} (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_enabled INTEGER NOT NULL DEFAULT 0,
        frequency TEXT NOT NULL DEFAULT 'weekly',
        last_backup TEXT,
        backup_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableActivityLogs} (
        id TEXT PRIMARY KEY,
        action_type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        entity_id TEXT,
        entity_type TEXT,
        extra_data TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableAnnouncements} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'general',
        target_type TEXT NOT NULL DEFAULT 'all',
        group_id TEXT,
        group_name TEXT,
        attachment_path TEXT,
        attachment_name TEXT,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        reads_count INTEGER NOT NULL DEFAULT 0,
        reactions TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        expires_at TEXT
      )
    ''');
  }

  // --- CRUD helpers ---

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> queryById(String table, String id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> update(String table, Map<String, dynamic> data, String id) async {
    final db = await database;
    return await db.update(table, data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, String id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// Export all tables to JSON-serializable Map
  Future<Map<String, List<Map<String, dynamic>>>> exportAll() async {
    final db = await database;
    return {
      'groups': await db.query(AppConstants.tableGroups),
      'students': await db.query(AppConstants.tableStudents),
      'attendance': await db.query(AppConstants.tableAttendance),
      'exams': await db.query(AppConstants.tableExams),
      'exam_results': await db.query(AppConstants.tableExamResults),
      'payments': await db.query(AppConstants.tablePayments),
      'notes': await db.query(AppConstants.tableNotes),
      'app_lock': await db.query(AppConstants.tableAppLock),
      'auto_backup': await db.query(AppConstants.tableAutoBackup),
    };
  }

  /// Wipe and re-import all data from backup
  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear all tables
      await txn.delete(AppConstants.tableAutoBackup);
      await txn.delete(AppConstants.tableAppLock);
      await txn.delete(AppConstants.tableNotes);
      await txn.delete(AppConstants.tablePayments);
      await txn.delete(AppConstants.tableExamResults);
      await txn.delete(AppConstants.tableExams);
      await txn.delete(AppConstants.tableAttendance);
      await txn.delete(AppConstants.tableStudents);
      await txn.delete(AppConstants.tableGroups);

      // Re-insert
      for (final group in (data['groups'] as List? ?? [])) {
        await txn.insert(AppConstants.tableGroups, Map<String, dynamic>.from(group));
      }
      for (final student in (data['students'] as List? ?? [])) {
        await txn.insert(AppConstants.tableStudents, Map<String, dynamic>.from(student));
      }
      for (final att in (data['attendance'] as List? ?? [])) {
        await txn.insert(AppConstants.tableAttendance, Map<String, dynamic>.from(att));
      }
      for (final exam in (data['exams'] as List? ?? [])) {
        await txn.insert(AppConstants.tableExams, Map<String, dynamic>.from(exam));
      }
      for (final result in (data['exam_results'] as List? ?? [])) {
        await txn.insert(AppConstants.tableExamResults, Map<String, dynamic>.from(result));
      }
      for (final payment in (data['payments'] as List? ?? [])) {
        await txn.insert(AppConstants.tablePayments, Map<String, dynamic>.from(payment));
      }
      for (final note in (data['notes'] as List? ?? data['student_notes'] as List? ?? [])) {
        await txn.insert(AppConstants.tableNotes, Map<String, dynamic>.from(note));
      }
      for (final appLock in (data['app_lock'] as List? ?? [])) {
        await txn.insert(AppConstants.tableAppLock, Map<String, dynamic>.from(appLock));
      }
      for (final autoBackup in (data['auto_backup'] as List? ?? [])) {
        await txn.insert(AppConstants.tableAutoBackup, Map<String, dynamic>.from(autoBackup));
      }
    });
  }
}
