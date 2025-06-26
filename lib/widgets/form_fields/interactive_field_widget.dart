import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/field_config.dart';

/// Interactive field widget for sliders, ratings, checkboxes, etc.
class InteractiveFieldWidget extends StatelessWidget {
  final FieldConfig field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final bool isRequired;
  final bool isLocked;

  const InteractiveFieldWidget({
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
        _buildInteractiveField(),
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

  Widget _buildInteractiveField() {
    switch (field.type) {
      case FieldType.slider:
        return _buildSlider();
      case FieldType.rating:
        return _buildRating();
      case FieldType.checkbox:
        return _buildCheckbox();
      case FieldType.radio:
        return _buildRadio();
      case FieldType.color:
        return _buildColorPicker();
      default:
        return _buildSlider(); // Default fallback
    }
  }

  Widget _buildSlider() {
    final double currentValue = value is num ? value.toDouble() : 0.0;
    final double minValue = field.minValue?.toDouble() ?? 0.0;
    final double maxValue = field.maxValue?.toDouble() ?? 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minValue.toInt().toString(),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.hintColor,
              ),
            ),
            Text(
              'القيمة: ${currentValue.toInt()}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
            Text(
              maxValue.toInt().toString(),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: currentValue.clamp(minValue, maxValue),
          min: minValue,
          max: maxValue,
          divisions: (maxValue - minValue).toInt(),
          activeColor: AppConstants.primaryColor,
          inactiveColor: AppConstants.hintColor.withOpacity(0.3),
          onChanged: isLocked ? null : (double val) => onChanged(val),
        ),
      ],
    );
  }

  Widget _buildRating() {
    final int currentRating = value is num ? value.toInt() : 0;
    final int maxRating = field.maxValue?.toInt() ?? 5;

    return Row(
      children: List.generate(maxRating, (index) {
        return GestureDetector(
          onTap: isLocked ? null : () => onChanged(index + 1),
          child: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color:
                index < currentRating ? Colors.amber : AppConstants.hintColor,
            size: 32,
          ),
        );
      }),
    );
  }

  Widget _buildCheckbox() {
    final bool isChecked = value is bool ? value : false;

    return CheckboxListTile(
      title: Text(
        field.displayName,
        style: GoogleFonts.cairo(
          fontSize: 16,
          color: AppConstants.textColor,
        ),
      ),
      value: isChecked,
      activeColor: AppConstants.primaryColor,
      onChanged: isLocked ? null : (bool? val) => onChanged(val ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildRadio() {
    final String selectedValue = value?.toString() ?? '';

    return Column(
      children: field.options.map((option) {
        return RadioListTile<String>(
          title: Text(
            option,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppConstants.textColor,
            ),
          ),
          value: option,
          groupValue: selectedValue,
          activeColor: AppConstants.primaryColor,
          onChanged: isLocked ? null : (String? val) => onChanged(val),
        );
      }).toList(),
    );
  }

  Widget _buildColorPicker() {
    final Color selectedColor = value is Color ? value : Colors.blue;

    return GestureDetector(
      onTap: isLocked ? null : () => _showColorPicker(),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.hintColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'اختر لون',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: _getContrastColor(selectedColor),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Simple contrast calculation
    final double luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _showColorPicker() {
    // This would show a color picker dialog
    // Implementation depends on the specific color picker package used
    // For now, just cycling through some preset colors
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final currentIndex = colors.indexOf(value is Color ? value : Colors.blue);
    final nextIndex = (currentIndex + 1) % colors.length;
    onChanged(colors[nextIndex]);
  }
}
