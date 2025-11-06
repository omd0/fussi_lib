import 'package:flutter/material.dart';

class AppConstants {
  // Google Sheets Configuration
  static const String spreadsheetId =
      '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';
  static const String sheetRange = 'الفهرس!A:G';
  static const String keySheetRange = 'مفتاح!A:H';

  // Column mappings for main data sheet (الفهرس)
  static const int locationRowColumn = 0; // A - Library Location (Row)
  static const int locationColumnColumn = 1; // B - Library Location (Column)
  static const int categoryColumn = 2; // C - Category
  static const int bookNameColumn = 3; // D - Book Name
  static const int authorColumn = 4; // E - Author Name
  static const int volumeColumn = 5; // F - Volume Number
  static const int descriptionColumn = 6; // G - Brief Description

  // Colors
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1F2937);
  static const Color hintColor = Color(0xFF9CA3AF);

  // Arabic Categories (from Google Sheets structure)
  static const List<String> categories = [
    'علوم',
    'إسلاميات',
    'إنسانيات',
    'لغة وأدب',
    'أعمال وإدارة',
    'فنون',
    'ثقافة عامة',
    'روايات',
  ];

  // App Strings
  static const String appTitle = 'مكتبة فصي';
  static const String welcome = 'أهلاً وسهلاً في مكتبة بيت الفصي';
  static const String addBook = 'إضافة كتاب جديد';
  static const String viewLibrary = 'عرض المكتبة';
  static const String searchLibrary = 'البحث في المكتبة';

  // Form Labels
  static const String bookName = 'اسم الكتاب';
  static const String authorName = 'اسم المؤلف';
  static const String category = 'التصنيف';
  static const String libraryLocation = 'الموقع في المكتبة';
  static const String briefDescription = 'مختصر تعريفي';
  static const String submitButton = 'إضافة إلى المكتبة';

  // Messages
  static const String bookAddedSuccessfully = 'تم إضافة الكتاب بنجاح!';
  static const String errorAddingBook = 'حدث خطأ أثناء إضافة الكتاب';
  static const String fillAllFields = 'يرجى ملء جميع الحقول';

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Border Radius
  static const double borderRadius = 12.0;
}
