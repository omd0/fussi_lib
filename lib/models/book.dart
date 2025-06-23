class Book {
  final String bookName;
  final String authorName;
  final String category;
  final String libraryLocation;
  final String briefDescription;
  final String? barcode;
  final String? volumeNumber;

  Book({
    required this.bookName,
    required this.authorName,
    required this.category,
    required this.libraryLocation,
    required this.briefDescription,
    this.barcode,
    this.volumeNumber,
  });

  // Convert to list for Google Sheets API - matches exact structure
  List<String> toSheetRow() {
    // Parse location into Row and Column if format is like "A1", "B2", etc.
    String locationRow = '';
    String locationColumn = '';

    if (libraryLocation.isNotEmpty) {
      // Try to parse location like "A1" or "B2"
      final match = RegExp(r'^([A-Z])(\d+)$').firstMatch(libraryLocation);
      if (match != null) {
        locationRow = match.group(1)!;
        locationColumn = match.group(2)!;
      } else {
        // If not in expected format, put the whole location in Row
        locationRow = libraryLocation;
      }
    }

    return [
      locationRow, // Column A: Library Location (Row)
      locationColumn, // Column B: Library Location (Column)
      category, // Column C: Category
      bookName, // Column D: Book Name
      authorName, // Column E: Author Name
      volumeNumber ?? '', // Column F: Volume Number
      briefDescription, // Column G: Brief Description
    ];
  }

  // Create from form data
  static Book fromForm({
    required String bookName,
    required String authorName,
    required String category,
    required String libraryLocation,
    required String briefDescription,
  }) {
    return Book(
      bookName: bookName.trim(),
      authorName: authorName.trim(),
      category: category,
      libraryLocation: libraryLocation.trim(),
      briefDescription: briefDescription.trim(),
    );
  }

  // Validation
  bool isValid() {
    return bookName.isNotEmpty &&
        authorName.isNotEmpty &&
        category.isNotEmpty &&
        libraryLocation.isNotEmpty &&
        briefDescription.isNotEmpty;
  }

  // Validation
  String? validate() {
    if (bookName.trim().isEmpty) {
      return 'اسم الكتاب مطلوب';
    }
    if (authorName.trim().isEmpty) {
      return 'اسم المؤلف مطلوب';
    }
    if (category.trim().isEmpty) {
      return 'التصنيف مطلوب';
    }
    if (libraryLocation.trim().isEmpty) {
      return 'موقع الكتاب في المكتبة مطلوب';
    }
    return null;
  }

  // Convert to Google Sheets row format - DEPRECATED: Use toSheetRow() instead
  @deprecated
  List<String> toGoogleSheetsRow() {
    return toSheetRow(); // Use the updated method
  }

  // Convert to Map for local database
  Map<String, dynamic> toMap() {
    return {
      'book_name': bookName,
      'author_name': authorName,
      'category': category,
      'library_location': libraryLocation,
      'brief_description': briefDescription,
      'barcode': barcode,
      'volume_number': volumeNumber,
    };
  }

  // Create from Map
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      bookName: map['book_name'] ?? '',
      authorName: map['author_name'] ?? '',
      category: map['category'] ?? '',
      libraryLocation: map['library_location'] ?? '',
      briefDescription: map['brief_description'] ?? '',
      barcode: map['barcode'],
      volumeNumber: map['volume_number'],
    );
  }

  // Create copy with modifications
  Book copyWith({
    String? bookName,
    String? authorName,
    String? category,
    String? libraryLocation,
    String? briefDescription,
    String? barcode,
    String? volumeNumber,
  }) {
    return Book(
      bookName: bookName ?? this.bookName,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      libraryLocation: libraryLocation ?? this.libraryLocation,
      briefDescription: briefDescription ?? this.briefDescription,
      barcode: barcode ?? this.barcode,
      volumeNumber: volumeNumber ?? this.volumeNumber,
    );
  }
}
