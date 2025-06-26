import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/book.dart';
import '../models/form_structure.dart';
import '../services/hybrid_library_service.dart';
import '../services/enhanced_dynamic_service.dart';
import '../widgets/field_builder_widget.dart';
import '../widgets/location_selector_widget.dart';
import '../widgets/physical_bookshelf_widget.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final HybridLibraryService _hybridService = HybridLibraryService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _lockModeEnabled = false;
  final Map<String, bool> _lockedFields = {};
  final Map<String, String> _lockedValues = {};
  final Map<String, TextEditingController> _controllers = {};

  FormStructure? _formStructure;

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
    setState(() {
      _isLoading = true;
    });

    try {
      await _hybridService.initialize();

      // Use the enhanced dynamic service
      final enhancedService = ref.read(enhancedDynamicServiceProvider);
      _formStructure = await enhancedService.getFormStructure();

      if (_formStructure != null) {
        // Initialize controllers for all fields
        for (final field in _formStructure!.fields) {
          _controllers[field.name] = TextEditingController();
        }
      }

      print(
          '📋 Form structure loaded with ${_formStructure?.fields.length ?? 0} fields');
    } catch (e) {
      print('❌ Error initializing services: $e');
      _showMessage('خطأ في تحميل النظام: $e', isSuccess: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleFormSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Collect form data
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
        _showDuplicateDialog(book, result['message']);
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

  Widget _buildEnhancedForm() {
    if (_formStructure == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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

            // Build each field using FieldBuilderWidget
            for (final field in _formStructure!.fields) ...[
              Column(
                children: [
                  FieldBuilderWidget(
                    field: field,
                    controller: _controllers[field.name],
                    onChanged: (value) {
                      // Handle value changes
                      if (_controllers[field.name] != null) {
                        _controllers[field.name]!.text = value;
                      }
                    },
                    isRequired: _isRequiredField(field.name),
                    isLocked: _lockedFields[field.name] ?? false,
                    options: field.options,
                    locationData: _formStructure?.locationData,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleFormSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: AppConstants.primaryColor.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'إضافة الكتاب',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
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

  bool _isRequiredField(String fieldName) {
    // Fields that are required for book creation
    return fieldName.contains('اسم الكتاب') ||
        fieldName.contains('اسم المؤلف') ||
        fieldName.contains('التصنيف') ||
        fieldName.contains('موقع');
  }

  Book _createBookFromFormData(Map<String, String> formData) {
    // Try to find the fields by their display names or keys
    return Book(
      bookName: formData['اسم الكتاب'] ?? formData['D'] ?? '',
      authorName: formData['اسم المؤلف'] ?? formData['E'] ?? '',
      category: formData['التصنيف'] ?? formData['C'] ?? '',
      libraryLocation: formData['موقع المكتبة'] ?? formData['A'] ?? '',
      briefDescription: formData['مختصر تعريفي'] ?? formData['G'] ?? '',
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.secondaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
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
        body: _isLoading
            ? _buildLoadingWidget()
            : _formStructure == null
                ? _buildErrorWidget('فشل في تحميل هيكل البيانات')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Lock Mode Toggle Button
                        _buildLockModeToggle(),
                        const SizedBox(height: 16),

                        // Enhanced Dynamic Form using the field system
                        _buildEnhancedForm(),
                      ],
                    ),
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
                _initializeServices(); // Retry initialization
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

  Widget _buildLockModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _lockModeEnabled
              ? [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.primaryColor.withOpacity(0.05)
                ]
              : [AppConstants.cardColor, AppConstants.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _lockModeEnabled
              ? AppConstants.primaryColor.withOpacity(0.5)
              : AppConstants.hintColor.withOpacity(0.2),
        ),
        boxShadow: _lockModeEnabled
            ? [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
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
            trackColor: MaterialStateProperty.all(
                AppConstants.primaryColor.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }
}
