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

/// Represents a row in the Google Sheets key sheet
class KeySheetRow {
  final int rowIndex;
  final Map<String, String> values;

  KeySheetRow({
    required this.rowIndex,
    required this.values,
  });

  /// Get value for a specific column header
  String getValue(String header) => values[header] ?? '';

  /// Check if this row has any non-empty values
  bool get hasData => values.values.any((value) => value.trim().isNotEmpty);

  /// Get all non-empty values
  List<String> get nonEmptyValues =>
      values.values.where((value) => value.trim().isNotEmpty).toList();

  factory KeySheetRow.fromRawData(
      int rowIndex, List<String> headers, List<String> rowData) {
    final values = <String, String>{};

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].trim();
      final value = i < rowData.length ? rowData[i].trim() : '';
      if (header.isNotEmpty) {
        values[header] = value;
      }
    }

    return KeySheetRow(rowIndex: rowIndex, values: values);
  }
}

/// Represents the complete key sheet structure
class KeySheetData {
  final List<String> headers;
  final List<String> fieldTypes;
  final List<KeySheetRow> dataRows;

  KeySheetData({
    required this.headers,
    required this.fieldTypes,
    required this.dataRows,
  });

  /// Get all unique values for a specific column
  Set<String> getColumnValues(String header) {
    final values = <String>{};
    for (final row in dataRows) {
      final value = row.getValue(header);
      if (_isValidValue(value)) {
        values.add(value);
      }
    }
    return values;
  }

  /// Get field type for a specific header
  String getFieldType(String header) {
    final index = headers.indexOf(header);
    if (index >= 0 && index < fieldTypes.length) {
      return fieldTypes[index].trim();
    }
    return '';
  }

  /// Check if a header exists
  bool hasHeader(String header) => headers.contains(header);

  /// Get non-empty headers
  List<String> get nonEmptyHeaders =>
      headers.where((header) => header.trim().isNotEmpty).toList();

  bool _isValidValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed == '-') return false;
    if (trimmed == 'N/A') return false;
    if (trimmed == 'لا يوجد') return false;
    if (trimmed == 'null') return false;
    if (trimmed.toLowerCase() == 'none') return false;
    return true;
  }

  factory KeySheetData.fromRawData(List<List<String>> rawData) {
    if (rawData.length < 2) {
      throw ArgumentError(
          'Key sheet must have at least 2 rows (headers + field types)');
    }

    final headers = rawData[0].map((h) => h.toString().trim()).toList();
    final fieldTypes = rawData.length > 1
        ? rawData[1].map((t) => t.toString().trim()).toList()
        : <String>[];

    final dataRows = <KeySheetRow>[];
    for (int i = 2; i < rawData.length; i++) {
      final rowData = rawData[i].map((cell) => cell.toString()).toList();
      final row = KeySheetRow.fromRawData(i, headers, rowData);
      if (row.hasData) {
        dataRows.add(row);
      }
    }

    return KeySheetData(
      headers: headers,
      fieldTypes: fieldTypes,
      dataRows: dataRows,
    );
  }
}

/// Represents location data extracted from key sheet
class LocationData {
  final List<String> rows;
  final List<String> columns;

  LocationData({
    required this.rows,
    required this.columns,
  });

  bool get isComplete => rows.isNotEmpty && columns.isNotEmpty;

  /// Generate all possible location combinations
  List<String> generateCombinations() {
    final combinations = <String>[];
    for (final row in rows) {
      for (final column in columns) {
        combinations.add('$row$column');
      }
    }
    return combinations..sort();
  }
}

/// Represents field configuration for form generation
class FieldConfig {
  final String name;
  final String displayName;
  final FieldType type;
  final List<FieldFeature> features;
  final List<String> options;
  final bool isDynamic;
  final String? keySheetColumn;

  FieldConfig({
    required this.name,
    required this.displayName,
    required this.type,
    this.features = const [],
    this.options = const [],
    this.isDynamic = false,
    this.keySheetColumn,
  });

  /// Check if this field has a specific feature
  bool hasFeature(FieldFeature feature) => features.contains(feature);

  /// Get display type with features for debugging
  String get displayType {
    if (features.isEmpty) return type.name;
    return '${type.name} ${features.map((f) => f.name).join(' ')}';
  }

  /// Check if this is a location field
  bool get isLocationField => type == FieldType.locationCompound;

  /// Check if this field supports autocomplete
  bool get supportsAutocomplete => type == FieldType.autocomplete;

