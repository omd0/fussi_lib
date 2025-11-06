import 'package:flutter/material.dart';
import '../../models/field_config.dart';
import '../arabic_form_field.dart';

/// Extension on FieldConfig to provide feature-based functionality
extension FieldConfigFeatures on FieldConfig {
  /// Check if field has any of the given features
  bool hasAnyFeature(List<FieldFeature> features) {
    return features.any((feature) => this.features.contains(feature));
  }

  /// Get all features that affect UI rendering
  List<FieldFeature> get uiFeatures {
    return features.where((feature) => _isUIFeature(feature)).toList();
  }

  /// Get all features that affect behavior
  List<FieldFeature> get behaviorFeatures {
    return features.where((feature) => _isBehaviorFeature(feature)).toList();
  }

  /// Get all features that affect validation
  List<FieldFeature> get validationFeatures {
    return features.where((feature) => _isValidationFeature(feature)).toList();
  }

  bool _isUIFeature(FieldFeature feature) {
    return [
      FieldFeature.long,
      FieldFeature.md,
      FieldFeature.readonly,
      FieldFeature.required,
    ].contains(feature);
  }

  bool _isBehaviorFeature(FieldFeature feature) {
    return [
      FieldFeature.searchable,
      FieldFeature.unique,
      FieldFeature.realtime,
      FieldFeature.calculated,
      FieldFeature.conditional,
    ].contains(feature);
  }

  bool _isValidationFeature(FieldFeature feature) {
    return [
      FieldFeature.validated,
      FieldFeature.required,
      FieldFeature.unique,
    ].contains(feature);
  }
}

/// Extension on Widget to add field feature functionality
extension FieldFeatureWidget on Widget {
  /// Apply field features to this widget
  Widget withFieldFeatures(FieldConfig field) {
    Widget result = this;

    // Apply features in order of priority
    for (final feature in field.uiFeatures) {
      result = result._applyFeature(field, feature);
    }

    return result;
  }

  /// Apply a specific feature to this widget
  Widget _applyFeature(FieldConfig field, FieldFeature feature) {
    switch (feature) {
      case FieldFeature.long:
        return _applyLongFeature(field);
      case FieldFeature.md:
        return _applyMarkdownFeature(field);
      case FieldFeature.readonly:
        return _applyReadonlyFeature(field);
      case FieldFeature.required:
        return _applyRequiredFeature(field);
      case FieldFeature.searchable:
        return _applySearchableFeature(field);
      case FieldFeature.unique:
        return _applyUniqueFeature(field);
      case FieldFeature.validated:
        return _applyValidatedFeature(field);
      default:
        return this;
    }
  }

  Widget _applyLongFeature(FieldConfig field) {
    if (this is ArabicFormField) {
      final formField = this as ArabicFormField;
      return ArabicFormField(
        hint: formField.hint,
        controller: formField.controller,
        isRequired: formField.isRequired,
        maxLines: 8, // Override for long text
        keyboardType: formField.keyboardType,
        validator: formField.validator,
        onChanged: formField.onChanged,
        icon: formField.icon,
      );
    }
    return this;
  }

