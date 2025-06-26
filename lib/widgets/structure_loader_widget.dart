import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/book.dart';
import '../models/location_data.dart';
import '../services/enhanced_dynamic_service.dart';

/// Widget that demonstrates structure loading and caching with location selector
class StructureLoaderWidget extends ConsumerWidget {
  const StructureLoaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppConstants.cardColor,
              AppConstants.cardColor.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هيكل البيانات (Structure)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildEnhancedStructureSection(ref),
            const SizedBox(height: 16),
            _buildLocationDataSection(ref),
            const SizedBox(height: 16),
            _buildBrowsingStructureSection(ref),
            const SizedBox(height: 16),
            _buildRefreshButton(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStructureSection(WidgetRef ref) {
    final structureAsync = ref.watch(enhancedStructureProvider);

    return _buildSection(
      title: '🚀 هيكل البيانات المحسن (Enhanced Structure)',
      content: structureAsync.when(
        data: (structure) => structure != null
            ? _buildStructureInfo(structure)
            : _buildEmptyMessage('لا توجد بيانات هيكل متاحة'),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) =>
            _buildErrorMessage('خطأ في تحميل الهيكل: ${error.toString()}'),
      ),
    );
  }

  Widget _buildLocationDataSection(WidgetRef ref) {
    final locationDataAsync = ref.watch(locationDataProvider);

    return _buildSection(
      title: '📍 بيانات المواقع (Location Data)',
      action: IconButton(
        icon: const Icon(Icons.grid_view, size: 20),
        onPressed: () => _showLocationGridDialog(ref),
        tooltip: 'عرض شبكة المواقع',
      ),
      content: locationDataAsync.when(
        data: (locationData) => locationData != null
            ? _buildLocationInfo(locationData)
            : _buildEmptyMessage('لا توجد بيانات موقع متاحة'),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) =>
            _buildErrorMessage('خطأ في تحميل المواقع: ${error.toString()}'),
      ),
    );
  }

  Widget _buildBrowsingStructureSection(WidgetRef ref) {
    final browsingAsync = ref.watch(browsingStructureProvider);

    return _buildSection(
      title: '🔍 هيكل التصفح (Browsing Structure)',
      content: browsingAsync.when(
        data: (browsing) => browsing != null
            ? _buildBrowsingInfo(browsing)
            : _buildEmptyMessage('لا توجد بيانات تصفح متاحة'),
        loading: () => const CircularProgressIndicator(),
        error: (error, stack) => _buildErrorMessage(
            'خطأ في تحميل بيانات التصفح: ${error.toString()}'),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (action != null) ...[
              const Spacer(),
              action,
            ],
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildStructureInfo(EnhancedStructureData structure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoChip('الإصدار', structure.version, Colors.blue),
        const SizedBox(height: 4),
        _buildInfoChip('عدد الحقول', '${structure.formStructure.fields.length}',
            Colors.green),
        const SizedBox(height: 4),
        _buildInfoChip('التصنيفات',
            '${structure.browsingStructure.categories.length}', Colors.orange),
        const SizedBox(height: 4),
        _buildInfoChip(
          'حالة البيانات',
          structure.isExpired ? 'منتهي الصلاحية' : 'حديث',
          structure.isExpired ? Colors.red : Colors.green,
        ),
      ],
    );
  }

  Widget _buildLocationInfo(LocationData locationData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationSummary(locationData),
        const SizedBox(height: 12),
        _buildLocationGridPreview(locationData),
      ],
    );
  }

  Widget _buildBrowsingInfo(BrowsingStructure browsing) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildInfoChip(
            'التصنيفات', '${browsing.categories.length}', Colors.blue),
        _buildInfoChip('المؤلفون', '${browsing.authors.length}', Colors.green),
        _buildInfoChip('الحقول القابلة للبحث',
            '${browsing.searchableFields.length}', Colors.purple),
      ],
    );
  }

  Widget _buildLocationSummary(LocationData locationData) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildInfoChip('الصفوف', '${locationData.rows.length}', Colors.purple),
        _buildInfoChip(
            'الأعمدة', '${locationData.columns.length}', Colors.teal),
        if (locationData.rooms.isNotEmpty)
          _buildInfoChip('الغرف', '${locationData.rooms.length}', Colors.brown),
        _buildInfoChip(
          'إجمالي المواقع',
          '${locationData.rows.length * locationData.columns.length}',
          Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildLocationGridPreview(LocationData locationData) {
    if (locationData.rows.isEmpty || locationData.columns.isEmpty) {
      return _buildEmptyPreview('لا توجد بيانات كافية لعرض المعاينة');
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildPreviewHeaders(locationData.columns),
            ..._buildPreviewRows(locationData),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewHeaders(List<String> columns) {
    return Row(
      children: [
        const SizedBox(width: 20),
        ...columns.take(8).map((col) => Expanded(
              child: Container(
                height: 20,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    col,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }

  List<Widget> _buildPreviewRows(LocationData locationData) {
    return locationData.rows
        .take(4)
        .map((row) => Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      row,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ),
                ...locationData.columns.take(8).map((col) => Expanded(
                      child: Container(
                        height: 20,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.book,
                            size: 8,
                            color: AppConstants.primaryColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    )),
              ],
            ))
        .toList();
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style:
                GoogleFonts.cairo(fontSize: 12, color: AppConstants.textColor),
          ),
          Text(
            value,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Text(
      message,
      style: TextStyle(color: AppConstants.hintColor),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Text(
      message,
      style: const TextStyle(color: Colors.red),
    );
  }

  Widget _buildEmptyPreview(String message) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.cairo(color: AppConstants.hintColor),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final service = ref.read(enhancedDynamicServiceProvider);
          await service.refresh();
          if (ref.context.mounted) {
            ScaffoldMessenger.of(ref.context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم تحديث هيكل البيانات',
                  style: GoogleFonts.cairo(color: Colors.white),
                ),
                backgroundColor: AppConstants.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        icon: const Icon(Icons.refresh),
        label: const Text('تحديث هيكل البيانات'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showLocationGridDialog(WidgetRef ref) {
    final locationDataAsync = ref.watch(locationDataProvider);

    showDialog(
      context: ref.context,
      builder: (context) =>
          LocationGridDialog(locationDataAsync: locationDataAsync),
    );
  }
}

/// Dialog to show full location grid
class LocationGridDialog extends StatelessWidget {
  final AsyncValue<LocationData?> locationDataAsync;

  const LocationGridDialog({super.key, required this.locationDataAsync});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Expanded(
              child: locationDataAsync.when(
                data: (locationData) => locationData != null
                    ? LocationGridWidget(locationData: locationData)
                    : const Center(child: Text('لا توجد بيانات موقع متاحة')),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'خطأ في تحميل المواقع: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.grid_view, color: AppConstants.primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          'شبكة مواقع المكتبة',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

/// Interactive location grid widget
class LocationGridWidget extends StatefulWidget {
  final LocationData locationData;
  final String? selectedLocation;
  final Function(String?)? onLocationSelected;

  const LocationGridWidget({
    super.key,
    required this.locationData,
    this.selectedLocation,
    this.onLocationSelected,
  });

  @override
  State<LocationGridWidget> createState() => _LocationGridWidgetState();
}

class _LocationGridWidgetState extends State<LocationGridWidget> {
  String? _selectedRow;
  String? _selectedCol;

  @override
  void initState() {
    super.initState();
    _parseSelectedLocation();
  }

  void _parseSelectedLocation() {
    if (widget.selectedLocation?.isNotEmpty == true) {
      final match =
          RegExp(r'^([A-Z]+)(\d+)$').firstMatch(widget.selectedLocation!);
      if (match != null) {
        _selectedCol = match.group(1);
        _selectedRow = match.group(2);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locationData.rows.isEmpty ||
        widget.locationData.columns.isEmpty) {
      return const Center(child: Text('لا توجد بيانات كافية لعرض الشبكة'));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppConstants.primaryColor.withOpacity(0.2), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            _buildGridHeaders(),
            Expanded(child: _buildGridContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildGridHeaders() {
    return Container(
      height: 50,
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Container(
            width: 50,
            decoration: BoxDecoration(
              color: Colors.orange.shade200,
              border: Border.all(color: Colors.orange.shade300),
            ),
          ),
          ...widget.locationData.columns.map((col) => Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade300)),
                  child: Center(
                    child: Text(
                      col,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGridContent() {
    return SingleChildScrollView(
      child: Column(
        children:
            widget.locationData.rows.map((row) => _buildGridRow(row)).toList(),
      ),
    );
  }

  Widget _buildGridRow(String row) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 50,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Center(
              child: Text(
                row,
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ),
          ...widget.locationData.columns.map((col) => _buildGridCell(row, col)),
        ],
      ),
    );
  }

  Widget _buildGridCell(String row, String col) {
    final isSelected = _selectedRow == row && _selectedCol == col;

    return Expanded(
      child: InkWell(
        onTap: widget.onLocationSelected != null
            ? () {
                setState(() {
                  _selectedRow = row;
                  _selectedCol = col;
                });
                widget.onLocationSelected!('$col$row');
              }
            : null,
        child: Container(
          height: double.infinity,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.8)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : AppConstants.primaryColor.withOpacity(0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  '$col$row',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppConstants.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Debug widget to show structure loading status
class StructureDebugWidget extends ConsumerWidget {
  const StructureDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structureAsync = ref.watch(enhancedStructureProvider);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.grey.shade100, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 معلومات تقنية (Debug Info)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          structureAsync.when(
            data: (structure) => structure != null
                ? _buildDebugInfo(structure)
                : const Text('❌ لا توجد بيانات هيكل متاحة'),
            loading: () => const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⏳ حالة التحميل: جاري التحميل...'),
                SizedBox(height: 8),
                LinearProgressIndicator(),
              ],
            ),
            error: (error, stack) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('❌ حالة التحميل: خطأ'),
                Text('📝 تفاصيل الخطأ: ${error.toString()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfo(EnhancedStructureData structure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('✅ حالة التحميل: مكتمل'),
        Text('📅 تاريخ التحميل: ${_formatDateTime(structure.loadedAt)}'),
        Text('🏷️ الإصدار: ${structure.version}'),
        Text('⏰ منتهي الصلاحية: ${structure.isExpired ? 'نعم' : 'لا'}'),
        Text('📋 عدد حقول النموذج: ${structure.formStructure.fields.length}'),
        Text(
            '🔑 عدد التصنيفات: ${structure.browsingStructure.categories.length}'),
        if (structure.locationData != null) ...[
          Text('📍 الصفوف: ${structure.locationData!.rows.length}'),
          Text('📍 الأعمدة: ${structure.locationData!.columns.length}'),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
