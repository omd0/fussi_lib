import 'package:flutter/material.dart';
import '../../models/field_config.dart';

/// Abstract base class for field feature decorators
abstract class FieldFeatureDecorator {
  /// The feature this decorator handles
  FieldFeature get feature;

  /// Whether this decorator can be applied to the given field
  bool canApply(FieldConfig field);

  /// Apply the feature to the widget
  Widget decorate(FieldConfig field, Widget child);

  /// Get the priority of this decorator (higher = applied later)
  int get priority => 0;
}

/// Decorator for markdown feature
class MarkdownFeatureDecorator extends FieldFeatureDecorator {
  @override
  FieldFeature get feature => FieldFeature.md;

  @override
  bool canApply(FieldConfig field) => field.hasFeature(FieldFeature.md);

  @override
  Widget decorate(FieldConfig field, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: child),
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

  @override
  int get priority => 10;
}

/// Decorator for long text feature
class LongTextFeatureDecorator extends FieldFeatureDecorator {
  @override
  FieldFeature get feature => FieldFeature.long;

  @override
  bool canApply(FieldConfig field) => field.hasFeature(FieldFeature.long);

  @override
  Widget decorate(FieldConfig field, Widget child) {
    // For long text, we modify the child widget itself
    // Note: This would need to be implemented based on your specific form field type
    return child;
  }

  @override
  int get priority => 5;
}

/// Decorator for required feature
class RequiredFeatureDecorator extends FieldFeatureDecorator {
  @override
  FieldFeature get feature => FieldFeature.required;

  @override
  bool canApply(FieldConfig field) => field.hasFeature(FieldFeature.required);

  @override
  Widget decorate(FieldConfig field, Widget child) {
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
        child,
      ],
    );
  }

  @override
  int get priority => 1;
}

/// Decorator for readonly feature
class ReadonlyFeatureDecorator extends FieldFeatureDecorator {
  @override
  FieldFeature get feature => FieldFeature.readonly;

  @override
  bool canApply(FieldConfig field) => field.hasFeature(FieldFeature.readonly);

  @override
  Widget decorate(FieldConfig field, Widget child) {
    // Add readonly styling wrapper
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: child,
    );
  }

  @override
  int get priority => 8;
}

/// Decorator for validation feature
class ValidationFeatureDecorator extends FieldFeatureDecorator {
  @override
  FieldFeature get feature => FieldFeature.validated;

  @override
  bool canApply(FieldConfig field) => field.hasFeature(FieldFeature.validated);

  @override
  Widget decorate(FieldConfig field, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.verified,
              size: 16,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
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

  @override
  int get priority => 15;
}

/// Decorator for searchable feature
class SearchableFeatureDecorator extends FieldFeatureDecorator {
  @override
  FieldFeature get feature => FieldFeature.searchable;

  @override
  bool canApply(FieldConfig field) => field.hasFeature(FieldFeature.searchable);

  @override
  Widget decorate(FieldConfig field, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.search,
              size: 16,
              color: Colors.blue,
            ),
            const SizedBox(width: 4),
            Text(
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

  @override
  int get priority => 12;
}

/// Decorator for unique feature
class UniqueFeatureDecorator extends FieldFeatureDecorator {
  @override
  FieldFeature get feature => FieldFeature.unique;

  @override
  bool canApply(FieldConfig field) => field.hasFeature(FieldFeature.unique);

  @override
  Widget decorate(FieldConfig field, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.fingerprint,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
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

  @override
  int get priority => 12;
}
