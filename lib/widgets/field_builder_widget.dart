import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/book.dart';
import '../models/field_config.dart';
import '../models/location_data.dart';
import '../widgets/arabic_form_field.dart';
import '../widgets/location_selector_widget.dart';

/// Simple mocked field builder widget using DATA MODEL approach only
class FieldBuilderWidget extends ConsumerStatefulWidget {
  final FieldConfig field;
  final TextEditingController? controller;
  final String? value;
  final Function(String) onChanged;
  final bool isRequired;
  final bool isLocked;
  final List<String> options;
  final LocationData? locationData;
  final bool showLabel;

  const FieldBuilderWidget({
    super.key,
    required this.field,
    this.controller,
    this.value,
    required this.onChanged,
    this.isRequired = false,
    this.isLocked = false,
    this.options = const [],
    this.locationData,
    this.showLabel = true,
  });

  @override
  ConsumerState<FieldBuilderWidget> createState() => _FieldBuilderWidgetState();
}

/// Mocked icon system using data model approach - no external dependencies
class FieldTypeIconMapper {
  static IconData getIconForFieldType(FieldType fieldType) {
    // Mocked with simple default icon - using data model approach
    return Icons.edit; // Simple mock icon for all field types
  }

  /// Get icon name for debugging/display purposes
  static String getIconNameForFieldType(FieldType fieldType) {
    // Simple mock icon name for all field types
    return 'edit';
  }
}

class _FieldBuilderWidgetState extends ConsumerState<FieldBuilderWidget> {
  late TextEditingController _internalController;
  String? _dropdownValue;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    if (widget.value != null) {
      _internalController.text = widget.value!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) _buildFieldLabel(),
        const SizedBox(height: 8),
        _buildFieldWidget(),
      ],
    );
  }

  Widget _buildFieldLabel() {
    return Row(
      children: [
        // Simple mocked icon using data model approach
        Icon(
          Icons.edit, // Mocked icon for all field types
          size: 16,
          color: widget.isLocked
              ? AppConstants.primaryColor
              : AppConstants.hintColor,
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.field.displayName}${widget.isRequired ? ' *' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: widget.isLocked
                ? AppConstants.primaryColor
                : AppConstants.textColor,
          ),
        ),
        if (widget.field.features.isNotEmpty) ...[
          const SizedBox(width: 8),
          ...widget.field.features
              .take(2)
              .map((feature) => _buildFeatureBadge(feature)),
        ],
      ],
    );
  }

  Widget _buildFeatureBadge(FieldFeature feature) {
    Color badgeColor;
    switch (feature) {
      case FieldFeature.required:
        badgeColor = Colors.red;
        break;
      case FieldFeature.plus:
        badgeColor = AppConstants.primaryColor;
        break;
      case FieldFeature.md:
        badgeColor = AppConstants.secondaryColor;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        feature.displayName,
        style: GoogleFonts.cairo(
          fontSize: 10,
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFieldWidget() {
    // Using DATA MODEL approach - switch based on enum type
    switch (widget.field.type) {
      case FieldType.dropdown:
        return _buildDropdownField();
      case FieldType.locationCompound:
        return _buildLocationField();
      case FieldType.textarea:
        return _buildTextAreaField();
      case FieldType.number:
        return _buildNumberField();
      case FieldType.email:
        return _buildEmailField();
      case FieldType.phone:
        return _buildPhoneField();
      case FieldType.password:
        return _buildPasswordField();
      default:
        return _buildTextField();
    }
  }

  Widget _buildTextField() {
    return ArabicFormField(
      hint: 'أدخل ${widget.field.displayName}',
      controller: _internalController,
      isRequired: widget.isRequired,
      icon: Icons.edit, // Mocked icon
      onChanged: (value) => widget.onChanged(value),
    );
  }

  Widget _buildTextAreaField() {
    return ArabicFormField(
      hint: 'أدخل ${widget.field.displayName}',
      controller: _internalController,
      isRequired: widget.isRequired,
      maxLines: widget.field.hasFeature(FieldFeature.long) ? 8 : 4,
      icon: Icons.description, // Mocked icon
      onChanged: (value) => widget.onChanged(value),
    );
  }

  Widget _buildNumberField() {
    return ArabicFormField(
      hint: 'أدخل ${widget.field.displayName}',
      controller: _internalController,
      isRequired: widget.isRequired,
      keyboardType: TextInputType.number,
      icon: Icons.numbers, // Mocked icon
      onChanged: (value) => widget.onChanged(value),
    );
  }

  Widget _buildEmailField() {
    return ArabicFormField(
      hint: 'أدخل ${widget.field.displayName}',
      controller: _internalController,
      isRequired: widget.isRequired,
      keyboardType: TextInputType.emailAddress,
      icon: Icons.email, // Mocked icon
      onChanged: (value) => widget.onChanged(value),
    );
  }

  Widget _buildPhoneField() {
    return ArabicFormField(
      hint: 'أدخل ${widget.field.displayName}',
      controller: _internalController,
      isRequired: widget.isRequired,
      keyboardType: TextInputType.phone,
      icon: Icons.phone, // Mocked icon
      onChanged: (value) => widget.onChanged(value),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.hintColor.withOpacity(0.2),
        ),
      ),
      child: TextFormField(
        controller: _internalController,
        obscureText: true,
        enabled: !widget.isLocked,
        decoration: InputDecoration(
          hintText: 'أدخل ${widget.field.displayName}',
          hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
          prefixIcon:
              Icon(Icons.lock, color: AppConstants.hintColor), // Mocked icon
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: GoogleFonts.cairo(
          fontSize: 16,
          color: AppConstants.textColor,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isLocked
              ? AppConstants.primaryColor.withOpacity(0.3)
              : AppConstants.hintColor.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _dropdownValue,
        decoration: InputDecoration(
          hintText: 'اختر ${widget.field.displayName}',
          hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
          prefixIcon: Icon(Icons.arrow_drop_down,
              color: AppConstants.hintColor), // Mocked icon
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        items: widget.options
            .map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: GoogleFonts.cairo()),
                ))
            .toList(),
        onChanged: widget.isLocked
            ? null
            : (value) {
                setState(() => _dropdownValue = value);
                widget.onChanged(value ?? '');
              },
      ),
    );
  }

  Widget _buildLocationField() {
    return LocationSelectorWidget(
      title: widget.field.displayName,
      selectedLocation:
          _internalController.text.isNotEmpty ? _internalController.text : null,
      onLocationSelected: widget.isLocked
          ? (String? location) {}
          : (String? location) {
              if (location != null) {
                _internalController.text = location;
                widget.onChanged(location);
              }
            },
      mode: LocationSelectorMode.popup,
      isRequired: widget.isRequired,
      placeholder: 'اختر ${widget.field.displayName}',
    );
  }
}
