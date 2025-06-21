import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../services/hybrid_library_service.dart';
import '../services/structure_loader_service.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  final _hybridService = HybridLibraryService();

  bool _isLoading = true;
  Map<String, int> _categoryStats = {};
  Map<String, int> _authorStats = {};
  Set<String> _locations = {};
  int _totalBooks = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadStatistics();
  }

  @override
  void dispose() {
    _hybridService.dispose();
    super.dispose();
  }

  Future<void> _initializeAndLoadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _hybridService.initialize();
      await _loadStatistics();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تهيئة الإحصائيات: ${e.toString()}';
      });
      _showMessage('خطأ في تهيئة الإحصائيات: ${e.toString()}', isError: true);
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use hybrid service to get statistics with timeout
      final stats = await _hybridService
          .getStatistics()
          .timeout(const Duration(seconds: 45));

      _categoryStats.clear();
      _authorStats.clear();
      _locations.clear();
      _totalBooks = stats['totalBooks'] ?? 0;

      // Process categories
      final categories =
          stats['categories'] as List<Map<String, dynamic>>? ?? [];
      for (final category in categories) {
        final name = category['category']?.toString() ?? '';
        final count = category['count'] as int? ?? 0;
        if (name.isNotEmpty) {
          _categoryStats[name] = count;
        }
      }

      // Process authors
      final authors = stats['authors'] as List<Map<String, dynamic>>? ?? [];
      for (final author in authors) {
        final name = author['author_name']?.toString() ?? '';
        final count = author['count'] as int? ?? 0;
        if (name.isNotEmpty) {
          _authorStats[name] = count;
        }
      }

      // Process locations
      final locations = stats['locations'] as List<String>? ?? [];
      _locations = locations.where((loc) => loc.isNotEmpty).toSet();

      setState(() {
        _isLoading = false;
      });

      if (_totalBooks == 0) {
        _showMessage('لا توجد بيانات إحصائية متاحة', isError: false);
      } else {
        _showMessage('تم تحميل الإحصائيات بنجاح (${_totalBooks} كتاب)',
            isError: false);
      }
    } on TimeoutException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'انتهت مهلة تحميل الإحصائيات';
      });
      _showMessage('انتهت مهلة تحميل الإحصائيات', isError: true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحميل الإحصائيات: ${e.toString()}';
      });
      _showMessage('خطأ في تحميل الإحصائيات: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final structureAsync = ref.watch(cachedStructureProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
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
              onPressed: _isLoading ? null : _loadStatistics,
              tooltip: 'تحديث الإحصائيات',
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
            : _errorMessage != null
                ? _buildErrorWidget()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Structure Status Info
                        _buildStructureStatusCard(structureAsync),
                        const SizedBox(height: 16),

                        // Main Stats
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard(
                                    'إجمالي الكتب',
                                    '$_totalBooks',
                                    Icons.library_books,
                                    AppConstants.primaryColor)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard(
                                    'التصنيفات',
                                    '${_categoryStats.length}',
                                    Icons.category,
                                    AppConstants.secondaryColor)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard(
                                    'المؤلفون',
                                    '${_authorStats.length}',
                                    Icons.person,
                                    AppConstants.accentColor)),
                            const SizedBox(width: 16),
                            Expanded(
                                child: _buildStatCard(
                                    'المواقع',
                                    '${_locations.length}',
                                    Icons.location_on,
                                    Colors.orange)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Category Comparison with Structure
                        _buildCategoryComparisonCard(categoriesAsync),

                        const SizedBox(height: 24),

                        // Category Stats
                        if (_categoryStats.isNotEmpty) ...[
                          _buildSectionCard('توزيع الكتب حسب التصنيف',
                              _categoryStats, AppConstants.secondaryColor),
                          const SizedBox(height: 24),
                        ],

                        // Author Stats
                        if (_authorStats.isNotEmpty) ...[
                          _buildSectionCard('أكثر المؤلفين', _authorStats,
                              AppConstants.accentColor),
                          const SizedBox(height: 24),
                        ],

                        // Location Stats
                        if (_locations.isNotEmpty) ...[
                          _buildLocationStatsCard(),
                        ],
                      ],
                    ),
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
            strokeWidth: 3.0,
          ),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الإحصائيات...',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'يتم تحليل بيانات المكتبة وإنشاء الإحصائيات...',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppConstants.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = false;
                _errorMessage = 'تم إلغاء تحميل الإحصائيات';
              });
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

  Widget _buildErrorWidget() {
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
              _errorMessage ?? 'حدث خطأ غير متوقع',
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
                  onPressed: _initializeAndLoadStatistics,
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
                  'حالة هيكل البيانات',
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
                        ? 'منتهي الصلاحية - قد تكون الإحصائيات قديمة'
                        : 'محدث - الإحصائيات حديثة',
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

  Widget _buildCategoryComparisonCard(
      AsyncValue<List<String>> categoriesAsync) {
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
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: AppConstants.secondaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'مقارنة التصنيفات',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (structureCategories) {
              final usedCategories = _categoryStats.keys.toSet();
              final availableCategories = structureCategories.toSet();
              final missingCategories =
                  availableCategories.difference(usedCategories);
              final extraCategories =
                  usedCategories.difference(availableCategories);

              return Column(
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
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'جاري تحميل هيكل التصنيفات...',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppConstants.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            error: (_, __) => Row(
              children: [
                Icon(
                  Icons.error,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'خطأ في تحميل هيكل التصنيفات',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.red,
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
          Text(
            '$label: $value',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatsCard() {
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
                Icons.location_on,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'مواقع الكتب في المكتبة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _locations
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

  Widget _buildSectionCard(String title, Map<String, int> stats, Color color) {
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
                title,
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
                                value: _totalBooks > 0
                                    ? entry.value / _totalBooks
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
                                    _totalBooks > 0
                                        ? '${((entry.value / _totalBooks) * 100).toStringAsFixed(1)}%'
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
