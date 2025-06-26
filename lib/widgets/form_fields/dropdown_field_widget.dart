import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/field_config.dart';
import '../arabic_form_field.dart';

/// Dropdown field widget component extracted from dynamic_form_widget
class DropdownFieldWidget extends StatelessWidget {
  final FieldConfig field;
  final String? value;
  final Function(String?) onChanged;
  final bool isRequired;
  final bool isLocked;

  const DropdownFieldWidget({
    super.key,
    required this.field,
    this.value,
    required this.onChanged,
    this.isRequired = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 8),
        _buildDropdown(),
      ],
    );
  }

  Widget _buildLabel() {
    return Text(
      '${field.displayName}${isRequired ? ' *' : ''}',
      style: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isLocked ? AppConstants.primaryColor : AppConstants.textColor,
      ),
    );
  }

  Widget _buildDropdown() {
    return ArabicDropdownField(
      label: field.displayName,
      value: value,
      items: field.options,
      onChanged: isLocked ? (_) {} : (String? val) => onChanged(val),
      isRequired: isRequired,
      icon: _getIconForField(),
    );
  }

  IconData _getIconForField() {
    switch (field.type) {
      case FieldType.dropdown:
        return Icons.arrow_drop_down;
      default:
        return Icons.list;
    }
  }
}

/// Autocomplete field widget component
class AutocompleteFieldWidget extends StatelessWidget {
  final FieldConfig field;
  final String? value;
  final Function(String?) onChanged;
  final bool isRequired;
  final bool isLocked;

  const AutocompleteFieldWidget({
    super.key,
    required this.field,
    this.value,
    required this.onChanged,
    this.isRequired = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 8),
        _buildAutocomplete(),
      ],
    );
  }

  Widget _buildLabel() {
    return Text(
      '${field.displayName}${isRequired ? ' *' : ''}',
      style: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isLocked ? AppConstants.primaryColor : AppConstants.textColor,
      ),
    );
  }

  Widget _buildAutocomplete() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Autocomplete<String>(
        initialValue: value != null ? TextEditingValue(text: value!) : null,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return field.options.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          onChanged(selection);
        },
        fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppConstants.textColor,
            ),
            decoration: InputDecoration(
              hintText: 'اختر أو أكتب ${field.displayName}',
              hintStyle: GoogleFonts.cairo(
                color: AppConstants.hintColor,
              ),
              filled: true,
              fillColor: AppConstants.backgroundColor,
              prefixIcon:
                  const Icon(Icons.search, color: AppConstants.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppConstants.hintColor.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppConstants.hintColor.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppConstants.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            enabled: !isLocked,
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'هذا الحقل مطلوب';
                    }
                    return null;
                  }
                : null,
            onFieldSubmitted: (String value) {
              onChanged(value);
            },
          );
        },
        optionsViewBuilder: (BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return ListTile(
                      title: Text(
                        option,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: AppConstants.textColor,
                        ),
                      ),
                      onTap: () {
                        onSelected(option);
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
