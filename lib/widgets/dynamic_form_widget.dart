import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/dynamic_sheets_service.dart';
import '../widgets/arabic_form_field.dart';

class DynamicFormWidget extends StatefulWidget {
  final SheetsStructure structure;
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
    for (final column in widget.structure.columns) {
      if (column.fieldType == 'text' || column.fieldType == 'autocomplete') {
        final controller = TextEditingController();
        // Set locked values if available
        if (widget.lockedValues.containsKey(column.header)) {
          controller.text = widget.lockedValues[column.header]!;
        }
        _controllers[column.header] = controller;
      }
    }

    // Set locked dropdown values
    for (final entry in widget.lockedValues.entries) {
      final column = widget.structure.columns.firstWhere(
        (col) => col.header == entry.key,
        orElse: () =>
            ColumnMapping(header: '', index: -1, fieldType: '', options: []),
      );
      if (column.fieldType == 'dropdown') {
        _dropdownValues[entry.key] = entry.value;
      } else if (column.fieldType == 'location_compound') {
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

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildFormField(ColumnMapping column) {
    final isLockableField = _isLockableField(column.header);
    final isFieldLocked = widget.lockedFields[column.header] ?? false;

    Widget field;
    switch (column.fieldType) {
      case 'dropdown':
        field = _buildDropdownField(column);
        break;
      case 'location_compound':
        field = _buildLocationCompoundField(column);
        break;
      case 'autocomplete':
        field = _buildAutocompleteField(column);
        break;
      case 'text':
      default:
        field = _buildTextField(column);
        break;
    }

    // If lock mode is enabled and this is a lockable field, add lock button
    if (widget.lockModeEnabled && isLockableField) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: field),
              const SizedBox(width: 8),
              _buildLockButton(column.header, isFieldLocked),
            ],
          ),
          if (isFieldLocked) _buildLockedIndicator(column.header),
        ],
      );
    }

    return field;
  }

  Widget _buildTextField(ColumnMapping column) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${column.header} ${_isRequiredField(column.header) ? '*' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),
        ArabicFormField(
          label: '',
          hint: 'أدخل ${column.header}',
          controller: _controllers[column.header]!,
          isRequired: _isRequiredField(column.header),
        ),
      ],
    );
  }

  Widget _buildAutocompleteField(ColumnMapping column) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${column.header} ${_isRequiredField(column.header) ? '*' : ''}',
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
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return column.options.where((String option) {
                return option
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()) ||
                    option.contains(textEditingValue.text);
              });
            },
            onSelected: (String selection) {
              _controllers[column.header]!.text = selection;
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController fieldController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted) {
              // Use our controller instead of the autocomplete's
              fieldController.text = _controllers[column.header]!.text;
              fieldController.addListener(() {
                _controllers[column.header]!.text = fieldController.text;
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
                  hintText: 'اكتب أو اختر ${column.header}',
                  hintStyle: GoogleFonts.cairo(
                    color: AppConstants.hintColor,
                  ),
                  suffixIcon: Icon(
                    Icons.arrow_drop_down,
                    color: AppConstants.hintColor,
                  ),
                ),
                style: GoogleFonts.cairo(),
                validator: _isRequiredField(column.header)
                    ? (value) => value == null || value.isEmpty
                        ? 'يرجى إدخال ${column.header}'
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
                  child: Container(
                    height: 200,
                    width: MediaQuery.of(context).size.width - 40,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
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
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCompoundField(ColumnMapping column) {
    final rowOptions =
        widget.structure.dropdownOptions['${column.header}_rows']?.toList() ??
            [];
    final columnOptions = widget
            .structure.dropdownOptions['${column.header}_columns']
            ?.toList() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${column.header} ${_isRequiredField(column.header) ? '*' : ''}',
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
                  value: _locationRows[column.header],
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
                  validator: _isRequiredField(column.header)
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
                      _locationRows[column.header] = value;
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
                  value: _locationColumns[column.header],
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
                  validator: _isRequiredField(column.header)
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
                      _locationColumns[column.header] = value;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        // Show combined location preview
        if (_locationRows[column.header] != null &&
            _locationColumns[column.header] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'الموقع: ${_locationRows[column.header]}${_locationColumns[column.header]}',
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

  Widget _buildDropdownField(ColumnMapping column) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${column.header} ${_isRequiredField(column.header) ? '*' : ''}',
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
          child: DropdownButtonFormField<String>(
            value: _dropdownValues[column.header],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            hint: Text(
              'اختر ${column.header}',
              style: GoogleFonts.cairo(
                color: AppConstants.hintColor,
              ),
            ),
            validator: _isRequiredField(column.header)
                ? (value) => value == null || value.isEmpty
                    ? 'يرجى اختيار ${column.header}'
                    : null
                : null,
            items: [
              // Add "Other" option for flexibility
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
              ...column.options.map((option) {
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
                  _showAddNewOptionDialog(column);
                } else {
                  _dropdownValues[column.header] = value;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  void _showAddNewOptionDialog(ColumnMapping column) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'إضافة ${column.header} جديد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أدخل قيمة جديدة لـ ${column.header}:',
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
                    column.options.add(newValue);
                    _dropdownValues[column.header] = newValue;
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
      for (final column in widget.structure.columns) {
        if (column.fieldType == 'location_compound') {
          final row = _locationRows[column.header];
          final col = _locationColumns[column.header];
          if (row != null && col != null) {
            formData[column.header] = '$row$col'; // e.g., "B5"
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
      for (final column in widget.structure.columns) {
        if (column.fieldType == 'location_compound') {
          final isLocked = widget.lockedFields[column.header] ?? false;
          if (isLocked) {
            newLocationRows[column.header] = _locationRows[column.header];
            newLocationColumns[column.header] = _locationColumns[column.header];
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
                ...widget.structure.columns.map((column) {
                  if (column.header.trim().isEmpty) return const SizedBox();

                  return Column(
                    children: [
                      _buildFormField(column),
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
