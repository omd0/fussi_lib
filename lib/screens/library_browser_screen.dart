import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/cache_service.dart';
import '../services/sheet_structure_service.dart';
import '../models/book.dart';
import 'edit_book_screen.dart';
import '../widgets/location_selector_widget.dart';

enum SortBy { name, author, category, location }

enum FilterBy { all, category, location, author }

class LibraryBrowserScreen extends ConsumerStatefulWidget {
  const LibraryBrowserScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LibraryBrowserScreen> createState() =>
      _LibraryBrowserScreenState();
}

class _LibraryBrowserScreenState extends ConsumerState<LibraryBrowserScreen> {
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedLocation;
  String? _selectedAuthor;
  String _sortBy = 'bookName';
  bool _sortAscending = true;

  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 0; // Reset to first page on search
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksCacheProvider);
    final browsingStructureAsync = ref.watch(browsingStructureProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(booksCacheProvider);
          ref.invalidate(browsingStructureProvider);
        },
        child: Column(
          children: [
            // Search and Filter Section
            browsingStructureAsync.when(
              data: (browsingStructure) =>
                  _buildSearchAndFilterSection(browsingStructure),
              loading: () => _buildLoadingSearchSection(),
              error: (error, stack) => _buildErrorSearchSection(error),
            ),

            // Books List
            Expanded(
              child: booksAsync.when(
                data: (books) => _buildBooksList(books),
                loading: () => _buildLoadingState(),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
      title: Text(
        'تصفح المكتبة',
        style: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            ref.invalidate(booksCacheProvider);
            ref.invalidate(browsingStructureProvider);
          },
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection(BrowsingStructure? browsingStructure) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'ابحث في المكتبة...',
                hintStyle: GoogleFonts.cairo(color: Colors.grey[600]),
                prefixIcon:
                    const Icon(Icons.search, color: AppConstants.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppConstants.primaryColor, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.cairo(fontSize: 16),
            ),
          ),

          const SizedBox(height: 16),

          // Filter Options
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category Filter
                if (browsingStructure?.categories.isNotEmpty ?? false)
                  _buildFilterDropdown(
                    label: 'التصنيف',
                    value: _selectedCategory,
                    items: browsingStructure!.categories,
                    onChanged: (value) => setState(() {
                      _selectedCategory = value;
                      _currentPage = 0;
                    }),
                  ),

                const SizedBox(width: 12),

                // Smart Location Filter
                if (browsingStructure?.locations.isNotEmpty ?? false)
                  _buildSmartLocationFilter(browsingStructure!.locations),

                const SizedBox(width: 12),

                // Author Filter
                if (browsingStructure?.authors.isNotEmpty ?? false)
                  _buildFilterDropdown(
                    label: 'المؤلف',
                    value: _selectedAuthor,
                    items: browsingStructure!.authors,
                    onChanged: (value) => setState(() {
                      _selectedAuthor = value;
                      _currentPage = 0;
                    }),
                  ),

                const SizedBox(width: 12),

                // Sort Options
                _buildSortDropdown(),

                const SizedBox(width: 12),

                // Clear Filters
                ElevatedButton(
                  onPressed: () => _clearFilters(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'مسح الفلاتر',
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartLocationFilter(List<String> locations) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: LocationSelectorWidget(
        title: 'فلتر حسب الموقع',
        selectedLocation: _selectedLocation,
        onLocationSelected: (value) => setState(() {
          _selectedLocation = value;
          _currentPage = 0;
        }),
        mode: LocationSelectorMode.inline,
        placeholder: 'اختر موقع للفلترة',
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            label,
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
          ),
          value: value,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('كل $label', style: GoogleFonts.cairo(fontSize: 14)),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.cairo(fontSize: 14)),
                )),
          ],
          onChanged: onChanged,
          style: GoogleFonts.cairo(fontSize: 14, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              items: const [
                DropdownMenuItem(value: 'bookName', child: Text('الاسم')),
                DropdownMenuItem(value: 'authorName', child: Text('المؤلف')),
                DropdownMenuItem(value: 'category', child: Text('التصنيف')),
                DropdownMenuItem(
                    value: 'libraryLocation', child: Text('الموقع')),
              ],
              onChanged: (value) => setState(() {
                _sortBy = value ?? 'bookName';
                _currentPage = 0;
              }),
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.black),
            ),
          ),
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: AppConstants.primaryColor,
            ),
            onPressed: () => setState(() {
              _sortAscending = !_sortAscending;
              _currentPage = 0;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث في المكتبة...',
              hintStyle: GoogleFonts.cairo(color: Colors.grey[600]),
              prefixIcon:
                  const Icon(Icons.search, color: AppConstants.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppConstants.primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.cairo(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            height: 40,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSearchSection(error) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث في المكتبة...',
              hintStyle: GoogleFonts.cairo(color: Colors.grey[600]),
              prefixIcon:
                  const Icon(Icons.search, color: AppConstants.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppConstants.primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.cairo(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'تعذر تحميل إعدادات البحث المتقدم',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList(List<Book> allBooks) {
    final filteredBooks = _filterAndSortBooks(allBooks);
    final totalPages = (filteredBooks.length / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, filteredBooks.length);
    final paginatedBooks = filteredBooks.sublist(startIndex, endIndex);

    if (filteredBooks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Statistics Bar
        _buildStatisticsBar(filteredBooks.length, allBooks.length),

        // Books Grid
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paginatedBooks.length,
            itemBuilder: (context, index) =>
                _buildBookCard(paginatedBooks[index]),
          ),
        ),

        // Pagination
        if (totalPages > 1) _buildPagination(totalPages),
      ],
    );
  }

  Widget _buildStatisticsBar(int filteredCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'عرض $filteredCount من أصل $totalCount كتاب',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
          if (filteredCount != totalCount)
            Text(
              'مُطبق عليها فلاتر',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToEdit(book),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Name
              Text(
                book.bookName,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Author and Category Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المؤلف: ${book.authorName}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'التصنيف: ${book.category}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),

                  // Location Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      book.libraryLocation,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (book.briefDescription.isNotEmpty)
                Text(
                  book.briefDescription,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous Button
          IconButton(
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_right),
            color: AppConstants.primaryColor,
          ),

          // Page Numbers
          ...List.generate(totalPages, (index) {
            if (totalPages <= 7) {
              return _buildPageButton(index);
            } else {
              // Show first page, current page ±1, and last page
              if (index == 0 ||
                  index == totalPages - 1 ||
                  (index >= _currentPage - 1 && index <= _currentPage + 1)) {
                return _buildPageButton(index);
              } else if (index == 1 && _currentPage > 3) {
                return const Text('...', style: TextStyle(color: Colors.grey));
              } else if (index == totalPages - 2 &&
                  _currentPage < totalPages - 4) {
                return const Text('...', style: TextStyle(color: Colors.grey));
              }
              return const SizedBox.shrink();
            }
          }),

          // Next Button
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(int page) {
    final isActive = page == _currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        onPressed: () => setState(() => _currentPage = page),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isActive ? AppConstants.primaryColor : Colors.grey[200],
          foregroundColor: isActive ? Colors.white : Colors.grey[700],
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          '${page + 1}',
          style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
      ),
    );
  }

  Widget _buildErrorState(error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل الكتب',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(booksCacheProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لم يتم العثور على كتب',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'جرب تغيير معايير البحث أو الفلاتر',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'مسح كل الفلاتر',
                style: GoogleFonts.cairo(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Book> _filterAndSortBooks(List<Book> books) {
    var filtered = books.where((book) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!book.bookName.toLowerCase().contains(query) &&
            !book.authorName.toLowerCase().contains(query) &&
            !book.category.toLowerCase().contains(query) &&
            !book.libraryLocation.toLowerCase().contains(query) &&
            !book.briefDescription.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != null && book.category != _selectedCategory) {
        return false;
      }

      // Location filter
      if (_selectedLocation != null &&
          book.libraryLocation != _selectedLocation) {
        return false;
      }

      // Author filter
      if (_selectedAuthor != null && book.authorName != _selectedAuthor) {
        return false;
      }

      return true;
    }).toList();

    // Sort books
    filtered.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortBy) {
        case 'bookName':
          aValue = a.bookName;
          bValue = b.bookName;
          break;
        case 'authorName':
          aValue = a.authorName;
          bValue = b.authorName;
          break;
        case 'category':
          aValue = a.category;
          bValue = b.category;
          break;
        case 'libraryLocation':
          aValue = a.libraryLocation;
          bValue = b.libraryLocation;
          break;
        default:
          aValue = a.bookName;
          bValue = b.bookName;
      }

      int comparison = aValue.toString().compareTo(bValue.toString());
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = null;
      _selectedLocation = null;
      _selectedAuthor = null;
      _currentPage = 0;
    });
  }

  void _navigateToEdit(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookScreen(book: book),
      ),
    );
  }
}
