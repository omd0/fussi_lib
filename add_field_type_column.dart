import 'dart:convert';
import 'dart:io';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

// Configuration
const String SPREADSHEET_ID = '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';
const String KEY_SHEET_NAME = 'مفتاح';
const String CREDENTIALS_PATH = 'assets/credentials/service-account-key.json';

void main() async {
  print('🚀 Adding Field Type Column to Google Sheet...\n');
  print('📋 Spreadsheet ID: $SPREADSHEET_ID');
  print('📋 Key Sheet Name: $KEY_SHEET_NAME');

  try {
    await addFieldTypeColumn();
    print('\n✅ Field type column added successfully!');
    print('📋 You can now specify field types in the "نوع الحقل" column');
    print('🔄 Restart your app to see the new field type behavior');
  } catch (e) {
    print('❌ Error: $e');
    print('\n💡 Make sure to:');
    print('1. Check internet connection');
    print('2. Verify spreadsheet ID is correct');
    print('3. Ensure key sheet name is correct');
    print('4. Check that credentials file exists');
  }
}

Future<SheetsApi> initializeGoogleSheets() async {
  print('🔐 Initializing Google Sheets API...');

  try {
    // Load credentials
    final credentialsFile = File(CREDENTIALS_PATH);
    if (!await credentialsFile.exists()) {
      throw Exception('Credentials file not found at: $CREDENTIALS_PATH');
    }

    final credentialsJson = await credentialsFile.readAsString();
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

Future<void> addFieldTypeColumn() async {
  print('📊 Analyzing current key sheet structure...');

  try {
    // Get current key sheet data
    final sheetsApi = await initializeGoogleSheets();
    final keySheetRange = '$KEY_SHEET_NAME!A:ZZ';
    final response = await sheetsApi.spreadsheets.values.get(
      SPREADSHEET_ID,
      keySheetRange,
    );

    if (response.values == null || response.values!.isEmpty) {
      throw Exception('Key sheet is empty or not found');
    }

    final headers = response.values![0];
    final dataRows = response.values!.skip(1).toList();

    print('📋 Current headers: ${headers.join(' | ')}');
    print('📊 Found ${dataRows.length} data rows');

    // Check if field type column already exists
    final fieldTypeColumnIndex = findFieldTypeColumn(headers);
    if (fieldTypeColumnIndex != -1) {
      print(
          '⚠️ Field type column already exists at index $fieldTypeColumnIndex');
      print('🔄 Updating existing column...');
      await updateExistingFieldTypeColumn(
          sheetsApi, headers, dataRows, fieldTypeColumnIndex);
    } else {
      print('➕ Adding new field type column...');
      await addNewFieldTypeColumn(sheetsApi, headers, dataRows);
    }
  } catch (e) {
    throw Exception('Failed to add field type column: $e');
  }
}

int findFieldTypeColumn(List<dynamic> headers) {
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

Future<void> addNewFieldTypeColumn(SheetsApi sheetsApi, List<dynamic> headers,
    List<List<dynamic>> dataRows) async {
  print('📝 Adding "نوع الحقل" column...');

  // Add header
  final newHeaders = List<dynamic>.from(headers)..add('نوع الحقل');

  // Prepare new data with suggested field types
  final newDataRows = <List<dynamic>>[];

  for (int i = 0; i < dataRows.length; i++) {
    final row = List<dynamic>.from(dataRows[i]);

    // Ensure row has enough columns
    while (row.length < headers.length) {
      row.add('');
    }

    // Suggest field type based on the first column (field name)
    final fieldName = row.isNotEmpty ? row[0].toString() : '';
    final suggestedType = suggestFieldType(fieldName);
    row.add(suggestedType);

    newDataRows.add(row);
  }

  // Update the sheet
  await updateSheetData(sheetsApi, [newHeaders] + newDataRows);

  print('✅ Added field type column with suggested types');
  printFieldTypeSuggestions(newDataRows, headers.length);
}

Future<void> updateExistingFieldTypeColumn(
    SheetsApi sheetsApi,
    List<dynamic> headers,
    List<List<dynamic>> dataRows,
    int fieldTypeColumnIndex) async {
  print('🔄 Updating existing field type column...');

  final newDataRows = <List<dynamic>>[];

  for (int i = 0; i < dataRows.length; i++) {
    final row = List<dynamic>.from(dataRows[i]);

    // Ensure row has enough columns
    while (row.length <= fieldTypeColumnIndex) {
      row.add('');
    }

    // If field type is empty, suggest one
    if (row[fieldTypeColumnIndex].toString().trim().isEmpty) {
      final fieldName = row.isNotEmpty ? row[0].toString() : '';
      final suggestedType = suggestFieldType(fieldName);
      row[fieldTypeColumnIndex] = suggestedType;
    }

    newDataRows.add(row);
  }

  // Update the sheet
  await updateSheetData(sheetsApi, [headers] + newDataRows);

  print('✅ Updated existing field type column');
  printFieldTypeSuggestions(newDataRows, fieldTypeColumnIndex);
}

String suggestFieldType(String fieldName) {
  final name = fieldName.toLowerCase().trim();

  // Location fields (العامود/الصف) - these are for library location
  if (name.contains('عامود') ||
      name.contains('صف') ||
      name.contains('column') ||
      name.contains('row')) {
    return 'location';
  }

  // Category fields (التصنيف)
  if (name.contains('تصنيف') ||
      name.contains('category') ||
      name.contains('موضوع') ||
      name.contains('فئة') ||
      name.contains('قسم')) {
    return 'dropdown';
  }

  // Book title fields (اسم الكتاب)
  if (name.contains('اسم') && name.contains('كتاب') ||
      name.contains('عنوان') ||
      name.contains('title')) {
    return 'autocomplete';
  }

  // Author fields (المؤلف)
  if (name.contains('مؤلف') ||
      name.contains('كاتب') ||
      name.contains('author')) {
    return 'autocomplete';
  }

  // Volume/part number fields (رقم الجزء)
  if (name.contains('رقم') && name.contains('جزء') ||
      name.contains('volume') ||
      name.contains('part')) {
    return 'text';
  }

  // Description fields (مختصر تعريفي)
  if (name.contains('مختصر') && name.contains('تعريفي') ||
      name.contains('وصف') ||
      name.contains('description') ||
      name.contains('summary')) {
    return 'text';
  }

  // Notes/restrictions fields (ملاحظة)
  if (name.contains('ملاحظة') ||
      name.contains('note') ||
      name.contains('comment') ||
      name.contains('restriction')) {
    return 'autocomplete';
  }

  // Default suggestion
  return 'text';
}

Future<void> updateSheetData(
    SheetsApi sheetsApi, List<List<dynamic>> data) async {
  final valueRange = ValueRange(values: data);

  await sheetsApi.spreadsheets.values.update(
    valueRange,
    SPREADSHEET_ID,
    '$KEY_SHEET_NAME!A:ZZ',
    valueInputOption: 'RAW',
  );
}

void printFieldTypeSuggestions(
    List<List<dynamic>> dataRows, int fieldTypeColumnIndex) {
  print('\n📋 Field Type Suggestions:');
  print('────────────────────────────────────────');

  for (final row in dataRows) {
    if (row.isNotEmpty && row.length > fieldTypeColumnIndex) {
      final fieldName = row[0].toString();
      final fieldType = row[fieldTypeColumnIndex].toString();

      if (fieldName.isNotEmpty) {
        final icon = getFieldTypeIcon(fieldType);
        print('$icon $fieldName → $fieldType');
      }
    }
  }

  print('────────────────────────────────────────');
  print('💡 You can modify these types directly in the Google Sheet');
  print('📖 Supported types: text, dropdown, autocomplete, location');
  print('🌐 Arabic types: نص, قائمة, تلقائي, موقع');
}

String getFieldTypeIcon(String fieldType) {
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
