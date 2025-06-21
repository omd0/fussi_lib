import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/hybrid_library_service.dart';
import '../services/structure_loader_service.dart';
import '../models/book.dart';

class LibraryBrowserScreen extends ConsumerStatefulWidget {
  const LibraryBrowserScreen({super.key});

  @override
  ConsumerState<LibraryBrowserScreen> createState() =>
      _LibraryBrowserScreenState();
}

class _LibraryBrowserScreenState extends ConsumerState<LibraryBrowserScreen> {
  final _hybridService = HybridLibraryService();
  final _searchController = TextEditingController();

  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _hybridService.initialize();
      _loadBooks();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('خطأ في تهيئة الخدمة: ${e.toString()}', isError: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hybridService.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add timeout to prevent infinite loading
      final books = await _hybridService
          .getBooksAsObjects()
          .timeout(const Duration(seconds: 45), onTimeout: () {
        throw TimeoutException(
            'انتهت مهلة تحميل البيانات', const Duration(seconds: 45));
      });

      setState(() {
        _allBooks = books;
        _filteredBooks = List.from(_allBooks);
        _isLoading = false;
      });

      if (books.isEmpty) {
        _showMessage('لا توجد كتب في المكتبة حالياً', isError: false);
      } else {
        _showMessage('تم تحميل ${books.length} كتاب بنجاح', isError: false);
      }
    } on TimeoutException catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('انتهت مهلة التحميل - تحقق من الاتصال', isError: true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('خطأ في تحميل الكتب: ${e.toString()}', isError: true);
      print('Error loading books: $e');
    }
  }

  void _filterBooks() {
    setState(() {
      _filteredBooks = _allBooks.where((book) {
        final matchesSearch = _searchQuery.isEmpty ||
            book.bookName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            book.authorName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            book.libraryLocation
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            book.category.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategory =
            _selectedCategory == 'الكل' || book.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final structureAsync = ref.watch(cachedStructureProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          title: Text(
            'مكتبة بيت الفصي',
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
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isLoading ? null : _loadBooks,
              tooltip: 'تحديث الكتب',
            ),
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              onPressed: () {
                ref.read(structureRefreshProvider)();
                _showMessage('تم تحديث هيكل البيانات', isError: false);
              },
              tooltip: 'تحديث هيكل البيانات',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _isLoading
            ? _buildLoadingWidget()
            : Column(
                children: [
                  // Header Info with Structure Status
                  _buildHeaderInfo(structureAsync),

                  // Search
                  _buildSearchField(),

                  const SizedBox(height: 16),

                  // Categories - Dynamic from structure
                  _buildCategoriesSection(categoriesAsync),

                  const SizedBox(height: 16),

                  // Books List
                  _buildBooksList(),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.primaryColor,
            strokeWidth: 2.0,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل المكتبة...',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'جاري تحميل الكتب من Google Sheets...',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = false;
              });
              _showMessage('تم إلغاء التحميل', isError: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'إلغاء التحميل',
              style: GoogleFonts.cairo(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(AsyncValue<SheetStructureData> structureAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
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
          // Connection Status
          Row(
            children: [
              Icon(
                Icons.cloud_done,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'متصل بـ Google Sheets',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                  ),
                ),
              ),
              // Structure Status Indicator
              structureAsync.when(
                data: (structure) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: structure.isExpired
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        structure.isExpired
                            ? Icons.warning
                            : Icons.check_circle,
                        size: 16,
                        color:
                            structure.isExpired ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        structure.isExpired ? 'منتهي الصلاحية' : 'محدث',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: structure.isExpired
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'جاري التحميل',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                error: (_, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'خطأ',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Statistics
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.library_books,
                        color: AppConstants.primaryColor, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${_allBooks.length}',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    Text(
                      'إجمالي الكتب',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppConstants.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppConstants.hintColor.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.search,
                        color: AppConstants.secondaryColor, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${_filteredBooks.length}',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.secondaryColor,
                      ),
                    ),
                    Text(
                      'نتائج البحث',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppConstants.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppConstants.hintColor.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.category, color: Colors.orange, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCategory == 'الكل' ? 'الكل' : '1',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'التصنيف المحدد',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppConstants.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.cairo(fontSize: 16, color: AppConstants.textColor),
        decoration: InputDecoration(
          hintText: 'ابحث عن كتاب، مؤلف، تصنيف، أو موقع...',
          hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
          prefixIcon:
              const Icon(Icons.search, color: AppConstants.primaryColor),
          filled: true,
          fillColor: AppConstants.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _filterBooks();
        },
      ),
    );
  }

  Widget _buildCategoriesSection(AsyncValue<List<String>> categoriesAsync) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: categoriesAsync.when(
        data: (categories) => ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildCategoryChip('الكل'),
            ...categories.map((category) => _buildCategoryChip(category)),
          ],
        ),
        loading: () => Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'جاري تحميل التصنيفات...',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppConstants.hintColor,
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 20,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'خطأ في تحميل التصنيفات',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBooksList() {
    return Expanded(
      child: _filteredBooks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _allBooks.isEmpty
                        ? Icons.library_books_outlined
                        : Icons.search_off,
                    size: 64,
                    color: AppConstants.hintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _allBooks.isEmpty
                        ? 'لا توجد كتب في المكتبة بعد'
                        : 'لم يتم العثور على كتب مطابقة للبحث',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: AppConstants.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_allBooks.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadBooks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'إعادة المحاولة',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredBooks.length,
              itemBuilder: (context, index) {
                final book = _filteredBooks[index];
                return _buildBookCard(book, index);
              },
            ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(
          category,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: isSelected ? Colors.white : AppConstants.textColor,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _filterBooks();
        },
        backgroundColor: AppConstants.backgroundColor,
        selectedColor: AppConstants.primaryColor,
        side: BorderSide(
          color: isSelected
              ? AppConstants.primaryColor
              : AppConstants.hintColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Title
            Text(
              book.bookName,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Author
            Row(
              children: [
                const Icon(Icons.person,
                    size: 16, color: AppConstants.hintColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    book.authorName,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppConstants.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Category and Location
            Row(
              children: [
                // Category
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    book.category,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Location
                const Icon(Icons.location_on,
                    size: 16, color: AppConstants.secondaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    book.libraryLocation,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppConstants.secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Brief description if available
            if (book.briefDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                book.briefDescription,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppConstants.hintColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            message,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        backgroundColor:
            isError ? Colors.red.shade400 : AppConstants.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
