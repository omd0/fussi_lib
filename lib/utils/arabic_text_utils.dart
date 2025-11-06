import 'package:dartarabic/dartarabic.dart';
import 'dart:math' as math;

/// Utility class for handling Arabic text patterns and matching
class ArabicTextUtils {
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

  /// Check if a header represents an author field
  static bool isAuthorColumn(String header) {
    return _authorPattern.hasMatch(header);
  }

  /// Check if a header represents a category field
  static bool isCategoryColumn(String header) {
    return _categoryPattern.hasMatch(header);
  }

  /// Check if a header represents a book name field
  static bool isBookNameColumn(String header) {
    return _bookNamePattern.hasMatch(header);
  }

  /// Check if a header represents a location field
  static bool isLocationColumn(String header) {
    return _locationPattern.hasMatch(header);
  }

  /// Check if a header represents a description field
  static bool isDescriptionColumn(String header) {
    return _descriptionPattern.hasMatch(header);
  }

  /// Check if a header represents a volume/part number field
  static bool isVolumeColumn(String header) {
    return _volumePattern.hasMatch(header);
  }

  /// Check if a header represents a restriction field
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
      'state'
    ];

    return _containsAnyPattern(header, patterns);
  }

  /// Check if a header represents a number field
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
      'code'
    ];

    return _containsAnyPattern(header, patterns);
  }

  /// Check if a column header indicates a date field
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
      'زمن'
    ];

    return _containsAnyPattern(header, patterns);
  }

  /// Check if a column header indicates a price/cost field
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
      'دينار'
    ];

    return _containsAnyPattern(header, patterns);
  }

  /// Helper method to check if header contains any of the given patterns
  static bool _containsAnyPattern(String header, List<String> patterns) {
    final normalizedHeader = normalize(header.toLowerCase());

    for (final pattern in patterns) {
      final normalizedPattern = normalize(pattern.toLowerCase());
      if (normalizedHeader.contains(normalizedPattern)) {
        return true;
      }
    }

    return false;
  }

  /// Normalize Arabic text for better matching using the dartarabic package
  static String normalize(String text) {
    // 1. Strip all diacritics (Tashkeel)
    String normalized = DartArabic.stripTashkeel(text);

    // 2. Normalize Alef variations to a single Alef
    normalized = DartArabic.normalizeAlef(normalized);

    // 3. Normalize Teh Marbuta to Heh
    normalized = normalized.replaceAll('ة', 'ه');

    // 4. Normalize Alef Maqsurah to Yeh (more standard for search)
    normalized = normalized.replaceAll('ى', 'ي');

    // 5. Remove Tatweel (character elongation)
    normalized = DartArabic.stripTatweel(normalized);

    return normalized.trim();
  }

  /// Check if two Arabic texts match with normalization
  static bool arabicTextMatches(String text1, String text2) {
    final normalized1 = normalize(text1.toLowerCase());
    final normalized2 = normalize(text2.toLowerCase());

    return normalized1.contains(normalized2) ||
        normalized2.contains(normalized1);
  }

  /// Enhanced Arabic text search using Levenshtein distance for fuzzy matching.
  /// Returns true if the edit distance is within an acceptable threshold.
  static bool arabicFuzzyMatch(String text, String query) {
    if (query.isEmpty) return true;
    if (text.isEmpty) return false;

    final normalizedText = normalize(text.toLowerCase());
    final normalizedQuery = normalize(query.toLowerCase());

    // Allow more typos for longer queries
    final int maxDistance = normalizedQuery.length > 7 ? 3 : 2;

    // If the query is a substring, it's a definite match.
    if (normalizedText.contains(normalizedQuery)) {
      return true;
    }

    final distance = _levenshtein(normalizedText, normalizedQuery, maxDistance);

    return distance <= maxDistance;
  }

  /// Calculates the Levenshtein distance between two strings.
  /// An optimized version that returns early if maxDistance is exceeded.
  static int _levenshtein(String a, String b, int maxDistance) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length <= maxDistance ? b.length : maxDistance + 1;
    if (b.isEmpty) return a.length <= maxDistance ? a.length : maxDistance + 1;

    final aLength = a.length;
    final bLength = b.length;

    // The previous row of distances
    var v0 = List<int>.generate(bLength + 1, (i) => i, growable: false);
    // The current row of distances
    var v1 = List<int>.generate(bLength + 1, (i) => 0, growable: false);

    for (int i = 0; i < aLength; i++) {
      v1[0] = i + 1;
      int minV1 = v1[0];

      for (int j = 0; j < bLength; j++) {
        final cost = (a[i] == b[j]) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
        minV1 = math.min(minV1, v1[j + 1]);
      }

      if (minV1 > maxDistance) {
        return maxDistance + 1;
      }

      // Swap v1 and v0
      var vtemp = v0;
      v0 = v1;
      v1 = vtemp;
    }

    return v0[bLength];
  }

  /// Get common Arabic restriction values
  static List<String> getCommonRestrictionValues() {
    return [
      'ممنوع',
      'لا ينصح بالقراءة إلا لغرض النقد',
      'ﻷهل التخصص',
      'مسموح',
      'للجميع',
      'محدود',
      'للبالغين فقط',
    ];
  }

  /// Remove common Arabic words that don't add meaning
  static String _removeCommonWords(String text) {
    final commonWords = [
      'في',
      'من',
      'إلى',
      'على',
      'عن',
      'مع',
      'بين',
      'تحت',
      'فوق',
      'أمام',
      'خلف',
      'يمين',
      'يسار',
      'داخل',
      'خارج',
      'حول',
      'ضد',
      'the',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by'
    ];

    String cleaned = text;
    for (final word in commonWords) {
      cleaned = cleaned.replaceAll(word, ' ');
    }

    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Arabic text processing utilities
  static String normalizeArabicText(String text) {
    return text
        .replaceAll('ي', 'ى')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '') // Remove diacritics
        .trim();
  }

  static bool containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  static String cleanArabicText(String text) {
    return text
        .replaceAll(RegExp(r'[^\u0600-\u06FF\u0020-\u007E\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Enhanced field type detection based on key sheet analysis
  static String suggestFieldType(String header, Set<String> values) {
    final cleanHeader = normalizeArabicText(header.toLowerCase());
    final validValues = values.where((v) => v.trim().isNotEmpty).toSet();

    print('   🔍 Analyzing "$header" with ${validValues.length} values');

    // Location components - handle specially
    if (_isLocationComponent(cleanHeader, validValues)) {
      print('     🗺️ Location component detected');
      return 'location_component';
    }

    // Author fields - always autocomplete for better UX
    if (isAuthorColumn(header)) {
      print('     👤 Author field -> autocomplete');
      return 'autocomplete';
    }

    // Title/name fields - usually autocomplete for better search
    if (_isTitleColumn(cleanHeader)) {
      print('     📖 Title field -> autocomplete');
      return 'autocomplete';
    }

    // ملاحظة (Notes) should always be autocomplete for better UX
    if (header.contains('ملاحظة')) {
      print('     📝 Notes field (ملاحظة) -> autocomplete');
      return 'autocomplete';
    }

    // Other restriction fields - usually dropdown with predefined values
    if (_isRestrictionColumn(cleanHeader)) {
      print('     ⚠️ Restriction field -> dropdown');
      return 'dropdown';
    }

    // Publisher/category fields - dropdown if limited options
    if (_isPublisherOrCategoryColumn(cleanHeader)) {
      if (validValues.length <= 15) {
        print(
            '     🏢 Publisher/Category field -> dropdown (${validValues.length} options)');
        return 'dropdown';
      } else {
        print(
            '     🏢 Publisher/Category field -> autocomplete (${validValues.length} options)');
        return 'autocomplete';
      }
    }

    // Numeric fields - usually text input
    if (_isNumericColumn(cleanHeader, validValues)) {
      print('     🔢 Numeric field -> text');
      return 'text';
    }

    // Date/year fields - text input
    if (_isDateColumn(cleanHeader)) {
      print('     📅 Date field -> text');
      return 'text';
    }

    // General rule: small option sets = dropdown, large = autocomplete
    if (validValues.length <= 1) {
      print('     📝 Single/no values -> text');
      return 'text';
    } else if (validValues.length <= 10) {
      print(
          '     📋 Small option set -> dropdown (${validValues.length} options)');
      return 'dropdown';
    } else {
      print(
          '     🔍 Large option set -> autocomplete (${validValues.length} options)');
      return 'autocomplete';
    }
  }

  // Check if header indicates a title/name column
  static bool _isTitleColumn(String header) {
    return header.contains('اسم') ||
        header.contains('عنوان') ||
        header.contains('title') ||
        header.contains('name') ||
        header.contains('كتاب');
  }

  // Check if header indicates a restriction/notes column
  static bool _isRestrictionColumn(String header) {
    return header.contains('ملاحظة') ||
        header.contains('ممنوع') ||
        header.contains('تقييد') ||
        header.contains('restriction') ||
        header.contains('note') ||
        header.contains('comment');
  }

  // Check if header indicates publisher or category
  static bool _isPublisherOrCategoryColumn(String header) {
    return header.contains('ناشر') ||
        header.contains('موضوع') ||
        header.contains('فئة') ||
        header.contains('قسم') ||
        header.contains('تصنيف') ||
        header.contains('نوع') ||
        header.contains('publisher') ||
        header.contains('category') ||
        header.contains('subject') ||
        header.contains('topic') ||
        header.contains('classification');
  }

  // Check if column contains numeric data
  static bool _isNumericColumn(String header, Set<String> values) {
    if (header.contains('رقم') ||
        header.contains('number') ||
        header.contains('id')) {
      return true;
    }

    // Check if most values are numeric
    final numericValues =
        values.where((v) => RegExp(r'^\d+$').hasMatch(v.trim()));
    return numericValues.length > values.length * 0.7; // 70% numeric
  }

  // Check if column contains date/year data
  static bool _isDateColumn(String header) {
    return header.contains('سنة') ||
        header.contains('تاريخ') ||
        header.contains('year') ||
        header.contains('date') ||
        header.contains('time');
  }

  // Check if column is a location component
  static bool _isLocationComponent(String header, Set<String> values) {
    // Check header patterns
    if (header.contains('صف') ||
        header.contains('row') ||
        header.contains('عامود') ||
        header.contains('عمود') ||
        header.contains('column')) {
      return true;
    }

    // Check value patterns - if all values are single letters or numbers
    final allSingleLetters =
        values.every((v) => RegExp(r'^[A-Z]$').hasMatch(v));
    final allNumbers = values.every((v) => RegExp(r'^\d+$').hasMatch(v));

    return allSingleLetters || allNumbers;
  }

  // Validate author name
  static bool isValidAuthorName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length < 2) return false;
    if (trimmed == '-' || trimmed == 'N/A' || trimmed == 'لا يوجد')
      return false;
    return true;
  }

  // Check if two headers match (flexible matching)
  static bool headersMatch(String header1, String header2) {
    final clean1 = normalizeArabicText(header1.toLowerCase());
    final clean2 = normalizeArabicText(header2.toLowerCase());

    // Exact match
    if (clean1 == clean2) return true;

    // Contains match for key terms
    final keyTerms1 = _extractKeyTerms(clean1);
    final keyTerms2 = _extractKeyTerms(clean2);

    return keyTerms1.any((term) => keyTerms2.contains(term));
  }

  // Extract key terms from header
  static Set<String> _extractKeyTerms(String header) {
    final terms = <String>{};

    // Common Arabic terms
    if (header.contains('مؤلف')) terms.add('مؤلف');
    if (header.contains('كتاب')) terms.add('كتاب');
    if (header.contains('اسم')) terms.add('اسم');
    if (header.contains('ناشر')) terms.add('ناشر');
    if (header.contains('موضوع')) terms.add('موضوع');
    if (header.contains('سنة')) terms.add('سنة');
    if (header.contains('رقم')) terms.add('رقم');
    if (header.contains('ملاحظة')) terms.add('ملاحظة');

    // Common English terms
    if (header.contains('author')) terms.add('author');
    if (header.contains('title')) terms.add('title');
    if (header.contains('publisher')) terms.add('publisher');
    if (header.contains('subject')) terms.add('subject');
    if (header.contains('year')) terms.add('year');
    if (header.contains('number')) terms.add('number');
    if (header.contains('note')) terms.add('note');

    return terms;
  }

  // Enhanced search functionality for Arabic text
  static bool matchesSearchQuery(String text, String query) {
    if (query.isEmpty) return true;

    final normalizedText = normalizeArabicText(text.toLowerCase());
    final normalizedQuery = normalizeArabicText(query.toLowerCase());

    // Direct substring match
    if (normalizedText.contains(normalizedQuery)) return true;

    // Word-by-word match
    final textWords = normalizedText.split(' ');
    final queryWords = normalizedQuery.split(' ');

    return queryWords.every((queryWord) =>
        textWords.any((textWord) => textWord.contains(queryWord)));
  }

  // Sort options with Arabic text consideration
  static List<String> sortArabicOptions(List<String> options) {
    return options
      ..sort((a, b) {
        // Arabic text should come first, then English
        final aHasArabic = containsArabic(a);
        final bHasArabic = containsArabic(b);

        if (aHasArabic && !bHasArabic) return -1;
        if (!aHasArabic && bHasArabic) return 1;

        // Both same type, sort alphabetically
        return a.compareTo(b);
      });
  }

  // Get field type icon for UI
  static String getFieldTypeIcon(String fieldType) {
    switch (fieldType) {
      case 'dropdown':
        return '📋';
      case 'autocomplete':
        return '🔍';
      case 'location_compound':
        return '🗺️';
      case 'location_component':
        return '📍';
      case 'text':
      default:
        return '📝';
    }
  }

  // Check if a value should be considered as a valid option
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
