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
      return true;
    } catch (e) {
      _lastError = 'Failed to initialize: $e';
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

      return true;
    } catch (e) {
      _lastError = 'Failed to add book: $e';
      return false;
    }
  }

  // Get all books from the sheet with timeout and error handling
  Future<List<List<String>>?> getAllBooks() async {
    try {
      if (_sheetsApi == null) {
        final initialized = await initialize();
        if (!initialized) {
          return null;
        }
      }

      final response = await _sheetsApi!.spreadsheets.values
          .get(AppConstants.spreadsheetId, AppConstants.sheetRange)
          .timeout(const Duration(seconds: 30));

      if (response.values != null && response.values!.isNotEmpty) {
        return response.values!
            .map((row) =>
                List<String>.from(row.map((cell) => cell?.toString() ?? '')))
            .toList();
      } else {
        return [];
      }
    } on TimeoutException catch (e) {
      _lastError = 'انتهت مهلة الاتصال - تحقق من الإنترنت';
      return null;
    } catch (e) {
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
      _lastError = 'Connection test failed: $e';
      return false;
    }
  }

  // Check if credentials exist
  static Future<bool> credentialsExist() async {
    try {
      await rootBundle.load('assets/credentials/service-account-key.json');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get last error for debugging
  String? _lastError;
  String? get lastError => _lastError;

  void _setError(String error) {
    _lastError = error;
  }
}
