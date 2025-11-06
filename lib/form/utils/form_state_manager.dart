import 'package:flutter/material.dart';
import '../../models/field_config.dart';
import '../../models/form_structure.dart';

/// Manages form state including controllers and field values.
/// 
/// This class handles the lifecycle of form controllers and maintains
/// state for various field types (text, dropdown, location, etc.).
class FormStateManager {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, String?> _locationRows = {};
  final Map<String, String?> _locationColumns = {};
  final Map<String, String?> _locationRooms = {};

  /// Initialize controllers for all fields in the form structure.
  void initializeControllers(FormStructure structure, Map<String, String> lockedValues) {
    for (final field in structure.fields) {
      if (_needsController(field.type)) {
        final controller = TextEditingController();
        // Set locked values if available
        if (lockedValues.containsKey(field.name)) {
          controller.text = lockedValues[field.name]!;
        }
        _controllers[field.name] = controller;
      }
    }

    // Set locked dropdown values
    for (final entry in lockedValues.entries) {
      final field = structure.getField(entry.key);
      if (field != null) {
        if (field.type == FieldType.dropdown) {
          _dropdownValues[entry.key] = entry.value;
        } else if (field.type == FieldType.locationCompound) {
          _parseLocationValue(entry.key, entry.value);
        }
      }
    }
  }

  /// Parse compound location value into components.
  void _parseLocationValue(String fieldName, String value) {
    if (value.contains('-')) {
      final parts = value.split('-');
      if (parts.length == 2) {
        _locationRooms[fieldName] = parts[0];
        final locationPart = parts[1];
        if (locationPart.length >= 2) {
          final row = locationPart.substring(0, 1);
          final col = locationPart.substring(1);
          _locationRows[fieldName] = row;
          _locationColumns[fieldName] = col;
        }
      }
    } else if (value.length >= 2) {
      // Legacy format (e.g., "B5" -> row "B", column "5")
      final row = value.substring(0, 1);
      final col = value.substring(1);
      _locationRows[fieldName] = row;
      _locationColumns[fieldName] = col;
    }
  }

  /// Check if a field type needs a text controller.
  bool _needsController(FieldType type) {
    return [
      FieldType.text,
      FieldType.autocomplete,
      FieldType.textarea,
      FieldType.number,
      FieldType.email,
      FieldType.phone,
      FieldType.url,
      FieldType.password,
      FieldType.checkbox,
      FieldType.date,
      FieldType.time,
      FieldType.datetime,
      FieldType.radio,
      FieldType.slider,
      FieldType.rating,
      FieldType.color,
      FieldType.file,
      FieldType.image,
      FieldType.barcode,
      FieldType.qrcode,
    ].contains(type);
  }

  /// Get a controller for a field.
  TextEditingController? getController(String fieldName) {
    return _controllers[fieldName];
  }

  /// Set controller for a field.
  void setController(String fieldName, TextEditingController controller) {
    _controllers[fieldName] = controller;
  }

  /// Get dropdown value for a field.
  String? getDropdownValue(String fieldName) {
    return _dropdownValues[fieldName];
  }

  /// Set dropdown value for a field.
  void setDropdownValue(String fieldName, String? value) {
    _dropdownValues[fieldName] = value;
  }

  /// Get location row for a field.
  String? getLocationRow(String fieldName) {
    return _locationRows[fieldName];
  }

  /// Set location row for a field.
  void setLocationRow(String fieldName, String? value) {
    _locationRows[fieldName] = value;
  }

  /// Get location column for a field.
  String? getLocationColumn(String fieldName) {
    return _locationColumns[fieldName];
  }

  /// Set location column for a field.
  void setLocationColumn(String fieldName, String? value) {
    _locationColumns[fieldName] = value;
  }

  /// Get location room for a field.
  String? getLocationRoom(String fieldName) {
    return _locationRooms[fieldName];
  }

  /// Set location room for a field.
  void setLocationRoom(String fieldName, String? value) {
    _locationRooms[fieldName] = value;
  }

  /// Collect all form data into a map.
  Map<String, String> collectFormData(FormStructure structure) {
    final formData = <String, String>{};

    // Collect text field data
    for (final entry in _controllers.entries) {
      formData[entry.key] = entry.value.text.trim();
    }

    // Collect dropdown data
    for (final entry in _dropdownValues.entries) {
      if (entry.value != null) {
        formData[entry.key] = entry.value!;
      }
    }

    // Collect compound location data
    for (final field in structure.fields) {
      if (field.type == FieldType.locationCompound) {
        final row = _locationRows[field.name];
        final col = _locationColumns[field.name];
        if (row != null && col != null) {
          formData[field.name] = '$row$col'; // e.g., "B5"
        }
      }
    }

    return formData;
  }

  /// Clear all controllers and values.
  void clearAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _dropdownValues.clear();
    _locationRows.clear();
    _locationColumns.clear();
    _locationRooms.clear();
  }

  /// Clear only unlocked fields (preserve locked ones).
  void clearUnlockedFields(Map<String, bool> lockedFields) {
    final keysToRemove = <String>[];
    
    for (final entry in _controllers.entries) {
      if (!lockedFields.containsKey(entry.key) || !lockedFields[entry.key]!) {
        entry.value.clear();
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      if (!lockedFields.containsKey(key) || !lockedFields[key]!) {
        _dropdownValues.remove(key);
        _locationRows.remove(key);
        _locationColumns.remove(key);
        _locationRooms.remove(key);
      }
    }
  }

  /// Dispose all resources.
  void dispose() {
    clearAll();
  }
}

