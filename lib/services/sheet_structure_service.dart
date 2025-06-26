import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/field_config.dart';
import '../models/form_structure.dart';
import '../models/key_sheet_data.dart';
import '../models/location_data.dart';

/// Browsing structure for filter and search capabilities
class BrowsingStructure {
  final List<String> categories;
  final List<String> locations;
  final List<String> authors;
  final Map<String, List<String>> searchableFields;

  const BrowsingStructure({
    required this.categories,
    required this.locations,
    required this.authors,
    required this.searchableFields,
  });
}

/// Enhanced structure data that works for both forms and browsing
class EnhancedStructureData {
  final FormStructure formStructure;
  final BrowsingStructure browsingStructure;
  final LocationData? locationData;
  final DateTime loadedAt;
  final String version;

  const EnhancedStructureData({
    required this.formStructure,
    required this.browsingStructure,
    required this.locationData,
    required this.loadedAt,
    required this.version,
  });

  bool get isExpired {
    final now = DateTime.now();
    final diff = now.difference(loadedAt);
    return diff.inHours > 12; // Expire after 12 hours
  }
}

/// Sheet Structure Service that provides structure for both forms and browsing
class SheetStructureService {
  static final _instance = SheetStructureService._internal();
  factory SheetStructureService() => _instance;
  SheetStructureService._internal();

  EnhancedStructureData? _cachedStructure;
  Timer? _refreshTimer;
  final _structureController =
      StreamController<EnhancedStructureData?>.broadcast();

  /// Stream of structure updates
  Stream<EnhancedStructureData?> get structureStream =>
      _structureController.stream;

  /// Get current structure (cached or fresh)
  Future<EnhancedStructureData?> getStructure(
      {bool forceRefresh = false}) async {
    if (_cachedStructure != null &&
        !_cachedStructure!.isExpired &&
        !forceRefresh) {
      return _cachedStructure;
    }

    return await _loadFreshStructure();
  }

  /// Get form structure specifically
  Future<FormStructure?> getFormStructure({bool forceRefresh = false}) async {
    final structure = await getStructure(forceRefresh: forceRefresh);
    return structure?.formStructure;
  }

  /// Get browsing structure specifically
  Future<BrowsingStructure?> getBrowsingStructure(
      {bool forceRefresh = false}) async {
    final structure = await getStructure(forceRefresh: forceRefresh);
    return structure?.browsingStructure;
  }

  /// Get location data specifically
  Future<LocationData?> getLocationData({bool forceRefresh = false}) async {
    final structure = await getStructure(forceRefresh: forceRefresh);
    return structure?.locationData;
  }

  /// Load fresh structure from Google Sheets
  Future<EnhancedStructureData?> _loadFreshStructure() async {
    try {
      // Load key sheet data
      final keySheetData = await _loadKeySheetData();
      if (keySheetData == null) {
        return _getFallbackStructure();
      }

      // Load actual library data for browsing structure
      final libraryData = await _loadLibraryData();

      // Build combined structure
      final enhancedStructure =
          await _buildEnhancedStructure(keySheetData, libraryData);

      _cachedStructure = enhancedStructure;
      _structureController.add(enhancedStructure);

      // Set up auto-refresh timer
      _setupAutoRefresh();

      return enhancedStructure;
    } catch (e) {
      return _getFallbackStructure();
    }
  }

  /// Load key sheet data for field definitions
  Future<KeySheetData?> _loadKeySheetData() async {
    try {
      final credentialsJson = await rootBundle
          .loadString('assets/credentials/service-account-key.json');
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(credentialsJson));
      final client = await clientViaServiceAccount(
          credentials, [SheetsApi.spreadsheetsScope]);
      final sheetsApi = SheetsApi(client);

      const spreadsheetId = '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';

      final keyData = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'مفتاح!A:ZZ',
      );

      client.close();

