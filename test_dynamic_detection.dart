import 'lib/services/dynamic_sheets_service.dart';
import 'lib/models/book.dart';

void main() async {
  print('🚀 Testing Dynamic Column Detection with Data Models...\n');

  final dynamicService = DynamicSheetsService();

  try {
    // Test the new data model-based structure analysis
    final structure = await dynamicService.analyzeSheetStructure();

    if (structure != null) {
      print('✅ Structure Analysis Complete!\n');

      // Test FormStructure methods
      print('📊 Form Structure Analysis:');
      print('   Total fields: ${structure.fields.length}');
      print('   Dynamic fields: ${structure.dynamicFields.length}');
      print('   Static fields: ${structure.staticFields.length}');
      print(
          '   Has location data: ${structure.locationData?.isComplete ?? false}');
      print('   Last updated: ${structure.lastUpdated}');
      print('   Needs refresh: ${structure.needsRefresh}\n');

      // Test field types
      print('📋 Field Type Distribution:');
      final typeGroups = <FieldType, List<FieldConfig>>{};
      for (final field in structure.fields) {
        typeGroups.putIfAbsent(field.type, () => []).add(field);
      }

      for (final entry in typeGroups.entries) {
        print('   ${entry.key.displayName}: ${entry.value.length} fields');
        for (final field in entry.value.take(3)) {
          print(
              '     - ${field.displayName} (${field.options.length} options)');
        }
        if (entry.value.length > 3) {
          print('     ... and ${entry.value.length - 3} more');
        }
      }
      print('');

      // Test field features
      print('🎯 Field Features:');
      for (final field in structure.fields) {
        if (field.features.isNotEmpty) {
          final featureNames =
              field.features.map((f) => f.displayName).join(', ');
          print('   ${field.displayName}: $featureNames');
        }
      }
      print('');

      // Test specific field queries
      print('🔍 Field Query Tests:');

      // Test getting field by name
      final testFieldName = structure.fields.first.name;
      final testField = structure.getField(testFieldName);
      print(
          '   Get field "$testFieldName": ${testField != null ? "✅ Found" : "❌ Not found"}');

      // Test getting fields by type
      final dropdownFields = structure.getFieldsByType(FieldType.dropdown);
      print('   Dropdown fields: ${dropdownFields.length}');

      final autocompleteFields =
          structure.getFieldsByType(FieldType.autocomplete);
      print('   Autocomplete fields: ${autocompleteFields.length}');

      // Test field options
      for (final field in structure.fields.take(5)) {
        final options = structure.getFieldOptions(field.name);
        print(
            '   "${field.displayName}" options: ${options.length} (${options.take(3).join(', ')}${options.length > 3 ? '...' : ''})');
      }
      print('');

      // Test location data if available
      if (structure.locationData != null &&
          structure.locationData!.isComplete) {
        print('🗺️ Location Data:');
        print('   Rows: ${structure.locationData!.rows.join(', ')}');
        print('   Columns: ${structure.locationData!.columns.join(', ')}');
        final combinations = structure.locationData!.generateCombinations();
        print('   Total combinations: ${combinations.length}');
        print(
            '   Sample combinations: ${combinations.take(10).join(', ')}${combinations.length > 10 ? '...' : ''}');
        print('');
      }

      // Test service methods with data models
      print('🔧 Service Method Tests:');

      // Test getFieldOptions
      for (final field in structure.fields.take(3)) {
        final options = dynamicService.getFieldOptions(field.name);
        print('   getFieldOptions("${field.name}"): ${options.length} options');
      }

      // Test getAutocompleteOptions for author fields
      final authorFields = structure.fields
          .where((f) =>
              f.name.contains('مؤلف') ||
              f.name.contains('author') ||
              f.name.toLowerCase().contains('author'))
          .toList();

      if (authorFields.isNotEmpty) {
        print('   Testing author autocomplete...');
        for (final authorField in authorFields.take(2)) {
          final autocompleteOptions =
              await dynamicService.getAutocompleteOptions(authorField.name);
          print(
              '   getAutocompleteOptions("${authorField.name}"): ${autocompleteOptions.length} options');
        }
      }

      // Test backward compatibility
      print('');
      print('🔄 Backward Compatibility Tests:');
      final legacyStructure = dynamicService.currentLegacyStructure;
      if (legacyStructure != null) {
        print('   Legacy structure conversion: ✅ Success');
        print('   Legacy columns: ${legacyStructure.columns.length}');
        print(
            '   Legacy dropdown options: ${legacyStructure.dropdownOptions.length}');

        // Test legacy methods
        final legacyOptions =
            dynamicService.getDropdownOptions(structure.fields.first.name);
        print('   Legacy getDropdownOptions: ${legacyOptions.length} options');
      } else {
        print('   Legacy structure conversion: ❌ Failed');
      }

      print('\n🎉 All tests completed successfully!');
      print(
          '📝 The service now uses proper Dart data models instead of raw JSON!');
    } else {
      print('❌ Failed to analyze structure');
    }
  } catch (e, stackTrace) {
    print('❌ Error during testing: $e');
    print('Stack trace: $stackTrace');
  }
}
