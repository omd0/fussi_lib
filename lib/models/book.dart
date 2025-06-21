class Book {
  final String bookName;
  final String authorName;
  final String category;
  final String libraryLocation;
  final String briefDescription;
  final String? barcode;

  Book({
    required this.bookName,
    required this.authorName,
    required this.category,
    required this.libraryLocation,
    required this.briefDescription,
    this.barcode,
  });

  // Convert to list for Google Sheets API
  List<String> toSheetRow() {
    return [
      libraryLocation, // Column A: Main location
      '', // Column B: Location details
      category, // Column C: Category
      bookName, // Column D: Book Name
      authorName, // Column E: Author Name
      '', // Column F: Part Number
      // Note: Column G (Brief Description) missing in data
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

  // Convert to Google Sheets row format (6 columns for data rows)
  List<String> toGoogleSheetsRow() {
    return [
      libraryLocation, // Column A: Main location (B, A, etc.)
      '', // Column B: Location details (5, etc.) - will be filled by user
      category, // Column C: Category
      bookName, // Column D: Book Name
      authorName, // Column E: Author Name
      '', // Column F: Part Number - will be filled by user
      // Note: Column G (Brief Description) is missing in actual data rows
    ];
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
  }) {
    return Book(
      bookName: bookName ?? this.bookName,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      libraryLocation: libraryLocation ?? this.libraryLocation,
      briefDescription: briefDescription ?? this.briefDescription,
      barcode: barcode ?? this.barcode,
    );
  }
}
