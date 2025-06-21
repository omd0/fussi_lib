import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/book.dart';
import '../constants/app_constants.dart';

class GoogleSheetsService {
  SheetsApi? _sheetsApi;
  bool _isInitialized = false;
  static const Duration _timeout = Duration(seconds: 30);

  // Initialize the service with credentials
  Future<bool> initialize() async {
    try {
      // Load credentials from assets
      final credentialsJson = await rootBundle
          .loadString('assets/credentials/service-account-key.json')
          .timeout(_timeout);
      final credentials =
          ServiceAccountCredentials.fromJson(json.decode(credentialsJson));

      // Create authenticated client
      final client = await clientViaServiceAccount(
        credentials,
        [SheetsApi.spreadsheetsScope],
      ).timeout(_timeout);

      _sheetsApi = SheetsApi(client);
      _isInitialized = true;
      print('Google Sheets service initialized successfully');
      return true;
    } catch (e) {
      print('Failed to initialize Google Sheets service: $e');
      if (e is TimeoutException) {
        print('Timeout while initializing Google Sheets service');
      }
      return false;
    }
  }

  // Add a book to the Google Sheet
  Future<bool> addBook(Book book) async {
    if (!_isInitialized || _sheetsApi == null) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      final values = ValueRange(
        values: [book.toSheetRow()],
      );

      await _sheetsApi!.spreadsheets.values
          .append(
            values,
            AppConstants.spreadsheetId,
            AppConstants.sheetRange,
            valueInputOption: 'RAW',
          )
          .timeout(_timeout);

      print('Book added successfully to Google Sheets');
      return true;
    } catch (e) {
      print('Failed to add book: $e');
      if (e is TimeoutException) {
        print('Timeout while adding book to Google Sheets');
      }
      return false;
    }
  }

  // Get all books from the sheet with timeout and error handling
  Future<List<List<String>>?> getAllBooks() async {
    try {
      print('🔍 DEBUG: Starting getAllBooks()');
      print('🔍 DEBUG: Spreadsheet ID: ${AppConstants.spreadsheetId}');
      print('🔍 DEBUG: Range: ${AppConstants.sheetRange}');

      if (_sheetsApi == null) {
        print('❌ DEBUG: Sheets API is null, initializing...');
        final initialized = await initialize();
        if (!initialized) {
          print('❌ DEBUG: Failed to initialize Sheets API');
          return null;
        }
        print('✅ DEBUG: Sheets API initialized successfully');
      }

      print('🔄 DEBUG: Making API call to get values...');
      final response = await _sheetsApi!.spreadsheets.values
          .get(AppConstants.spreadsheetId, AppConstants.sheetRange)
          .timeout(const Duration(seconds: 30));

      print('📊 DEBUG: API Response received');
      print('📊 DEBUG: Response values type: ${response.values?.runtimeType}');
      print('📊 DEBUG: Response values length: ${response.values?.length}');

      if (response.values != null && response.values!.isNotEmpty) {
        print('✅ DEBUG: Found ${response.values!.length} rows');

        // Log first few rows for debugging
        for (int i = 0; i < response.values!.length && i < 3; i++) {
          final row = response.values![i];
          print('📝 DEBUG: Row $i (${row.length} columns): ${row.join(' | ')}');
        }

        return response.values!
            .map((row) =>
                List<String>.from(row.map((cell) => cell?.toString() ?? '')))
            .toList();
      } else {
        print('⚠️ DEBUG: No data found in response');
        return [];
      }
    } on TimeoutException catch (e) {
      print('⏰ DEBUG: Timeout error: $e');
      _lastError = 'انتهت مهلة الاتصال - تحقق من الإنترنت';
      return null;
    } catch (e) {
      print('❌ DEBUG: Error in getAllBooks: $e');
      print('❌ DEBUG: Error type: ${e.runtimeType}');
      _lastError = e.toString();
      return null;
    }
  }

  // Test connection to Google Sheets
  Future<bool> testConnection() async {
    try {
      if (!_isInitialized || _sheetsApi == null) {
        final initialized = await initialize();
        if (!initialized) return false;
      }

      // Try to get just the first row to test connection
      await _sheetsApi!.spreadsheets.values
          .get(
            AppConstants.spreadsheetId,
            'A1:A1',
          )
          .timeout(const Duration(seconds: 10));

      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // Check if credentials exist
  static Future<bool> credentialsExist() async {
    try {
      await rootBundle.load('assets/credentials/service-account-key.json');
      return true;
    } catch (e) {
      print('Credentials file not found: $e');
      return false;
    }
  }

  // Get last error for debugging
  String? _lastError;
  String? get lastError => _lastError;

  void _setError(String error) {
    _lastError = error;
    print('GoogleSheetsService Error: $error');
  }
}
