import 'field_config.dart';
import 'location_data.dart';

/// Represents the complete form structure with all fields and metadata
class FormStructure {
  final List<FieldConfig> fields;
  final LocationData? locationData;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  FormStructure({
    required this.fields,
    this.locationData,
    DateTime? lastUpdated,
    this.metadata = const {},
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// Get dynamic fields (those with actual data)
  List<FieldConfig> get dynamicFields =>
      fields.where((field) => field.isDynamic).toList();

  /// Get static fields (those without data)
  List<FieldConfig> get staticFields =>
      fields.where((field) => !field.isDynamic).toList();

  /// Check if structure needs refresh (older than 5 minutes)
  bool get needsRefresh => DateTime.now().difference(lastUpdated).inMinutes > 5;

  /// Get field by name
  FieldConfig? getField(String name) {
    try {
      return fields.firstWhere((field) => field.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get fields by type
  List<FieldConfig> getFieldsByType(FieldType type) =>
      fields.where((field) => field.type == type).toList();

  /// Get field options for a specific field
  List<String> getFieldOptions(String fieldName) {
    final field = getField(fieldName);
    return field?.options ?? [];
  }

  /// Check if field has options
  bool fieldHasOptions(String fieldName) =>
      getFieldOptions(fieldName).isNotEmpty;

  /// Get required fields
  List<FieldConfig> get requiredFields =>
      fields.where((field) => field.isRequired).toList();

  /// Get searchable fields
  List<FieldConfig> get searchableFields =>
      fields.where((field) => field.isSearchable).toList();

  /// Get dropdown fields
  List<FieldConfig> get dropdownFields =>
      fields.where((field) => field.type == FieldType.dropdown).toList();

  /// Get autocomplete fields
  List<FieldConfig> get autocompleteFields =>
      fields.where((field) => field.type == FieldType.autocomplete).toList();

  /// Get location fields
  List<FieldConfig> get locationFields =>
      fields.where((field) => field.isLocationField).toList();

  /// Create a copy with updated fields
  FormStructure copyWith({
    List<FieldConfig>? fields,
    LocationData? locationData,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
  }) {
    return FormStructure(
      fields: fields ?? this.fields,
      locationData: locationData ?? this.locationData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to Map for debugging
  Map<String, dynamic> toMap() {
    return {
      'fields': fields
          .map((f) => {
                'name': f.name,
                'displayName': f.displayName,
                'type': f.type.name,
                'features': f.features.map((feat) => feat.name).toList(),
                'options': f.options,
                'isDynamic': f.isDynamic,
              })
          .toList(),
      'locationData': locationData != null
          ? {
              'rows': locationData!.rows,
              'columns': locationData!.columns,
              'rooms': locationData!.rooms,
              'isComplete': locationData!.isComplete,
            }
          : null,
      'lastUpdated': lastUpdated.toIso8601String(),
      'metadata': metadata,
    };
  }
}
