import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _tableName = 'books';
  static const String _syncTableName = 'sync_queue';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fussi_library.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Books table
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_name TEXT NOT NULL,
            author_name TEXT NOT NULL,
            category TEXT NOT NULL,
            library_location TEXT NOT NULL,
            brief_description TEXT,
            barcode TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER DEFAULT 0,
            device_id TEXT NOT NULL
          )
        ''');

        // Sync queue table for P2P synchronization
        await db.execute('''
          CREATE TABLE $_syncTableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            book_data TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');

        // Create indexes for better performance
        await db.execute(
            'CREATE INDEX idx_books_category ON $_tableName(category)');
        await db.execute(
            'CREATE INDEX idx_books_author ON $_tableName(author_name)');
        await db.execute(
            'CREATE INDEX idx_books_location ON $_tableName(library_location)');
        await db.execute(
            'CREATE INDEX idx_sync_status ON $_tableName(sync_status)');
      },
    );
  }

  // Add book to local database
  Future<int> addBook(Book book) async {
    final db = await database;
    final deviceId = await _getDeviceId();
    final now = DateTime.now().toIso8601String();

    final bookData = {
      'book_name': book.bookName,
      'author_name': book.authorName,
      'category': book.category,
      'library_location': book.libraryLocation,
      'brief_description': book.briefDescription,
      'barcode': book.barcode,
      'created_at': now,
      'updated_at': now,
      'sync_status': 0, // 0 = not synced, 1 = synced
      'device_id': deviceId,
    };

    final bookId = await db.insert(_tableName, bookData);

    // Add to sync queue
    await _addToSyncQueue('INSERT', bookData);

    return bookId;
  }

  // Get all books from local database
  Future<List<Map<String, dynamic>>> getAllBooks() async {
    final db = await database;
    return await db.query(_tableName, orderBy: 'created_at DESC');
  }

  // Search books locally
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    final db = await database;
    return await db.query(
      _tableName,
      where: '''
        book_name LIKE ? OR 
        author_name LIKE ? OR 
        library_location LIKE ? OR 
        brief_description LIKE ?
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  // Get books by category
  Future<List<Map<String, dynamic>>> getBooksByCategory(String category) async {
    final db = await database;
    return await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
  }

  // Update book
  Future<int> updateBook(int id, Book book) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final bookData = {
      'book_name': book.bookName,
      'author_name': book.authorName,
      'category': book.category,
      'library_location': book.libraryLocation,
      'brief_description': book.briefDescription,
      'barcode': book.barcode,
      'updated_at': now,
      'sync_status': 0,
    };

    final result = await db.update(
      _tableName,
      bookData,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Add to sync queue
    await _addToSyncQueue('UPDATE', {...bookData, 'id': id});

    return result;
  }

  // Delete book
  Future<int> deleteBook(int id) async {
    final db = await database;

    // Get book data before deletion for sync
    final bookData =
        await db.query(_tableName, where: 'id = ?', whereArgs: [id]);

    final result =
        await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);

    // Add to sync queue
    if (bookData.isNotEmpty) {
      await _addToSyncQueue('DELETE', bookData.first);
    }

    return result;
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final totalBooks = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_tableName')) ??
        0;

    final categories = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM $_tableName 
      GROUP BY category 
      ORDER BY count DESC
    ''');

    final authors = await db.rawQuery('''
      SELECT author_name, COUNT(*) as count 
      FROM $_tableName 
      GROUP BY author_name 
      ORDER BY count DESC
    ''');

    final locations = await db.rawQuery('''
      SELECT DISTINCT library_location 
      FROM $_tableName 
      ORDER BY library_location
    ''');

    return {
      'totalBooks': totalBooks,
      'categories': categories,
      'authors': authors,
      'locations': locations.map((e) => e['library_location']).toList(),
    };
  }

  // Sync queue management
  Future<void> _addToSyncQueue(
      String action, Map<String, dynamic> bookData) async {
    final db = await database;
    await db.insert(_syncTableName, {
      'action': action,
      'book_data': jsonEncode(bookData),
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(
      _syncTableName,
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> markAsSynced(int syncId) async {
    final db = await database;
    await db.update(
      _syncTableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [syncId],
    );
  }

  // Device management
  Future<String> _getDeviceId() async {
    // In a real implementation, you'd generate a unique device ID
    // For now, we'll use a simple timestamp-based ID
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Backup and restore
  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    final books = await db.query(_tableName);
    return {
      'books': books,
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    final books = data['books'] as List<dynamic>;

    await db.transaction((txn) async {
      for (final book in books) {
        await txn.insert(_tableName, book as Map<String, dynamic>,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  // Clear all data
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_tableName);
    await db.delete(_syncTableName);
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
