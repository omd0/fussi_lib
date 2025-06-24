import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/book.dart';
import '../utils/arabic_text_utils.dart';
import 'google_sheets_service.dart';

class ColumnMapping {
  final String header;
  final int index;
  final String
      fieldType; // Base type: 'text', 'dropdown', 'autocomplete', 'location_compound'
  final List<String> features; // Features: 'plus', 'md', 'long'
  final List<String> options; // For dropdown/autocomplete fields
  final bool isDynamic; // Track if this is a dynamically detected field
  final String? keySheetColumn; // Track which key sheet column this came from

  ColumnMapping({
    required this.header,
    required this.index,
    required this.fieldType,
    this.features = const [],
    this.options = const [],
    this.isDynamic = false,
    this.keySheetColumn,
  });

  /// Check if this field has a specific feature
  bool hasFeature(String feature) => features.contains(feature);

  /// Get display type with features for debugging
  String get displayType {
    if (features.isEmpty) return fieldType;
    return '$fieldType ${features.join(' ')}';
  }

  Map<String, dynamic> toJson() => {
        'header': header,
        'index': index,
        'fieldType': fieldType,
        'features': features,
        'options': options,
        'isDynamic': isDynamic,
        'keySheetColumn': keySheetColumn,
      };

  factory ColumnMapping.fromJson(Map<String, dynamic> json) => ColumnMapping(
        header: json['header'] ?? '',
        index: json['index'] ?? 0,
        fieldType: json['fieldType'] ?? 'text',
        features: List<String>.from(json['features'] ?? []),
        options: List<String>.from(json['options'] ?? []),
        isDynamic: json['isDynamic'] ?? false,
        keySheetColumn: json['keySheetColumn'],
      );
}

class SheetsStructure {
  final List<ColumnMapping> columns;
  final Map<String, Set<String>> dropdownOptions;
  final Map<String, String>
      dynamicColumns; // Track dynamic columns from key sheet
  final Map<String, List<String>> locationData; // For compound location fields

  SheetsStructure({
    required this.columns,
    required this.dropdownOptions,
    this.dynamicColumns = const {},
    this.locationData = const {},
  });

  Map<String, dynamic> toJson() => {
        'columns': columns.map((c) => c.toJson()).toList(),
        'dropdownOptions': dropdownOptions.map(
          (key, value) => MapEntry(key, value.toList()),
        ),
        'dynamicColumns': dynamicColumns,
        'locationData': locationData,
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

    final dynamicColumns =
        Map<String, String>.from(json['dynamicColumns'] ?? {});
    final locationData = <String, List<String>>{};
    (json['locationData'] as Map<String, dynamic>?)?.forEach(
      (key, value) => locationData[key] = List<String>.from(value),
    );

    return SheetsStructure(
      columns: columns,
      dropdownOptions: dropdownOptions,
      dynamicColumns: dynamicColumns,
      locationData: locationData,
    );
  }
}

class DynamicSheetsService {
  final GoogleSheetsService _googleSheetsService = GoogleSheetsService();
  FormStructure? _currentStructure;

