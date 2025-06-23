import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/book.dart';
import 'google_sheets_service.dart';

class ColumnMapping {
  final String header;
  final int index;
  final String fieldType; // 'text', 'dropdown', 'number'
  final List<String> options; // For dropdown fields

  ColumnMapping({
    required this.header,
    required this.index,
    required this.fieldType,
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
        'header': header,
        'index': index,
        'fieldType': fieldType,
        'options': options,
      };

  factory ColumnMapping.fromJson(Map<String, dynamic> json) => ColumnMapping(
        header: json['header'] ?? '',
        index: json['index'] ?? 0,
        fieldType: json['fieldType'] ?? 'text',
        options: List<String>.from(json['options'] ?? []),
      );
}

class SheetsStructure {
  final List<ColumnMapping> columns;
  final Map<String, Set<String>> dropdownOptions;

  SheetsStructure({
    required this.columns,
    required this.dropdownOptions,
  });

  Map<String, dynamic> toJson() => {
        'columns': columns.map((c) => c.toJson()).toList(),
        'dropdownOptions': dropdownOptions.map(
          (key, value) => MapEntry(key, value.toList()),
        ),
      };

  factory SheetsStructure.fromJson(Map<String, dynamic> json) {
    final columns = (json['columns'] as List?)
            ?.map((c) => ColumnMapping.fromJson(c))
            .toList() ??
        [];

    final dropdownOptions = <String, Set<String>>{};
    (json['dropdownOptions'] as Map<String, dynamic>?)?.forEach(
      (key, value) => dropdownOptions[key] = Set<String>.from(value),
    );

    return SheetsStructure(
      columns: columns,
      dropdownOptions: dropdownOptions,
    );
  }
}

class DynamicSheetsService {
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();
  SheetsStructure? _currentStructure;

  // Analyze Google Sheets structure and extract dynamic information
  Future<SheetsStructure?> analyzeSheetStructure() async {
    try {
      print('🔍 Analyzing Google Sheets structure...');

      // First, try to get key sheet data
      final keyConfig = await _loadKeyConfiguration();

      final rawData = await _googleSheetsService.getAllBooks();
      if (rawData == null || rawData.isEmpty) {
        print('❌ No data found in Google Sheets');
        return null;
      }

      print('📊 Found ${rawData.length} rows in Google Sheets');

      // Extract headers from first row
      final headers = rawData.first;
      print('📋 Headers: ${headers.join(' | ')}');

      // Analyze each column
      final columns = <ColumnMapping>[];
      final dropdownOptions = <String, Set<String>>{};

      for (int i = 0; i < headers.length; i++) {
        final header = headers[i].trim();
        if (header.isEmpty) continue;

        // Check if we have key configuration for this column
        Map<String, dynamic> keyInfo = {'type': 'none', 'options': <String>[]};
        if (keyConfig != null) {
          keyInfo = _getKeyOptionsForColumn(header, i, keyConfig);
        }

        // Collect all values in this column (excluding header)
        final columnValues = <String>{};
        for (int rowIndex = 1; rowIndex < rawData.length; rowIndex++) {
          if (i < rawData[rowIndex].length) {
            final value = rawData[rowIndex][i].toString().trim();
            if (value.isNotEmpty && value != 'لا يوجد') {
              columnValues.add(value);
            }
          }
        }

        // Determine field type based on key configuration and data
        String fieldType;
        List<String> finalOptions = [];

        if (keyInfo['type'] == 'location_compound') {
          fieldType = 'location_compound';
          finalOptions = []; // Will be handled specially in UI
        } else if (keyInfo['type'] == 'dropdown') {
          fieldType = 'dropdown';
          final keyOptions = keyInfo['options'] as List<String>;
          final allOptions = <String>{};
          allOptions.addAll(keyOptions);
          allOptions.addAll(columnValues);
          finalOptions = allOptions.toList();
        } else if (keyInfo['type'] == 'autocomplete') {
          fieldType = 'autocomplete';
          final keyOptions = keyInfo['options'] as List<String>;
          final allOptions = <String>{};
          allOptions.addAll(keyOptions);
          allOptions.addAll(columnValues);
          finalOptions = allOptions.toList();
        } else {
          // Use fallback logic
          fieldType = _determineFieldType(header, columnValues, false);
          finalOptions = fieldType == 'dropdown' ? columnValues.toList() : [];
        }

        final mapping = ColumnMapping(
          header: header,
          index: i,
          fieldType: fieldType,
          options: finalOptions,
        );

        columns.add(mapping);

        // Store additional data for compound location fields
        if (fieldType == 'location_compound') {
          dropdownOptions['${header}_rows'] =
              (keyInfo['rows'] as List<String>).toSet();
          dropdownOptions['${header}_columns'] =
              (keyInfo['columns'] as List<String>).toSet();
        } else if (fieldType == 'dropdown' || fieldType == 'autocomplete') {
          dropdownOptions[header] = finalOptions.toSet();
        }

        final keyOptionsCount = keyInfo['options'] is List
            ? (keyInfo['options'] as List).length
            : 0;
        print(
            '📝 Column $i: $header -> $fieldType (${finalOptions.length} total options, $keyOptionsCount from key)');
      }

      _currentStructure = SheetsStructure(
        columns: columns,
        dropdownOptions: dropdownOptions,
      );

      print('✅ Sheet structure analyzed successfully');
      return _currentStructure;
    } catch (e) {
      print('❌ Error analyzing sheet structure: $e');
      return null;
    }
  }

