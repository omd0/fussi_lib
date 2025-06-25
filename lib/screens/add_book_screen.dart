import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/book.dart';
import '../services/hybrid_library_service.dart';
import '../services/dynamic_sheets_service.dart';
import '../widgets/dynamic_form_widget.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final HybridLibraryService _hybridService = HybridLibraryService();
  final DynamicSheetsService _dynamicSheetsService = DynamicSheetsService();

  bool _isLoading = false;

  // Lock functionality for fast group adding
  final Map<String, bool> _lockedFields = {};
  final Map<String, String> _lockedValues = {};
  bool _lockModeEnabled = false;

  // Dynamic form structure
  FormStructure? _formStructure;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _hybridService.initialize();
    await _loadFormStructure();
  }

  Future<void> _loadFormStructure() async {
    try {
      print('🔄 Loading form structure...');

      // Load dynamic structure using new data models
      final structure = await _dynamicSheetsService.analyzeSheetStructure();
      if (structure != null) {
        setState(() {
          _formStructure = structure;
        });
        print('✅ Loaded form structure with ${structure.fields.length} fields');
      }
    } catch (e) {
      print('⚠️ Failed to load form structure: $e');
    }
  }

  Future<void> _handleFormSubmit(Map<String, String> formData) async {
    setState(() {
      _isLoading = true;
    });

    try {
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
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // In lock mode, just wait a bit for user feedback
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
      bookName: formData['اسم الكتاب'] ?? formData['D'] ?? '', // اسم الكتاب
      authorName: formData['اسم المؤلف'] ?? formData['E'] ?? '', // اسم المؤلف
      category: formData['التصنيف'] ?? formData['C'] ?? '', // التصنيف
      libraryLocation: formData['الموقع في المكتبة'] ??
          formData['A'] ??
          '', // الموقع في المكتبة
      briefDescription:
          formData['مختصر تعريفي'] ?? formData['G'] ?? '', // مختصر تعريفي
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

  void _toggleFieldLock(String fieldName) {
    setState(() {
      _lockedFields[fieldName] = !(_lockedFields[fieldName] ?? false);
      if (!_lockedFields[fieldName]!) {
        _lockedValues.remove(fieldName);
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
          // In lock mode, just wait a bit for user feedback
          await Future.delayed(const Duration(milliseconds: 800));
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
        body: _formStructure == null
            ? _buildLoadingWidget()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Lock Mode Toggle Button
                    _buildLockModeToggle(),
                    const SizedBox(height: 16),

                    // Dynamic Form Widget
                    DynamicFormWidget(
                      structure: _formStructure!,
                      onFormSubmit: _handleFormSubmit,
                      isLoading: _isLoading,
                      lockModeEnabled: _lockModeEnabled,
                      lockedFields: _lockedFields,
                      lockedValues: _lockedValues,
                      onToggleFieldLock: _toggleFieldLock,
                    ),
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
