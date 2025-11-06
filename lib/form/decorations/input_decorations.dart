import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';

/// Form input decoration utilities for creating consistent form field decorations.
/// 
/// This class provides reusable InputDecoration builders for Arabic and
/// standard form fields, ensuring consistent styling across the application.
class InputDecorations {
  /// Creates an Arabic-styled InputDecoration with RTL support.
  /// 
  /// This decoration is optimized for Arabic text input with:
  /// - Cairo font for Arabic text
  /// - RTL-friendly styling
  /// - Consistent border radius and colors from AppConstants
  /// 
  /// Parameters:
  /// - [hint]: The hint text to display in the field
  /// - [icon]: Optional icon to display as prefix
  /// 
  /// Returns:
  /// An [InputDecoration] configured for Arabic form fields
  static InputDecoration buildArabicDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.cairo(
        color: AppConstants.hintColor,
      ),
      filled: true,
      fillColor: AppConstants.backgroundColor,
      prefixIcon: icon != null ? Icon(icon, color: AppConstants.hintColor) : null,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  /// Creates a default InputDecoration with standard styling.
  /// 
  /// This decoration provides a consistent look for non-Arabic form fields.
  /// 
  /// Parameters:
  /// - [hint]: The hint text to display in the field
  /// - [icon]: Optional icon to display as prefix
  /// 
  /// Returns:
  /// An [InputDecoration] with standard styling
  static InputDecoration buildDefaultDecoration({
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppConstants.hintColor,
      ),
      filled: true,
      fillColor: AppConstants.backgroundColor,
      prefixIcon: icon != null ? Icon(icon, color: AppConstants.hintColor) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide(
          color: AppConstants.hintColor.withOpacity(0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide(
          color: AppConstants.hintColor.withOpacity(0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(
          color: AppConstants.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}

