import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../constants/app_constants.dart';

/// Data model for sheet structure information
class SheetStructureData {
  final Map<String, List<String>> indexStructure; // من الفهرس
  final Map<String, Map<String, dynamic>> keyStructure; // من مفتاح
  final DateTime loadedAt;
  final String version;

  const SheetStructureData({
    required this.indexStructure,
    required this.keyStructure,
    required this.loadedAt,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
        'indexStructure': indexStructure,
        'keyStructure': keyStructure,
        'loadedAt': loadedAt.toIso8601String(),
        'version': version,
      };

  factory SheetStructureData.fromJson(Map<String, dynamic> json) {
    return SheetStructureData(
      indexStructure: Map<String, List<String>>.from(
        json['indexStructure']?.map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ) ??
            {},
      ),
      keyStructure: Map<String, Map<String, dynamic>>.from(
        json['keyStructure']?.map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
            ) ??
            {},
      ),
      loadedAt:
          DateTime.parse(json['loadedAt'] ?? DateTime.now().toIso8601String()),
      version: json['version'] ?? '1.0.0',
    );
  }

  bool get isExpired {
    final now = DateTime.now();
    final diff = now.difference(loadedAt);
    return diff.inHours > 24; // Structure expires after 24 hours
  }
}

/// Repository class for loading structure data from Google Sheets
class StructureRepository {
  /// Load structure data from Google Sheets
  Future<SheetStructureData> loadStructureFromSheets() async {
    print('🔄 Loading structure from Google Sheets...');

    try {
      // Initialize Google Sheets API
      final sheetsApi = await _initializeSheetsApi();

      // Load data from both sheets concurrently
      final results = await Future.wait([
        _loadIndexStructure(sheetsApi),
        _loadKeyStructure(sheetsApi),
      ]);

      final indexStructure = results[0] as Map<String, List<String>>;
      final keyStructure = results[1] as Map<String, Map<String, dynamic>>;

      final structureData = SheetStructureData(
        indexStructure: indexStructure,
        keyStructure: keyStructure,
        loadedAt: DateTime.now(),
        version: '1.0.0',
      );

      print('✅ Structure loaded successfully from Google Sheets');
      return structureData;
    } catch (e) {
      print('❌ Failed to load structure from Google Sheets: $e');

      // Fallback to default structure
      print('🔄 Using fallback structure');
      return _getFallbackStructure();
    }
  }

  /// Initialize Google Sheets API
  Future<SheetsApi> _initializeSheetsApi() async {
    final credentialsJson = await rootBundle
        .loadString('assets/credentials/service-account-key.json');
    final credentials =
        ServiceAccountCredentials.fromJson(json.decode(credentialsJson));

    final client = await clientViaServiceAccount(
      credentials,
      [SheetsApi.spreadsheetsScope],
    );

    return SheetsApi(client);
  }

  /// Load structure from الفهرس (Index) sheet - first row
  Future<Map<String, List<String>>> _loadIndexStructure(
      SheetsApi sheetsApi) async {
    print('📋 Loading index structure from "الفهرس" sheet...');

    try {
      final response = await sheetsApi.spreadsheets.values.get(
        AppConstants.spreadsheetId,
        'الفهرس!1:1', // First row only
      );

      if (response.values != null && response.values!.isNotEmpty) {
        final headers = response.values!.first
            .map((cell) => cell?.toString() ?? '')
            .toList();

        final structure = <String, List<String>>{};

        for (int i = 0; i < headers.length; i++) {
          final columnLetter = String.fromCharCode(65 + i); // A, B, C, etc.
          structure[columnLetter] = [headers[i]];
        }

        print('✅ Index structure loaded: ${structure.keys.join(', ')}');
        return structure;
      }

      return {};
    } catch (e) {
      print('❌ Failed to load index structure: $e');
      return {};
    }
  }

  /// Load structure from مفتاح (Key) sheet
  Future<Map<String, Map<String, dynamic>>> _loadKeyStructure(
      SheetsApi sheetsApi) async {
    print('🔑 Loading key structure from "مفتاح" sheet...');

    try {
      final response = await sheetsApi.spreadsheets.values.get(
        AppConstants.spreadsheetId,
        'مفتاح!A1:F50', // Extended range for key data
      );

      if (response.values != null && response.values!.isNotEmpty) {
        final keyData = response.values!
            .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
            .toList();

        return _parseKeyStructure(keyData);
      }

      return {};
    } catch (e) {
      print('❌ Failed to load key structure: $e');
      return _getFallbackKeyStructure();
    }
  }

