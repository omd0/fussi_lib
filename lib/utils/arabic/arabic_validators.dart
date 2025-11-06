import 'package:dartarabic/dartarabic.dart';
import 'arabic_formatters.dart';

/// Arabic text validation utilities.
/// 
/// This class provides validation functions specifically for Arabic text,
/// including column type detection, value validation, and pattern matching.
class ArabicValidators {
  // Arabic author patterns - handles various forms and diacritics
  static final RegExp _authorPattern = RegExp(
    r'مؤلف|المؤلف|اسم.*مؤلف|كاتب|الكاتب|author|writer',
    caseSensitive: false,
    unicode: true,
  );

  // Arabic category patterns
  static final RegExp _categoryPattern = RegExp(
    r'تصنيف|التصنيف|فئة|الفئة|نوع|النوع|category|type',
    caseSensitive: false,
    unicode: true,
  );

  // Arabic book name patterns
  static final RegExp _bookNamePattern = RegExp(
    r'كتاب|الكتاب|اسم.*كتاب|عنوان|العنوان|book.*name|title',
    caseSensitive: false,
    unicode: true,
  );

  // Arabic location patterns
  static final RegExp _locationPattern = RegExp(
    r'موقع|الموقع|مكان|المكان|location|place|position',
    caseSensitive: false,
    unicode: true,
  );

  // Arabic description patterns
  static final RegExp _descriptionPattern = RegExp(
    r'تعريف|التعريف|وصف|الوصف|ملخص|الملخص|description|summary',
    caseSensitive: false,
    unicode: true,
  );

  // Arabic volume/part number patterns
  static final RegExp _volumePattern = RegExp(
    r'جزء|الجزء|رقم.*جزء|مجلد|المجلد|volume|part',
    caseSensitive: false,
    unicode: true,
  );

  // Arabic restriction patterns
  static final RegExp _restrictionPattern = RegExp(
    r'ممنوع|منع|حظر|تقييد|restriction|prohibited|banned',
    caseSensitive: false,
    unicode: true,
  );

  // Arabic number patterns
  static final RegExp _numberPattern = RegExp(
    r'رقم|الرقم|عدد|العدد|number|num',
    caseSensitive: false,
    unicode: true,
  );

  /// Check if a header represents an author field.
  /// 
  /// Uses pattern matching to detect if a column header represents an author field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents an author field
  static bool isAuthorColumn(String header) {
    return _authorPattern.hasMatch(header);
  }

  /// Check if a header represents a category field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a category field
  static bool isCategoryColumn(String header) {
    return _categoryPattern.hasMatch(header);
  }

  /// Check if a header represents a book name field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a book name field
  static bool isBookNameColumn(String header) {
    return _bookNamePattern.hasMatch(header);
  }

  /// Check if a header represents a location field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a location field
  static bool isLocationColumn(String header) {
    return _locationPattern.hasMatch(header);
  }

  /// Check if a header represents a description field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a description field
  static bool isDescriptionColumn(String header) {
    return _descriptionPattern.hasMatch(header);
  }

  /// Check if a header represents a volume/part number field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a volume field
  static bool isVolumeColumn(String header) {
    return _volumePattern.hasMatch(header);
  }

  /// Check if a header represents a restriction field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a restriction field
  static bool isRestrictionColumn(String header) {
    final patterns = [
      'ممنوع',
      'مسموح',
      'إذن',
      'تصريح',
      'حظر',
      'منع',
      'restriction',
      'permission',
      'allowed',
      'forbidden',
      'ban',
      'permit',
      'access',
      'level',
      'مستوى',
      'درجة',
      'تقييد',
      'حالة',
      'status',
      'state',
    ];

    return _containsAnyPattern(header, patterns);
  }

  /// Check if a header represents a number field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a number field
  static bool isNumberColumn(String header) {
    final patterns = [
      'رقم',
      'عدد',
      'number',
      'num',
      '#',
      'id',
      'معرف',
      'كود',
      'code',
    ];

    return _containsAnyPattern(header, patterns);
  }

  /// Check if a header represents a date field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a date field
  static bool isDateColumn(String header) {
    final patterns = [
      'تاريخ',
      'يوم',
      'شهر',
      'سنة',
      'date',
      'time',
      'day',
      'month',
      'year',
      'وقت',
      'زمن',
    ];

    return _containsAnyPattern(header, patterns);
  }

  /// Check if a header represents a price/cost field.
  /// 
  /// Parameters:
  /// - [header]: The column header to check
  /// 
  /// Returns:
  /// - `true` if the header represents a price field
  static bool isPriceColumn(String header) {
    final patterns = [
      'سعر',
      'ثمن',
      'تكلفة',
      'مبلغ',
      'price',
      'cost',
      'amount',
      'value',
      'قيمة',
      'ريال',
      'دولار',
      'دينار',
    ];

    return _containsAnyPattern(header, patterns);
  }

  /// Helper method to check if header contains any of the given patterns.
  /// 
  /// Parameters:
  /// - [header]: The header to check
  /// - [patterns]: List of patterns to match against
  /// 
  /// Returns:
  /// - `true` if header matches any pattern
  static bool _containsAnyPattern(String header, List<String> patterns) {
    final normalizedHeader = ArabicFormatters.normalize(header.toLowerCase());

    for (final pattern in patterns) {
      final normalizedPattern = ArabicFormatters.normalize(pattern.toLowerCase());
      if (normalizedHeader.contains(normalizedPattern)) {
        return true;
      }
    }

    return false;
  }

  /// Validate author name.
  /// 
  /// Checks if an author name is valid (not empty, not placeholder values).
  /// 
  /// Parameters:
  /// - [name]: The author name to validate
  /// 
  /// Returns:
  /// - `true` if the author name is valid
  static bool isValidAuthorName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 2) return false;
    if (trimmed == '-' || trimmed == 'N/A' || trimmed == 'لا يوجد') {
      return false;
    }
    return true;
  }

  /// Check if a value should be considered as a valid option.
  /// 
  /// Filters out placeholder values and empty strings.
  /// 
  /// Parameters:
  /// - [value]: The value to check
  /// 
  /// Returns:
  /// - `true` if the value is a valid option
  static bool isValidOptionValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed == '-') return false;
    if (trimmed == 'N/A') return false;
    if (trimmed == 'لا يوجد') return false;
    if (trimmed == 'null') return false;
    if (trimmed.toLowerCase() == 'none') return false;
    return true;
  }
}

