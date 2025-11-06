/// Form validation utilities for consistent validation across the application.
/// 
/// This class provides reusable validator functions for various form field types,
/// including Arabic and English field validations.
class FormValidators {
  /// Default required field validator for Arabic fields.
  /// 
  /// Returns an error message in Arabic if the field is empty or null.
  /// 
  /// Parameters:
  /// - [value]: The field value to validate
  /// 
  /// Returns:
  /// - `null` if the value is valid
  /// - Error message string if validation fails
  static String? defaultRequiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  /// Required field validator with custom field name.
  /// 
  /// Provides a more descriptive error message with the field name.
  /// 
  /// Parameters:
  /// - [value]: The field value to validate
  /// - [fieldName]: The display name of the field (for error message)
  /// 
  /// Returns:
  /// - `null` if the value is valid
  /// - Error message string if validation fails
  static String? requiredFieldValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }

  /// Required selection validator for dropdown fields.
  /// 
  /// Validates that a selection has been made in dropdown/select fields.
  /// 
  /// Parameters:
  /// - [value]: The selected value
  /// - [fieldName]: The display name of the field (for error message)
  /// 
  /// Returns:
  /// - `null` if a value is selected
  /// - Error message string if no selection is made
  static String? requiredSelectionValidator(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى اختيار $fieldName';
    }
    return null;
  }

  /// Email address validator.
  /// 
  /// Validates that the input follows proper email format.
  /// 
  /// Parameters:
  /// - [value]: The email value to validate
  /// 
  /// Returns:
  /// - `null` if the email is valid or empty (use with required validator)
  /// - Error message string if email format is invalid
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }

    // Email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    return null;
  }

  /// Phone number validator.
  /// 
  /// Validates that the input follows proper phone number format.
  /// Supports various phone number formats.
  /// 
  /// Parameters:
  /// - [value]: The phone value to validate
  /// 
  /// Returns:
  /// - `null` if the phone is valid or empty (use with required validator)
  /// - Error message string if phone format is invalid
  static String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }

    // Remove common formatting characters
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it's all digits and has reasonable length (7-15 digits)
    if (!RegExp(r'^\d{7,15}$').hasMatch(cleaned)) {
      return 'يرجى إدخال رقم هاتف صحيح';
    }

    return null;
  }

  /// URL validator.
  /// 
  /// Validates that the input follows proper URL format.
  /// 
  /// Parameters:
  /// - [value]: The URL value to validate
  /// 
  /// Returns:
  /// - `null` if the URL is valid or empty (use with required validator)
  /// - Error message string if URL format is invalid
  static String? urlValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }

    // URL regex pattern
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'يرجى إدخال رابط صحيح (يجب أن يبدأ بـ http:// أو https://)';
    }

    return null;
  }

  /// Number validator.
  /// 
  /// Validates that the input is a valid number.
  /// 
  /// Parameters:
  /// - [value]: The number value to validate
  /// 
  /// Returns:
  /// - `null` if the number is valid or empty (use with required validator)
  /// - Error message string if number format is invalid
  static String? numberValidator(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Let required validator handle empty values
    }

    // Check if it's a valid number (integer or decimal)
    if (double.tryParse(value) == null) {
      return 'يرجى إدخال رقم صحيح';
    }

    return null;
  }

  /// Combined validator for required and type-specific validation.
  /// 
  /// This is a convenience method that combines required validation with
  /// a specific type validator (email, phone, URL, etc.).
  /// 
  /// Parameters:
  /// - [value]: The field value to validate
  /// - [fieldName]: The display name of the field (for error message)
  /// - [isRequired]: Whether the field is required
  /// - [typeValidator]: Optional specific type validator function
  /// 
  /// Returns:
  /// - `null` if validation passes
  /// - Error message string if validation fails
  static String? combinedValidator(
    String? value,
    String fieldName, {
    bool isRequired = true,
    String? Function(String?)? typeValidator,
  }) {
    // First check if required
    if (isRequired) {
      final requiredError = requiredFieldValidator(value, fieldName);
      if (requiredError != null) {
        return requiredError;
      }
    }

    // Then check type-specific validation if provided
    if (typeValidator != null && value != null && value.isNotEmpty) {
      return typeValidator(value);
    }

    return null;
  }

  /// Checks if a field name indicates it's a required field.
  /// 
  /// This is a helper method to determine if a field should be required
  /// based on its name matching common required field patterns.
  /// 
  /// Parameters:
  /// - [fieldName]: The name of the field to check
  /// 
  /// Returns:
  /// - `true` if the field is required based on its name
  /// - `false` otherwise
  static bool isRequiredField(String fieldName) {
    final requiredFields = ['اسم الكتاب', 'اسم المؤلف', 'التصنيف', 'الموقع'];
    return requiredFields.any((required) => fieldName.contains(required));
  }

  /// Validates uniqueness of a field value.
  /// 
  /// This is a placeholder for uniqueness validation that can be extended
  /// to check against existing data in the database.
  /// 
  /// Parameters:
  /// - [fieldName]: The name of the field being validated
  /// - [value]: The value to check for uniqueness
  /// 
  /// Returns:
  /// - `null` if the value is unique or validation passes
  /// - Error message string if the value is not unique
  static String? validateUniqueness(String fieldName, String value) {
    // TODO: Implement actual uniqueness check against database
    // This is a placeholder that can be extended
    if (value.isEmpty) return null;
    
    // Example: Check uniqueness (to be implemented with actual data source)
    print('🔍 Validating uniqueness for $fieldName: $value');
    
    return null; // For now, always passes
  }

  /// Performs custom validation rules for a field.
  /// 
  /// This is a placeholder for custom validation logic that can be extended
  /// based on specific field requirements.
  /// 
  /// Parameters:
  /// - [fieldName]: The name of the field being validated
  /// - [value]: The value to validate
  /// 
  /// Returns:
  /// - `null` if validation passes
  /// - Error message string if validation fails
  static String? performCustomValidation(String fieldName, String value) {
    // TODO: Implement custom validation rules based on field requirements
    // This is a placeholder that can be extended
    if (value.isEmpty) return null;
    
    // Example: Custom validation (to be implemented based on requirements)
    print('✅ Custom validation for $fieldName: $value');
    
    return null; // For now, always passes
  }
}

