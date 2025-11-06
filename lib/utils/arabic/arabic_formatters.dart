import 'package:dartarabic/dartarabic.dart';

/// Arabic text formatting utilities.
/// 
/// This class provides formatting functions for Arabic text,
/// including normalization, cleaning, and text transformation.
class ArabicFormatters {
  /// Normalize Arabic text for better matching using the dartarabic package.
  /// 
  /// This function performs comprehensive normalization:
  /// - Strips all diacritics (Tashkeel)
  /// - Normalizes Alef variations to a single Alef
  /// - Normalizes Teh Marbuta to Heh
  /// - Normalizes Alef Maqsurah to Yeh
  /// - Removes Tatweel (character elongation)
  /// 
  /// Parameters:
  /// - [text]: The text to normalize
  /// 
  /// Returns:
  /// - Normalized Arabic text string
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

  /// Normalize Arabic text (simplified version).
  /// 
  /// This is a simpler normalization that handles basic transformations:
  /// - Converts ي to ى
  /// - Converts ة to ه
  /// - Removes diacritics
  /// 
  /// Parameters:
  /// - [text]: The text to normalize
  /// 
  /// Returns:
  /// - Normalized Arabic text string
  static String normalizeArabicText(String text) {
    return text
        .replaceAll('ي', 'ى')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[ًٌٍَُِّْ]'), '') // Remove diacritics
        .trim();
  }

  /// Clean Arabic text by removing unwanted characters.
  /// 
  /// Removes all characters except Arabic letters, basic ASCII,
  /// and whitespace.
  /// 
  /// Parameters:
  /// - [text]: The text to clean
  /// 
  /// Returns:
  /// - Cleaned Arabic text string
  static String cleanArabicText(String text) {
    return text
        .replaceAll(RegExp(r'[^\u0600-\u06FF\u0020-\u007E\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Remove common Arabic words that don't add meaning.
  /// 
  /// Removes common stop words from Arabic and English text.
  /// 
  /// Parameters:
  /// - [text]: The text to process
  /// 
  /// Returns:
  /// - Text with common words removed
  static String removeCommonWords(String text) {
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
      'by',
    ];

    String cleaned = text;
    for (final word in commonWords) {
      cleaned = cleaned.replaceAll(word, ' ');
    }

    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Sort options with Arabic text consideration.
  /// 
  /// Sorts a list of options with Arabic text appearing first,
  /// followed by English text.
  /// 
  /// Parameters:
  /// - [options]: List of options to sort
  /// 
  /// Returns:
  /// - Sorted list with Arabic options first
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

  /// Check if text contains Arabic characters.
  /// 
  /// Parameters:
  /// - [text]: The text to check
  /// 
  /// Returns:
  /// - `true` if the text contains Arabic characters
  static bool containsArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }
}

