import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _tableName = 'books';
  static const String _syncTableName = 'sync_queue';

  // Web fallback storage
  static final List<Map<String, dynamic>> _webBooks = [];
  static final List<Map<String, dynamic>> _webSyncQueue = [];
  static int _nextId = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // For web, we'll create a mock database that throws
      // This will be handled gracefully by the web fallback methods
      throw UnsupportedError('SQLite is not supported on web platform');
    }

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

  // Helper method to check if we're on web
  bool get _isWebPlatform => kIsWeb;

  // Add book to local database
  Future<int> addBook(Book book) async {
    if (_isWebPlatform) {
      return _addBookWeb(book);
    }

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

  // Web fallback methods
  int _addBookWeb(Book book) {
    final now = DateTime.now().toIso8601String();
    final bookData = {
      'id': _nextId++,
      'book_name': book.bookName,
      'author_name': book.authorName,
      'category': book.category,
      'library_location': book.libraryLocation,
      'brief_description': book.briefDescription,
      'barcode': book.barcode,
      'created_at': now,
      'updated_at': now,
      'sync_status': 0,
      'device_id': 'web_device_${DateTime.now().millisecondsSinceEpoch}',
    };

    _webBooks.add(bookData);
    _addToSyncQueueWeb('INSERT', bookData);
    return bookData['id'] as int;
  }

  // Get all books from local database
  Future<List<Map<String, dynamic>>> getAllBooks() async {
    if (_isWebPlatform) {
      return List<Map<String, dynamic>>.from(_webBooks);
    }

    try {
      final db = await database;
      return await db.query(_tableName, orderBy: 'created_at DESC');
    } catch (e) {
      print('Error accessing local database: $e');
      return [];
    }
  }

  // Search books locally
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    if (_isWebPlatform) {
      return _searchBooksWeb(query);
    }

    try {
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
    } catch (e) {
      print('Error searching in local database: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _searchBooksWeb(String query) {
    final lowerQuery = query.toLowerCase();
    return _webBooks.where((book) {
      return (book['book_name']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerQuery) ??
              false) ||
          (book['author_name']?.toString().toLowerCase().contains(lowerQuery) ??
              false) ||
          (book['library_location']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerQuery) ??
              false) ||
          (book['brief_description']
                  ?.toString()
                  .toLowerCase()
                  .contains(lowerQuery) ??
              false);
    }).toList();
  }

  // Get books by category
  Future<List<Map<String, dynamic>>> getBooksByCategory(String category) async {
    if (_isWebPlatform) {
      return _webBooks.where((book) => book['category'] == category).toList();
    }

    try {
      final db = await database;
      return await db.query(
        _tableName,
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error getting books by category: $e');
      return [];
    }
  }

  // Update book
  Future<int> updateBook(int id, Book book) async {
    if (_isWebPlatform) {
      return _updateBookWeb(id, book);
    }

    try {
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
    } catch (e) {
      print('Error updating book: $e');
      return 0;
    }
  }

  int _updateBookWeb(int id, Book book) {
    final bookIndex = _webBooks.indexWhere((b) => b['id'] == id);
    if (bookIndex == -1) return 0;

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

    _webBooks[bookIndex].addAll(bookData);
    _addToSyncQueueWeb('UPDATE', {...bookData, 'id': id});
    return 1;
  }

  // Delete book
  Future<int> deleteBook(int id) async {
    if (_isWebPlatform) {
      return _deleteBookWeb(id);
    }

    try {
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
    } catch (e) {
      print('Error deleting book: $e');
      return 0;
    }
  }

  int _deleteBookWeb(int id) {
    final bookIndex = _webBooks.indexWhere((b) => b['id'] == id);
    if (bookIndex == -1) return 0;

    final bookData = _webBooks[bookIndex];
    _webBooks.removeAt(bookIndex);
    _addToSyncQueueWeb('DELETE', bookData);
    return 1;
  }

  // Get statistics
  Future<Map<String, dynamic>> getStatistics() async {
    if (_isWebPlatform) {
      return _getStatisticsWeb();
    }

    try {
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
    } catch (e) {
      print('Error getting statistics: $e');
      return _getStatisticsWeb();
    }
  }

  Map<String, dynamic> _getStatisticsWeb() {
    final totalBooks = _webBooks.length;

    final categoryMap = <String, int>{};
    final authorMap = <String, int>{};
    final locationSet = <String>{};

    for (final book in _webBooks) {
      final category = book['category']?.toString() ?? '';
      final author = book['author_name']?.toString() ?? '';
      final location = book['library_location']?.toString() ?? '';

      if (category.isNotEmpty) {
        categoryMap[category] = (categoryMap[category] ?? 0) + 1;
      }
      if (author.isNotEmpty) {
        authorMap[author] = (authorMap[author] ?? 0) + 1;
      }
      if (location.isNotEmpty) {
        locationSet.add(location);
      }
    }

    final categories = categoryMap.entries
        .map((e) => {'category': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    final authors = authorMap.entries
        .map((e) => {'author_name': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return {
      'totalBooks': totalBooks,
      'categories': categories,
      'authors': authors,
      'locations': locationSet.toList()..sort(),
    };
  }

  // Sync queue management
  Future<void> _addToSyncQueue(
      String action, Map<String, dynamic> bookData) async {
    if (_isWebPlatform) {
      _addToSyncQueueWeb(action, bookData);
      return;
    }

    try {
      final db = await database;
      await db.insert(_syncTableName, {
        'action': action,
        'book_data': jsonEncode(bookData),
        'timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      });
    } catch (e) {
      print('Error adding to sync queue: $e');
    }
  }

  void _addToSyncQueueWeb(String action, Map<String, dynamic> bookData) {
    _webSyncQueue.add({
      'id': _webSyncQueue.length + 1,
      'action': action,
      'book_data': jsonEncode(bookData),
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    if (_isWebPlatform) {
      return _webSyncQueue.where((item) => item['synced'] == 0).toList();
    }

    try {
      final db = await database;
      return await db.query(
        _syncTableName,
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'timestamp ASC',
      );
    } catch (e) {
      print('Error getting pending sync items: $e');
      return [];
    }
  }

  Future<void> markAsSynced(int syncId) async {
    if (_isWebPlatform) {
      final index = _webSyncQueue.indexWhere((item) => item['id'] == syncId);
      if (index != -1) {
        _webSyncQueue[index]['synced'] = 1;
      }
      return;
    }

    try {
      final db = await database;
      await db.update(
        _syncTableName,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [syncId],
      );
    } catch (e) {
      print('Error marking as synced: $e');
    }
  }

  // Device management
  Future<String> _getDeviceId() async {
    // In a real implementation, you'd generate a unique device ID
    // For now, we'll use a simple timestamp-based ID
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Backup and restore
  Future<Map<String, dynamic>> exportData() async {
    final books = await getAllBooks();
    return {
      'books': books,
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    if (_isWebPlatform) {
      _importDataWeb(data);
      return;
    }

    try {
      final db = await database;
      final books = data['books'] as List<dynamic>;

      await db.transaction((txn) async {
        for (final book in books) {
          await txn.insert(_tableName, book as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      print('Error importing data: $e');
    }
  }

  void _importDataWeb(Map<String, dynamic> data) {
    final books = data['books'] as List<dynamic>;
    _webBooks.clear();
    _webBooks.addAll(books.cast<Map<String, dynamic>>());

    // Update next ID
    int maxId = 0;
    for (final book in _webBooks) {
      final id = book['id'] as int? ?? 0;
      if (id > maxId) maxId = id;
    }
    _nextId = maxId + 1;
  }

  // Clear all data
  Future<void> clearAllData() async {
    if (_isWebPlatform) {
      _webBooks.clear();
      _webSyncQueue.clear();
      _nextId = 1;
      return;
    }

    try {
      final db = await database;
      await db.delete(_tableName);
      await db.delete(_syncTableName);
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Close database
  Future<void> close() async {
    if (_isWebPlatform) {
      // No database to close on web
      return;
    }

    try {
      final db = await database;
      await db.close();
      _database = null;
    } catch (e) {
      print('Error closing database: $e');
    }
  }
}
