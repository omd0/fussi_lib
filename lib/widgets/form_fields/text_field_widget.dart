import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/field_config.dart';
import '../arabic_form_field.dart';

/// Text field widget component extracted from adaptive_form_widget
class TextFieldWidget extends StatelessWidget {
  final FieldConfig field;
  final TextEditingController? controller;
  final String? value;
  final Function(String) onChanged;
  final bool isRequired;
  final bool isLocked;

  const TextFieldWidget({
    super.key,
    required this.field,
    this.controller,
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
        _buildTextField(),
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

  Widget _buildTextField() {
    if (field.hasFeature(FieldFeature.long) ||
        field.type == FieldType.textarea) {
      return _buildTextAreaField();
    } else if (field.type == FieldType.number) {
      return _buildNumberField();
    } else if (field.type == FieldType.email) {
      return _buildEmailField();
    } else if (field.type == FieldType.phone) {
      return _buildPhoneField();
    } else if (field.type == FieldType.url) {
      return _buildUrlField();
    } else if (field.type == FieldType.password) {
      return _buildPasswordField();
    } else {
      return _buildBasicTextField();
    }
  }

  Widget _buildBasicTextField() {
    if (controller == null) return const SizedBox.shrink();
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller!,
      isRequired: isRequired,
      icon: Icons.text_fields,
      onChanged: onChanged,
    );
  }

  Widget _buildTextAreaField() {
    if (controller == null) return const SizedBox.shrink();
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller!,
      isRequired: isRequired,
      maxLines: field.hasFeature(FieldFeature.long) ? 8 : 4,
      icon: Icons.description,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField() {
    if (controller == null) return const SizedBox.shrink();
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller!,
      isRequired: isRequired,
      keyboardType: TextInputType.number,
      icon: Icons.numbers,
      onChanged: onChanged,
    );
  }

  Widget _buildEmailField() {
    if (controller == null) return const SizedBox.shrink();
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller!,
      isRequired: isRequired,
      keyboardType: TextInputType.emailAddress,
      icon: Icons.email,
      onChanged: onChanged,
    );
  }

  Widget _buildPhoneField() {
    if (controller == null) return const SizedBox.shrink();
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller!,
      isRequired: isRequired,
      keyboardType: TextInputType.phone,
      icon: Icons.phone,
      onChanged: onChanged,
    );
  }

  Widget _buildUrlField() {
    if (controller == null) return const SizedBox.shrink();
    return ArabicFormField(
      hint: 'أدخل ${field.displayName}',
      controller: controller!,
      isRequired: isRequired,
      keyboardType: TextInputType.url,
      icon: Icons.link,
      onChanged: onChanged,
    );
  }

  Widget _buildPasswordField() {
    if (controller == null) return const SizedBox.shrink();
    // Create a custom password field since ArabicFormField doesn't support isPassword
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        controller: controller!,
        obscureText: true,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'أدخل ${field.displayName}',
          prefixIcon: const Icon(Icons.lock),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'هذا الحقل مطلوب';
                }
                return null;
              }
            : null,
        onChanged: onChanged,
      ),
    );
  }
}