  /// Check if this field supports dropdown
  bool get supportsDropdown => type == FieldType.dropdown;

  /// Check if this field supports adding new options
  bool get supportsAddNew => hasFeature(FieldFeature.plus);

  /// Check if this field is required
  bool get isRequired => hasFeature(FieldFeature.required);

  /// Check if this field is read-only
  bool get isReadOnly => hasFeature(FieldFeature.readonly);

  /// Check if this field is hidden
  bool get isHidden => hasFeature(FieldFeature.hidden);

  /// Check if this field is searchable
  bool get isSearchable => hasFeature(FieldFeature.searchable);

  /// Check if this field is sortable
  bool get isSortable => hasFeature(FieldFeature.sortable);

  /// Check if this field is filterable
  bool get isFilterable => hasFeature(FieldFeature.filterable);

  /// Check if this field must be unique
  bool get isUnique => hasFeature(FieldFeature.unique);

  /// Check if this field is encrypted
  bool get isEncrypted => hasFeature(FieldFeature.encrypted);

  /// Check if this field is cached
  bool get isCached => hasFeature(FieldFeature.cached);

  /// Check if this field has custom validation
  bool get hasValidation => hasFeature(FieldFeature.validated);

  /// Check if this field has custom formatting
  bool get hasFormatting => hasFeature(FieldFeature.formatted);

  /// Check if this field is conditional
  bool get isConditional => hasFeature(FieldFeature.conditional);

  /// Check if this field is calculated
  bool get isCalculated => hasFeature(FieldFeature.calculated);

  /// Check if this field is indexed
  bool get isIndexed => hasFeature(FieldFeature.indexed);

  /// Check if this field supports localization
  bool get isLocalized => hasFeature(FieldFeature.localized);

  /// Check if this field is versioned
  bool get isVersioned => hasFeature(FieldFeature.versioned);

  /// Check if this field is audited
  bool get isAudited => hasFeature(FieldFeature.audited);

  /// Check if this field supports rich text
  bool get isRichText => hasFeature(FieldFeature.rich);

  /// Check if this field has preview
  bool get hasPreview => hasFeature(FieldFeature.preview);

  /// Check if this field supports bulk operations
  bool get supportsBulk => hasFeature(FieldFeature.bulk);

  /// Check if this field is exportable
  bool get isExportable => hasFeature(FieldFeature.export);

  /// Check if this field is importable
  bool get isImportable => hasFeature(FieldFeature.import);

  /// Check if this field syncs with external systems
  bool get isSynced => hasFeature(FieldFeature.sync);

  /// Check if this field updates in real-time
  bool get isRealtime => hasFeature(FieldFeature.realtime);

  /// Check if this field works offline
  bool get worksOffline => hasFeature(FieldFeature.offline);

  /// Check if this field has automatic backup
  bool get hasBackup => hasFeature(FieldFeature.backup);

  /// Check if this field data is compressed
  bool get isCompressed => hasFeature(FieldFeature.compress);

  /// Get input type for HTML/web forms
  String get inputType {
    switch (type) {
      case FieldType.text:
        return 'text';
      case FieldType.number:
        return 'number';
      case FieldType.email:
        return 'email';
      case FieldType.phone:
        return 'tel';
      case FieldType.url:
        return 'url';
      case FieldType.password:
        return 'password';
      case FieldType.date:
        return 'date';
      case FieldType.time:
        return 'time';
      case FieldType.datetime:
        return 'datetime-local';
      case FieldType.color:
        return 'color';
      case FieldType.file:
        return 'file';
      case FieldType.image:
        return 'file';
      case FieldType.textarea:
        return 'textarea';
      case FieldType.checkbox:
        return 'checkbox';
      case FieldType.radio:
        return 'radio';
      case FieldType.slider:
        return 'range';
      default:
        return 'text';
    }
  }

  /// Check if this field type supports multiple values
  bool get supportsMultipleValues {
    return type == FieldType.checkbox ||
        type == FieldType.file ||
        type == FieldType.image;
  }

  /// Check if this field type is numeric
  bool get isNumeric {
    return type == FieldType.number ||
        type == FieldType.slider ||
        type == FieldType.rating;
  }

  /// Check if this field type is date/time related
  bool get isDateTime {
    return type == FieldType.date ||
        type == FieldType.time ||
        type == FieldType.datetime;
  }

