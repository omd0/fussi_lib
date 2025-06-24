import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/book.dart';
import '../services/hybrid_library_service.dart';
import '../services/structure_loader_service.dart';
import '../services/dynamic_sheets_service.dart';
import '../utils/arabic_text_utils.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final HybridLibraryService _hybridService = HybridLibraryService();
  final DynamicSheetsService _dynamicSheetsService = DynamicSheetsService();

  // Form controllers
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // Lock functionality for fast group adding
  final Map<String, bool> _lockedFields = {};
  final Map<String, String> _lockedValues = {};
  bool _lockModeEnabled = false;

  // Dynamic field detection and options
  Map<String, List<String>> _dynamicFieldOptions = {};
  Map<String, String> _fieldTypes = {};
  bool _dynamicOptionsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _hybridService.initialize();
    await _loadDynamicFieldOptions();
  }

  Future<void> _loadDynamicFieldOptions() async {
    try {
      print('🔄 Loading dynamic field options...');

      // Load dynamic structure using new data models
      final structure = await _dynamicSheetsService.analyzeSheetStructure();
      if (structure != null) {
        for (final field in structure.fields) {
          // Store field type using enum name
          _fieldTypes[field.name] = field.type.name;

          // Store options for dropdown/autocomplete fields
          if (field.options.isNotEmpty) {
            _dynamicFieldOptions[field.name] = field.options;
          }

          print(
              '🎯 Field "${field.displayName}": ${field.type.name} (${field.options.length} options)');
        }

        print('✅ Loaded ${_fieldTypes.length} dynamic field configurations');
      }

      setState(() {
        _dynamicOptionsLoaded = true;
      });
    } catch (e) {
      print('⚠️ Failed to load dynamic field options: $e');
      setState(() {
        _dynamicOptionsLoaded = true; // Continue with fallback detection
      });
    }
  }

  void _initializeControllers(Map<String, String> headers) {
    // Clear existing controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    // Create controllers for each header
    for (final entry in headers.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value.isNotEmpty) {
        _controllers[key] = TextEditingController();

        // Set locked values if available
        if (_lockedValues.containsKey(key)) {
          _controllers[key]!.text = _lockedValues[key]!;
        }
      }
    }
  }

  Future<void> _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get form data
      final formData = <String, String>{};
      for (final entry in _controllers.entries) {
        formData[entry.key] = entry.value.text.trim();
      }

      // Store locked values before processing
      _updateLockedValues(formData);

      // Create book from form data
      final book = _createBookFromFormData(formData);

      // Add book using hybrid service
      final result = await _hybridService.addBook(book);

      if (result['success']) {
        _showMessage(result['message'], isSuccess: true);

        // Clear form if not in lock mode
        if (!_lockModeEnabled) {
          _clearForm();
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // In lock mode, clear non-locked fields only
          _clearNonLockedFields();
          await Future.delayed(const Duration(milliseconds: 800));
        }
      } else if (result['isDuplicate']) {
        // Show duplicate dialog
        _showDuplicateDialog(
            _createBookFromFormData(formData), result['message']);
      } else {
        _showMessage(result['message'], isSuccess: false);
      }
    } catch (e) {
      _showMessage('خطأ في إضافة الكتاب: $e', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Book _createBookFromFormData(Map<String, String> formData) {
    return Book(
      bookName: formData['D'] ?? '', // اسم الكتاب
      authorName: formData['E'] ?? '', // اسم المؤلف
      category: formData['C'] ?? '', // التصنيف
      libraryLocation: formData['A'] ?? '', // الموقع في المكتبة
      briefDescription: formData['G'] ?? '', // مختصر تعريفي
    );
  }

  void _updateLockedValues(Map<String, String> formData) {
    // Store locked field values for next form
    for (final entry in _lockedFields.entries) {
      if (entry.value && formData.containsKey(entry.key)) {
        _lockedValues[entry.key] = formData[entry.key]!;
      }
    }
  }

  void _clearForm() {
    for (final controller in _controllers.values) {
      controller.clear();
    }
  }

  void _clearNonLockedFields() {
    for (final entry in _controllers.entries) {
      if (!_isFieldLocked(entry.key)) {
        entry.value.clear();
      }
    }
  }

  void _toggleFieldLock(String fieldName) {
    setState(() {
      _lockedFields[fieldName] = !(_lockedFields[fieldName] ?? false);
      if (!_lockedFields[fieldName]!) {
        _lockedValues.remove(fieldName);
      } else if (_controllers.containsKey(fieldName)) {
        _lockedValues[fieldName] = _controllers[fieldName]!.text;
      }
    });
  }

  void _toggleLockMode() {
    setState(() {
      _lockModeEnabled = !_lockModeEnabled;
      if (!_lockModeEnabled) {
        // Clear all locks when disabling lock mode
        _lockedFields.clear();
        _lockedValues.clear();
      }
    });
  }

  bool _isFieldLocked(String fieldName) {
    return _lockedFields[fieldName] ?? false;
  }

  void _showDuplicateDialog(Book book, String message) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'كتاب مكرر',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'هل تريد إضافة الكتاب رغم ذلك؟',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _forceAddBook(book);
              },
              child: Text('إضافة رغم ذلك', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forceAddBook(Book book) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _hybridService.forceAddBook(book);
      if (success) {
        _showMessage('تم إضافة الكتاب بنجاح!', isSuccess: true);
        if (!_lockModeEnabled) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          _clearNonLockedFields();
        }
      } else {
        _showMessage('فشل في إضافة الكتاب', isSuccess: false);
      }
    } catch (e) {
      _showMessage('خطأ في إضافة الكتاب: $e', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 2 : 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final structureAsync = ref.watch(cachedStructureProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final locationsAsync = ref.watch(locationsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          title: Text(
            'إضافة كتاب جديد',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: structureAsync.when(
          data: (structure) {
            // Initialize controllers when structure is loaded
            if (_controllers.isEmpty) {
              final headers = <String, String>{};
              structure.indexStructure.forEach((key, values) {
                if (values.isNotEmpty) {
                  headers[key] = values.first;
                }
              });
              _initializeControllers(headers);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Lock Mode Toggle Button
                  _buildLockModeToggle(),
                  const SizedBox(height: 16),

                  // Dynamic Form
                  _buildDynamicForm(structure, categoriesAsync, locationsAsync),
                ],
              ),
            );
          },
          loading: () => _buildLoadingWidget(),
          error: (error, stack) => _buildErrorWidget(error.toString()),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'جاري تحميل هيكل البيانات...',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppConstants.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'يتم تحميل هيكل قاعدة البيانات من Google Sheets...',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
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
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'فشل في تحميل هيكل البيانات',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(structureRefreshProvider)();
              },
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicForm(
    SheetStructureData structure,
    AsyncValue<List<String>> categoriesAsync,
    AsyncValue<Map<String, List<String>>> locationsAsync,
  ) {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معلومات الكتاب',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(height: 20),

            // Generate form fields based on structure
            for (final entry in structure.indexStructure.entries) ...[
              () {
                final columnKey = entry.key;
                final columnName =
                    entry.value.isNotEmpty ? entry.value.first : '';

                if (columnName.isEmpty) return const SizedBox.shrink();

                return Column(
                  children: [
                    _buildFormField(
                      columnKey,
                      columnName,
                      categoriesAsync,
                      locationsAsync,
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }(),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleFormSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'إضافة الكتاب',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(
    String columnKey,
    String columnName,
    AsyncValue<List<String>> categoriesAsync,
    AsyncValue<Map<String, List<String>>> locationsAsync,
  ) {
    final controller = _controllers[columnKey];
    if (controller == null) return const SizedBox.shrink();

    final isLocked = _isFieldLocked(columnKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label only (no lock button here)
        Text(
          columnName,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        const SizedBox(height: 8),

        // Input field with aligned lock button
        Row(
          children: [
            Expanded(
              child: _buildDynamicField(
                controller,
                columnName,
                isLocked,
                columnKey,
                categoriesAsync,
                locationsAsync,
              ),
            ),
            // Lock button aligned with input field
            if (_lockModeEnabled) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _toggleFieldLock(columnKey),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? AppConstants.primaryColor.withOpacity(0.1)
                        : AppConstants.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLocked
                          ? AppConstants.primaryColor
                          : AppConstants.hintColor.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    isLocked ? Icons.lock : Icons.lock_open,
                    size: 20,
                    color: isLocked
                        ? AppConstants.primaryColor
                        : AppConstants.hintColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(
    TextEditingController controller,
    AsyncValue<List<String>> categoriesAsync,
    bool isLocked,
    String columnKey,
  ) {
    return categoriesAsync.when(
      data: (categories) => DropdownButtonFormField<String>(
        value: categories.contains(controller.text) ? controller.text : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: isLocked
              ? AppConstants.primaryColor.withValues(alpha: 0.1)
              : AppConstants.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintText: 'اختر التصنيف',
          hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
        ),
        items: categories
            .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: GoogleFonts.cairo(),
                  ),
                ))
            .toList(),
        onChanged: isLocked
            ? null
            : (value) {
                controller.text = value ?? '';
              },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'يرجى اختيار التصنيف';
          }
          return null;
        },
      ),
      loading: () => _buildTextFormField(controller, 'التصنيف', isLocked, 'C'),
      error: (_, __) =>
          _buildTextFormField(controller, 'التصنيف', isLocked, 'C'),
    );
  }

  Widget _buildLocationField(
    TextEditingController controller,
    AsyncValue<Map<String, List<String>>> locationsAsync,
    bool isLocked,
    String columnKey,
  ) {
    return locationsAsync.when(
      data: (locations) {
        final rows = locations['rows'] ?? [];
        final columns = locations['columns'] ?? [];

        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: rows.any((row) => controller.text.startsWith(row))
                    ? rows.firstWhere((row) => controller.text.startsWith(row),
                        orElse: () => '')
                    : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isLocked
                      ? AppConstants.primaryColor.withOpacity(0.1)
                      : AppConstants.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'الصف',
                  hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
                ),
                items: rows
                    .map((row) => DropdownMenuItem(
                          value: row,
                          child: Text(row, style: GoogleFonts.cairo()),
                        ))
                    .toList(),
                onChanged: isLocked
                    ? null
                    : (value) {
                        final currentColumn =
                            controller.text.replaceAll(RegExp(r'^[A-Z]'), '');
                        controller.text = '${value ?? ''}$currentColumn';
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: columns.any((col) => controller.text.endsWith(col))
                    ? columns.firstWhere((col) => controller.text.endsWith(col),
                        orElse: () => '')
                    : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isLocked
                      ? AppConstants.primaryColor.withOpacity(0.1)
                      : AppConstants.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'العمود',
                  hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
                ),
                items: columns
                    .map((column) => DropdownMenuItem(
                          value: column,
                          child: Text(column, style: GoogleFonts.cairo()),
                        ))
                    .toList(),
                onChanged: isLocked
                    ? null
                    : (value) {
                        final currentRow =
                            controller.text.replaceAll(RegExp(r'\d+$'), '');
                        controller.text = '$currentRow${value ?? ''}';
                      },
              ),
            ),
          ],
        );
      },
      loading: () =>
          _buildTextFormField(controller, 'الموقع في المكتبة', isLocked, 'A'),
      error: (_, __) =>
          _buildTextFormField(controller, 'الموقع في المكتبة', isLocked, 'A'),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    bool isLocked,
    String columnKey,
  ) {
    return TextFormField(
      controller: controller,
      enabled: !isLocked,
      style: GoogleFonts.cairo(
        fontSize: 16,
        color: AppConstants.textColor,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: isLocked
            ? AppConstants.primaryColor.withOpacity(0.1)
            : AppConstants.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintText: 'أدخل $label',
        hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
      ),
      validator: (value) {
        if (label.contains('اسم الكتاب') || label.contains('اسم المؤلف')) {
          if (value == null || value.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }
        }
        return null;
      },
    );
  }

  // Dynamic field builder - no hardcoding!
  Widget _buildDynamicField(
    TextEditingController controller,
    String columnName,
    bool isLocked,
    String columnKey,
    AsyncValue<List<String>> categoriesAsync,
    AsyncValue<Map<String, List<String>>> locationsAsync,
  ) {
    // Check if we have dynamic field type information
    final fieldType = _fieldTypes[columnName];
    final options = _dynamicFieldOptions[columnName] ?? [];

    print(
        '🎯 Building field "$columnName" with type: $fieldType (${options.length} options)');

    // Use dynamic field type if available
    if (_dynamicOptionsLoaded && fieldType != null) {
      return _buildFieldByType(
        fieldType,
        options,
        controller,
        columnName,
        isLocked,
        true, // isDynamic
      );
    }

    // Fallback to intelligent detection
    return _buildFieldByIntelligentDetection(
      controller,
      columnName,
      isLocked,
      columnKey,
      categoriesAsync,
      locationsAsync,
    );
  }

  // Build field by detected type
  Widget _buildFieldByType(
    String fieldType,
    List<String> options,
    TextEditingController controller,
    String columnName,
    bool isLocked,
    bool isDynamic,
  ) {
    switch (fieldType) {
      case 'autocomplete':
        return _buildAutocompleteField(
            controller, columnName, isLocked, options, isDynamic);
      case 'dropdown':
        return _buildDropdownField(
            controller, columnName, isLocked, options, isDynamic);
      case 'location_compound':
        // For now, fallback to text - could be enhanced later
        return _buildTextFormField(controller, columnName, isLocked, '');
      default:
        return _buildTextFormField(controller, columnName, isLocked, '');
    }
  }

  // Intelligent field detection fallback
  Widget _buildFieldByIntelligentDetection(
    TextEditingController controller,
    String columnName,
    bool isLocked,
    String columnKey,
    AsyncValue<List<String>> categoriesAsync,
    AsyncValue<Map<String, List<String>>> locationsAsync,
  ) {
    // Use Arabic text utilities for intelligent detection
    if (ArabicTextUtils.isCategoryColumn(columnName)) {
      return _buildCategoryDropdown(
          controller, categoriesAsync, isLocked, columnKey);
    } else if (ArabicTextUtils.isLocationColumn(columnName)) {
      return _buildLocationField(
          controller, locationsAsync, isLocked, columnKey);
    } else if (ArabicTextUtils.isAuthorColumn(columnName)) {
      // Check if we have author options from dynamic loading
      final authorOptions = _dynamicFieldOptions.entries
          .where((entry) => ArabicTextUtils.isAuthorColumn(entry.key))
          .expand((entry) => entry.value)
          .toList();

      if (authorOptions.isNotEmpty) {
        return _buildAutocompleteField(
            controller, columnName, isLocked, authorOptions, true);
      }
      return _buildTextFormField(controller, columnName, isLocked, columnKey);
    } else if (ArabicTextUtils.isRestrictionColumn(columnName)) {
      // Check if we have restriction options from dynamic loading
      final restrictionOptions = _dynamicFieldOptions.entries
          .where((entry) => ArabicTextUtils.isRestrictionColumn(entry.key))
          .expand((entry) => entry.value)
          .toList();

      if (restrictionOptions.isNotEmpty) {
        return _buildDropdownField(
            controller, columnName, isLocked, restrictionOptions, true);
      } else {
        // Use common restriction values
        return _buildDropdownField(controller, columnName, isLocked,
            ArabicTextUtils.getCommonRestrictionValues(), false);
      }
    } else {
      // Default to text field
      return _buildTextFormField(controller, columnName, isLocked, columnKey);
    }
  }

  // Enhanced autocomplete field
  Widget _buildAutocompleteField(
    TextEditingController controller,
    String label,
    bool isLocked,
    List<String> options,
    bool isDynamic,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDynamic) ...[
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'تم الكشف تلقائياً',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return options.take(5);
            }
            return options.where((String option) {
              return ArabicTextUtils.arabicFuzzyMatch(
                  option, textEditingValue.text);
            });
          },
          onSelected: (String selection) {
            controller.text = selection;
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            if (fieldController.text != controller.text) {
              fieldController.text = controller.text;
            }
            fieldController.addListener(() {
              controller.text = fieldController.text;
            });

            return TextFormField(
              controller: fieldController,
              focusNode: fieldFocusNode,
              enabled: !isLocked,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppConstants.textColor,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isLocked
                    ? AppConstants.primaryColor.withOpacity(0.1)
                    : AppConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: 'اكتب أو اختر $label',
                hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: AppConstants.hintColor,
                ),
                prefixIcon: isDynamic
                    ? Icon(
                        Icons.auto_awesome,
                        color: AppConstants.primaryColor,
                        size: 18,
                      )
                    : null,
              ),
              validator: (value) {
                if (_isRequiredField(label) &&
                    (value == null || value.trim().isEmpty)) {
                  return 'هذا الحقل مطلوب';
                }
                return null;
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: MediaQuery.of(context).size.width - 80,
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
      ],
    );
  }

  // Enhanced dropdown field
  Widget _buildDropdownField(
    TextEditingController controller,
    String label,
    bool isLocked,
    List<String> options,
    bool isDynamic,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDynamic) ...[
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'تم الكشف تلقائياً',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        DropdownButtonFormField<String>(
          value: options.contains(controller.text) ? controller.text : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: isLocked
                ? AppConstants.primaryColor.withOpacity(0.1)
                : AppConstants.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: 'اختر $label',
            hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
            prefixIcon: isDynamic
                ? Icon(
                    Icons.auto_awesome,
                    color: AppConstants.primaryColor,
                    size: 18,
                  )
                : null,
          ),
          items: options
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Text(
                      option,
                      style: GoogleFonts.cairo(),
                    ),
                  ))
              .toList(),
          onChanged: isLocked
              ? null
              : (value) {
                  controller.text = value ?? '';
                },
          validator: (value) {
            if (_isRequiredField(label) && (value == null || value.isEmpty)) {
              return 'يرجى اختيار $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Helper method to determine if field is required
  bool _isRequiredField(String label) {
    return ArabicTextUtils.isBookNameColumn(label) ||
        ArabicTextUtils.isAuthorColumn(label);
  }

  Widget _buildLockModeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lockModeEnabled
            ? AppConstants.primaryColor.withOpacity(0.1)
            : AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _lockModeEnabled
              ? AppConstants.primaryColor
              : AppConstants.hintColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _lockModeEnabled ? Icons.lock : Icons.lock_open,
            color: _lockModeEnabled
                ? AppConstants.primaryColor
                : AppConstants.hintColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وضع الإضافة السريعة',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _lockModeEnabled
                        ? AppConstants.primaryColor
                        : AppConstants.textColor,
                  ),
                ),
                Text(
                  _lockModeEnabled
                      ? 'قفل التصنيف والموقع لإضافة مجموعة كتب بسرعة'
                      : 'اضغط لتفعيل قفل التصنيف والموقع',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppConstants.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _lockModeEnabled,
            onChanged: (value) => _toggleLockMode(),
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }
}
