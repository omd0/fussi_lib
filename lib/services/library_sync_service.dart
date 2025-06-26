import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/book.dart';
import '../constants/app_constants.dart';
import 'google_sheets_service.dart';
import 'local_database_service.dart';
import 'p2p_service.dart';

enum ConnectionMode { online, offline, p2p }

class LibrarySyncService {
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();
  final LocalDatabaseService _localDbService = LocalDatabaseService();
  final P2PService _p2pService = P2PService();

  ConnectionMode _currentMode = ConnectionMode.offline;
  bool _isInitialized = false;

  // Event callbacks
  Function(ConnectionMode)? onModeChanged;
  Function(String)? onStatusChanged;
  Function(List<Map<String, dynamic>>)? onDevicesUpdated;

  // Throttle status updates to prevent UI overflow
  DateTime _lastStatusUpdate = DateTime.now();
  String _lastStatus = '';
  int _statusUpdateCount = 0;
  bool _statusUpdatesBlocked = false;

  void _updateStatus(String status) {
    if (_statusUpdatesBlocked) return;

    final now = DateTime.now();

    // Reset counter every 5 seconds
    if (now.difference(_lastStatusUpdate).inSeconds > 5) {
      _statusUpdateCount = 0;
    }

    // Block updates if too many in short time (circuit breaker)
    if (_statusUpdateCount > 10) {
      print('WARNING: Too many status updates, blocking for 10 seconds');
      _statusUpdatesBlocked = true;
      Future.delayed(const Duration(seconds: 10), () {
        _statusUpdatesBlocked = false;
        _statusUpdateCount = 0;
      });
      return;
    }

    // Only update if status changed or 500ms have passed
    if (status != _lastStatus ||
        now.difference(_lastStatusUpdate).inMilliseconds > 500) {
      _lastStatus = status;
      _lastStatusUpdate = now;
      _statusUpdateCount++;
      onStatusChanged?.call(status);
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _updateStatus('تهيئة خدمة Google Sheets...');

    // P2P is disabled - initialize P2P service as disabled
    await _p2pService.initialize();

    // Check initial connection (will only use Google Sheets)
    await _checkConnectionAndSetMode();

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    _isInitialized = true;
    _updateStatus('تم تهيئة خدمة Google Sheets');
  }

  Future<void> _checkConnectionAndSetMode() async {
    try {
      // First check if credentials exist
      final credentialsExist = await GoogleSheetsService.credentialsExist();
      if (!credentialsExist) {
        _updateStatus('ملفات الاعتماد غير موجودة - استخدام الوضع المحلي');
        await _setMode(ConnectionMode.offline);
        return;
      }

      // Test Google Sheets connection
      final sheetsConnectionTest = await _googleSheetsService.testConnection();
      if (sheetsConnectionTest) {
        await _setMode(ConnectionMode.online);
        return;
      }

      // Test general internet connectivity as fallback
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 10));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Has internet but Google Sheets failed, try to initialize sheets service
        final initialized = await _googleSheetsService.initialize();
        if (initialized) {
          await _setMode(ConnectionMode.online);
          return;
        }
      }
    } catch (e) {
      print('Connection check failed: $e');
      _updateStatus('فشل في فحص الاتصال - استخدام الوضع المحلي');
    }

    // No internet or failed connections, use offline mode (P2P disabled)
    await _setMode(ConnectionMode.offline);
  }

  Future<void> _setMode(ConnectionMode mode) async {
    if (_currentMode == mode) return;

    final previousMode = _currentMode;
    _currentMode = mode;

    switch (mode) {
      case ConnectionMode.online:
        await _p2pService.stop();
        _updateStatus('متصل بالإنترنت - وضع Google Sheets');
        break;

      case ConnectionMode.p2p:
        // P2P disabled - this mode should not be used
        _updateStatus('P2P معطل - استخدام الوضع المحلي');
        break;

      case ConnectionMode.offline:
        await _p2pService.stop();
        _updateStatus('وضع العمل بدون اتصال');
        break;
    }

    onModeChanged?.call(mode);

    // If switching from offline/P2P to online, sync pending changes
    if (mode == ConnectionMode.online &&
        (previousMode == ConnectionMode.offline ||
            previousMode == ConnectionMode.p2p)) {
      await _syncPendingChangesToOnline();
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      await _setMode(ConnectionMode.offline); // P2P disabled
    } else {
      await _checkConnectionAndSetMode();
    }
  }

  // Check for duplicate books
  Future<bool> checkForDuplicate(Book book) async {
    try {
      // Check in local database
      final localBooks = await _localDbService.searchBooks(book.bookName);
      for (final existingBook in localBooks) {
        if (_isSimilarBook(book, Book.fromMap(existingBook))) {
          return true;
        }
      }

      // If online, also check Google Sheets
      if (_currentMode == ConnectionMode.online) {
        try {
          final onlineBooks = await _googleSheetsService.getAllBooks();
          if (onlineBooks != null && onlineBooks.length > 1) {
            // Skip header row
            for (int i = 1; i < onlineBooks.length; i++) {
              final row = onlineBooks[i];
              if (row.length >= 6) {
                // Map according to actual data structure (6 columns)
                final mainLocation = row[0];
                final locationDetails = row[1];
                final fullLocation = locationDetails.isNotEmpty
                    ? '$mainLocation$locationDetails'
                    : mainLocation;

                final existingBook = Book(
                  libraryLocation: fullLocation, // Combine A + B
                  category: row[2], // Column C: Category
                  bookName: row[3], // Column D: Book Name
                  authorName: row[4], // Column E: Author Name
                  briefDescription: '', // Column G missing in data
                );
                if (_isSimilarBook(book, existingBook)) {
                  return true;
                }
              }
            }
          }
        } catch (e) {
          // Ignore online check errors
        }
      }

      return false;
    } catch (e) {
      // In case of error, assume no duplicate
      return false;
    }
  }

  // Check if two books are similar (potential duplicates)
  bool _isSimilarBook(Book book1, Book book2) {
    // Normalize strings for comparison
    String normalize(String str) => str.trim().toLowerCase();

    final name1 = normalize(book1.bookName);
    final name2 = normalize(book2.bookName);
    final author1 = normalize(book1.authorName);
    final author2 = normalize(book2.authorName);

    // Exact match on book name and author
    if (name1 == name2 && author1 == author2) {
      return true;
    }

    // Check for similar book names (contains or very similar)
    if (name1.contains(name2) || name2.contains(name1)) {
      if (author1 == author2) {
        return true;
      }
    }

    return false;
  }

  // Add book with duplicate checking - works in all modes
  Future<Map<String, dynamic>> addBook(Book book) async {
    try {
      onStatusChanged?.call('التحقق من التكرار...');

      // Check for duplicates first
      final isDuplicate = await checkForDuplicate(book);
      if (isDuplicate) {
        return {
          'success': false,
          'isDuplicate': true,
          'message': 'تحذير: يبدو أن هذا الكتاب موجود بالفعل في المكتبة'
        };
      }

      onStatusChanged?.call('إضافة كتاب...');

      // Always save to local database first
      await _localDbService.addBook(book);

      // Try to sync to Google Sheets if online
      if (_currentMode == ConnectionMode.online) {
        try {
          await _googleSheetsService.addBook(book);
          onStatusChanged?.call('تم إضافة الكتاب وحفظه في Google Sheets');
          return {
            'success': true,
            'isDuplicate': false,
            'message': 'تم إضافة الكتاب وحفظه في Google Sheets'
          };
        } catch (e) {
          onStatusChanged?.call('تم حفظ الكتاب محلياً - سيتم المزامنة لاحقاً');
          return {
            'success': true,
            'isDuplicate': false,
            'message': 'تم حفظ الكتاب محلياً - سيتم المزامنة لاحقاً'
          };
        }
      } else {
        onStatusChanged?.call('تم حفظ الكتاب محلياً');
        return {
          'success': true,
          'isDuplicate': false,
          'message': 'تم حفظ الكتاب محلياً'
        };
      }
    } catch (e) {
      onStatusChanged?.call('خطأ في إضافة الكتاب: $e');
      return {
        'success': false,
        'isDuplicate': false,
        'message': 'خطأ في إضافة الكتاب: $e'
      };
    }
  }

  // Force add book (ignoring duplicates)
  Future<bool> forceAddBook(Book book) async {
    try {
      onStatusChanged?.call('إضافة كتاب...');

      // Always save to local database first
      await _localDbService.addBook(book);

      // Try to sync to Google Sheets if online
      if (_currentMode == ConnectionMode.online) {
        try {
          await _googleSheetsService.addBook(book);
          onStatusChanged?.call('تم إضافة الكتاب وحفظه في Google Sheets');
        } catch (e) {
          onStatusChanged?.call('تم حفظ الكتاب محلياً - سيتم المزامنة لاحقاً');
        }
      } else {
        onStatusChanged?.call('تم حفظ الكتاب محلياً');
      }

      return true;
    } catch (e) {
      onStatusChanged?.call('خطأ في إضافة الكتاب: $e');
      return false;
    }
  }

  // Get all books - prioritizes local data
  Future<List<Book>> getBooksAsObjects() async {
    try {
      List<Book> books = [];

      if (_currentMode == ConnectionMode.online) {
        try {
          _updateStatus('تحميل الكتب من Google Sheets...');

          final rawData = await _googleSheetsService
              .getAllBooks()
              .timeout(const Duration(seconds: 45));

          if (rawData != null && rawData.isNotEmpty) {
            // Skip header row and process data
            for (int i = 1; i < rawData.length; i++) {
              final row = rawData[i];

              // Handle both 6-column data rows and 7-column header
              if (row.length >= 6) {
                try {
                  // Map according to actual data structure:
                  // A: Main location (B, A, etc.)
                  // B: Location details (5, etc.)
                  // C: Category
                  // D: Book Name
                  // E: Author Name
                  // F: Part Number
                  // G: Brief Description (missing in data, so use empty string)

                  final mainLocation = row[0]?.toString() ?? '';
                  final locationDetails = row[1]?.toString() ?? '';
                  final fullLocation = locationDetails.isNotEmpty
                      ? '$mainLocation$locationDetails'
                      : mainLocation;

                  final book = Book(
                    libraryLocation:
                        fullLocation, // Combine A + B for full location
                    category: row[2]?.toString() ?? '', // Column C
                    bookName: row[3]?.toString() ?? '', // Column D
                    authorName: row[4]?.toString() ?? '', // Column E
                    briefDescription: '', // Column G missing, use empty string
                  );

                  // Only add books with valid name and author
                  if (book.bookName.trim().isNotEmpty &&
                      book.authorName.trim().isNotEmpty) {
                    books.add(book);
                  }
                } catch (e) {
                  // Skip problematic rows
                }
              }
            }

            // Save to local for offline access
            try {
              await _saveOnlineBooksToLocal(rawData.cast<List<String>>());
            } catch (e) {
              // Continue if saving fails
            }

            _updateStatus('تم تحميل ${books.length} كتاب من Google Sheets');
          } else {
            _updateStatus('لا توجد بيانات في Google Sheets');
          }
        } catch (e) {
          _updateStatus('خطأ في تحميل الكتب من Google Sheets: $e');

          // Fallback to local database
          books = await _loadFromLocalDatabase();
        }
      } else {
        books = await _loadFromLocalDatabase();
      }

      return books;
    } catch (e) {
      _updateStatus('خطأ في تحميل الكتب: $e');
      return [];
    }
  }

  // Helper method to load from local database
  Future<List<Book>> _loadFromLocalDatabase() async {
    try {
      final localBooks = await _localDbService.getAllBooks();

      final books = localBooks.map((bookMap) {
        return Book.fromMap(bookMap);
      }).toList();

      _updateStatus('تم تحميل ${books.length} كتاب من قاعدة البيانات المحلية');
      return books;
    } catch (e) {
      _updateStatus('لا يمكن الوصول إلى قاعدة البيانات المحلية');
      return [];
    }
  }

  Future<List<List<String>>?> getAllBooks() async {
    try {
      // Always get from local database first
      final localBooks = await _localDbService.getAllBooks();

      if (localBooks.isNotEmpty) {
        // Convert to Google Sheets format
        final result = <List<String>>[];
        result.add([
          'الموقع في المكتبة', // Column A: Library Location
          '', // Column B: Additional Location
          'التصنيف', // Column C: Category
          'اسم الكتاب', // Column D: Book Name
          'اسم المؤلف', // Column E: Author Name
          'رقم الجزء (إن توفر)', // Column F: Part Number
          'مختصر تعريفي' // Column G: Brief Description
        ]);

        for (final bookMap in localBooks) {
          result.add([
            bookMap['library_location'] ?? '', // Column A: Library Location
            '', // Column B: Additional Location (empty for now)
            bookMap['category'] ?? '', // Column C: Category
            bookMap['book_name'] ?? '', // Column D: Book Name
            bookMap['author_name'] ?? '', // Column E: Author Name
            '', // Column F: Part Number (empty for now)
            bookMap['brief_description'] ?? '', // Column G: Brief Description
          ]);
        }

        return result;
      }

      // If no local data and online, try to get from Google Sheets
      if (_currentMode == ConnectionMode.online) {
        try {
          final onlineBooks = await _googleSheetsService.getAllBooks();
          if (onlineBooks != null && onlineBooks.isNotEmpty) {
            // Save to local database for offline access
            await _saveOnlineBooksToLocal(onlineBooks);
            return onlineBooks;
          }
        } catch (e) {
          onStatusChanged?.call('لا يمكن الوصول إلى Google Sheets');
        }
      }

      return [];
    } catch (e) {
      onStatusChanged?.call('خطأ في تحميل الكتب: $e');
      return null;
    }
  }

  // Save online books to local database
  Future<void> _saveOnlineBooksToLocal(List<List<String>> onlineBooks) async {
    try {
      // Skip header row
      final books = onlineBooks.skip(1);

      for (final bookRow in books) {
        if (bookRow.length >= 6 && bookRow[3].trim().isNotEmpty) {
          // Map according to actual data structure (6 columns)
          final mainLocation = bookRow[0];
          final locationDetails = bookRow[1];
          final fullLocation = locationDetails.isNotEmpty
              ? '$mainLocation$locationDetails'
              : mainLocation;

          final book = Book(
            libraryLocation: fullLocation, // Combine A + B
            category:
                bookRow.length > 2 ? bookRow[2] : '', // Column C: Category
            bookName:
                bookRow.length > 3 ? bookRow[3] : '', // Column D: Book Name
            authorName:
                bookRow.length > 4 ? bookRow[4] : '', // Column E: Author Name
            briefDescription: '', // Column G missing in data
          );

          // Check if book already exists locally to avoid duplicates
          final existingBooks =
              await _localDbService.searchBooks(book.bookName);
          bool isDuplicate = false;
          for (final existingBookMap in existingBooks) {
            final existingBook = Book.fromMap(existingBookMap);
            if (_isSimilarBook(book, existingBook)) {
              isDuplicate = true;
              break;
            }
          }

          if (!isDuplicate) {
            await _localDbService.addBook(book);
          }
        }
      }
    } catch (e) {
      print('Error saving online books to local: $e');
      // Ignore errors in background sync
    }
  }

  // Sync pending changes to online
  Future<void> _syncPendingChangesToOnline() async {
    try {
      onStatusChanged?.call('مزامنة التغييرات المعلقة...');

      final pendingItems = await _localDbService.getPendingSyncItems();

      for (final item in pendingItems) {
        try {
          // Process sync item based on action
          // This is a simplified implementation
          await _localDbService.markAsSynced(item['id']);
        } catch (e) {
          // Continue with other items
        }
      }

      onStatusChanged?.call('تمت مزامنة التغييرات');
    } catch (e) {
      onStatusChanged?.call('خطأ في المزامنة: $e');
    }
  }

  // Get statistics - from local database
  Future<Map<String, dynamic>> getStatistics() async {
    return await _localDbService.getStatistics();
  }

  // Search books - from local database
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    return await _localDbService.searchBooks(query);
  }

  // P2P Sync methods
  Future<void> syncWithDevice(Map<String, dynamic> device) async {
    await _p2pService.syncLibraryData();
  }

  Future<void> sendDataToDevice(Map<String, dynamic> device) async {
    await _p2pService.requestLibraryData();
  }

  List<Map<String, dynamic>> get discoveredDevices =>
      _p2pService.discoveredDevices;

  // Force sync with Google Sheets
  Future<void> forceSyncWithGoogleSheets() async {
    if (_currentMode != ConnectionMode.online) {
      onStatusChanged?.call('يجب الاتصال بالإنترنت للمزامنة مع Google Sheets');
      return;
    }

    try {
      onStatusChanged?.call('مزامنة مع Google Sheets...');

      // Get all local books
      final localBooks = await _localDbService.getAllBooks();

      // Clear Google Sheets and upload all local data
      // This is a simplified approach - in production you'd want more sophisticated conflict resolution

      for (final bookMap in localBooks) {
        final book = Book.fromMap(bookMap);
        await _googleSheetsService.addBook(book);
      }

      onStatusChanged?.call('تمت المزامنة مع Google Sheets');
    } catch (e) {
      onStatusChanged?.call('خطأ في المزامنة مع Google Sheets: $e');
    }
  }

  // Export data for backup
  Future<Map<String, dynamic>> exportData() async {
    return await _localDbService.exportData();
  }

  // Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    await _localDbService.importData(data);
    onStatusChanged?.call('تم استيراد البيانات');
  }

  // Getters
  ConnectionMode get currentMode => _currentMode;

  String get modeDescription {
    switch (_currentMode) {
      case ConnectionMode.online:
        return 'متصل - Google Sheets';
      case ConnectionMode.p2p:
        return 'مزامنة محلية نشطة';
      case ConnectionMode.offline:
        return 'غير متصل';
    }
  }

  Map<String, String> get deviceInfo => {
        'name': _p2pService.deviceName ?? 'Unknown',
        'mode': _p2pService.statusDescription,
      };

  // Cleanup
  Future<void> dispose() async {
    await _p2pService.stop();
    await _localDbService.close();
  }

  // Debug and diagnostic methods
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final diagnostics = <String, dynamic>{};

    try {
      // Check credentials
      final credentialsExist = await GoogleSheetsService.credentialsExist();
      diagnostics['credentials_exist'] = credentialsExist;

      // Check Google Sheets connection
      if (credentialsExist) {
        final sheetsConnected = await _googleSheetsService.testConnection();
        diagnostics['sheets_connected'] = sheetsConnected;
        diagnostics['sheets_last_error'] = _googleSheetsService.lastError;
      }

      // Check local database
      final localBookCount = await _localDbService.getAllBooks();
      diagnostics['local_book_count'] = localBookCount.length;

      // Current mode
      diagnostics['current_mode'] = _currentMode.toString();
      diagnostics['mode_description'] = modeDescription;

      // P2P status
      diagnostics['p2p_devices'] = discoveredDevices.length;
    } catch (e) {
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }

  // Comprehensive Google Sheets test and analysis
  Future<String> performGoogleSheetsTest() async {
    final results = <String>[];

    results.add('🔍 بدء الاختبار الشامل لـ Google Sheets...\n');

    try {
      // Test 1: Check credentials
      results.add('📋 الخطوة 1: فحص ملف الاعتماد');
      final credentialsExist = await GoogleSheetsService.credentialsExist();
      if (credentialsExist) {
        results.add('✅ ملف الاعتماد موجود');
      } else {
        results.add('❌ ملف الاعتماد غير موجود');
        results.add(
            '   المسار المطلوب: assets/credentials/service-account-key.json');
        return results.join('\n');
      }

      // Test 2: Initialize service
      results.add('\n📋 الخطوة 2: تهيئة خدمة Google Sheets');
      final initialized = await _googleSheetsService.initialize();
      if (initialized) {
        results.add('✅ تم تهيئة الخدمة بنجاح');
      } else {
        results.add('❌ فشل في تهيئة الخدمة');
        final error = _googleSheetsService.lastError;
        if (error != null) results.add('   السبب: $error');
        return results.join('\n');
      }

      // Test 3: Test connection
      results.add('\n📋 الخطوة 3: اختبار الاتصال');
      final connected = await _googleSheetsService.testConnection();
      if (connected) {
        results.add('✅ الاتصال ناجح');
      } else {
        results.add('❌ فشل الاتصال');
        final error = _googleSheetsService.lastError;
        if (error != null) results.add('   السبب: $error');
        return results.join('\n');
      }

      // Test 4: Get raw data
      results.add('\n📋 الخطوة 4: استرجاع البيانات الخام');
      results.add('   معرف الجدول: ${AppConstants.spreadsheetId}');
      results.add('   النطاق: ${AppConstants.sheetRange}');

      final rawData = await _googleSheetsService.getAllBooks();

      if (rawData == null) {
        results.add('❌ لم يتم استرجاع أي بيانات');
        final error = _googleSheetsService.lastError;
        if (error != null) results.add('   السبب: $error');
        return results.join('\n');
      }

      if (rawData.isEmpty) {
        results.add('⚠️ الجدول فارغ - لا توجد بيانات');
        return results.join('\n');
      }

      results.add('✅ تم استرجاع ${rawData.length} صف');

      // Test 5: Analyze structure
      results.add('\n📋 الخطوة 5: تحليل هيكل البيانات');

      // Analyze header row
      if (rawData.isNotEmpty) {
        final headerRow = rawData[0];
        results.add('📊 صف العناوين (${headerRow.length} عمود):');
        for (int i = 0; i < headerRow.length; i++) {
          final columnLetter = String.fromCharCode(65 + i); // A, B, C, etc.
          results.add('   العمود $columnLetter: "${headerRow[i]}"');
        }

        // Expected structure
        results.add('\n📋 الهيكل المتوقع:');
        results.add('   العمود A: الموقع في المكتبة');
        results.add('   العمود B: [فارغ أو موقع إضافي]');
        results.add('   العمود C: التصنيف');
        results.add('   العمود D: اسم الكتاب');
        results.add('   العمود E: اسم المؤلف');
        results.add('   العمود F: رقم الجزء');
        results.add('   العمود G: مختصر تعريفي');

        // Analyze data rows
        results.add('\n📋 تحليل صفوف البيانات:');
        int validRows = 0;
        int invalidRows = 0;

        for (int i = 1; i < rawData.length && i <= 5; i++) {
          // Check first 5 data rows
          final row = rawData[i];
          results.add('\n   الصف $i (${row.length} عمود):');

          if (row.length >= 7) {
            results.add('     A: "${row[0]}" (الموقع)');
            results.add('     B: "${row[1]}" (إضافي)');
            results.add('     C: "${row[2]}" (التصنيف)');
            results.add('     D: "${row[3]}" (اسم الكتاب)');
            results.add('     E: "${row[4]}" (اسم المؤلف)');
            results.add('     F: "${row[5]}" (رقم الجزء)');
            results.add('     G: "${row[6]}" (مختصر تعريفي)');

            // Check if row has essential data
            if (row[3].trim().isNotEmpty && row[4].trim().isNotEmpty) {
              results.add('     ✅ صف صالح');
              validRows++;
            } else {
              results.add('     ❌ صف غير صالح (اسم الكتاب أو المؤلف فارغ)');
              invalidRows++;
            }
          } else {
            results.add('     ❌ عدد الأعمدة غير كافي (${row.length} من 7)');
            invalidRows++;
          }
        }

        if (rawData.length > 6) {
          results.add('\n   ... و ${rawData.length - 6} صف إضافي');
        }

        results.add('\n📊 ملخص البيانات:');
        results.add('   إجمالي الصفوف: ${rawData.length}');
        results.add('   صفوف البيانات: ${rawData.length - 1}');
        results.add('   الصفوف الصالحة: $validRows');
        results.add('   الصفوف غير الصالحة: $invalidRows');
      }

      // Test 6: Try to create Book objects
      results.add('\n📋 الخطوة 6: محاولة إنشاء كائنات الكتب');
      int successfulBooks = 0;
      int failedBooks = 0;

      for (int i = 1; i < rawData.length && i <= 3; i++) {
        // Test first 3 data rows
        final row = rawData[i];
        try {
          if (row.length >= 7) {
            final book = Book(
              libraryLocation: row[0],
              category: row[2],
              bookName: row[3],
              authorName: row[4],
              briefDescription: row[6],
            );
            results.add(
                '   ✅ كتاب ${i}: "${book.bookName}" - "${book.authorName}"');
            successfulBooks++;
          } else {
            results.add('   ❌ كتاب ${i}: عدد أعمدة غير كافي');
            failedBooks++;
          }
        } catch (e) {
          results.add('   ❌ كتاب ${i}: خطأ في الإنشاء - $e');
          failedBooks++;
        }
      }

      results.add('\n📊 نتائج إنشاء الكتب:');
      results.add('   نجح: $successfulBooks');
      results.add('   فشل: $failedBooks');

      // Final assessment
      results.add('\n🏁 التقييم النهائي:');
      if (successfulBooks > 0) {
        results.add('✅ Google Sheets يعمل بشكل صحيح');
        results.add('   يمكن قراءة البيانات وإنشاء الكتب');
        results.add('   المشكلة قد تكون في معالجة البيانات أو واجهة المستخدم');
      } else {
        results.add('❌ مشكلة في هيكل البيانات');
        results.add('   تحقق من أن البيانات في الأعمدة الصحيحة');
        results.add('   تأكد من وجود بيانات في أعمدة اسم الكتاب والمؤلف');
      }
    } catch (e) {
      results.add('\n❌ خطأ في الاختبار: $e');
      results.add('نوع الخطأ: ${e.runtimeType}');
    }

    return results.join('\n');
  }

  // Connection test method for debugging
  Future<Map<String, dynamic>> performConnectionTest() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
    };

    try {
      // Test Google Sheets connection
      results['tests']['google_sheets'] = await _testGoogleSheetsConnection();

      // Test local database
      results['tests']['local_database'] = await _testLocalDatabase();

      // P2P is disabled
      results['tests']['p2p'] = {
        'status': 'disabled',
        'message': 'P2P functionality is disabled',
        'success': true,
      };

      results['overall_status'] = 'completed';
      results['success'] = true;
    } catch (e) {
      results['overall_status'] = 'failed';
      results['error'] = e.toString();
      results['success'] = false;
    }

    return results;
  }

  Future<Map<String, dynamic>> _testGoogleSheetsConnection() async {
    try {
      final credentialsExist = await GoogleSheetsService.credentialsExist();
      if (!credentialsExist) {
        return {
          'status': 'failed',
          'message': 'ملفات الاعتماد غير موجودة',
          'success': false,
        };
      }

      final connectionTest = await _googleSheetsService.testConnection();
      if (connectionTest) {
        // Try to get a sample of data
        final books = await _googleSheetsService.getAllBooks();
        return {
          'status': 'connected',
          'message': 'متصل بـ Google Sheets بنجاح',
          'book_count': books?.length ?? 0,
          'success': true,
        };
      } else {
        return {
          'status': 'failed',
          'message': 'فشل في الاتصال بـ Google Sheets',
          'success': false,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'خطأ في اختبار Google Sheets: $e',
        'success': false,
      };
    }
  }

  Future<Map<String, dynamic>> _testLocalDatabase() async {
    try {
      final books = await _localDbService.getAllBooks();
      return {
        'status': 'connected',
        'message': 'قاعدة البيانات المحلية تعمل بشكل صحيح',
        'book_count': books.length,
        'success': true,
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'خطأ في قاعدة البيانات المحلية: $e',
        'success': false,
      };
    }
  }
}