  /// Check if this field type is for media/files
  bool get isMedia {
    return type == FieldType.file ||
        type == FieldType.image ||
        type == FieldType.barcode ||
        type == FieldType.qrcode;
  }

  /// Get validation pattern for this field type
  String? get validationPattern {
    switch (type) {
      case FieldType.email:
        return r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
      case FieldType.phone:
        return r'^[\+]?[0-9\-\(\)\s]+$';
      case FieldType.url:
        return r'^https?:\/\/[^\s]+$';
      default:
        return null;
    }
  }

  FieldConfig copyWith({
    String? name,
    String? displayName,
    FieldType? type,
    List<FieldFeature>? features,
    List<String>? options,
    bool? isDynamic,
    String? keySheetColumn,
  }) {
    return FieldConfig(
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      features: features ?? this.features,
      options: options ?? this.options,
      isDynamic: isDynamic ?? this.isDynamic,
      keySheetColumn: keySheetColumn ?? this.keySheetColumn,
    );
  }
}

/// Enum for field types
enum FieldType {
  text,
  dropdown,
  autocomplete,
  locationCompound,
  number,
  date,
  time,
  datetime,
  email,
  phone,
  url,
  password,
  textarea,
  checkbox,
  radio,
  slider,
  rating,
  color,
  file,
  image,
  barcode,
  qrcode;

  String get displayName {
    switch (this) {
      case FieldType.text:
        return 'نص';
      case FieldType.dropdown:
        return 'قائمة منسدلة';
      case FieldType.autocomplete:
        return 'إكمال تلقائي';
      case FieldType.locationCompound:
        return 'موقع مركب';
      case FieldType.number:
        return 'رقم';
      case FieldType.date:
        return 'تاريخ';
      case FieldType.time:
        return 'وقت';
      case FieldType.datetime:
        return 'تاريخ ووقت';
      case FieldType.email:
        return 'بريد إلكتروني';
      case FieldType.phone:
        return 'رقم هاتف';
      case FieldType.url:
        return 'رابط';
      case FieldType.password:
        return 'كلمة مرور';
      case FieldType.textarea:
        return 'نص طويل';
      case FieldType.checkbox:
        return 'مربع اختيار';
      case FieldType.radio:
        return 'اختيار واحد';
      case FieldType.slider:
        return 'شريط تمرير';
      case FieldType.rating:
        return 'تقييم';
      case FieldType.color:
        return 'لون';
      case FieldType.file:
        return 'ملف';
      case FieldType.image:
        return 'صورة';
      case FieldType.barcode:
        return 'باركود';
      case FieldType.qrcode:
        return 'رمز QR';
    }
  }

  String get englishName {
    switch (this) {
      case FieldType.text:
        return 'Text';
      case FieldType.dropdown:
        return 'Dropdown';
      case FieldType.autocomplete:
        return 'Autocomplete';
      case FieldType.locationCompound:
        return 'Location Compound';
      case FieldType.number:
        return 'Number';
      case FieldType.date:
        return 'Date';
      case FieldType.time:
        return 'Time';
      case FieldType.datetime:
        return 'Date Time';
      case FieldType.email:
        return 'Email';
      case FieldType.phone:
        return 'Phone';
      case FieldType.url:
        return 'URL';
      case FieldType.password:
        return 'Password';
      case FieldType.textarea:
        return 'Text Area';
      case FieldType.checkbox:
        return 'Checkbox';
      case FieldType.radio:
        return 'Radio';
      case FieldType.slider:
        return 'Slider';
      case FieldType.rating:
        return 'Rating';
      case FieldType.color:
        return 'Color';
      case FieldType.file:
        return 'File';
      case FieldType.image:
        return 'Image';
      case FieldType.barcode:
        return 'Barcode';
      case FieldType.qrcode:
        return 'QR Code';
    }
  }
}

/// Enum for field features/modifiers
enum FieldFeature {
  plus, // Add new option button
  md, // Markdown support
  long, // Multiline text area
  required, // Required field
  readonly, // Read-only field
  hidden, // Hidden field
  searchable, // Can be searched
  sortable, // Can be sorted
  filterable, // Can be filtered
  unique, // Must be unique
  encrypted, // Should be encrypted
  cached, // Should be cached
  validated, // Has custom validation
  formatted, // Has custom formatting
  conditional, // Shows/hides based on other fields
  calculated, // Value calculated from other fields
  indexed, // Should be indexed for performance
  localized, // Supports multiple languages
  versioned, // Keeps version history
  audited, // Tracks changes
  rich, // Rich text editor
  preview, // Shows preview
  bulk, // Supports bulk operations
  export, // Can be exported
  import, // Can be imported
  sync, // Syncs with external systems
  realtime, // Real-time updates
  offline, // Works offline
  backup, // Automatically backed up
  compress, // Compresses data
  row, // Display in row layout (horizontal)
  col; // Display in column layout (vertical)