  // Load key configuration from the مفتاح sheet
  Future<List<List<String>>?> _loadKeyConfiguration() async {
    try {
      print('🔑 Loading key configuration...');

      // Use a more robust approach - limit the range to avoid parsing issues
      final credentialsJson = await rootBundle
          .loadString('assets/credentials/service-account-key.json');
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(credentialsJson));
      final client = await clientViaServiceAccount(
          credentials, [SheetsApi.spreadsheetsScope]);
      final sheetsApi = SheetsApi(client);

      const spreadsheetId = '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';

      // Use correct range to get all key data including authors in column F
      final keyData = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'مفتاح!A:H', // Full range to include authors in column F
      );

      client.close();

      if (keyData.values != null && keyData.values!.isNotEmpty) {
        print('✅ Key configuration loaded: ${keyData.values!.length} rows');
        return keyData.values!
            .map((row) => row.map((cell) => cell.toString()).toList())
            .toList();
      }

      return null;
    } catch (e) {
      print('⚠️ Could not load key configuration: $e');
      print('⚠️ Falling back to static configuration');
      return _getStaticKeyConfiguration();
    }
  }

  // Fallback static key configuration based on actual structure
  List<List<String>> _getStaticKeyConfiguration() {
    return [
      ['الصف', 'العامود', '', 'تصنيفات', '', 'المؤلفين'],
      ['A', '1', '', 'علوم', '', 'إبراهيم عباس'],
      ['B', '2', '', 'إسلاميات', '', 'ياسر بهجت'],
      ['C', '3', '', 'إنسانيات', '', 'مهن الهناني'],
      ['D', '4', '', 'لغة وأدب', '', 'أحمد مراد'],
      ['E', '5', '', 'أعمال وإدارة', '', 'تزكية النفس والدعاء'],
      ['', '6', '', 'فنون', '', ''],
      ['', '7', '', 'ثقافة عامة', '', ''],
      ['', '8', '', 'روايات', '', ''],
    ];
  }

  // Extract dropdown options from key configuration ONLY (efficient!)
  Map<String, dynamic> _getKeyOptionsForColumn(
      String header, int columnIndex, List<List<String>> keyConfig) {
    // Check if this is a category column
    if (header.contains('تصنيف') || header.toLowerCase().contains('category')) {
      final categories = <String>[];
      for (int i = 1; i < keyConfig.length; i++) {
        if (keyConfig[i].length > 3) {
          final category = keyConfig[i][3].trim();
          if (category.isNotEmpty) {
            categories.add(category);
          }
        }
      }
      print(
          '🎯 Found ${categories.length} categories from Key sheet: ${categories.take(5).join(', ')}${categories.length > 5 ? '...' : ''}');
      return {
        'type': 'dropdown',
        'options': categories.toSet().toList()..sort(),
      };
    }

    // Check if this is an author column - USE ONLY KEY SHEET
    else if (header.contains('مؤلف') ||
        header.toLowerCase().contains('author')) {
      final authors = <String>{};

      // Extract authors ONLY from Key config (column F, index 5) - More efficient!
      for (int i = 1; i < keyConfig.length; i++) {
        if (keyConfig[i].length > 5) {
          final author =
              keyConfig[i][5].trim(); // Column F (index 5) in Key sheet
          if (author.isNotEmpty &&
              author != 'لا يوجد' &&
              author != 'N/A' &&
              author != '-' &&
              author != 'المؤلفين') {
            // Exclude header
            authors.add(author);
          }
        }
      }

      print(
          '📚 Found ${authors.length} authors from Key sheet only: ${authors.take(3).join(', ')}${authors.length > 3 ? '...' : ''}');

      return {
        'type': 'autocomplete',
        'options': authors.toList()..sort(),
      };
    }

    // For other columns, return regular text field
    return {
      'type': 'text',
      'options': <String>[],
    };
  }

  // Determine field type based on header and data (fallback logic)
  String _determineFieldType(String header, Set<String> values,
      [bool hasKeyData = false]) {
    final headerLower = header.toLowerCase();

    // Book names should always be text (not dropdown)
    if (headerLower.contains('اسم الكتاب') ||
        headerLower.contains('book name') ||
        headerLower.contains('كتاب')) {
      return 'text';
    }

    // Author names should be autocomplete (not restrictive dropdown)
    if (headerLower.contains('مؤلف') ||
        headerLower.contains('author') ||
        headerLower.contains('كاتب')) {
      return 'autocomplete';
    }

    // Part numbers and descriptions should be text
    if (headerLower.contains('رقم') ||
        headerLower.contains('number') ||
        headerLower.contains('جزء') ||
        headerLower.contains('تعريف') ||
        headerLower.contains('description')) {
      return 'text';
    }

    // Categories should be dropdown (but this is usually handled by key)
    if (headerLower.contains('تصنيف') ||
        headerLower.contains('category') ||
        headerLower.contains('النوع')) {
      return 'dropdown';
    }

    // Location should be compound (but this is usually handled by key)
    if (headerLower.contains('موقع') ||
        headerLower.contains('location') ||
        headerLower.contains('مكان')) {
      return 'dropdown'; // Fallback to simple dropdown
    }

    // Default to text for safety (avoid restrictive dropdowns)
    return 'text';
  }

  // Get available options for a specific field
  List<String> getDropdownOptions(String fieldName) {
    if (_currentStructure == null) return [];

    final options = _currentStructure!.dropdownOptions[fieldName];
    return options?.toList() ?? [];
  }

  // Get column mapping by header name
  ColumnMapping? getColumnByHeader(String headerName) {
    if (_currentStructure == null) return null;

    try {
      return _currentStructure!.columns.firstWhere(
        (col) => col.header.toLowerCase().contains(headerName.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  // Create a Book object from dynamic form data
  Book createBookFromDynamicData(Map<String, String> formData) {
    if (_currentStructure == null) {
      throw Exception('Sheet structure not analyzed');
    }

    String libraryLocation = '';
    String category = '';
    String bookName = '';
    String authorName = '';
    String briefDescription = '';

    String volumeNumber = '';

    // Map form data to book fields based on column headers
    for (final column in _currentStructure!.columns) {
      final value = formData[column.header] ?? '';

      if (column.header.contains('موقع') ||
          column.header.toLowerCase().contains('location')) {
        libraryLocation += (libraryLocation.isEmpty ? '' : '') + value;
      } else if (column.header.contains('تصنيف') ||
          column.header.toLowerCase().contains('category')) {
        category = value;
      } else if (column.header.contains('اسم الكتاب') ||
          column.header.toLowerCase().contains('book')) {
        bookName = value;
      } else if (column.header.contains('مؤلف') ||
          column.header.toLowerCase().contains('author')) {
        authorName = value;
      } else if (column.header.contains('رقم الجزء') ||
          column.header.toLowerCase().contains('volume')) {
        volumeNumber = value;
      } else if (column.header.contains('تعريف') ||
          column.header.toLowerCase().contains('description')) {
        briefDescription = value;
      }
    }

    return Book(
      libraryLocation: libraryLocation.trim(),
      category: category,
      bookName: bookName,
      authorName: authorName,
      briefDescription: briefDescription,
      volumeNumber: volumeNumber.isNotEmpty ? volumeNumber : null,
    );
  }

  // Convert Book to sheet row using dynamic structure
  List<String> bookToSheetRow(Book book) {
    if (_currentStructure == null) {
      return book.toSheetRow(); // Fallback to default
    }

    final row = List<String>.filled(_currentStructure!.columns.length, '');

    for (final column in _currentStructure!.columns) {
      final index = column.index;

      if (column.header.contains('موقع') ||
          column.header.toLowerCase().contains('location')) {
        row[index] = book.libraryLocation;
      } else if (column.header.contains('تصنيف') ||
          column.header.toLowerCase().contains('category')) {
        row[index] = book.category;
      } else if (column.header.contains('اسم الكتاب') ||
          column.header.toLowerCase().contains('book')) {
        row[index] = book.bookName;
      } else if (column.header.contains('مؤلف') ||
          column.header.toLowerCase().contains('author')) {
        row[index] = book.authorName;
      } else if (column.header.contains('رقم الجزء') ||
          column.header.toLowerCase().contains('volume')) {
        row[index] = book.volumeNumber ?? '';
      } else if (column.header.contains('تعريف') ||
          column.header.toLowerCase().contains('description')) {
        row[index] = book.briefDescription;
      }
    }

    return row;
  }

  // Get current structure
  SheetsStructure? get currentStructure => _currentStructure;

  // Get all categories from the data
  List<String> getCategories() {
    final categoryColumn = getColumnByHeader('تصنيف');
    if (categoryColumn != null) {
      return categoryColumn.options;
    }

    // Fallback to analyzing dropdown options
    final categories = _currentStructure?.dropdownOptions.entries
            .where((entry) => entry.key.contains('تصنيف'))
            .expand((entry) => entry.value)
            .toList() ??
        [];

    return categories;
  }

  // Get all locations from the data
  List<String> getLocations() {
    final locationColumns = _currentStructure?.columns
            .where((col) => col.header.contains('موقع'))
            .toList() ??
        [];

    final locations = <String>{};
    for (final column in locationColumns) {
      locations.addAll(column.options);
    }

    return locations.toList();
  }

  // Get all authors from the data
  List<String> getAuthors() {
    final authorColumn = getColumnByHeader('مؤلف');
    if (authorColumn != null) {
      return authorColumn.options;
    }

    // Fallback to analyzing dropdown options
    final authors = _currentStructure?.dropdownOptions.entries
            .where((entry) =>
                entry.key.contains('مؤلف') ||
                entry.key.toLowerCase().contains('author'))
            .expand((entry) => entry.value)
            .toList() ??
        [];

    return authors;
  }

  // Update structure with additional authors from local data
  void updateAuthorsFromLocalData(List<String> localAuthors) {
    if (_currentStructure == null) return;

    // Find author column
    final authorColumn = _currentStructure!.columns.firstWhere(
      (col) =>
          col.header.contains('مؤلف') ||
          col.header.toLowerCase().contains('author'),
      orElse: () => throw Exception('Author column not found'),
    );

    // Combine existing authors with local authors
    final existingAuthors = Set<String>.from(authorColumn.options);
    final allAuthors = <String>{};

    // Add existing authors
    allAuthors.addAll(existingAuthors);

    // Add local authors (filtered)
    for (final author in localAuthors) {
      final cleanAuthor = author.trim();
      if (cleanAuthor.isNotEmpty &&
          cleanAuthor != 'لا يوجد' &&
          cleanAuthor != 'N/A' &&
          cleanAuthor != '-') {
        allAuthors.add(cleanAuthor);
      }
    }

    // Update the column options
    final updatedColumns = _currentStructure!.columns.map((col) {
      if (col.header.contains('مؤلف') ||
          col.header.toLowerCase().contains('author')) {
        return ColumnMapping(
          header: col.header,
          index: col.index,
          fieldType: col.fieldType,
          options: allAuthors.toList()..sort(),
        );
      }
      return col;
    }).toList();

    // Update the structure
    _currentStructure = SheetsStructure(
      columns: updatedColumns,
      dropdownOptions: {
        ..._currentStructure!.dropdownOptions,
        authorColumn.header: allAuthors,
      },
    );

    print('📚 Updated authors list with ${allAuthors.length} total authors');
  }
}
