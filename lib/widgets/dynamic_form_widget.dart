import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/book.dart';
import '../models/field_config.dart';
import '../models/form_structure.dart';
import '../models/location_data.dart';
import '../utils/arabic_text_utils.dart';
import '../widgets/arabic_form_field.dart';
import '../services/local_database_service.dart';

class DynamicFormWidget extends StatefulWidget {
  final FormStructure structure;
  final Function(Map<String, String>) onFormSubmit;
  final bool isLoading;
  final bool lockModeEnabled;
  final Map<String, bool> lockedFields;
  final Map<String, String> lockedValues;
  final Function(String) onToggleFieldLock;

  const DynamicFormWidget({
    super.key,
    required this.structure,
    required this.onFormSubmit,
    this.isLoading = false,
    this.lockModeEnabled = false,
    this.lockedFields = const {},
    this.lockedValues = const {},
    required this.onToggleFieldLock,
  });

  @override
  State<DynamicFormWidget> createState() => _DynamicFormWidgetState();
}

class _DynamicFormWidgetState extends State<DynamicFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, String?> _locationRows = {}; // For compound location fields
  final Map<String, String?> _locationColumns =
      {}; // For compound location fields
  final Map<String, String?> _locationRooms = {}; // For room selection

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final field in widget.structure.fields) {
      if (field.type == FieldType.text ||
          field.type == FieldType.autocomplete ||
          field.type == FieldType.textarea ||
          field.type == FieldType.number ||
          field.type == FieldType.email ||
          field.type == FieldType.phone ||
          field.type == FieldType.url ||
          field.type == FieldType.password ||
          field.type == FieldType.checkbox ||
          field.type == FieldType.date ||
          field.type == FieldType.time ||
          field.type == FieldType.datetime ||
          field.type == FieldType.radio ||
          field.type == FieldType.slider ||
          field.type == FieldType.rating ||
          field.type == FieldType.color ||
          field.type == FieldType.file ||
          field.type == FieldType.image ||
          field.type == FieldType.barcode ||
          field.type == FieldType.qrcode) {
        final controller = TextEditingController();
        // Set locked values if available
        if (widget.lockedValues.containsKey(field.name)) {
          controller.text = widget.lockedValues[field.name]!;
        }
        _controllers[field.name] = controller;
      }
    }

    // Set locked dropdown values
    for (final entry in widget.lockedValues.entries) {
      final field = widget.structure.getField(entry.key);
      if (field != null) {
        if (field.type == FieldType.dropdown) {
          _dropdownValues[entry.key] = entry.value;
        } else if (field.type == FieldType.locationCompound) {
          // Parse compound location (e.g., "Room1-B5" -> room "Room1", row "B", column "5")
          final value = entry.value;
          if (value.contains('-')) {
            final parts = value.split('-');
            if (parts.length == 2) {
              _locationRooms[entry.key] = parts[0];
              final locationPart = parts[1];
              if (locationPart.length >= 2) {
                final row = locationPart.substring(0, 1);
                final col = locationPart.substring(1);
                _locationRows[entry.key] = row;
                _locationColumns[entry.key] = col;
              }
            }
          } else if (value.length >= 2) {
            // Legacy format (e.g., "B5" -> row "B", column "5")
            final row = value.substring(0, 1);
            final col = value.substring(1);
            _locationRows[entry.key] = row;
            _locationColumns[entry.key] = col;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildFormField(FieldConfig field) {
    final isLockableField = _isLockableField(field.name);
    final isFieldLocked = widget.lockedFields[field.name] ?? false;

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
        // Check for features to determine text field type
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
      case FieldType.radio:
        fieldWidget = _buildRadioField(field);
        break;
      case FieldType.slider:
        fieldWidget = _buildSliderField(field);
        break;
      case FieldType.rating:
        fieldWidget = _buildRatingField(field);
        break;
      case FieldType.color:
        fieldWidget = _buildColorField(field);
        break;
      case FieldType.file:
        fieldWidget = _buildFileField(field);
        break;
      case FieldType.image:
        fieldWidget = _buildImageField(field);
        break;
      case FieldType.barcode:
        fieldWidget = _buildBarcodeField(field);
        break;
      case FieldType.qrcode:
        fieldWidget = _buildQRCodeField(field);
        break;
    }

    // Apply feature modifications to the field widget
    fieldWidget = _applyFieldFeatures(field, fieldWidget);

    // If lock mode is enabled and this is a lockable field, add lock button
    if (widget.lockModeEnabled && isLockableField) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: fieldWidget),
              const SizedBox(width: 8),
              _buildLockButton(field.name, isFieldLocked),
            ],
          ),
          if (isFieldLocked) _buildLockedIndicator(field.name),
        ],
      );
    }

    return fieldWidget;
  }

  Widget _buildTextField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          onChanged: (value) => _handleFieldInteraction(field, value),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithMarkdown(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'تنسيق',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppConstants.secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName} (يدعم التنسيق)',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          maxLines: 3,
          onChanged: (value) => _handleFieldInteraction(field, value),
        ),
      ],
    );
  }

  Widget _buildTextFieldMultiline(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'نص طويل',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          maxLines: 5,
          onChanged: (value) => _handleFieldInteraction(field, value),
        ),
      ],
    );
  }

  Widget _buildNumberField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildEmailField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildPhoneField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildUrlField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          hint: 'أدخل ${field.displayName}',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildPasswordField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            controller: _controllers[field.name]!,
            obscureText: true,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppConstants.textColor,
            ),
            decoration: InputDecoration(
              hintText: 'أدخل ${field.displayName}',
              hintStyle: GoogleFonts.cairo(
                color: AppConstants.hintColor,
              ),
              filled: true,
              fillColor: AppConstants.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(
                  color: AppConstants.hintColor.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                borderSide: BorderSide(
                  color: AppConstants.hintColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
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
            validator: _isRequiredField(field.name)
                ? (value) => value == null || value.isEmpty
                    ? 'يرجى إدخال ${field.displayName}'
                    : null
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxField(FieldConfig field) {
    // For checkbox fields, we need to track boolean state separately
    final checkboxValues = <String, bool>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        StatefulBuilder(
          builder: (context, setState) {
            final isChecked = checkboxValues[field.name] ?? false;
            return CheckboxListTile(
              title: Text(
                field.displayName,
                style: GoogleFonts.cairo(),
              ),
              value: isChecked,
              onChanged: (bool? value) {
                setState(() {
                  checkboxValues[field.name] = value ?? false;
                  // Update the text controller to store the boolean value as string
                  _controllers[field.name]!.text = (value ?? false).toString();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAutocompleteField(FieldConfig field) {
    final isDynamicField = field.isDynamic;

    // Debug print
    print(
        '🎯 Building autocomplete field for: "${field.displayName}" with ${field.options.length} options');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
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
          child: FutureBuilder<List<String>>(
            future: _getAutocompleteOptions(field),
            builder: (context, snapshot) {
              final options = snapshot.data ?? field.options;
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting;

              // Show loading indicator when data is loading
              if (isLoading && options.isEmpty) {
                return Container(
                  height: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'جاري تحميل الخيارات...',
                        style: GoogleFonts.cairo(
                          color: AppConstants.hintColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    // Show top 5 options when field is empty for better UX
                    return options.take(5);
                  }

                  // Enhanced Arabic text matching with fuzzy search
                  return options.where((String option) {
                    return ArabicTextUtils.arabicFuzzyMatch(
                        option, textEditingValue.text);
                  });
                },
                onSelected: (String selection) {
                  _controllers[field.name]!.text = selection;
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController fieldController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted) {
                  // Only set initial value if not already set to avoid cursor issues
                  if (fieldController.text != _controllers[field.name]!.text) {
                    fieldController.text = _controllers[field.name]!.text;
                  }

                  fieldController.addListener(() {
                    _controllers[field.name]!.text = fieldController.text;
                  });

                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: 'اكتب أو اختر ${field.displayName}',
                      hintStyle: GoogleFonts.cairo(
                        color: AppConstants.hintColor,
                      ),
                      suffixIcon: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.arrow_drop_down,
                              color: AppConstants.hintColor,
                            ),
                    ),
                    style: GoogleFonts.cairo(),
                    validator: _isRequiredField(field.name)
                        ? (value) => value == null || value.isEmpty
                            ? 'يرجى إدخال ${field.displayName}'
                            : null
                        : null,
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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth: MediaQuery.of(context).size.width - 40,
                        ),
                        child: options.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'لا توجد خيارات متاحة',
                                  style: GoogleFonts.cairo(
                                    color: AppConstants.hintColor,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option =
                                      options.elementAt(index);
                                  return ListTile(
                                    title: Text(
                                      option,
                                      style: GoogleFonts.cairo(),
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
              );
            },
          ),
        ),
      ],
    );
  }

  // Get autocomplete options for a field, with enhanced fallback logic
  Future<List<String>> _getAutocompleteOptions(FieldConfig field) async {
    final options = <String>{};

    // Always start with the field's predefined options
    options.addAll(field.options);

    // Special handling for author columns - get from multiple sources
    if (ArabicTextUtils.isAuthorColumn(field.name)) {
      try {
        // Get authors from local database
        final localDbService = LocalDatabaseService();
        final stats = await localDbService.getStatistics();
        final authorsData = stats['authors'] as List? ?? [];

        for (final author in authorsData) {
          if (author is Map<String, dynamic>) {
            final name = author['author_name']?.toString() ?? '';
            if (ArabicTextUtils.isValidAuthorName(name)) {
              options.add(name.trim());
            }
          }
        }

        print(
            '📚 Author autocomplete: ${options.length} total options (${field.options.length} from key sheet)');
      } catch (e) {
        print('⚠️ Failed to get local authors for autocomplete: $e');
      }
    }

    // For dynamic fields detected from key sheet, ensure we have good options
    final isDynamicField = field.isDynamic;
    if (isDynamicField) {
      print(
          '🎯 Dynamic field "${field.displayName}" has ${options.length} autocomplete options');

      // If this is a dynamic restriction column like "ممنوع", add common values
      if (ArabicTextUtils.isRestrictionColumn(field.name)) {
        options.addAll(ArabicTextUtils.getCommonRestrictionValues());
      }
    }

    final finalOptions = options.toList()..sort();

    // Ensure we have a reasonable number of options for autocomplete
    if (finalOptions.length < 3 && field.type == FieldType.autocomplete) {
      print(
          '⚠️ Few options for autocomplete field "${field.displayName}": ${finalOptions.length}');
    }

    return finalOptions;
  }

  Widget _buildLocationCompoundField(FieldConfig field) {
    // For location compound fields, get location data from the structure
    final locationData = widget.structure.locationData;
    final rowOptions = locationData?.rows ?? [];
    final columnOptions = locationData?.columns ?? [];
    final roomOptions = locationData?.rooms ?? [];

    // Check for layout features to determine display mode
    final bool isRowLayout = field.hasFeature(FieldFeature.row);
    final bool isColLayout = field.hasFeature(FieldFeature.col);

    // Default to grid if no specific layout feature is set
    final bool useSimpleLayout = isRowLayout || isColLayout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 16),
        if (useSimpleLayout)
          // Simple Row/Column Layout (inline)
          _buildSimpleLocationLayout(
              field, rowOptions, columnOptions, roomOptions, isRowLayout)
        else
          // Popup Location Selector Button (default)
          _buildLocationPopupButton(
              field, rowOptions, columnOptions, roomOptions),
      ],
    );
  }

  Widget _buildSimpleLocationLayout(FieldConfig field, List<String> rowOptions,
      List<String> columnOptions, List<String> roomOptions, bool isRowLayout) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'اختر موقع الكتاب',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isRowLayout)
            // Row layout (horizontal)
            Row(
              children: [
                // Column selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'العمود',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _locationColumns[field.name],
                            hint: Text(
                              'اختر العمود',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            isExpanded: true,
                            items: columnOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    value,
                                    style: GoogleFonts.cairo(fontSize: 14),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _locationColumns[field.name] = newValue;
                                if (newValue != null &&
                                    _locationRows[field.name] != null) {
                                  _handleFieldInteraction(field,
                                      '$newValue${_locationRows[field.name]}');
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Row selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الصف',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _locationRows[field.name],
                            hint: Text(
                              'اختر الصف',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            isExpanded: true,
                            items: rowOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Text(
                                    value,
                                    style: GoogleFonts.cairo(fontSize: 14),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _locationRows[field.name] = newValue;
                                if (newValue != null &&
                                    _locationColumns[field.name] != null) {
                                  _handleFieldInteraction(field,
                                      '${_locationColumns[field.name]}$newValue');
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            // Column layout (vertical)
            Column(
              children: [
                // Column selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'العمود',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _locationColumns[field.name],
                          hint: Text(
                            'اختر العمود',
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                          isExpanded: true,
                          items: columnOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  value,
                                  style: GoogleFonts.cairo(fontSize: 14),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _locationColumns[field.name] = newValue;
                              if (newValue != null &&
                                  _locationRows[field.name] != null) {
                                _handleFieldInteraction(field,
                                    '$newValue${_locationRows[field.name]}');
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الصف',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _locationRows[field.name],
                          hint: Text(
                            'اختر الصف',
                            style: GoogleFonts.cairo(fontSize: 12),
                          ),
                          isExpanded: true,
                          items: rowOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  value,
                                  style: GoogleFonts.cairo(fontSize: 14),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _locationRows[field.name] = newValue;
                              if (newValue != null &&
                                  _locationColumns[field.name] != null) {
                                _handleFieldInteraction(field,
                                    '${_locationColumns[field.name]}$newValue');
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Selected location display
          if (_locationRows[field.name] != null &&
              _locationColumns[field.name] != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppConstants.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'الموقع: ${_locationColumns[field.name]}${_locationRows[field.name]}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationPopupButton(FieldConfig field, List<String> rowOptions,
      List<String> columnOptions, List<String> roomOptions) {
    final hasRoomSelection =
        roomOptions.isNotEmpty && _locationRooms[field.name] != null;
    final hasLocationSelection = _locationRows[field.name] != null &&
        _locationColumns[field.name] != null;
    final hasSelection = hasLocationSelection;

    String? selectedLocation;
    if (hasSelection) {
      final baseLocation =
          '${_locationColumns[field.name]}${_locationRows[field.name]}';
      selectedLocation = hasRoomSelection
          ? '${_locationRooms[field.name]}-$baseLocation'
          : baseLocation;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              _showLocationSelectionPopup(field, rowOptions, columnOptions),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Location icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasSelection
                        ? AppConstants.primaryColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: hasSelection
                        ? AppConstants.primaryColor
                        : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Location text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSelection ? 'الموقع المحدد' : 'اختر موقع الكتاب',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasSelection
                              ? AppConstants.primaryColor
                              : AppConstants.textColor,
                        ),
                      ),
                      if (hasSelection) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            selectedLocation!,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Text(
                          'اضغط لفتح خريطة المكتبة',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppConstants.hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.keyboard_arrow_left,
                  color: AppConstants.hintColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationSelectionPopup(
      FieldConfig field, List<String> rowOptions, List<String> columnOptions) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Create local state variables for the dialog
        String? localSelectedRow = _locationRows[field.name];
        String? localSelectedCol = _locationColumns[field.name];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories,
                            color: AppConstants.primaryColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'اختر موقع الكتاب في المكتبة',
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            color: AppConstants.hintColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Library Grid
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.grey.shade50,
                                Colors.grey.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _buildLibraryGridForDialog(
                                field,
                                rowOptions,
                                columnOptions,
                                localSelectedRow,
                                localSelectedCol, (row, col) {
                              // Update both dialog state and main widget state
                              setDialogState(() {
                                localSelectedRow = row;
                                localSelectedCol = col;
                              });
                              setState(() {
                                _locationRows[field.name] = row;
                                _locationColumns[field.name] = col;
                              });
                              _handleFieldInteraction(field, '$col$row');
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Selected location display
                      if (localSelectedRow != null &&
                          localSelectedCol != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppConstants.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الموقع المحدد: ',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: AppConstants.textColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$localSelectedCol$localSelectedRow',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Action buttons
                      Row(
                        children: [
                          if (localSelectedRow != null &&
                              localSelectedCol != null) ...[
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setDialogState(() {
                                    localSelectedRow = null;
                                    localSelectedCol = null;
                                  });
                                  setState(() {
                                    _locationRows[field.name] = null;
                                    _locationColumns[field.name] = null;
                                  });
                                },
                                child: Text(
                                  'مسح التحديد',
                                  style: GoogleFonts.cairo(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              onPressed: localSelectedRow != null &&
                                      localSelectedCol != null
                                  ? () {
                                      final location =
                                          '$localSelectedCol$localSelectedRow';
                                      _handleFieldInteraction(field, location);
                                      Navigator.of(context).pop();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'تأكيد الاختيار',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLibraryGrid(
      FieldConfig field, List<String> rowOptions, List<String> columnOptions) {
    // Create a visual grid that looks like your library
    final selectedRow = _locationRows[field.name];
    final selectedCol = _locationColumns[field.name];

    // Dynamically detect which data should go where based on the actual content
    final layoutInfo = _detectLayoutFromData(rowOptions, columnOptions);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Top headers - dynamically determined
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Empty corner
                const SizedBox(width: 40),
                // Top headers - dynamically assigned
                ...layoutInfo['topHeaders']
                    .map<Widget>((header) => Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                header,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),

          // Grid rows - dynamically determined
          ...layoutInfo['sideHeaders']
              .map<Widget>((sideHeader) => Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Side header - dynamically assigned
                        Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sideHeader,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Grid cells
                        ...layoutInfo['topHeaders'].map<Widget>((topHeader) {
                          // Determine which is row and which is column based on layout
                          final actualRow =
                              layoutInfo['rowIsTop'] ? topHeader : sideHeader;
                          final actualCol =
                              layoutInfo['rowIsTop'] ? sideHeader : topHeader;

                          final isSelected = selectedRow == actualRow &&
                              selectedCol == actualCol;
                          return Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _locationRows[field.name] = actualRow;
                                  _locationColumns[field.name] = actualCol;
                                  _handleFieldInteraction(
                                      field, '$actualCol$actualRow');
                                });
                              },
                              child: Container(
                                height: double.infinity,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppConstants.primaryColor
                                      : _getShelfColor(actualCol, actualRow),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppConstants.primaryColor
                                            .withOpacity(0.8)
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppConstants.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu_book,
                                      size: 20,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$actualCol$actualRow',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildLibraryGridForDialog(
      FieldConfig field,
      List<String> rowOptions,
      List<String> columnOptions,
      String? selectedRow,
      String? selectedCol,
      Function(String row, String col) onLocationSelected) {
    // Create a visual grid that looks like your library - for dialog

    // Dynamically detect which data should go where based on the actual content
    final layoutInfo = _detectLayoutFromData(rowOptions, columnOptions);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Top headers - dynamically determined
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Empty corner
                const SizedBox(width: 40),
                // Top headers - dynamically assigned
                ...layoutInfo['topHeaders']
                    .map<Widget>((header) => Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                header,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),

          // Grid rows - dynamically determined
          ...layoutInfo['sideHeaders']
              .map<Widget>((sideHeader) => Container(
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Side header - dynamically assigned
                        Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sideHeader,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Grid cells
                        ...layoutInfo['topHeaders'].map<Widget>((topHeader) {
                          // Determine which is row and which is column based on layout
                          final actualRow =
                              layoutInfo['rowIsTop'] ? topHeader : sideHeader;
                          final actualCol =
                              layoutInfo['rowIsTop'] ? sideHeader : topHeader;

                          final isSelected = selectedRow == actualRow &&
                              selectedCol == actualCol;
                          return Expanded(
                            child: InkWell(
                              onTap: () {
                                onLocationSelected(actualRow, actualCol);
                              },
                              child: Container(
                                height: double.infinity,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppConstants.primaryColor
                                      : _getShelfColor(actualCol, actualRow),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppConstants.primaryColor
                                            .withOpacity(0.8)
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppConstants.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu_book,
                                      size: 20,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$actualCol$actualRow',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  /// Follow field type definitions from Google Sheet
  Map<String, dynamic> _detectLayoutFromData(
      List<String> rowOptions, List<String> columnOptions) {
    // Follow the explicit field types from Google Sheet instead of guessing

    // Default layout
    List<String> topHeaders = rowOptions;
    List<String> sideHeaders = columnOptions;
    bool rowIsTop = true;

    // Check what field types we have from the sheet structure
    bool hasRowFieldType = false;
    bool hasColFieldType = false;
    String? rowFieldSource;
    String? colFieldSource;

    // Look at the structure to find location field sources
    final locationData = widget.structure.locationData;
    if (locationData != null) {
      // The field source information should come from the dynamic sheets service
      // For now, we'll use a heuristic based on naming patterns that match the service

      // Check if we can determine from the structure which field is which
      for (final field in widget.structure.fields) {
        if (field.keySheetColumn != null) {
          final columnName = field.keySheetColumn!.toLowerCase();

          // Check for row field indicators
          if (columnName.contains('صف') || columnName.contains('row')) {
            hasRowFieldType = true;
            rowFieldSource = field.keySheetColumn;
            print(
                '🎯 Found ROW field type from column: ${field.keySheetColumn}');
          }

          // Check for column field indicators
          if (columnName.contains('عامود') ||
              columnName.contains('عمود') ||
              columnName.contains('column') ||
              columnName.contains('col')) {
            hasColFieldType = true;
            colFieldSource = field.keySheetColumn;
            print(
                '🎯 Found COLUMN field type from column: ${field.keySheetColumn}');
          }
        }
      }
    }

    // Follow Google Sheet field type definitions:
    // - If we have explicit field types, use them
    // - "row" field data should display as it's meant to be in the physical layout
    // - "column" field data should display as it's meant to be in the physical layout

    if (hasRowFieldType && hasColFieldType) {
      // We have explicit field types - follow them exactly
      // The service already sorted them correctly into rowOptions and columnOptions
      // So we just need to display them in the most intuitive way for a library grid

      // Typically in libraries:
      // - Shorter sequences go on the side (usually letters: A,B,C,D,E)
      // - Longer sequences go on top (usually numbers: 1,2,3,4,5,6,7,8)

      if (rowOptions.length <= columnOptions.length) {
        // Row data (likely letters) on side, Column data (likely numbers) on top
        topHeaders = columnOptions;
        sideHeaders = rowOptions;
        rowIsTop = false;
        print(
            '📊 Field-type layout: ROW data (${rowOptions.length}) → SIDE, COLUMN data (${columnOptions.length}) → TOP');
      } else {
        // Row data (likely numbers) on top, Column data (likely letters) on side
        topHeaders = rowOptions;
        sideHeaders = columnOptions;
        rowIsTop = true;
        print(
            '📊 Field-type layout: ROW data (${rowOptions.length}) → TOP, COLUMN data (${columnOptions.length}) → SIDE');
      }
    } else {
      // Fallback: No explicit field types found, use data pattern detection
      final rowHasLetters =
          rowOptions.any((r) => RegExp(r'^[A-Za-z]+$').hasMatch(r));
      final colHasNumbers =
          columnOptions.any((c) => RegExp(r'^\d+$').hasMatch(c));

      if (rowHasLetters && colHasNumbers) {
        // Letters on side, numbers on top
        topHeaders = columnOptions;
        sideHeaders = rowOptions;
        rowIsTop = false;
      } else {
        // Keep default
        topHeaders = rowOptions;
        sideHeaders = columnOptions;
        rowIsTop = true;
      }
      print('📊 Fallback layout: Using data pattern detection');
    }

    print('🎯 Final layout based on field types:');
    print(
        '   Top headers (${topHeaders.length}): ${topHeaders.take(3).join(', ')}${topHeaders.length > 3 ? '...' : ''}');
    print(
        '   Side headers (${sideHeaders.length}): ${sideHeaders.take(3).join(', ')}${sideHeaders.length > 3 ? '...' : ''}');
    print('   Row data is on top: $rowIsTop');

    return {
      'topHeaders': topHeaders,
      'sideHeaders': sideHeaders,
      'rowIsTop': rowIsTop,
    };
  }

  Color _getShelfColor(String col, String row) {
    // Give different shelf sections different colors like in a real library
    final colIndex = col.codeUnits[0] - 'A'.codeUnits[0];
    final rowIndex = int.tryParse(row) ?? 1;

    // Create a pattern of colors similar to book categories
    if (colIndex % 3 == 0) {
      return Colors.blue.shade50; // Like blue academic books
    } else if (colIndex % 3 == 1) {
      return Colors.green.shade50; // Like green literature books
    } else {
      return Colors.purple.shade50; // Like purple reference books
    }
  }

  Widget _buildDropdownField(FieldConfig field) {
    final isDynamicField = field.isDynamic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
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
            value: _dropdownValues[field.name],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: Text(
              'اختر ${field.displayName}',
              style: GoogleFonts.cairo(
                color: AppConstants.hintColor,
              ),
            ),
            validator: _isRequiredField(field.name)
                ? (value) => value == null || value.isEmpty
                    ? 'يرجى اختيار ${field.displayName}'
                    : null
                : null,
            items: [
              // Add "Other" option if field has "plus" feature
              if (field.hasFeature(FieldFeature.plus))
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
              ...field.options.map((option) {
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
              setState(() {
                if (value == '__other__') {
                  _showAddNewOptionDialog(field);
                } else {
                  _dropdownValues[field.name] = value;
                  // Trigger field interaction handlers
                  _handleFieldInteraction(field, value ?? '');
                }
              });
            },
          ),
        ),
      ],
    );
  }

  void _showAddNewOptionDialog(FieldConfig field) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'إضافة ${field.displayName} جديد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أدخل قيمة جديدة لـ ${field.displayName}:',
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'القيمة الجديدة',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.cairo(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = controller.text.trim();
                if (newValue.isNotEmpty) {
                  setState(() {
                    // Add to field options (note: this modifies the field directly)
                    field.options.add(newValue);
                    _dropdownValues[field.name] = newValue;
                  });
                }
                Navigator.pop(context);
              },
              child: Text(
                'إضافة',
                style: GoogleFonts.cairo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Additional field type implementations
  Widget _buildDateField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                locale: const Locale('ar'),
              );
              if (date != null) {
                _controllers[field.name]!.text =
                    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _controllers[field.name]!.text.isEmpty
                          ? 'اختر ${field.displayName}'
                          : _controllers[field.name]!.text,
                      style: GoogleFonts.cairo(
                        color: _controllers[field.name]!.text.isEmpty
                            ? AppConstants.hintColor
                            : AppConstants.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                _controllers[field.name]!.text =
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _controllers[field.name]!.text.isEmpty
                          ? 'اختر ${field.displayName}'
                          : _controllers[field.name]!.text,
                      style: GoogleFonts.cairo(
                        color: _controllers[field.name]!.text.isEmpty
                            ? AppConstants.hintColor
                            : AppConstants.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
                      date.year, date.month, date.day, time.hour, time.minute);
                  _controllers[field.name]!.text =
                      '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.event,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _controllers[field.name]!.text.isEmpty
                          ? 'اختر ${field.displayName}'
                          : _controllers[field.name]!.text,
                      style: GoogleFonts.cairo(
                        color: _controllers[field.name]!.text.isEmpty
                            ? AppConstants.hintColor
                            : AppConstants.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: field.options.map((option) {
              return RadioListTile<String>(
                title: Text(
                  option,
                  style: GoogleFonts.cairo(),
                ),
                value: option,
                groupValue: _controllers[field.name]!.text,
                onChanged: (value) {
                  setState(() {
                    _controllers[field.name]!.text = value ?? '';
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderField(FieldConfig field) {
    double sliderValue = 0.0;
    try {
      sliderValue = double.parse(_controllers[field.name]!.text);
    } catch (e) {
      sliderValue = 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'القيمة: ${sliderValue.round()}',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      Text(
                        '0 - 100',
                        style: GoogleFonts.cairo(
                          color: AppConstants.hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: sliderValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: AppConstants.primaryColor,
                    onChanged: (value) {
                      setState(() {
                        sliderValue = value;
                        _controllers[field.name]!.text =
                            value.round().toString();
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingField(FieldConfig field) {
    int rating = 0;
    try {
      rating = int.parse(_controllers[field.name]!.text);
    } catch (e) {
      rating = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Text(
                    'التقييم: $rating/5',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            rating = index + 1;
                            _controllers[field.name]!.text = rating.toString();
                          });
                        },
                        child: Icon(
                          rating > index ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorField(FieldConfig field) {
    Color selectedColor = Colors.blue;
    try {
      final colorValue = _controllers[field.name]!.text;
      if (colorValue.isNotEmpty) {
        selectedColor = Color(int.parse(colorValue));
      }
    } catch (e) {
      selectedColor = Colors.blue;
    }

    final colorOptions = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.brown,
      Colors.grey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'اللون المختار',
                        style: GoogleFonts.cairo(
                          color: selectedColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colorOptions.map((color) {
                      final isSelected = color.value == selectedColor.value;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedColor = color;
                            _controllers[field.name]!.text =
                                color.value.toString();
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // File picker implementation would go here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'اختيار الملف - قريباً!',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 48,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _controllers[field.name]!.text.isEmpty
                        ? 'اضغط لاختيار ملف'
                        : _controllers[field.name]!.text,
                    style: GoogleFonts.cairo(
                      color: _controllers[field.name]!.text.isEmpty
                          ? AppConstants.hintColor
                          : AppConstants.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Image picker implementation would go here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'اختيار الصورة - قريباً!',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _controllers[field.name]!.text.isEmpty
                        ? 'اضغط لاختيار صورة'
                        : _controllers[field.name]!.text,
                    style: GoogleFonts.cairo(
                      color: _controllers[field.name]!.text.isEmpty
                          ? AppConstants.hintColor
                          : AppConstants.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ArabicFormField(
                hint: 'أدخل ${field.displayName} أو امسح الرمز',
                controller: _controllers[field.name]!,
                isRequired: _isRequiredField(field.name),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Barcode scanner implementation would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'مسح الباركود - قريباً!',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQRCodeField(FieldConfig field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${field.displayName} ${_isRequiredField(field.name) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ArabicFormField(
                hint: 'أدخل ${field.displayName} أو امسح الكود',
                controller: _controllers[field.name]!,
                isRequired: _isRequiredField(field.name),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: AppConstants.secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.qr_code,
                  color: Colors.white,
                ),
                onPressed: () {
                  // QR code scanner implementation would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'مسح رمز QR - قريباً!',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _applyFieldFeatures(FieldConfig field, Widget fieldWidget) {
    // Simply return the original widget without any feature indicators
    // This removes all the feature badges and indicators for a cleaner UI
    return fieldWidget;
  }

  Widget _buildFeaturesSummary() {
    // Don't show features summary for cleaner UI
    return const SizedBox.shrink();
  }

  Color _getFeatureColor(FieldFeature feature) {
    switch (feature) {
      case FieldFeature.plus:
        return Colors.blue;
      case FieldFeature.md:
        return Colors.purple;
      case FieldFeature.long:
        return Colors.orange;
      case FieldFeature.required:
        return Colors.red;
      case FieldFeature.readonly:
        return Colors.grey;
      case FieldFeature.conditional:
        return Colors.orange;
      case FieldFeature.validated:
        return Colors.green;
      case FieldFeature.formatted:
        return Colors.blue;
      case FieldFeature.encrypted:
        return Colors.red;
      case FieldFeature.unique:
        return Colors.purple;
      case FieldFeature.cached:
        return Colors.teal;
      case FieldFeature.searchable:
        return Colors.indigo;
      case FieldFeature.sortable:
        return Colors.brown;
      case FieldFeature.filterable:
        return Colors.cyan;
      case FieldFeature.preview:
        return Colors.pink;
      case FieldFeature.rich:
        return Colors.deepOrange;
      case FieldFeature.versioned:
        return Colors.lime.shade700;
      case FieldFeature.audited:
        return Colors.amber.shade700;
      case FieldFeature.localized:
        return Colors.lightGreen.shade700;
      case FieldFeature.sync:
        return Colors.blueGrey;
      case FieldFeature.offline:
        return Colors.grey.shade600;
      case FieldFeature.backup:
        return Colors.deepPurple;
      case FieldFeature.realtime:
        return Colors.green.shade600;
      case FieldFeature.export:
      case FieldFeature.import:
        return Colors.orange.shade600;
      case FieldFeature.bulk:
        return Colors.indigo.shade600;
      case FieldFeature.indexed:
        return Colors.teal.shade600;
      case FieldFeature.calculated:
        return Colors.purple.shade600;
      default:
        return Colors.grey;
    }
  }

  String _getFeatureDisplayName(FieldFeature feature) {
    switch (feature) {
      case FieldFeature.plus:
        return 'إضافة خيارات';
      case FieldFeature.md:
        return 'تنسيق';
      case FieldFeature.long:
        return 'نص طويل';
      case FieldFeature.required:
        return 'مطلوب';
      case FieldFeature.readonly:
        return 'قراءة فقط';
      case FieldFeature.conditional:
        return 'شرطي';
      case FieldFeature.validated:
        return 'محقق';
      case FieldFeature.formatted:
        return 'منسق';
      case FieldFeature.encrypted:
        return 'مشفر';
      case FieldFeature.unique:
        return 'فريد';
      case FieldFeature.cached:
        return 'محفوظ مؤقتاً';
      case FieldFeature.searchable:
        return 'قابل للبحث';
      case FieldFeature.sortable:
        return 'قابل للترتيب';
      case FieldFeature.filterable:
        return 'قابل للتصفية';
      case FieldFeature.preview:
        return 'معاينة';
      case FieldFeature.rich:
        return 'نص غني';
      case FieldFeature.versioned:
        return 'متتبع الإصدارات';
      case FieldFeature.audited:
        return 'مدقق';
      case FieldFeature.localized:
        return 'متعدد اللغات';
      case FieldFeature.sync:
        return 'متزامن';
      case FieldFeature.offline:
        return 'يعمل بلا إنترنت';
      case FieldFeature.backup:
        return 'نسخ احتياطي';
      case FieldFeature.realtime:
        return 'مباشر';
      case FieldFeature.export:
        return 'تصدير';
      case FieldFeature.import:
        return 'استيراد';
      case FieldFeature.bulk:
        return 'عمليات مجمعة';
      case FieldFeature.indexed:
        return 'مفهرس';
      case FieldFeature.calculated:
        return 'محسوب';
      default:
        return feature.toString();
    }
  }

  bool _isRequiredField(String fieldName) {
    final requiredFields = ['اسم الكتاب', 'اسم المؤلف', 'التصنيف', 'الموقع'];
    return requiredFields.any((required) => fieldName.contains(required));
  }

  bool _isLockableField(String fieldName) {
    return fieldName.contains('تصنيف') ||
        fieldName.contains('موقع') ||
        fieldName.toLowerCase().contains('category') ||
        fieldName.toLowerCase().contains('location');
  }

  Widget _buildLockButton(String fieldName, bool isLocked) {
    return Container(
      width: 40,
      height: 40,
      child: IconButton(
        onPressed: () => widget.onToggleFieldLock(fieldName),
        icon: Icon(
          isLocked ? Icons.lock : Icons.lock_open,
          color: isLocked ? AppConstants.primaryColor : AppConstants.hintColor,
          size: 20,
        ),
        style: IconButton.styleFrom(
          backgroundColor: isLocked
              ? AppConstants.primaryColor.withOpacity(0.1)
              : AppConstants.hintColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedIndicator(String fieldName) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock,
            size: 16,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'هذا الحقل مقفل - سيتم الاحتفاظ بقيمته للكتب التالية',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = <String, String>{};

      // Collect text field data
      for (final entry in _controllers.entries) {
        formData[entry.key] = entry.value.text.trim();
      }

      // Collect dropdown data
      for (final entry in _dropdownValues.entries) {
        if (entry.value != null) {
          formData[entry.key] = entry.value!;
        }
      }

      // Collect compound location data
      for (final field in widget.structure.fields) {
        if (field.type == FieldType.locationCompound) {
          final row = _locationRows[field.name];
          final col = _locationColumns[field.name];
          if (row != null && col != null) {
            formData[field.name] = '$row$col'; // e.g., "B5"
          }
        }
      }

      widget.onFormSubmit(formData);

      // If in lock mode, clear non-locked fields after submission
      if (widget.lockModeEnabled) {
        _clearUnlockedFields();
      }
    }
  }

  // Field interaction handlers for features
  void _handleFieldInteraction(FieldConfig field, String value) {
    // Handle real-time updates
    if (field.hasFeature(FieldFeature.realtime)) {
      _broadcastRealTimeUpdate(field.name, value);
    }

    // Handle calculated field updates
    if (field.hasFeature(FieldFeature.calculated)) {
      _updateCalculatedFields(field.name, value);
    }

    // Handle conditional field visibility
    if (field.hasFeature(FieldFeature.conditional)) {
      _updateConditionalFields(field.name, value);
    }

    // Handle validation triggers
    if (field.hasFeature(FieldFeature.validated)) {
      _triggerValidation(field.name, value);
    }

    // Handle formatting
    if (field.hasFeature(FieldFeature.formatted)) {
      _applyFormatting(field.name, value);
    }
  }

  void _broadcastRealTimeUpdate(String fieldName, String value) {
    // Implement real-time broadcasting logic
    print('🔴 Real-time update: $fieldName = $value');
  }

  void _updateCalculatedFields(String fieldName, String value) {
    // Find dependent calculated fields and update them
    for (final field in widget.structure.fields) {
      if (field.hasFeature(FieldFeature.calculated)) {
        final calculatedValue = _calculateFieldValue(field, _controllers);
        if (_controllers.containsKey(field.name)) {
          _controllers[field.name]!.text = calculatedValue;
        }
      }
    }
  }

  String _calculateFieldValue(
      FieldConfig field, Map<String, TextEditingController> controllers) {
    // Simple calculation example - can be extended
    if (field.name.contains('المجموع') || field.name.contains('Total')) {
      // Sum numeric fields
      double sum = 0;
      controllers.forEach((key, controller) {
        final value = double.tryParse(controller.text) ?? 0;
        if (key != field.name && value > 0) {
          sum += value;
        }
      });
      return sum.toString();
    }

    if (field.name.contains('العدد') || field.name.contains('Count')) {
      // Count non-empty fields
      int count = 0;
      controllers.forEach((key, controller) {
        if (key != field.name && controller.text.isNotEmpty) {
          count++;
        }
      });
      return count.toString();
    }

    return '';
  }

  void _updateConditionalFields(String fieldName, String value) {
    setState(() {
      // Update conditional field visibility based on value
      // This would typically be implemented based on specific business rules
      print('🎯 Conditional update: $fieldName = $value');
    });
  }

  void _triggerValidation(String fieldName, String value) {
    // Advanced validation logic
    if (value.isEmpty) return;

    // Validate unique fields
    final field =
        widget.structure.fields.firstWhere((f) => f.name == fieldName);
    if (field.hasFeature(FieldFeature.unique)) {
      _validateUniqueness(fieldName, value);
    }

    // Custom validation rules
    _performCustomValidation(fieldName, value);
  }

  void _validateUniqueness(String fieldName, String value) {
    // Check against existing data for uniqueness
    print('🔍 Validating uniqueness for $fieldName: $value');
  }

  void _performCustomValidation(String fieldName, String value) {
    // Implement field-specific validation rules
    print('✅ Custom validation for $fieldName: $value');
  }

  void _applyFormatting(String fieldName, String value) {
    final controller = _controllers[fieldName];
    if (controller == null) return;

    String formattedValue = value;

    // Apply number formatting
    if (fieldName.contains('رقم') || fieldName.contains('Number')) {
      formattedValue = _formatNumber(value);
    }

    // Apply date formatting
    if (fieldName.contains('تاريخ') || fieldName.contains('Date')) {
      formattedValue = _formatDate(value);
    }

    // Apply phone formatting
    if (fieldName.contains('هاتف') || fieldName.contains('Phone')) {
      formattedValue = _formatPhone(value);
    }

    if (formattedValue != value) {
      controller.text = formattedValue;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: formattedValue.length),
      );
    }
  }

  String _formatNumber(String value) {
    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(String value) {
    // Simple date formatting - could be enhanced
    if (value.length == 8 && value.contains(RegExp(r'^\d+$'))) {
      return '${value.substring(0, 4)}-${value.substring(4, 6)}-${value.substring(6, 8)}';
    }
    return value;
  }

  String _formatPhone(String value) {
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length >= 10) {
      return '${cleanNumber.substring(0, 3)}-${cleanNumber.substring(3, 6)}-${cleanNumber.substring(6)}';
    }
    return value;
  }

  void _clearUnlockedFields() {
    // Clear text controllers for unlocked fields
    for (final entry in _controllers.entries) {
      final isLocked = widget.lockedFields[entry.key] ?? false;
      if (!isLocked) {
        entry.value.clear();
      }
    }

    // Clear dropdown values for unlocked fields
    setState(() {
      final newDropdownValues = <String, String?>{};
      for (final entry in _dropdownValues.entries) {
        final isLocked = widget.lockedFields[entry.key] ?? false;
        if (isLocked) {
          newDropdownValues[entry.key] = entry.value;
        }
      }
      _dropdownValues.clear();
      _dropdownValues.addAll(newDropdownValues);

      // Clear location values for unlocked fields
      final newLocationRows = <String, String?>{};
      final newLocationColumns = <String, String?>{};
      for (final field in widget.structure.fields) {
        if (field.type == FieldType.locationCompound) {
          final isLocked = widget.lockedFields[field.name] ?? false;
          if (isLocked) {
            newLocationRows[field.name] = _locationRows[field.name];
            newLocationColumns[field.name] = _locationColumns[field.name];
          }
        }
      }
      _locationRows.clear();
      _locationColumns.clear();
      _locationRows.addAll(newLocationRows);
      _locationColumns.addAll(newLocationColumns);
    });
  }

  Widget _wrapWithRowIndicator(FieldConfig field, Widget fieldWidget) {
    return Column(
      children: [
        fieldWidget,
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_stream, size: 12, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                'صف',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wrapWithColIndicator(FieldConfig field, Widget fieldWidget) {
    return Column(
      children: [
        fieldWidget,
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_column, size: 12, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'عمود',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.secondaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.dynamic_form,
                  size: 48,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: 12),
                Text(
                  'إضافة كتاب جديد',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'املأ البيانات التالية لإضافة كتاب جديد إلى المكتبة',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppConstants.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _buildFeaturesSummary(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Dynamic Form Fields
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                ...widget.structure.fields.map((field) {
                  if (field.name.trim().isEmpty) return const SizedBox();

                  return Column(
                    children: [
                      _buildFormField(field),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.isLoading ? null : _submitForm,
                child: Center(
                  child: widget.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.lockModeEnabled
                              ? 'إضافة والمتابعة'
                              : 'إضافة إلى المكتبة',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
