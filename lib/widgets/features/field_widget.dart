import 'package:flutter/material.dart';
import '../../models/field_config.dart';
import 'field_feature_extensions.dart';

/// Field widget that uses extension-based feature system
class FieldWidget extends StatelessWidget {
  final FieldConfig field;
  final TextEditingController? controller;
  final String? value;
  final Function(String) onChanged;
  final bool isRequired;
  final bool isLocked;
  final bool showLabel;
  final bool showFeatureBadges;

  const FieldWidget({
    super.key,
    required this.field,
    this.controller,
    this.value,
    required this.onChanged,
    this.isRequired = false,
    this.isLocked = false,
    this.showLabel = true,
    this.showFeatureBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if field should be hidden
    if (field.hasFeature(FieldFeature.hidden)) {
      return const SizedBox.shrink();
    }

    // Create internal controller if none provided
    final effectiveController = controller ?? TextEditingController();
    if (value != null) {
      effectiveController.text = value!;
    }

    // Build the field using the extension method
    return field.buildField(
      controller: effectiveController,
      onChanged: onChanged,
      isRequired: isRequired || field.isRequired,
      showLabel: showLabel,
    );
  }
}

/// Widget for building multiple fields with consistent styling
class FieldList extends StatelessWidget {
  final List<FieldConfig> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, String> values;
  final Function(String fieldName, String value) onFieldChanged;
  final bool showLabels;
  final bool showFeatureBadges;
  final double spacing;

  const FieldList({
    super.key,
    required this.fields,
    required this.controllers,
    this.values = const {},
    required this.onFieldChanged,
    this.showLabels = true,
    this.showFeatureBadges = true,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: fields.map((field) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: FieldWidget(
            field: field,
            controller: controllers[field.name],
            value: values[field.name],
            onChanged: (value) => onFieldChanged(field.name, value),
            isRequired: field.isRequired,
            showLabel: showLabels,
            showFeatureBadges: showFeatureBadges,
          ),
        );
      }).toList(),
    );
  }
}

/// Widget for displaying field features summary
class FieldFeaturesSummary extends StatelessWidget {
  final List<FieldConfig> fields;
  final bool showOnlyActiveFeatures;

  const FieldFeaturesSummary({
    super.key,
    required this.fields,
    this.showOnlyActiveFeatures = true,
  });

  @override
  Widget build(BuildContext context) {
    final allFeatures = <FieldFeature, int>{};

    for (final field in fields) {
      for (final feature in field.features) {
        allFeatures[feature] = (allFeatures[feature] ?? 0) + 1;
      }
    }

    if (allFeatures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الميزات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: allFeatures.entries.map((entry) {
              final feature = entry.key;
              final count = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getFeatureColor(feature).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getFeatureColor(feature).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFeatureIcon(feature),
                      size: 12,
                      color: _getFeatureColor(feature),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_getFeatureText(feature)} ($count)',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getFeatureColor(feature),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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

  IconData _getFeatureIcon(FieldFeature feature) {
    switch (feature) {
      case FieldFeature.plus:
        return Icons.add;
      case FieldFeature.md:
        return Icons.text_format;
      case FieldFeature.long:
        return Icons.text_fields;
      case FieldFeature.required:
        return Icons.star;
      case FieldFeature.readonly:
        return Icons.lock;
      case FieldFeature.searchable:
        return Icons.search;
      case FieldFeature.unique:
        return Icons.fingerprint;
      case FieldFeature.validated:
        return Icons.verified;
      default:
        return Icons.info;
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
      case FieldFeature.required:
        return 'مطلوب';
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
}