  String get displayName {
    switch (this) {
      case FieldFeature.plus:
        return 'إضافة جديد';
      case FieldFeature.md:
        return 'تنسيق';
      case FieldFeature.long:
        return 'نص طويل';
      case FieldFeature.required:
        return 'مطلوب';
      case FieldFeature.readonly:
        return 'للقراءة فقط';
      case FieldFeature.hidden:
        return 'مخفي';
      case FieldFeature.searchable:
        return 'قابل للبحث';
      case FieldFeature.sortable:
        return 'قابل للترتيب';
      case FieldFeature.filterable:
        return 'قابل للتصفية';
      case FieldFeature.unique:
        return 'فريد';
      case FieldFeature.encrypted:
        return 'مشفر';
      case FieldFeature.cached:
        return 'محفوظ مؤقتاً';
      case FieldFeature.validated:
        return 'مُتحقق';
      case FieldFeature.formatted:
        return 'منسق';
      case FieldFeature.conditional:
        return 'شرطي';
      case FieldFeature.calculated:
        return 'محسوب';
      case FieldFeature.indexed:
        return 'مفهرس';
      case FieldFeature.localized:
        return 'متعدد اللغات';
      case FieldFeature.versioned:
        return 'متعدد الإصدارات';
      case FieldFeature.audited:
        return 'مراقب';
      case FieldFeature.rich:
        return 'نص غني';
      case FieldFeature.preview:
        return 'معاينة';
      case FieldFeature.bulk:
        return 'عمليات مجمعة';
      case FieldFeature.export:
        return 'قابل للتصدير';
      case FieldFeature.import:
        return 'قابل للاستيراد';
      case FieldFeature.sync:
        return 'متزامن';
      case FieldFeature.realtime:
        return 'فوري';
      case FieldFeature.offline:
        return 'يعمل بدون إنترنت';
      case FieldFeature.backup:
        return 'نسخ احتياطي';
      case FieldFeature.compress:
        return 'مضغوط';
      case FieldFeature.row:
        return 'صف';
      case FieldFeature.col:
        return 'عمود';
    }
  }

  String get englishName {
    switch (this) {
      case FieldFeature.plus:
        return 'Add New';
      case FieldFeature.md:
        return 'Markdown';
      case FieldFeature.long:
        return 'Long Text';
      case FieldFeature.required:
        return 'Required';
      case FieldFeature.readonly:
        return 'Read Only';
      case FieldFeature.hidden:
        return 'Hidden';
      case FieldFeature.searchable:
        return 'Searchable';
      case FieldFeature.sortable:
        return 'Sortable';
      case FieldFeature.filterable:
        return 'Filterable';
      case FieldFeature.unique:
        return 'Unique';
      case FieldFeature.encrypted:
        return 'Encrypted';
      case FieldFeature.cached:
        return 'Cached';
      case FieldFeature.validated:
        return 'Validated';
      case FieldFeature.formatted:
        return 'Formatted';
      case FieldFeature.conditional:
        return 'Conditional';
      case FieldFeature.calculated:
        return 'Calculated';
      case FieldFeature.indexed:
        return 'Indexed';
      case FieldFeature.localized:
        return 'Localized';
      case FieldFeature.versioned:
        return 'Versioned';
      case FieldFeature.audited:
        return 'Audited';
      case FieldFeature.rich:
        return 'Rich Text';
      case FieldFeature.preview:
        return 'Preview';
      case FieldFeature.bulk:
        return 'Bulk Operations';
      case FieldFeature.export:
        return 'Exportable';
      case FieldFeature.import:
        return 'Importable';
      case FieldFeature.sync:
        return 'Sync';
      case FieldFeature.realtime:
        return 'Real-time';
      case FieldFeature.offline:
        return 'Offline';
      case FieldFeature.backup:
        return 'Backup';
      case FieldFeature.compress:
        return 'Compress';
      case FieldFeature.row:
        return 'Row';
      case FieldFeature.col:
        return 'Column';
    }
  }

