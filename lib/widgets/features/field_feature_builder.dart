import 'package:flutter/material.dart';
import '../../models/field_config.dart';
import 'field_feature_decorator.dart';
import '../arabic_form_field.dart';

/// Builder class for applying field features to widgets
class FieldFeatureBuilder {
  static final List<FieldFeatureDecorator> _decorators = [
    RequiredFeatureDecorator(),
    LongTextFeatureDecorator(),
    ReadonlyFeatureDecorator(),
    SearchableFeatureDecorator(),
    UniqueFeatureDecorator(),
    ValidationFeatureDecorator(),
    MarkdownFeatureDecorator(),
  ];

  /// Register a new feature decorator
  static void registerDecorator(FieldFeatureDecorator decorator) {
    _decorators.add(decorator);
    // Sort by priority (lower priority = applied first)
    _decorators.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Remove a decorator by feature type
  static void unregisterDecorator(FieldFeature feature) {
    _decorators.removeWhere((decorator) => decorator.feature == feature);
  }

  /// Apply all applicable features to a widget
  static Widget applyFeatures(FieldConfig field, Widget baseWidget) {
    Widget result = baseWidget;

    // Get all decorators that can be applied to this field
    final applicableDecorators =
        _decorators.where((decorator) => decorator.canApply(field)).toList();

    // Apply decorators in priority order
    for (final decorator in applicableDecorators) {
      result = decorator.decorate(field, result);
    }

    return result;
  }

  /// Get all features that can be applied to a field
  static List<FieldFeature> getApplicableFeatures(FieldConfig field) {
    return _decorators
        .where((decorator) => decorator.canApply(field))
        .map((decorator) => decorator.feature)
        .toList();
  }

  /// Check if a specific feature can be applied to a field
  static bool canApplyFeature(FieldConfig field, FieldFeature feature) {
    final decorator =
        _decorators.where((d) => d.feature == feature).firstOrNull;
    return decorator?.canApply(field) ?? false;
  }

  /// Create a base widget for a field type
  static Widget createBaseWidget(
    FieldConfig field, {
    required TextEditingController controller,
    required Function(String) onChanged,
    bool isRequired = false,
  }) {
    switch (field.type) {
      case FieldType.text:
        return _createTextField(field, controller, onChanged, isRequired);
      case FieldType.textarea:
        return _createTextAreaField(field, controller, onChanged, isRequired);
      case FieldType.number:
        return _createNumberField(field, controller, onChanged, isRequired);
      case FieldType.email:
        return _createEmailField(field, controller, onChanged, isRequired);
      case FieldType.phone:
        return _createPhoneField(field, controller, onChanged, isRequired);
      case FieldType.url:
        return _createUrlField(field, controller, onChanged, isRequired);
      case FieldType.password:
        return _createPasswordField(field, controller, onChanged, isRequired);
      default:
        return _createTextField(field, controller, onChanged, isRequired);
    }
  }

  /// Create a complete field widget with all features applied
  static Widget buildField(
    FieldConfig field, {
    required TextEditingController controller,
    required Function(String) onChanged,
    bool isRequired = false,
    bool showLabel = true,
  }) {
    // Create base widget
    Widget baseWidget = createBaseWidget(
      field,
      controller: controller,
      onChanged: onChanged,
      isRequired: isRequired,
    );

    // Add label if needed
    if (showLabel) {
      baseWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(field, isRequired),
          const SizedBox(height: 8),
          baseWidget,
        ],
      );
    }

    // Apply all features
    return applyFeatures(field, baseWidget);
  }

  static Widget _buildFieldLabel(FieldConfig field, bool isRequired) {
    return Row(
      children: [
        Text(
          field.displayName,
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
        ..._buildFeatureBadges(field),
      ],
    );
  }

  static List<Widget> _buildFeatureBadges(FieldConfig field) {
    final badges = <Widget>[];

    for (final feature in field.features) {
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

  static Color _getFeatureColor(FieldFeature feature) {
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

  static String _getFeatureText(FieldFeature feature) {
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
  static Widget _createTextField(
      FieldConfig field,
      TextEditingController controller,
      Function(String) onChanged,
      bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller,
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }

  static Widget _createTextAreaField(
      FieldConfig field,
      TextEditingController controller,
      Function(String) onChanged,
      bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller,
      isRequired: isRequired,
      maxLines: 4,
      onChanged: onChanged,
    );
  }

  static Widget _createNumberField(
      FieldConfig field,
      TextEditingController controller,
      Function(String) onChanged,
      bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  static Widget _createEmailField(
      FieldConfig field,
      TextEditingController controller,
      Function(String) onChanged,
      bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.emailAddress,
      onChanged: onChanged,
    );
  }

  static Widget _createPhoneField(
      FieldConfig field,
      TextEditingController controller,
      Function(String) onChanged,
      bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.phone,
      onChanged: onChanged,
    );
  }

  static Widget _createUrlField(
      FieldConfig field,
      TextEditingController controller,
      Function(String) onChanged,
      bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.url,
      onChanged: onChanged,
    );
  }

  static Widget _createPasswordField(
      FieldConfig field,
      TextEditingController controller,
      Function(String) onChanged,
      bool isRequired) {
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller,
      isRequired: isRequired,
      keyboardType: TextInputType.visiblePassword,
      onChanged: onChanged,
    );
  }
}