      if (keyData.values != null && keyData.values!.isNotEmpty) {
        final rawData = keyData.values!
            .map((row) => row.map((cell) => cell.toString()).toList())
            .toList();

        return KeySheetData.fromRawData(rawData);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Load actual library data for browsing insights
  Future<List<Map<String, dynamic>>?> _loadLibraryData() async {
    try {
      final credentialsJson = await rootBundle
          .loadString('assets/credentials/service-account-key.json');
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(credentialsJson));
      final client = await clientViaServiceAccount(
          credentials, [SheetsApi.spreadsheetsScope]);
      final sheetsApi = SheetsApi(client);

      const spreadsheetId = '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';

      final libraryData = await sheetsApi.spreadsheets.values.get(
        spreadsheetId,
        'الفهرس!A:ZZ',
      );

      client.close();

      if (libraryData.values != null && libraryData.values!.isNotEmpty) {
        final rawData = libraryData.values!
            .map((row) => row.map((cell) => cell.toString()).toList())
            .toList();

        // Convert to structured data
        if (rawData.isEmpty) return null;

        final headers = rawData.first;
        final dataRows = rawData.skip(1).toList();

        return dataRows
            .map((row) {
              final Map<String, dynamic> record = {};
              for (int i = 0; i < headers.length && i < row.length; i++) {
                if (headers[i].isNotEmpty) {
                  record[headers[i]] = row[i];
                }
              }
              return record;
            })
            .where((record) => record.isNotEmpty)
            .toList();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Build enhanced structure combining form and browsing capabilities
  Future<EnhancedStructureData> _buildEnhancedStructure(
    KeySheetData keySheetData,
    List<Map<String, dynamic>>? libraryData,
  ) async {
    // Build form structure
    final formStructure = await _buildFormStructure(keySheetData);

    // Build browsing structure
    final browsingStructure =
        await _buildBrowsingStructure(keySheetData, libraryData);

    // Extract location data
    final locationData = formStructure.locationData;

    return EnhancedStructureData(
      formStructure: formStructure,
      browsingStructure: browsingStructure,
      locationData: locationData,
      loadedAt: DateTime.now(),
      version: '2.0.0',
    );
  }

  /// Build form structure for adding/editing books
  Future<FormStructure> _buildFormStructure(KeySheetData keySheetData) async {
    final fields = <FieldConfig>[];
    LocationData? locationData;

    // Process each column header
    for (final header in keySheetData.nonEmptyHeaders) {
      final columnValues = keySheetData.getColumnValues(header);
      final explicitFieldType = keySheetData.getFieldType(header);

      // Handle location components
      if (_isLocationComponent(header, columnValues, explicitFieldType)) {
        locationData = _handleLocationComponent(
            header, columnValues, locationData, explicitFieldType);
        continue;
      }

      // Determine field type
      final fieldTypeData = _determineFieldTypeAndFeatures(
          header, columnValues, explicitFieldType);

      // Create field configuration
      final fieldConfig = FieldConfig(
        name: header,
        displayName: header,
        type: fieldTypeData['type'],
        features: fieldTypeData['features'],
        options: columnValues.toList()..sort(),
        isDynamic: true,
        keySheetColumn: header,
      );

      fields.add(fieldConfig);
    }

    // Add compound location field
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
    }

    return FormStructure(
      fields: fields,
      locationData: locationData,
    );
  }

  /// Build browsing structure for filtering and searching
  Future<BrowsingStructure> _buildBrowsingStructure(
    KeySheetData keySheetData,
    List<Map<String, dynamic>>? libraryData,
  ) async {
    final categories = <String>{};
    final locations = <String>{};
    final authors = <String>{};
    final searchableFields = <String, List<String>>{};

    // Extract from key sheet data
    for (final header in keySheetData.nonEmptyHeaders) {
      final columnValues = keySheetData.getColumnValues(header);
      final explicitFieldType = keySheetData.getFieldType(header);

      // Determine if field is searchable
      final isSearchable = _isSearchableField(header, explicitFieldType);
      if (isSearchable) {
        searchableFields[header] = columnValues.toList();
      }

      // Categorize common fields
      if (_isCategoryField(header)) {
        categories.addAll(columnValues);
      } else if (_isLocationField(header)) {
        locations.addAll(columnValues);
      } else if (_isAuthorField(header)) {
        authors.addAll(columnValues);
      }
    }

    // Extract from actual library data if available
    if (libraryData != null) {
      for (final record in libraryData) {
        record.forEach((key, value) {
          final valueStr = value.toString().trim();
          if (valueStr.isNotEmpty) {
            if (_isCategoryField(key)) {
              categories.add(valueStr);
            } else if (_isLocationField(key)) {
              locations.add(valueStr);
            } else if (_isAuthorField(key)) {
              authors.add(valueStr);
            }
          }
        });
      }
    }

    return BrowsingStructure(
      categories: categories.toList()..sort(),
      locations: locations.toList()..sort(),
      authors: authors.toList()..sort(),
      searchableFields: searchableFields,
    );
  }

  /// Helper methods for field classification
  bool _isLocationComponent(
      String header, Set<String> values, String explicitType) {
    final lowerHeader = header.toLowerCase();
    final lowerType = explicitType.toLowerCase();

    // Check explicit field type first (more reliable)
    if (lowerType.contains('location')) {
      return true;
    }

    // Fallback to header name
    return lowerHeader.contains('موقع') || lowerHeader.contains('location');
  }

  bool _isSearchableField(String header, String explicitType) {
    final searchableKeywords = [
      'اسم',
      'عنوان',
      'مؤلف',
      'وصف',
      'title',
      'name',
      'author',
      'description'
    ];
    final lowerHeader = header.toLowerCase();
    return searchableKeywords.any((keyword) => lowerHeader.contains(keyword)) ||
        explicitType.contains('searchable');
  }

  bool _isCategoryField(String header) {
    final categoryKeywords = [
      'تصنيف',
      'فئة',
      'نوع',
      'category',
      'type',
      'genre'
    ];
    final lowerHeader = header.toLowerCase();
    return categoryKeywords.any((keyword) => lowerHeader.contains(keyword));
  }

  bool _isLocationField(String header) {
    final locationKeywords = ['موقع', 'مكان', 'location', 'place', 'position'];
    final lowerHeader = header.toLowerCase();
    return locationKeywords.any((keyword) => lowerHeader.contains(keyword));
  }

  bool _isAuthorField(String header) {
    final authorKeywords = ['مؤلف', 'كاتب', 'author', 'writer'];
    final lowerHeader = header.toLowerCase();
    return authorKeywords.any((keyword) => lowerHeader.contains(keyword));
  }

  LocationData? _handleLocationComponent(String header, Set<String> values,
      LocationData? existing, String explicitType) {
    final locationData =
        existing ?? LocationData(rows: [], columns: [], rooms: []);

    final lowerType = explicitType.toLowerCase();
    final lowerHeader = header.toLowerCase();

    // Use explicit field type to determine what kind of location data this is
    // Based on the test data:
    // - Field type "location row" -> store as rows
    // - Field type "location col" -> store as columns

    if (lowerType.contains('location row') || lowerType.contains('row')) {
      // This field contains the row identifiers (A, B, C, D, E)
      locationData.rows.addAll(values.where((v) => v.isNotEmpty));
      print(
          '   🗺️ Added ${values.length} rows from field "$header" (type: $explicitType): ${values.toList()}');
    } else if (lowerType.contains('location col') ||
        lowerType.contains('col')) {
      // This field contains the column identifiers (1, 2, 3, 4, 5, 6, 7, 8)
      locationData.columns.addAll(values.where((v) => v.isNotEmpty));
      print(
          '   🗺️ Added ${values.length} columns from field "$header" (type: $explicitType): ${values.toList()}');
    }
    // Room support
    else if (lowerType.contains('room') || lowerType.contains('غرفة')) {
      locationData.rooms.addAll(values.where((v) => v.isNotEmpty));
      print(
          '   🗺️ Added ${values.length} rooms from field "$header" (type: $explicitType): ${values.toList()}');
    }
    // Fallback to header-based detection
    else {
      if (lowerHeader.contains('عامود') || lowerHeader.contains('column')) {
        locationData.rows.addAll(values.where((v) => v.isNotEmpty));
        print(
            '   🗺️ Added ${values.length} rows from field "$header" (header-based): ${values.toList()}');
      } else if (lowerHeader.contains('صف') || lowerHeader.contains('row')) {
        locationData.columns.addAll(values.where((v) => v.isNotEmpty));
        print(
            '   🗺️ Added ${values.length} columns from field "$header" (header-based): ${values.toList()}');
      }
    }

    return locationData;
  }

  Map<String, dynamic> _determineFieldTypeAndFeatures(
      String header, Set<String> values, String explicitType) {
    FieldType type;
    List<FieldFeature> features = [];

    if (explicitType.isNotEmpty) {
      final parsed = _parseFieldTypeWithFeatures(explicitType);
      type = parsed['type'];
      features = parsed['features'];
    } else {
      type = _autoDetectFieldType(header, values);
    }

    return {
      'type': type,
      'features': features,
    };
  }

  FieldType _autoDetectFieldType(String header, Set<String> values) {
    // Simple auto-detection logic
    if (values.length > 1 && values.length < 20) {
      return FieldType.dropdown;
    } else if (values.length >= 20) {
      return FieldType.autocomplete;
    } else {
      return FieldType.text;
    }
  }

  Map<String, dynamic> _parseFieldTypeWithFeatures(String userInput) {
    final input = userInput.toLowerCase().trim();
    final features = <FieldFeature>[];
    String baseType = input;

    // Extract features
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

    if (input.contains('required') || input.contains('مطلوب')) {
      features.add(FieldFeature.required);
      baseType = baseType
          .replaceAll(RegExp(r'\s*required\s*'), ' ')
          .replaceAll('مطلوب', '')
          .trim();
    }

    FieldType normalizedType = _normalizeBaseFieldType(baseType);

    return {
      'type': normalizedType,
      'features': features,
    };
  }

  FieldType _normalizeBaseFieldType(String baseType) {
    switch (baseType.toLowerCase().trim()) {
      case 'dropdown':
      case 'قائمة':
        return FieldType.dropdown;
      case 'autocomplete':
      case 'إكمال_تلقائي':
        return FieldType.autocomplete;
      case 'text':
      case 'نص':
        return FieldType.text;
      case 'location':
      case 'location_compound':
      case 'موقع':
        return FieldType.locationCompound;
      default:
        return FieldType.text;
    }
  }

  /// Setup auto-refresh timer
  void _setupAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(hours: 6), // Refresh every 6 hours
      (_) => _loadFreshStructure(),
    );
  }

