import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/book.dart';
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
          field.type == FieldType.checkbox) {
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
          // Parse compound location (e.g., "B5" -> row "B", column "5")
          final value = entry.value;
          if (value.length >= 2) {
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
      case FieldType.time:
      case FieldType.datetime:
      case FieldType.radio:
      case FieldType.slider:
      case FieldType.rating:
      case FieldType.color:
      case FieldType.file:
      case FieldType.image:
      case FieldType.barcode:
      case FieldType.qrcode:
        // For advanced field types not yet implemented, fall back to text field
        fieldWidget = _buildTextField(field);
        break;
    }

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
          label: '',
          hint: 'أدخل ${field.displayName}',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
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
          label: '',
          hint: 'أدخل ${field.displayName} (يدعم التنسيق)',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          maxLines: 3,
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
          label: '',
          hint: 'أدخل ${field.displayName}',
          controller: _controllers[field.name]!,
          isRequired: _isRequiredField(field.name),
          maxLines: 5,
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
          label: '',
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
          label: '',
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
          label: '',
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
          label: '',
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
            if (isDynamicField) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'تم الكشف تلقائياً',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
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
            // Row selector (صف)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.hintColor.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _locationRows[field.name],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: Text(
                    'الصف',
                    style: GoogleFonts.cairo(
                      color: AppConstants.hintColor,
                    ),
                  ),
                  validator: _isRequiredField(field.name)
                      ? (value) =>
                          value == null || value.isEmpty ? 'اختر الصف' : null
                      : null,
                  items: rowOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: GoogleFonts.cairo(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _locationRows[field.name] = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Column selector (عامود)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConstants.hintColor.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _locationColumns[field.name],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: Text(
                    'العامود',
                    style: GoogleFonts.cairo(
                      color: AppConstants.hintColor,
                    ),
                  ),
                  validator: _isRequiredField(field.name)
                      ? (value) =>
                          value == null || value.isEmpty ? 'اختر العامود' : null
                      : null,
                  items: columnOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: GoogleFonts.cairo(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _locationColumns[field.name] = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        // Show combined location preview
        if (_locationRows[field.name] != null &&
            _locationColumns[field.name] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'الموقع: ${_locationRows[field.name]}${_locationColumns[field.name]}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownField(FieldConfig field) {
    final isDynamicField = field.isDynamic;

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
            if (isDynamicField) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'تم الكشف تلقائياً',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
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
                  'نموذج ديناميكي ذكي',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تم إنشاء هذا النموذج تلقائياً وتحسينه بناءً على بياناتك',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppConstants.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
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