  Widget _applyMarkdownFeature(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: this),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'تنسيق',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.purple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _applyReadonlyFeature(FieldConfig field) {
    // Add readonly styling wrapper
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: this,
    );
  }

  Widget _applyRequiredFeature(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              field.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 8),
        this,
      ],
    );
  }

  Widget _applySearchableFeature(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        this,
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.search,
              size: 16,
              color: Colors.blue,
            ),
            const SizedBox(width: 4),
            const Text(
              'قابل للبحث',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _applyUniqueFeature(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        this,
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.fingerprint,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            const Text(
              'فريد',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _applyValidatedFeature(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        this,
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.verified,
              size: 16,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            const Text(
              'محقق',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Extension on FieldConfig to create base widgets
extension FieldConfigWidgetBuilder on FieldConfig {
  /// Create a base widget for this field type
  Widget createBaseWidget({
    required TextEditingController controller,
    required Function(String) onChanged,
    bool isRequired = false,
  }) {
    switch (type) {
      case FieldType.text:
        return _createTextField(controller, onChanged, isRequired);
      case FieldType.textarea:
        return _createTextAreaField(controller, onChanged, isRequired);
      case FieldType.number:
        return _createNumberField(controller, onChanged, isRequired);
      case FieldType.email:
        return _createEmailField(controller, onChanged, isRequired);
      case FieldType.phone:
        return _createPhoneField(controller, onChanged, isRequired);
      case FieldType.url:
        return _createUrlField(controller, onChanged, isRequired);
      case FieldType.password:
        return _createPasswordField(controller, onChanged, isRequired);
      default:
        return _createTextField(controller, onChanged, isRequired);
    }
  }

  /// Create a complete field widget with all features applied
  Widget buildField({
    required TextEditingController controller,
    required Function(String) onChanged,
    bool isRequired = false,
    bool showLabel = true,
  }) {
    // Create base widget
    Widget baseWidget = createBaseWidget(
      controller: controller,
      onChanged: onChanged,
      isRequired: isRequired,
    );

    // Apply features
    baseWidget = baseWidget.withFieldFeatures(this);

    // Add label if needed
    if (showLabel) {
      baseWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(isRequired),
          const SizedBox(height: 8),
          baseWidget,
        ],
      );
    }

    return baseWidget;
  }

  Widget _buildFieldLabel(bool isRequired) {
    return Row(
      children: [
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const Text(
            ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
        const Spacer(),
        // Show feature badges
        ..._buildFeatureBadges(),
      ],
    );
  }

  List<Widget> _buildFeatureBadges() {
    final badges = <Widget>[];

    for (final feature in uiFeatures) {
      if (feature == FieldFeature.required)
        continue; // Already shown as asterisk

      final color = _getFeatureColor(feature);
      final text = _getFeatureText(feature);

      badges.add(
        Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return badges;
  }

  Color _getFeatureColor(FieldFeature feature) {
    switch (feature) {
      case FieldFeature.plus:
        return Colors.blue;
      case FieldFeature.md:
        return Colors.purple;
      case FieldFeature.long:
        return Colors.orange;
      case FieldFeature.required:
        return Colors.red;
      case FieldFeature.readonly:
        return Colors.grey;
      case FieldFeature.searchable:
        return Colors.blue;
      case FieldFeature.unique:
        return Colors.orange;
      case FieldFeature.validated:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getFeatureText(FieldFeature feature) {
    switch (feature) {
      case FieldFeature.plus:
        return 'إضافة';
      case FieldFeature.md:
        return 'تنسيق';
      case FieldFeature.long:
        return 'طويل';
      case FieldFeature.readonly:
        return 'قراءة';
      case FieldFeature.searchable:
        return 'بحث';
      case FieldFeature.unique:
        return 'فريد';
      case FieldFeature.validated:
        return 'محقق';
      default:
        return feature.name;
    }
  }

  // Base widget creation methods
  Widget _createTextField(TextEditingController controller,
      Function(String) onChanged, bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل $displayName',
      controller: controller,
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }

  Widget _createTextAreaField(TextEditingController controller,
      Function(String) onChanged, bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل $displayName',
      controller: controller,
      isRequired: isRequired,
      maxLines: 4,
      onChanged: onChanged,
    );
  }

  Widget _createNumberField(TextEditingController controller,
      Function(String) onChanged, bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل $displayName',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _createEmailField(TextEditingController controller,
      Function(String) onChanged, bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل $displayName',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.emailAddress,
      onChanged: onChanged,
    );
  }

  Widget _createPhoneField(TextEditingController controller,
      Function(String) onChanged, bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل $displayName',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.phone,
      onChanged: onChanged,
    );
  }

  Widget _createUrlField(TextEditingController controller,
      Function(String) onChanged, bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل $displayName',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.url,
      onChanged: onChanged,
    );
  }

  Widget _createPasswordField(TextEditingController controller,
      Function(String) onChanged, bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل $displayName',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.visiblePassword,
      onChanged: onChanged,
    );
  }
}
