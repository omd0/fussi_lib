import 'package:flutter/material.dart';
import '../../models/field_config.dart';
import '../../models/form_structure.dart';
import '../../widgets/arabic_form_field.dart';
import '../../widgets/form_fields/field_label_widget.dart';
import '../../form/utils/form_state_manager.dart';
import '../../form/validators/form_validators.dart';
import '../../utils/arabic/arabic_validators.dart';
import '../../form/decorations/input_decorations.dart';

/// Factory class for building form field widgets based on field configuration.
/// 
/// This class provides a centralized way to create field widgets
/// and delegates to specialized builders for each field type.
class FieldBuilders {
  final FormStateManager stateManager;
  final FormStructure structure;
  final BuildContext context;
  final Function(FieldConfig, String) onFieldChanged;
  final bool Function(String) isRequiredField;
  final VoidCallback Function() getSetState;

  FieldBuilders({
    required this.stateManager,
    required this.structure,
    required this.context,
    required this.onFieldChanged,
    required this.isRequiredField,
    required this.getSetState,
  });

  /// Build a field widget based on the field configuration.
  Widget buildField(FieldConfig field) {
    // Check if field should be hidden
    if (field.hasFeature(FieldFeature.hidden)) {
      return const SizedBox.shrink();
    }

    Widget fieldWidget;
    switch (field.type) {
      case FieldType.dropdown:
        fieldWidget = _buildDropdownField(field);
        break;
      case FieldType.locationCompound:
        fieldWidget = _buildLocationCompoundField(field);
        break;
      case FieldType.autocomplete:
        fieldWidget = _buildAutocompleteField(field);
        break;
      case FieldType.text:
        if (field.hasFeature(FieldFeature.md)) {
          fieldWidget = _buildTextFieldWithMarkdown(field);
        } else if (field.hasFeature(FieldFeature.long)) {
          fieldWidget = _buildTextFieldMultiline(field);
        } else {
          fieldWidget = _buildTextField(field);
        }
        break;
      case FieldType.textarea:
        fieldWidget = _buildTextFieldMultiline(field);
        break;
      case FieldType.number:
        fieldWidget = _buildNumberField(field);
        break;
      case FieldType.email:
        fieldWidget = _buildEmailField(field);
        break;
      case FieldType.phone:
        fieldWidget = _buildPhoneField(field);
        break;
      case FieldType.url:
        fieldWidget = _buildUrlField(field);
        break;
      case FieldType.password:
        fieldWidget = _buildPasswordField(field);
        break;
      case FieldType.checkbox:
        fieldWidget = _buildCheckboxField(field);
        break;
      case FieldType.date:
        fieldWidget = _buildDateField(field);
        break;
      case FieldType.time:
        fieldWidget = _buildTimeField(field);
        break;
      case FieldType.datetime:
        fieldWidget = _buildDateTimeField(field);
        break;
      default:
        fieldWidget = _buildTextField(field);
    }

    return fieldWidget;
  }

  Widget _buildTextField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: controller,
          isRequired: isRequiredField(field.name),
          onChanged: (value) => onFieldChanged(field, value),
        ),
      ],
    );
  }

  Widget _buildTextFieldMultiline(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: controller,
          isRequired: isRequiredField(field.name),
          maxLines: 5,
          onChanged: (value) => onFieldChanged(field, value),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithMarkdown(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FieldLabelWidget(
              field: field,
              isRequired: isRequiredField(field.name),
              isLocked: false,
              showIcon: true,
              showFeatureBadges: true,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'تنسيق',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName} (يدعم التنسيق)',
          controller: controller,
          isRequired: isRequiredField(field.name),
          maxLines: 3,
          onChanged: (value) => onFieldChanged(field, value),
        ),
      ],
    );
  }

  Widget _buildNumberField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: controller,
          isRequired: isRequiredField(field.name),
          keyboardType: TextInputType.number,
          onChanged: (value) => onFieldChanged(field, value),
        ),
      ],
    );
  }

  Widget _buildEmailField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: controller,
          isRequired: isRequiredField(field.name),
          keyboardType: TextInputType.emailAddress,
          validator: FormValidators.emailValidator,
          onChanged: (value) => onFieldChanged(field, value),
        ),
      ],
    );
  }

  Widget _buildPhoneField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: controller,
          isRequired: isRequiredField(field.name),
          keyboardType: TextInputType.phone,
          validator: FormValidators.phoneValidator,
          onChanged: (value) => onFieldChanged(field, value),
        ),
      ],
    );
  }

  Widget _buildUrlField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: controller,
          isRequired: isRequiredField(field.name),
          keyboardType: TextInputType.url,
          validator: FormValidators.urlValidator,
          onChanged: (value) => onFieldChanged(field, value),
        ),
      ],
    );
  }

  Widget _buildPasswordField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: controller,
          isRequired: isRequiredField(field.name),
          keyboardType: TextInputType.visiblePassword,
          onChanged: (value) => onFieldChanged(field, value),
        ),
      ],
    );
  }

  Widget _buildCheckboxField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return CheckboxListTile(
      title: Text(field.displayName),
      value: controller.text == 'true' || controller.text == '1',
      onChanged: (value) {
        controller.text = value == true ? 'true' : 'false';
        onFieldChanged(field, controller.text);
      },
    );
  }

  Widget _buildDropdownField(FieldConfig field) {
    // This will be handled by a more specialized widget
    // For now, return a placeholder
    return const SizedBox();
  }

  Widget _buildAutocompleteField(FieldConfig field) {
    // This will be handled by a more specialized widget
    // For now, return a placeholder
    return const SizedBox();
  }

  Widget _buildLocationCompoundField(FieldConfig field) {
    // This will be handled by a more specialized widget
    // For now, return a placeholder
    return const SizedBox();
  }

  Widget _buildDateField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              locale: const Locale('ar'),
            );
            if (date != null) {
              controller.text =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              onFieldChanged(field, controller.text);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(controller.text.isEmpty ? 'اختر التاريخ' : controller.text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              controller.text = '${time.hour}:${time.minute}';
              onFieldChanged(field, controller.text);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 8),
                Text(controller.text.isEmpty ? 'اختر الوقت' : controller.text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(FieldConfig field) {
    final controller = stateManager.getController(field.name);
    if (controller == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: field,
          isRequired: isRequiredField(field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
              locale: const Locale('ar'),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                final dateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
                controller.text = dateTime.toIso8601String();
                onFieldChanged(field, controller.text);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(controller.text.isEmpty ? 'اختر التاريخ والوقت' : controller.text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

