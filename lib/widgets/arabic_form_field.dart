import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../form/decorations/input_decorations.dart';
import '../form/validators/form_validators.dart';

class ArabicFormField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isRequired;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final IconData? icon;

  const ArabicFormField({
    super.key,
    required this.hint,
    required this.controller,
    this.isRequired = true,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: GoogleFonts.cairo(
          fontSize: 16,
          color: AppConstants.textColor,
        ),
        decoration: InputDecorations.buildArabicDecoration(
          hint: hint,
          icon: icon,
        ),
        validator: validator ??
            (isRequired ? FormValidators.defaultRequiredValidator : null),
        onChanged: onChanged,
      ),
    );
  }
}

class ArabicDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final bool isRequired;
  final IconData? icon;

  const ArabicDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecorations.buildArabicDecoration(
          hint: 'اختر $label',
          icon: icon,
        ),
        style: GoogleFonts.cairo(
          fontSize: 16,
          color: AppConstants.textColor,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppConstants.textColor,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى اختيار التصنيف';
                }
                return null;
              }
            : null,
      ),
    );
  }
}