  /// Parse key structure data
  Map<String, Map<String, dynamic>> _parseKeyStructure(
      List<List<String>> keyData) {
    final structure = <String, Map<String, dynamic>>{};

    if (keyData.isEmpty) return structure;

    // Parse categories
    final categories = <String>[];
    final locations = <String, List<String>>{
      'rows': <String>[],
      'columns': <String>[],
    };

    for (int i = 1; i < keyData.length; i++) {
      final row = keyData[i];

      if (row.length > 3 && row[3].trim().isNotEmpty) {
        categories.add(row[3].trim());
      }

      if (row.isNotEmpty && row[0].trim().isNotEmpty) {
        final rowValue = row[0].trim();
        if (RegExp(r'^[A-Z]$').hasMatch(rowValue)) {
          locations['rows']!.add(rowValue);
        }
      }

      if (row.length > 1 && row[1].trim().isNotEmpty) {
        final columnValue = row[1].trim();
        if (RegExp(r'^\d+$').hasMatch(columnValue)) {
          locations['columns']!.add(columnValue);
        }
      }
    }

    structure['categories'] = {
      'type': 'dropdown',
      'options': categories.toSet().toList()..sort(),
    };

    structure['locations'] = {
      'type': 'compound',
      'rows': locations['rows']!.toSet().toList()..sort(),
      'columns': locations['columns']!.toSet().toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b))),
    };

    print(
        '✅ Key structure parsed: ${categories.length} categories, ${locations['rows']!.length} rows, ${locations['columns']!.length} columns');

    return structure;
  }

  /// Get fallback structure when all else fails
  SheetStructureData _getFallbackStructure() {
    return SheetStructureData(
      indexStructure: {
        'A': ['الموقع في المكتبة'],
        'B': [''],
        'C': ['التصنيف'],
        'D': ['اسم الكتاب'],
        'E': ['اسم المؤلف'],
        'F': ['رقم الجزء'],
        'G': ['مختصر تعريفي'],
      },
      keyStructure: _getFallbackKeyStructure(),
      loadedAt: DateTime.now(),
      version: '1.0.0-fallback',
    );
  }

  /// Get fallback key structure
  Map<String, Map<String, dynamic>> _getFallbackKeyStructure() {
    return {
      'categories': {
        'type': 'dropdown',
        'options': [
          'علوم',
          'إسلاميات',
          'إنسانيات',
          'لغة وأدب',
          'أعمال وإدارة',
          'فنون',
          'ثقافة عامة',
          'روايات'
        ],
      },
      'locations': {
        'type': 'compound',
        'rows': ['A', 'B', 'C', 'D', 'E'],
        'columns': ['1', '2', '3', '4', '5', '6', '7', '8'],
      },
    };
  }
}

/// Provider for the structure repository
final structureRepositoryProvider = Provider<StructureRepository>((ref) {
  return StructureRepository();
});

/// Cached structure provider with auto-refresh and keepAlive
final cachedStructureProvider =
    FutureProvider.autoDispose<SheetStructureData>((ref) async {
  // Keep the data alive for 1 hour after last access
  final link = ref.keepAlive();

  // Auto-dispose after 1 hour of inactivity
  final timer = Timer(const Duration(hours: 1), () {
    link.close();
  });

  ref.onDispose(() => timer.cancel());

  // Get the structure data
  final repository = ref.watch(structureRepositoryProvider);
  final structureData = await repository.loadStructureFromSheets();

  return structureData;
});

/// Easy access provider for categories
final categoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final structure = await ref.watch(cachedStructureProvider.future);
  final categoriesData = structure.keyStructure['categories'];

  if (categoriesData != null && categoriesData['options'] is List) {
    return List<String>.from(categoriesData['options']);
  }

  return <String>[];
});

/// Easy access provider for locations
final locationsProvider =
    FutureProvider.autoDispose<Map<String, List<String>>>((ref) async {
  final structure = await ref.watch(cachedStructureProvider.future);
  final locationsData = structure.keyStructure['locations'];

  if (locationsData != null) {
    return {
      'rows': List<String>.from(locationsData['rows'] ?? []),
      'columns': List<String>.from(locationsData['columns'] ?? []),
    };
  }

  return {'rows': <String>[], 'columns': <String>[]};
});

/// Easy access provider for column headers
final columnHeadersProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final structure = await ref.watch(cachedStructureProvider.future);

  final headers = <String, String>{};
  structure.indexStructure.forEach((key, value) {
    if (value.isNotEmpty) {
      headers[key] = value.first;
    }
  });

  return headers;
});

/// Provider for refreshing structure data
final structureRefreshProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(cachedStructureProvider);
  };
});
