import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

// Import your app constants - adjust path as needed
// import 'lib/constants/app_constants.dart';

// Temporary constants - replace with your actual values
class TempConstants {
  static const String spreadsheetId =
      '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';
  static const String keySheetName = 'مفتاح';
  static const String credentialsPath =
      'assets/credentials/service-account-key.json';
}

void main() async {
  print('🚀 Adding Field Type Column to Google Sheet...\n');

  final service = FieldTypeColumnService();

  try {
    await service.addFieldTypeColumnToSheet();
    print('\n✅ Field type column added successfully!');
    print('📋 You can now specify field types in the "نوع الحقل" column');
    print('🔄 Restart your app to see the new field type behavior');
  } catch (e) {
    print('❌ Error: $e');
    print('\n💡 Make sure to:');
    print('1. Update SPREADSHEET_ID with your actual sheet ID');
    print('2. Ensure credentials file exists');
    print('3. Check internet connection');
  }
}

class FieldTypeColumnService {
  SheetsApi? _sheetsApi;

  Future<void> addFieldTypeColumnToSheet() async {
    print('🔐 Initializing Google Sheets API...');

    // Initialize API
    _sheetsApi = await _initializeGoogleSheets();

    // Add field type column
    await _addFieldTypeColumn();
  }

  Future<SheetsApi> _initializeGoogleSheets() async {
    try {
      // Load credentials from assets (same as your existing service)
      final credentialsJson =
          await rootBundle.loadString(TempConstants.credentialsPath);
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(credentialsJson));

      // Create authenticated client
      final client = await clientViaServiceAccount(
        credentials,
        [SheetsApi.spreadsheetsScope],
      );

      final sheetsApi = SheetsApi(client);
      print('✅ Google Sheets API initialized');

      return sheetsApi;
    } catch (e) {
      throw Exception('Failed to initialize Google Sheets API: $e');
    }
  }

  Future<void> _addFieldTypeColumn() async {
    print('📊 Analyzing current key sheet structure...');

    try {
      // Get current key sheet data
      final keySheetRange = '${TempConstants.keySheetName}!A:ZZ';
      final response = await _sheetsApi!.spreadsheets.values.get(
        TempConstants.spreadsheetId,
        keySheetRange,
      );

      if (response.values == null || response.values!.isEmpty) {
        throw Exception(
            'Key sheet "${TempConstants.keySheetName}" is empty or not found');
      }

      final headers = response.values![0];
      final dataRows = response.values!.skip(1).toList();

      print('📋 Current headers: ${headers.join(' | ')}');
      print('📊 Found ${dataRows.length} data rows');

      // Check if field type column already exists
      final fieldTypeColumnIndex = _findFieldTypeColumn(headers);
      if (fieldTypeColumnIndex != -1) {
        print(
            '⚠️ Field type column already exists at index $fieldTypeColumnIndex');
        print('🔄 Updating existing column with suggestions...');
        await _updateExistingFieldTypeColumn(
            headers, dataRows, fieldTypeColumnIndex);
      } else {
        print('➕ Adding new "نوع الحقل" column...');
        await _addNewFieldTypeColumn(headers, dataRows);
      }
    } catch (e) {
      throw Exception('Failed to add field type column: $e');
    }
  }

  int _findFieldTypeColumn(List<dynamic> headers) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toString().toLowerCase().trim();
      if (header.contains('نوع الحقل') ||
          header.contains('field type') ||
          header.contains('fieldtype') ||
          header.contains('type')) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _addNewFieldTypeColumn(
      List<dynamic> headers, List<List<dynamic>> dataRows) async {
    print('📝 Adding "نوع الحقل" column...');

    // Add header
    final newHeaders = List<dynamic>.from(headers)..add('نوع الحقل');

    // Prepare new data with intelligent field type suggestions
    final newDataRows = <List<dynamic>>[];

    for (int i = 0; i < dataRows.length; i++) {
      final row = List<dynamic>.from(dataRows[i]);

      // Ensure row has enough columns
      while (row.length < headers.length) {
        row.add('');
      }

      // Get field name (assuming first column contains field names)
      final fieldName = row.isNotEmpty ? row[0].toString() : '';

      // Get field values (all other columns for this row)
      final fieldValues = <String>{};
      for (int j = 1; j < row.length; j++) {
        final value = row[j].toString().trim();
        if (value.isNotEmpty && value != '-') {
          fieldValues.add(value);
        }
      }

      // Suggest field type based on field name and values
      final suggestedType = _suggestFieldType(fieldName, fieldValues);
      row.add(suggestedType);

      newDataRows.add(row);
    }

    // Update the sheet
    await _updateSheetData([newHeaders] + newDataRows);

    print('✅ Added field type column with intelligent suggestions');
    _printFieldTypeSuggestions(newDataRows, headers.length);
  }

  Future<void> _updateExistingFieldTypeColumn(List<dynamic> headers,
      List<List<dynamic>> dataRows, int fieldTypeColumnIndex) async {
    print('🔄 Updating existing field type column...');

    final newDataRows = <List<dynamic>>[];
    int updatedCount = 0;

    for (int i = 0; i < dataRows.length; i++) {
      final row = List<dynamic>.from(dataRows[i]);

      // Ensure row has enough columns
      while (row.length <= fieldTypeColumnIndex) {
        row.add('');
      }

      // If field type is empty, suggest one
      final currentType = row[fieldTypeColumnIndex].toString().trim();
      if (currentType.isEmpty) {
        final fieldName = row.isNotEmpty ? row[0].toString() : '';

        // Get field values
        final fieldValues = <String>{};
        for (int j = 1; j < row.length && j != fieldTypeColumnIndex; j++) {
          final value = row[j].toString().trim();
          if (value.isNotEmpty && value != '-') {
            fieldValues.add(value);
          }
        }

        final suggestedType = _suggestFieldType(fieldName, fieldValues);
        row[fieldTypeColumnIndex] = suggestedType;
        updatedCount++;
      }

      newDataRows.add(row);
    }

    // Update the sheet
    await _updateSheetData([headers] + newDataRows);

    print('✅ Updated $updatedCount empty field type cells');
    _printFieldTypeSuggestions(newDataRows, fieldTypeColumnIndex);
  }

  String _suggestFieldType(String fieldName, Set<String> fieldValues) {
    final name = fieldName.toLowerCase().trim();

    // Author fields - always autocomplete for better UX
    if (name.contains('مؤلف') ||
        name.contains('كاتب') ||
        name.contains('author')) {
      return 'autocomplete';
    }

    // Book title fields - autocomplete for search functionality
    if ((name.contains('اسم') && name.contains('كتاب')) ||
        name.contains('عنوان') ||
        name.contains('title')) {
      return 'autocomplete';
    }

    // Notes fields - autocomplete for flexibility
    if (name.contains('ملاحظة') ||
        name.contains('note') ||
        name.contains('comment')) {
      return 'autocomplete';
    }

    // Category/subject fields - dropdown with plus button
    if (name.contains('موضوع') ||
        name.contains('فئة') ||
        name.contains('قسم') ||
        name.contains('تصنيف') ||
        name.contains('نوع') ||
        name.contains('category') ||
        name.contains('subject')) {
      return 'dropdown';
    }

    // Publisher fields - dropdown with plus button
    if (name.contains('ناشر') || name.contains('publisher')) {
      return 'dropdown';
    }

    // Location fields - special location component
    if (name.contains('موقع') ||
        name.contains('صف') ||
        name.contains('عمود') ||
        name.contains('location') ||
        name.contains('row') ||
        name.contains('column')) {
      return 'location';
    }

    // Numeric fields - simple text input
    if (name.contains('رقم') ||
        name.contains('عدد') ||
        name.contains('number') ||
        name.contains('id')) {
      return 'text';
    }

    // Date fields - simple text input
    if (name.contains('سنة') ||
        name.contains('تاريخ') ||
        name.contains('year') ||
        name.contains('date')) {
      return 'text';
    }

    // Analyze field values to make smart suggestions
    if (fieldValues.isNotEmpty) {
      // Check if all values are single letters (row indicators)
      if (fieldValues.every((v) => RegExp(r'^[A-Z]$').hasMatch(v))) {
        return 'location';
      }

      // Check if all values are numbers (column indicators or IDs)
      if (fieldValues.every((v) => RegExp(r'^\d+$').hasMatch(v))) {
        return name.contains('رقم') || name.contains('number')
            ? 'text'
            : 'location';
      }

      // Small set of values - good for dropdown
      if (fieldValues.length <= 10) {
        return 'dropdown';
      }

      // Large set of values - better as autocomplete
      if (fieldValues.length > 10) {
        return 'autocomplete';
      }
    }

    // Default suggestion
    return 'text';
  }

  Future<void> _updateSheetData(List<List<dynamic>> data) async {
    final valueRange = ValueRange(values: data);

    await _sheetsApi!.spreadsheets.values.update(
      valueRange,
      TempConstants.spreadsheetId,
      '${TempConstants.keySheetName}!A:ZZ',
      valueInputOption: 'RAW',
    );
  }

  void _printFieldTypeSuggestions(
      List<List<dynamic>> dataRows, int fieldTypeColumnIndex) {
    print('\n📋 Field Type Suggestions Applied:');
    print('────────────────────────────────────────');

    final typeCount = <String, int>{};

    for (final row in dataRows) {
      if (row.isNotEmpty && row.length > fieldTypeColumnIndex) {
        final fieldName = row[0].toString();
        final fieldType = row[fieldTypeColumnIndex].toString();

        if (fieldName.isNotEmpty && fieldType.isNotEmpty) {
          final icon = _getFieldTypeIcon(fieldType);
          print('$icon $fieldName → $fieldType');

          typeCount[fieldType] = (typeCount[fieldType] ?? 0) + 1;
        }
      }
    }

    print('────────────────────────────────────────');
    print('📊 Summary:');
    typeCount.forEach((type, count) {
      final icon = _getFieldTypeIcon(type);
      print('$icon $type: $count fields');
    });

    print('\n💡 Next steps:');
    print('1. Review the suggestions in your Google Sheet');
    print('2. Modify any field types as needed');
    print('3. Restart your app to see the new behavior');
    print('\n📖 Available types:');
    print('• text/نص - Simple text input');
    print('• dropdown/قائمة - Dropdown with ➕ plus button');
    print('• autocomplete/تلقائي - Search with suggestions');
    print('• location/موقع - Location compound field');
  }

  String _getFieldTypeIcon(String fieldType) {
    switch (fieldType.toLowerCase()) {
      case 'dropdown':
      case 'قائمة':
        return '📋';
      case 'autocomplete':
      case 'تلقائي':
      case 'بحث':
        return '🔍';
      case 'location':
      case 'موقع':
        return '🗺️';
      case 'text':
      case 'نص':
      default:
        return '📝';
    }
  }
}
