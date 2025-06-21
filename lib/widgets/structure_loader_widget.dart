import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/structure_loader_service.dart';

/// Widget that demonstrates structure loading and caching
class StructureLoaderWidget extends ConsumerWidget {
  const StructureLoaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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

            // Categories Section
            _buildCategoriesSection(ref),
            const SizedBox(height: 16),

            // Locations Section
            _buildLocationsSection(ref),
            const SizedBox(height: 16),

            // Column Headers Section
            _buildColumnHeadersSection(ref),
            const SizedBox(height: 16),

            // Refresh Button
            _buildRefreshButton(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 التصنيفات (Categories)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          data: (categories) => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: categories
                .map((category) => Chip(
                      label: Text(category),
                      backgroundColor: Colors.blue.shade50,
                    ))
                .toList(),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text(
            'خطأ في تحميل التصنيفات: ${error.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationsSection(WidgetRef ref) {
    final locationsAsync = ref.watch(locationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📍 المواقع (Locations)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        locationsAsync.when(
          data: (locations) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'الصفوف (Rows): ${locations['rows']?.join(', ') ?? 'لا توجد'}'),
              const SizedBox(height: 4),
              Text(
                  'الأعمدة (Columns): ${locations['columns']?.join(', ') ?? 'لا توجد'}'),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text(
            'خطأ في تحميل المواقع: ${error.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnHeadersSection(WidgetRef ref) {
    final headersAsync = ref.watch(columnHeadersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 عناوين الأعمدة (Column Headers)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        headersAsync.when(
          data: (headers) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: headers.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${entry.key}: ${entry.value}'),
                    ))
                .toList(),
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text(
            'خطأ في تحميل العناوين: ${error.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton(WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          final refresh = ref.read(structureRefreshProvider);
          refresh();
          ScaffoldMessenger.of(ref.context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث هيكل البيانات'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.refresh),
        label: const Text('تحديث هيكل البيانات'),
      ),
    );
  }
}

/// Debug widget to show structure loading status
class StructureDebugWidget extends ConsumerWidget {
  const StructureDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structureAsync = ref.watch(cachedStructureProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 معلومات تقنية (Debug Info)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            structureAsync.when(
              data: (structure) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ حالة التحميل: مكتمل'),
                  Text(
                      '📅 تاريخ التحميل: ${_formatDateTime(structure.loadedAt)}'),
                  Text('🏷️ الإصدار: ${structure.version}'),
                  Text(
                      '⏰ منتهي الصلاحية: ${structure.isExpired ? 'نعم' : 'لا'}'),
                  Text(
                      '📋 عدد أعمدة الفهرس: ${structure.indexStructure.length}'),
                  Text(
                      '🔑 عدد مفاتيح البيانات: ${structure.keyStructure.length}'),
                ],
              ),
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
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
