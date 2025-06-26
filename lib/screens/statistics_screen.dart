import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/cache_service.dart';
import '../services/library_sync_service.dart';
import '../services/structure_loader_service.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  Future<void> _onRefresh() async {
    await ref.read(cacheManagerProvider.notifier).refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final statisticsAsync = ref.watch(statisticsCacheProvider);
    final structureAsync = ref.watch(structureCacheProvider);
    final categoriesAsync = ref.watch(categoriesCacheProvider);
    final cacheManager = ref.watch(cacheManagerProvider.notifier);
    final isRefreshing = ref.watch(cacheManagerProvider);

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
            'إحصائيات المكتبة',
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
              onPressed:
                  isRefreshing ? null : () => cacheManager.refreshStatistics(),
              tooltip: 'تحديث الإحصائيات',
            ),
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.white),
              onPressed:
                  isRefreshing ? null : () => cacheManager.refreshStructure(),
              tooltip: 'تحديث هيكل البيانات',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: Colors.white),
              onPressed: isRefreshing ? null : _onRefresh,
              tooltip: 'تحديث شامل',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: statisticsAsync.when(
            data: (stats) =>
                _buildStatisticsView(stats, structureAsync, categoriesAsync),
            loading: () => _buildLoadingWidget(),
            error: (error, stackTrace) =>
                _buildErrorWidget(error.toString(), cacheManager),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsView(
    Map<String, dynamic> stats,
    AsyncValue<SheetStructureData> structureAsync,
    AsyncValue<List<String>> categoriesAsync,
  ) {
    // Process statistics with safe casting
    final totalBooks = stats['totalBooks'] ?? 0;

    final categoryStats = <String, int>{};
    final categoriesData = stats['categories'];
    if (categoriesData is List) {
      for (final category in categoriesData) {
        if (category is Map<String, dynamic>) {
          final name = category['category']?.toString() ?? '';
          final count = category['count'];
          final countInt =
              count is int ? count : (int.tryParse(count.toString()) ?? 0);
          if (name.isNotEmpty) {
            categoryStats[name] = countInt;
          }
        }
      }
    }

    final authorStats = <String, int>{};
    final authorsData = stats['authors'];
    if (authorsData is List) {
      for (final author in authorsData) {
        if (author is Map<String, dynamic>) {
          final name = author['author_name']?.toString() ?? '';
          final count = author['count'];
          final countInt =
              count is int ? count : (int.tryParse(count.toString()) ?? 0);
          if (name.isNotEmpty) {
            authorStats[name] = countInt;
          }
        }
      }
    }

    final locations = <String>{};
    final locationsData = stats['locations'];
    if (locationsData is List) {
      locations.addAll(locationsData
          .map((loc) => loc?.toString() ?? '')
          .where((loc) => loc.isNotEmpty));
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Structure Status Info
          _buildStructureStatusCard(structureAsync),
          const SizedBox(height: 16),

          // Cache Status Card
          _buildCacheStatusCard(),
          const SizedBox(height: 16),

          // Main Stats
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('إجمالي الكتب', '$totalBooks',
                      Icons.library_books, AppConstants.primaryColor)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard('التصنيفات', '${categoryStats.length}',
                      Icons.category, AppConstants.secondaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard('المؤلفون', '${authorStats.length}',
                      Icons.person, AppConstants.accentColor)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard('المواقع', '${locations.length}',
                      Icons.location_on, Colors.orange)),
            ],
          ),

          const SizedBox(height: 24),

          // Category Comparison with Structure
          _buildCategoryComparisonCard(categoriesAsync, categoryStats),

          const SizedBox(height: 24),

          // Category Stats
          if (categoryStats.isNotEmpty) ...[
            _buildSectionCard('توزيع الكتب حسب التصنيف', categoryStats,
                AppConstants.secondaryColor, totalBooks),
            const SizedBox(height: 24),
          ],

          // Author Stats
          if (authorStats.isNotEmpty) ...[
            _buildSectionCard('أكثر المؤلفين', authorStats,
                AppConstants.accentColor, totalBooks),
            const SizedBox(height: 24),
          ],

          // Location Stats
          if (locations.isNotEmpty) ...[
            _buildLocationStatsCard(locations),
          ],
        ],
      ),
    );
  }

  Widget _buildCacheStatusCard() {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isRefreshing = ref.watch(cacheManagerProvider);

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
      child: Row(
        children: [
          Icon(
            isRefreshing ? Icons.sync : Icons.cached,
            color: AppConstants.accentColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'حالة البيانات',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    isRefreshing
                        ? 'جاري التحديث...'
                        : 'البيانات محفوظة - ${_getConnectionStatusText(connectionStatus)}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: isRefreshing ? Colors.blue : Colors.green,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (isRefreshing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  String _getConnectionStatusText(ConnectionMode mode) {
    switch (mode) {
      case ConnectionMode.online:
        return 'متصل بالإنترنت';
      case ConnectionMode.offline:
        return 'غير متصل';
      case ConnectionMode.p2p:
        return 'مزامنة محلية';
      default:
        return 'غير معروف';
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppConstants.primaryColor,
            strokeWidth: 3.0,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الإحصائيات المخزنة مؤقتاً...',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'يتم استخدام البيانات المخزنة مؤقتاً لتحسين الأداء...',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, CacheManager cacheManager) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'خطأ في تحميل الإحصائيات',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => cacheManager.refreshStatistics(),
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.cairo(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'العودة',
                    style: GoogleFonts.cairo(
                      color: AppConstants.hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureStatusCard(
      AsyncValue<SheetStructureData> structureAsync) {
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
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: AppConstants.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هيكل البيانات',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                structureAsync.when(
                  data: (structure) => Text(
                    structure.isExpired
                        ? 'منتهي الصلاحية - سيتم التحديث تلقائياً'
                        : 'محدث - البيانات حديثة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: structure.isExpired ? Colors.orange : Colors.green,
                    ),
                  ),
                  loading: () => Text(
                    'جاري التحميل...',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppConstants.hintColor,
                    ),
                  ),
                  error: (_, __) => Text(
                    'خطأ في تحميل هيكل البيانات',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          structureAsync.when(
            data: (structure) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: structure.isExpired
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                structure.isExpired ? Icons.warning : Icons.check_circle,
                size: 16,
                color: structure.isExpired ? Colors.orange : Colors.green,
              ),
            ),
            loading: () => const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => Icon(
              Icons.error,
              size: 16,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryComparisonCard(AsyncValue<List<String>> categoriesAsync,
      Map<String, int> categoryStats) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: AppConstants.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مقارنة التصنيفات',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (structureCategories) {
              final usedCategories = categoryStats.keys.toSet();
              final availableCategories = structureCategories.toSet();
              final missingCategories =
                  availableCategories.difference(usedCategories);
              final extraCategories =
                  usedCategories.difference(availableCategories);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildComparisonItem(
                          'متاحة في الهيكل',
                          '${availableCategories.length}',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildComparisonItem(
                          'مستخدمة فعلياً',
                          '${usedCategories.length}',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (missingCategories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildComparisonItem(
                      'غير مستخدمة',
                      '${missingCategories.length}',
                      Colors.orange,
                    ),
                  ],
                  if (extraCategories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildComparisonItem(
                      'غير موجودة في الهيكل',
                      '${extraCategories.length}',
                      Colors.red,
                    ),
                  ],
                ],
              );
            },
            loading: () => Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'جاري تحميل التصنيفات...',
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
            error: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'خطأ في تحميل هيكل التصنيفات',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: $value',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: color,
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

  Widget _buildLocationStatsCard(Set<String> locations) {
    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مواقع الكتب في المكتبة (مخزنة مؤقتاً)',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: locations
                .map((location) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        location,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title,
              style: GoogleFonts.cairo(
                  fontSize: 14, color: AppConstants.hintColor),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      String title, Map<String, int> stats, Color color, int totalBooks) {
    final sortedStats = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
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
              Icon(
                title.contains('التصنيف') ? Icons.category : Icons.person,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$title (مخزن مؤقتاً)',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedStats
              .take(10)
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '${entry.value}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              LinearProgressIndicator(
                                value: totalBooks > 0
                                    ? entry.value / totalBooks
                                    : 0,
                                backgroundColor: color.withOpacity(0.1),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: AppConstants.textColor,
                                    ),
                                  ),
                                  Text(
                                    totalBooks > 0
                                        ? '${((entry.value / totalBooks) * 100).toStringAsFixed(1)}%'
                                        : '0%',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      color: AppConstants.hintColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}