  String get description {
    switch (this) {
      case FieldFeature.plus:
        return 'يضيف زر "إضافة جديد" للحقول المنسدلة';
      case FieldFeature.md:
        return 'يدعم تنسيق النص باستخدام Markdown';
      case FieldFeature.long:
        return 'نص متعدد الأسطر للمحتوى الطويل';
      case FieldFeature.required:
        return 'حقل إجباري يجب ملؤه';
      case FieldFeature.readonly:
        return 'حقل للقراءة فقط لا يمكن تعديله';
      case FieldFeature.hidden:
        return 'حقل مخفي لا يظهر في النموذج';
      case FieldFeature.searchable:
        return 'يمكن البحث في محتوى هذا الحقل';
      case FieldFeature.sortable:
        return 'يمكن ترتيب البيانات حسب هذا الحقل';
      case FieldFeature.filterable:
        return 'يمكن تصفية البيانات حسب هذا الحقل';
      case FieldFeature.unique:
        return 'قيمة فريدة لا يمكن تكرارها';
      case FieldFeature.encrypted:
        return 'البيانات مشفرة للحماية';
      case FieldFeature.cached:
        return 'البيانات محفوظة مؤقتاً لتحسين الأداء';
      case FieldFeature.validated:
        return 'يحتوي على قواعد تحقق مخصصة';
      case FieldFeature.formatted:
        return 'يحتوي على تنسيق مخصص للعرض';
      case FieldFeature.conditional:
        return 'يظهر أو يختفي حسب قيم حقول أخرى';
      case FieldFeature.calculated:
        return 'قيمة محسوبة تلقائياً من حقول أخرى';
      case FieldFeature.indexed:
        return 'مفهرس لتحسين أداء البحث';
      case FieldFeature.localized:
        return 'يدعم عدة لغات';
      case FieldFeature.versioned:
        return 'يحتفظ بتاريخ التغييرات';
      case FieldFeature.audited:
        return 'يراقب ويسجل جميع التغييرات';
      case FieldFeature.rich:
        return 'محرر نص غني مع أدوات تنسيق متقدمة';
      case FieldFeature.preview:
        return 'يعرض معاينة للمحتوى';
      case FieldFeature.bulk:
        return 'يدعم العمليات المجمعة';
      case FieldFeature.export:
        return 'يمكن تصدير بياناته';
      case FieldFeature.import:
        return 'يمكن استيراد بيانات إليه';
      case FieldFeature.sync:
        return 'يتزامن مع أنظمة خارجية';
      case FieldFeature.realtime:
        return 'يحدث البيانات في الوقت الفعلي';
      case FieldFeature.offline:
        return 'يعمل بدون اتصال بالإنترنت';
      case FieldFeature.backup:
        return 'ينشئ نسخ احتياطية تلقائياً';
      case FieldFeature.compress:
        return 'يضغط البيانات لتوفير المساحة';
      case FieldFeature.row:
        return 'يعرض حقل الموقع في تخطيط أفقي (صف)';
      case FieldFeature.col:
        return 'يعرض حقل الموقع في تخطيط عمودي';
    }
  }
}

/// Represents the complete form structure
class FormStructure {
  final List<FieldConfig> fields;
  final LocationData? locationData;
  final DateTime lastUpdated;

  FormStructure({
    required this.fields,
    this.locationData,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Get field by name
  FieldConfig? getField(String name) {
    try {
      return fields.firstWhere((field) => field.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get all fields of a specific type
  List<FieldConfig> getFieldsByType(FieldType type) {
    return fields.where((field) => field.type == type).toList();
  }

  /// Get all dynamic fields
  List<FieldConfig> get dynamicFields {
    return fields.where((field) => field.isDynamic).toList();
  }

  /// Get all static fields
  List<FieldConfig> get staticFields {
    return fields.where((field) => !field.isDynamic).toList();
  }

  /// Get all options for a specific field
  List<String> getFieldOptions(String fieldName) {
    final field = getField(fieldName);
    return field?.options ?? [];
  }

  /// Check if structure needs refresh (older than 1 hour)
  bool get needsRefresh {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    return difference.inHours >= 1;
  }

  FormStructure copyWith({
    List<FieldConfig>? fields,
    LocationData? locationData,
    DateTime? lastUpdated,
  }) {
    return FormStructure(
      fields: fields ?? this.fields,
      locationData: locationData ?? this.locationData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