  /// Get fallback structure when sheets are unavailable
  EnhancedStructureData _getFallbackStructure() {
    final fallbackFields = [
      FieldConfig(
        name: 'اسم الكتاب',
        displayName: 'اسم الكتاب',
        type: FieldType.text,
        features: [FieldFeature.required],
        options: [],
        isDynamic: false,
        keySheetColumn: 'D',
      ),
      FieldConfig(
        name: 'اسم المؤلف',
        displayName: 'اسم المؤلف',
        type: FieldType.text,
        features: [FieldFeature.required],
        options: [],
        isDynamic: false,
        keySheetColumn: 'E',
      ),
      FieldConfig(
        name: 'التصنيف',
        displayName: 'التصنيف',
        type: FieldType.dropdown,
        features: [],
        options: ['الفقه', 'التفسير', 'الحديث', 'السيرة', 'العقيدة'],
        isDynamic: false,
        keySheetColumn: 'C',
      ),
    ];

    final fallbackLocation = LocationData(
      rows: ['1', '2', '3', '4', '5'],
      columns: ['A', 'B', 'C', 'D'],
      rooms: [],
    );

    final formStructure = FormStructure(
      fields: fallbackFields,
      locationData: fallbackLocation,
    );

    final browsingStructure = BrowsingStructure(
      categories: ['الفقه', 'التفسير', 'الحديث', 'السيرة', 'العقيدة'],
      locations: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'],
      authors: [],
      searchableFields: {
        'اسم الكتاب': [],
        'اسم المؤلف': [],
      },
    );

    return EnhancedStructureData(
      formStructure: formStructure,
      browsingStructure: browsingStructure,
      locationData: fallbackLocation,
      loadedAt: DateTime.now(),
      version: '1.0.0-fallback',
    );
  }

  /// Force refresh structure
  Future<void> refresh() async {
    await _loadFreshStructure();
  }

  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    _structureController.close();
  }
}

/// Providers for Riverpod integration
final sheetStructureServiceProvider = Provider<SheetStructureService>((ref) {
  return SheetStructureService();
});

final enhancedStructureProvider =
    FutureProvider<EnhancedStructureData?>((ref) async {
  final service = ref.read(sheetStructureServiceProvider);
  return await service.getStructure();
});

final formStructureProvider = FutureProvider<FormStructure?>((ref) async {
  final service = ref.read(sheetStructureServiceProvider);
  return await service.getFormStructure();
});

final browsingStructureProvider =
    FutureProvider<BrowsingStructure?>((ref) async {
  final service = ref.read(sheetStructureServiceProvider);
  return await service.getBrowsingStructure();
});

final locationDataProvider = FutureProvider<LocationData?>((ref) async {
  final service = ref.read(sheetStructureServiceProvider);
  return await service.getLocationData();
});

/// Stream provider for real-time structure updates
final structureStreamProvider = StreamProvider<EnhancedStructureData?>((ref) {
  final service = ref.read(sheetStructureServiceProvider);
  return service.structureStream;
});
