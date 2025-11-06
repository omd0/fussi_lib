import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/field_config.dart';
import '../../form/validators/form_validators.dart';
import '../../widgets/form_fields/field_label_widget.dart';

/// Dropdown field widget extracted from adaptive_form_widget.
class DropdownFieldWidget extends StatefulWidget {
  final FieldConfig field;
  final String? value;
  final Function(String?) onChanged;
  final bool Function(String) isRequiredField;
  final Function(FieldConfig) onAddNewOption;

  const DropdownFieldWidget({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.isRequiredField,
    required this.onAddNewOption,
  });

  @override
  State<DropdownFieldWidget> createState() => _DropdownFieldWidgetState();
}

class _DropdownFieldWidgetState extends State<DropdownFieldWidget> {
  @override
  Widget build(BuildContext context) {
    final isDynamicField = widget.field.isDynamic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: widget.field,
          isRequired: widget.isRequiredField(widget.field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDynamicField
                  ? AppConstants.primaryColor.withOpacity(0.4)
                  : AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: widget.value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: Text(
              'اختر ${widget.field.displayName}',
              style: GoogleFonts.cairo(
                color: AppConstants.hintColor,
              ),
            ),
            validator: widget.isRequiredField(widget.field.name)
                ? (value) => value == null || value.isEmpty
                    ? 'يرجى اختيار ${widget.field.displayName}'
                    : null
                : null,
            items: [
              // Add "Other" option if field has "plus" feature
              if (widget.field.hasFeature(FieldFeature.plus))
                DropdownMenuItem<String>(
                  value: '__other__',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'أخرى (إضافة جديد)',
                        style: GoogleFonts.cairo(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // Add existing options
              ...widget.field.options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: GoogleFonts.cairo(),
                  ),
                );
              }).toList(),
            ],
            onChanged: (value) {
              if (value == '__other__') {
                widget.onAddNewOption(widget.field);
              } else {
                widget.onChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

