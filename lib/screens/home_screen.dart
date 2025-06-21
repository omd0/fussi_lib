import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/book.dart';
import '../services/cache_service.dart';
import '../services/hybrid_library_service.dart';
import 'add_book_screen.dart';
import 'library_browser_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showWelcomeBanner = true;

  @override
  void initState() {
    super.initState();
    _loadBannerPreference();
  }

  Future<void> _loadBannerPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showWelcomeBanner = prefs.getBool('show_welcome_banner') ?? true;
    });
  }

  Future<void> _closeBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_welcome_banner', false);
    setState(() {
      _showWelcomeBanner = false;
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(cacheManagerProvider.notifier).refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final recentBooksAsync = ref.watch(recentBooksProvider);
    final popularCategoriesAsync = ref.watch(popularCategoriesProvider);
    final popularAuthorsAsync = ref.watch(popularAuthorsProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isRefreshing = ref.watch(cacheManagerProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          elevation: 0,
          title: Text(
            AppConstants.appTitle,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          actions: [
            // Refresh button
            IconButton(
              icon: Icon(
                isRefreshing ? Icons.sync : Icons.refresh,
                color: Colors.white,
              ),
              onPressed: isRefreshing ? null : _onRefresh,
              tooltip: 'تحديث جميع البيانات',
            ),
            // Connection status indicator
            Container(
              margin: const EdgeInsets.only(left: 16),
              child: Icon(
                _getConnectionIcon(connectionStatus),
                color: _getConnectionColor(connectionStatus),
                size: 20,
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner (dismissible)
                if (_showWelcomeBanner) ...[
                  _buildWelcomeBanner(context),
                  const SizedBox(height: 24),
                ],

                // Quick Stats Card
                _buildQuickStatsCard(context, ref),
                const SizedBox(height: 24),

                // Main Action Buttons
                _buildActionButtons(context),
                const SizedBox(height: 24),

                // Recent Books Section
                _buildRecentBooksSection(recentBooksAsync),
                const SizedBox(height: 24),

                // Popular Categories Section
                _buildPopularCategoriesSection(popularCategoriesAsync),
                const SizedBox(height: 24),

                // Popular Authors Section
                _buildPopularAuthorsSection(popularAuthorsAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.accentColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppConstants.welcome,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: _closeBanner,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'إغلاق',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'نظام إدارة مكتبة متطور مع تخزين ذكي',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(statisticsCacheProvider);

    return Container(
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
      child: statisticsAsync.when(
        data: (stats) {
          final totalBooks = stats['totalBooks'] ?? 0;
          final categories = stats['categories'] as List? ?? [];
          final authors = stats['authors'] as List? ?? [];
          final locations = stats['locations'] as List? ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dashboard,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نظرة سريعة على المكتبة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatItem(
                      'إجمالي الكتب',
                      '$totalBooks',
                      Icons.library_books,
                      AppConstants.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildQuickStatItem(
                      'التصنيفات',
                      '${categories.length}',
                      Icons.category,
                      AppConstants.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStatItem(
                      'المؤلفون',
                      '${authors.length}',
                      Icons.person,
                      AppConstants.accentColor,
                    ),
                  ),
                  Expanded(
                    child: _buildQuickStatItem(
                      'المواقع',
                      '${locations.length}',
                      Icons.location_on,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'جاري تحميل الإحصائيات...',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
        ),
        error: (error, _) => Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'خطأ في تحميل الإحصائيات',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppConstants.hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: AppConstants.addBook,
                subtitle: 'إضافة كتاب جديد إلى المكتبة',
                icon: Icons.add_circle,
                color: AppConstants.secondaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddBookScreen()),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                context,
                title: AppConstants.viewLibrary,
                subtitle: 'استعراض وبحث في الكتب',
                icon: Icons.library_books,
                color: AppConstants.primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LibraryBrowserScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildActionCard(
            context,
            title: 'إحصائيات المكتبة',
            subtitle: 'عرض تفصيلي للإحصائيات والتحليلات',
            icon: Icons.analytics,
            color: AppConstants.accentColor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_back_ios,
                  color: AppConstants.hintColor,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppConstants.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBooksSection(AsyncValue<List<Book>> recentBooksAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              color: AppConstants.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'الكتب الحديثة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recentBooksAsync.when(
          data: (books) => books.isEmpty
              ? _buildEmptyState('لا توجد كتب حديثة')
              : SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _buildBookCard(book);
                    },
                  ),
                ),
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _buildErrorState('خطأ في تحميل الكتب الحديثة'),
        ),
      ],
    );
  }

  Widget _buildPopularCategoriesSection(
      AsyncValue<List<MapEntry<String, int>>> popularCategoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: AppConstants.secondaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'التصنيفات الأكثر شيوعاً',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        popularCategoriesAsync.when(
          data: (categories) => categories.isEmpty
              ? _buildEmptyState('لا توجد تصنيفات')
              : Column(
                  children: categories
                      .map((entry) => _buildCategoryTile(entry))
                      .toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _buildErrorState('خطأ في تحميل التصنيفات الشائعة'),
        ),
      ],
    );
  }

  Widget _buildPopularAuthorsSection(
      AsyncValue<List<MapEntry<String, int>>> popularAuthorsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.person_pin,
              color: AppConstants.accentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'المؤلفون الأكثر شيوعاً',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        popularAuthorsAsync.when(
          data: (authors) => authors.isEmpty
              ? _buildEmptyState('لا يوجد مؤلفون')
              : Column(
                  children:
                      authors.map((entry) => _buildAuthorTile(entry)).toList(),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _buildErrorState('خطأ في تحميل المؤلفين الشائعين'),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    book.bookName,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    book.authorName,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppConstants.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              book.category,
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(MapEntry<String, int> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.category,
              color: AppConstants.secondaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.key,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.textColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.value}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorTile(MapEntry<String, int> entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.person,
              color: AppConstants.accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.key,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.textColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.value}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.hintColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: AppConstants.hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  IconData _getConnectionIcon(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.online:
        return Icons.cloud_done;
      case ConnectionMode.offline:
        return Icons.cloud_off;
      case ConnectionMode.p2p:
        return Icons.device_hub;
      default:
        return Icons.help_outline;
    }
  }

  Color _getConnectionColor(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.online:
        return Colors.green;
      case ConnectionMode.offline:
        return Colors.red;
      case ConnectionMode.p2p:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
