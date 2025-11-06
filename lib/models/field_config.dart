/// Enum for different field types
enum FieldType {
  text,
  dropdown,
  autocomplete,
  locationCompound,
  number,
  slider,
  rating,
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
  file,
  image,
  barcode,
  qrcode,
  color;

  String get name => toString().split('.').last;

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
      case FieldType.textarea:
        return 'نص طويل';
      case FieldType.email:
        return 'بريد إلكتروني';
      case FieldType.phone:
        return 'هاتف';
      case FieldType.date:
        return 'تاريخ';
      case FieldType.time:
        return 'وقت';
      case FieldType.checkbox:
        return 'مربع اختيار';
      default:
        return name;
    }
  }
}

/// Enum for field features
enum FieldFeature {
  plus,
  md,
  long,
  required,
  readonly,
  hidden,
  searchable,
  sortable,
  filterable,
  unique,
  encrypted,
  cached,
  indexed,
  compress,
  validated,
  formatted,
  conditional,
  calculated,
  localized,
  versioned,
  audited,
  rich,
  preview,
  bulk,
  export,
  import,
  sync,
  realtime,
  offline,
  backup,
  row,
  col;

  String get name => toString().split('.').last;

  String get displayName {
    switch (this) {
      case FieldFeature.plus:
        return 'إضافة جديد';
      case FieldFeature.required:
        return 'مطلوب';
      case FieldFeature.readonly:
        return 'للقراءة فقط';
      case FieldFeature.searchable:
        return 'قابل للبحث';
      case FieldFeature.unique:
        return 'فريد';
      default:
        return name;
    }
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
  final num? minValue;
  final num? maxValue;

  FieldConfig({
    required this.name,
    required this.displayName,
    required this.type,
    this.features = const [],
    this.options = const [],
    this.isDynamic = false,
    this.keySheetColumn,
    this.minValue,
    this.maxValue,
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
}
