import 'package:flutter/material.dart';
import '../../models/field_config.dart';
import 'field_feature_extensions.dart';
import 'enhanced_field_widget.dart';

/// Example showing how to use the new extension-based feature system
class FeatureSystemExample extends StatefulWidget {
  const FeatureSystemExample({super.key});

  @override
  State<FeatureSystemExample> createState() => _FeatureSystemExampleState();
}

class _FeatureSystemExampleState extends State<FeatureSystemExample> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _values = {};

  // Example field configurations with different features
  final List<FieldConfig> _exampleFields = [
    // Basic text field
    FieldConfig(
      name: 'title',
      displayName: 'العنوان',
      type: FieldType.text,
      features: [FieldFeature.required],
    ),

    // Long text field with markdown
    FieldConfig(
      name: 'description',
      displayName: 'الوصف',
      type: FieldType.text,
      features: [FieldFeature.long, FieldFeature.md, FieldFeature.required],
    ),

    // Searchable email field
    FieldConfig(
      name: 'email',
      displayName: 'البريد الإلكتروني',
      type: FieldType.email,
      features: [
        FieldFeature.required,
        FieldFeature.searchable,
        FieldFeature.validated
      ],
    ),

    // Unique phone number
    FieldConfig(
      name: 'phone',
      displayName: 'رقم الهاتف',
      type: FieldType.phone,
      features: [FieldFeature.unique, FieldFeature.required],
    ),

    // Readonly field
    FieldConfig(
      name: 'id',
      displayName: 'المعرف',
      type: FieldType.text,
      features: [FieldFeature.readonly],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    for (final field in _exampleFields) {
      _controllers[field.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام الميزات المحسن'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Features summary
            FieldFeaturesSummary(fields: _exampleFields),

            const SizedBox(height: 24),

            // Field list using the new system
            EnhancedFieldList(
              fields: _exampleFields,
              controllers: _controllers,
              values: _values,
              onFieldChanged: _onFieldChanged,
            ),

            const SizedBox(height: 24),

            // Example of using extensions directly
            _buildDirectExtensionExample(),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('إرسال النموذج'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectExtensionExample() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مثال على استخدام الامتدادات مباشرة:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Create a field using extensions
        _exampleFields.first.buildField(
          controller: _controllers['title']!,
          onChanged: (value) => _onFieldChanged('title', value),
          isRequired: true,
        ),
      ],
    );
  }

  void _onFieldChanged(String fieldName, String value) {
    setState(() {
      _values[fieldName] = value;
    });
  }

  void _submitForm() {
    // Collect form data
    final formData = <String, String>{};
    for (final field in _exampleFields) {
      final controller = _controllers[field.name];
      if (controller != null) {
        formData[field.name] = controller.text.trim();
      }
    }

    // Show results
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بيانات النموذج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: formData.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('${entry.key}: ${entry.value}'),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

/// Example of creating custom feature extensions
extension CustomFieldFeatures on FieldConfig {
  /// Check if this field has advanced features
  bool get hasAdvancedFeatures {
    return hasAnyFeature([
      FieldFeature.md,
      FieldFeature.validated,
      FieldFeature.unique,
    ]);
  }

  /// Get field complexity level
  String get complexityLevel {
    final featureCount = features.length;
    if (featureCount <= 1) return 'بسيط';
    if (featureCount <= 3) return 'متوسط';
    return 'معقد';
  }

  /// Create a field with custom styling based on complexity
  Widget buildCustomField({
    required TextEditingController controller,
    required Function(String) onChanged,
    bool isRequired = false,
  }) {
    final baseWidget = buildField(
      controller: controller,
      onChanged: onChanged,
      isRequired: isRequired,
    );

    // Add custom styling based on complexity
    if (complexityLevel == 'معقد') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: baseWidget,
      );
    }

    return baseWidget;
  }
}