  /// Key sheet is the ONLY source of truth for ALL field definitions
  Future<FormStructure?> analyzeSheetStructure() async {
    try {
      print(
          '🔑 Analyzing structure using KEY SHEET as SINGLE SOURCE OF TRUTH...');

      // Load key sheet data using proper data model
      final keySheetData = await _loadKeySheetData();
      if (keySheetData == null) {
        print('❌ No key sheet data found - cannot proceed');
        return null;
      }

      print(
          '📊 Loaded key sheet with ${keySheetData.dataRows.length} data rows');
      print('🎯 Headers: ${keySheetData.nonEmptyHeaders.join(' | ')}');

      // Build complete structure from key sheet using data models
      final structure = await _buildFormStructure(keySheetData);

      _currentStructure = structure;

      print('✅ Structure built ENTIRELY from key sheet using data models!');
      print('🎯 Total fields detected: ${structure.fields.length}');

      // Debug log all detected fields
      for (final field in structure.fields) {
        final optionsInfo = field.options.isNotEmpty
            ? ' (${field.options.length} options)'
            : '';
        print('   📝 ${field.displayName} -> ${field.displayType}$optionsInfo');
      }

      return structure;
    } catch (e, stackTrace) {
      print('❌ Error analyzing key sheet structure: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Load key sheet data and return structured data model
  Future<KeySheetData?> _loadKeySheetData() async {
    try {
      print('🔑 Loading key sheet data using data models...');

      final credentialsJson = await rootBundle
          .loadString('assets/credentials/service-account-key.json');
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(credentialsJson));
      final client = await clientViaServiceAccount(
          credentials, [SheetsApi.spreadsheetsScope]);
      final sheetsApi = SheetsApi(client);

      const spreadsheetId = '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';

      // Use maximum range to capture ALL possible columns
      final keyData = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'مفتاح!A:ZZ', // Maximum range to handle future column additions dynamically
      );

      client.close();

      if (keyData.values != null && keyData.values!.isNotEmpty) {
        final rawData = keyData.values!
            .map((row) => row.map((cell) => cell.toString()).toList())
            .toList();

        print('✅ Raw key sheet loaded: ${rawData.length} rows');

        // Convert to structured data model
        final keySheetData = KeySheetData.fromRawData(rawData);

        print('✅ Key sheet data model created:');
        print('   📋 Headers: ${keySheetData.headers.length}');
        print('   🎯 Field types: ${keySheetData.fieldTypes.length}');
        print('   📊 Data rows: ${keySheetData.dataRows.length}');

        return keySheetData;
      }

      return null;
    } catch (e) {
      print('⚠️ Could not load key sheet: $e');
      return null;
    }
  }

  /// Build form structure using data models instead of raw JSON
  Future<FormStructure> _buildFormStructure(KeySheetData keySheetData) async {
    print('🏗️ Building form structure using data models...');

    final fields = <FieldConfig>[];
    LocationData? locationData;

    // Process each column header
    for (final header in keySheetData.nonEmptyHeaders) {
      print('🔍 Processing field: "$header"');

      // Get column data using data model methods
      final columnValues = keySheetData.getColumnValues(header);
      final explicitFieldType = keySheetData.getFieldType(header);

      // Skip completely empty columns
      if (columnValues.isEmpty) {
        print('   ⚠️ Skipping empty field: "$header"');
        continue;
      }

      print('   📋 Found ${columnValues.length} unique values');

      // Handle location components specially
      if (_isLocationComponent(header, columnValues)) {
        print('   🗺️ Detected location component: "$header"');
        locationData =
            _handleLocationComponent(header, columnValues, locationData);
        continue; // Don't add as separate field
      }

      // Determine field type and features
      final fieldTypeData = _determineFieldTypeAndFeatures(
          header, columnValues, explicitFieldType);

      // Create field configuration
      final fieldConfig = FieldConfig(
        name: header,
        displayName: header,
        type: fieldTypeData['type'],
        features: fieldTypeData['features'],
        options: columnValues.toList()..sort(),
        isDynamic: true, // All key sheet fields are dynamic
        keySheetColumn: header,
      );

      fields.add(fieldConfig);

      print(
          '   ✅ Added field: "${fieldConfig.displayName}" -> ${fieldConfig.displayType}');
    }

    // Add compound location field if we found components
    if (locationData != null && locationData.isComplete) {
      final locationField = FieldConfig(
        name: 'موقع المكتبة',
        displayName: 'موقع المكتبة',
        type: FieldType.locationCompound,
        features: [],
        options: locationData.generateCombinations(),
        isDynamic: true,
        keySheetColumn: 'location_compound',
      );
      fields.add(locationField);
      print(
          '   🗺️ Added compound location field with ${locationField.options.length} combinations');
    }

    print(
        '✅ Form structure complete: ${fields.length} fields using data models');

    return FormStructure(
      fields: fields,
      locationData: locationData,
    );
  }

  /// Determine field type and features from data
  Map<String, dynamic> _determineFieldTypeAndFeatures(
      String header, Set<String> values, String explicitFieldType) {
    FieldType type;
    List<FieldFeature> features = [];

    if (explicitFieldType.isNotEmpty) {
      // Parse explicit field type with features
      final parsed = _parseFieldTypeWithFeatures(explicitFieldType);
      type = parsed['type'];
      features = parsed['features'];
      print(
          '   🎯 Using explicit field type: ${type.name} with features: ${features.map((f) => f.name).join(', ')}');
    } else {
      // Auto-detect field type
      type = _autoDetectFieldType(header, values);
      print('   🎯 Auto-detected field type: ${type.name}');
    }

    return {
      'type': type,
      'features': features,
    };
  }

  /// Auto-detect field type based on header and values
  FieldType _autoDetectFieldType(String header, Set<String> values) {
    // Use existing Arabic text utils for field type suggestion
    final typeString = ArabicTextUtils.suggestFieldType(header, values);

    switch (typeString) {
      case 'dropdown':
        return FieldType.dropdown;
      case 'autocomplete':
        return FieldType.autocomplete;
      case 'location_compound':
        return FieldType.locationCompound;
      default:
        return FieldType.text;
    }
  }

  /// Parse field type with features from user input
  Map<String, dynamic> _parseFieldTypeWithFeatures(String userInput) {
    final input = userInput.toLowerCase().trim();

    // Extract features (modifiers)
    final features = <FieldFeature>[];
    String baseType = input;

    // Check for "plus" feature (add new option button)
    if (input.contains('plus') ||
        input.contains('+') ||
        input.contains('إضافة')) {
      features.add(FieldFeature.plus);
      baseType = baseType
          .replaceAll(RegExp(r'\s*plus\s*'), ' ')
          .replaceAll('+', '')
          .replaceAll('إضافة', '')
          .trim();
    }

    // Check for "md" feature (markdown support)
    if (input.contains('md') ||
        input.contains('markdown') ||
        input.contains('تنسيق')) {
      features.add(FieldFeature.md);
      baseType = baseType
          .replaceAll(RegExp(r'\s*md\s*'), ' ')
          .replaceAll('markdown', '')
          .replaceAll('تنسيق', '')
          .trim();
    }

    // Check for "long" feature (multiline/large text area)
    if (input.contains('long') ||
        input.contains('multiline') ||
        input.contains('طويل') ||
        input.contains('متعدد')) {
      features.add(FieldFeature.long);
      baseType = baseType
          .replaceAll(RegExp(r'\s*long\s*'), ' ')
          .replaceAll('multiline', '')
          .replaceAll('طويل', '')
          .replaceAll('متعدد', '')
          .trim();
    }

    // Normalize base type
    FieldType normalizedType = _normalizeBaseFieldType(baseType);

    print(
        '   🎯 Parsed "$userInput" → type: "${normalizedType.name}", features: ${features.map((f) => f.name).join(', ')}');

    return {
      'type': normalizedType,
      'features': features,
    };
  }

  /// Normalize base field type from user input to enum
  FieldType _normalizeBaseFieldType(String userInput) {
    final input = userInput.toLowerCase().trim();

    // Text field variations
    if (input == 'text' || input == 'نص' || input == 'كتابة') {
      return FieldType.text;
    }

    // Dropdown field variations
    if (input == 'dropdown' ||
        input == 'قائمة' ||
        input == 'اختيار' ||
        input == 'select') {
      return FieldType.dropdown;
    }

    // Autocomplete field variations
    if (input == 'autocomplete' ||
        input == 'تلقائي' ||
        input == 'بحث' ||
        input == 'search') {
      return FieldType.autocomplete;
    }

    // Location compound field variations
    if (input == 'location' ||
        input == 'موقع' ||
        input == 'location_compound') {
      return FieldType.locationCompound;
    }

    // Default to text if unknown
    print('   ⚠️ Unknown base field type "$userInput", defaulting to text');
    return FieldType.text;
  }

  /// Check if a column represents a location component (row/column)
  bool _isLocationComponent(String header, Set<String> values) {
    final lowerHeader = header.toLowerCase();

    // Check header patterns
    if (lowerHeader.contains('صف') ||
        lowerHeader.contains('row') ||
        lowerHeader.contains('عامود') ||
        lowerHeader.contains('عمود') ||
        lowerHeader.contains('column')) {
      return true;
    }

    // Check value patterns - if all values are single letters or numbers
    final allSingleLetters =
        values.every((v) => RegExp(r'^[A-Z]$').hasMatch(v));
    final allNumbers = values.every((v) => RegExp(r'^\d+$').hasMatch(v));

    return allSingleLetters || allNumbers;
  }

  /// Handle location component data using data models
  LocationData? _handleLocationComponent(
      String header, Set<String> values, LocationData? existingLocationData) {
    final lowerHeader = header.toLowerCase();
    final valuesList = values.toList()..sort();

    List<String> rows = existingLocationData?.rows ?? [];
    List<String> columns = existingLocationData?.columns ?? [];

    if (lowerHeader.contains('صف') || lowerHeader.contains('row')) {
      rows = valuesList;
      print(
          '   🗺️ Stored ${valuesList.length} row values: ${valuesList.join(', ')}');
    } else if (lowerHeader.contains('عامود') ||
        lowerHeader.contains('عمود') ||
        lowerHeader.contains('column')) {
      columns = valuesList;
      print(
          '   🗺️ Stored ${valuesList.length} column values: ${valuesList.join(', ')}');
    }

    return LocationData(rows: rows, columns: columns);
  }

  // Get available options for a specific field using data models
  List<String> getFieldOptions(String fieldName) {
    final field = _currentStructure?.getField(fieldName);
    return field?.options ?? [];
  }

  // Get current structure
  FormStructure? get currentStructure => _currentStructure;

  // Check if structure needs refresh
  bool shouldRefreshStructure() {
    return _currentStructure == null || _currentStructure!.needsRefresh;
  }

  // Clear cached structure to force refresh
  void clearStructureCache() {
    _currentStructure = null;
    print('🔄 Structure cache cleared - will refresh on next access');
  }

  /// Enhanced method to get autocomplete options using data models
  Future<List<String>> getAutocompleteOptions(String fieldName) async {
    final fieldOptions = getFieldOptions(fieldName);

    // For author fields, also get data from main sheet for comprehensive autocomplete
    if (ArabicTextUtils.isAuthorColumn(fieldName)) {
      try {
        final rawData = await _googleSheetsService.getAllBooks();
        if (rawData != null && rawData.isNotEmpty) {
          final headers = rawData[0];

          // Find author column index
          int? authorColumnIndex;
          for (int i = 0; i < headers.length; i++) {
            if (ArabicTextUtils.isAuthorColumn(headers[i].toString())) {
              authorColumnIndex = i;
              break;
            }
          }

          if (authorColumnIndex != null) {
            final mainSheetAuthors = <String>{};
            for (int i = 1; i < rawData.length; i++) {
              if (authorColumnIndex < rawData[i].length) {
                final author = rawData[i][authorColumnIndex].toString().trim();
                if (ArabicTextUtils.isValidAuthorName(author)) {
                  mainSheetAuthors.add(author);
                }
              }
            }

            // Combine field options + main sheet authors
            final combinedOptions = <String>{};
            combinedOptions.addAll(fieldOptions);
            combinedOptions.addAll(mainSheetAuthors);

            print(
                '🎯 Enhanced autocomplete for "$fieldName": ${fieldOptions.length} from key + ${mainSheetAuthors.length} from main = ${combinedOptions.length} total');

            return combinedOptions.toList()..sort();
          }
        }
      } catch (e) {
        print('⚠️ Could not enhance autocomplete options: $e');
      }
    }

    return fieldOptions;
  }

  /// DEPRECATED: Legacy methods for backward compatibility
  @deprecated
  List<String> getDropdownOptions(String fieldName) =>
      getFieldOptions(fieldName);

  @deprecated
  SheetsStructure? get currentLegacyStructure {
    if (_currentStructure == null) return null;

    // Convert FormStructure back to legacy SheetsStructure for compatibility
    final columns = _currentStructure!.fields
        .map((field) => ColumnMapping(
              header: field.name,
              index: 0, // Legacy index not used in new model
              fieldType: field.type.name,
              features: field.features.map((f) => f.name).toList(),
              options: field.options,
              isDynamic: field.isDynamic,
              keySheetColumn: field.keySheetColumn,
            ))
        .toList();

    final dropdownOptions = <String, Set<String>>{};
    for (final field in _currentStructure!.fields) {
      if (field.supportsDropdown || field.supportsAutocomplete) {
        dropdownOptions[field.name] = field.options.toSet();
      }
    }

    return SheetsStructure(
      columns: columns,
      dropdownOptions: dropdownOptions,
    );
  }
}
