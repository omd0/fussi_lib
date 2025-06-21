import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/book.dart';
import 'hybrid_library_service.dart';
import 'structure_loader_service.dart';

part 'cache_service.g.dart';

// Cache duration constants
const Duration _shortCacheDuration = Duration(minutes: 5);
const Duration _mediumCacheDuration = Duration(minutes: 15);
const Duration _longCacheDuration = Duration(hours: 1);

// Global hybrid service provider
@riverpod
HybridLibraryService hybridLibraryService(HybridLibraryServiceRef ref) {
  final service = HybridLibraryService();

  // Dispose service when provider is disposed
  ref.onDispose(() => service.dispose());

  return service;
}

// Books cache provider with auto-refresh
@riverpod
class BooksCache extends _$BooksCache {
  @override
  Future<List<Book>> build() async {
    // Cache for medium duration
    ref.cacheFor(_mediumCacheDuration);

    final service = ref.watch(hybridLibraryServiceProvider);
    await service.initialize();

    final books = await service.getBooksAsObjects();

    // Keep cache fresh by invalidating after duration
    Timer(_mediumCacheDuration, () {
      ref.invalidateSelf();
    });

    return books;
  }

  // Method to refresh books manually
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // Method to add a book and update cache
  Future<void> addBook(Book book) async {
    final service = ref.read(hybridLibraryServiceProvider);
    final success = await service.forceAddBook(book);

    if (success) {
      // Invalidate cache to trigger refresh
      ref.invalidateSelf();
      // Also invalidate statistics cache
      ref.invalidate(statisticsCacheProvider);
    }
  }
}

// Statistics cache provider
@riverpod
class StatisticsCache extends _$StatisticsCache {
  @override
  Future<Map<String, dynamic>> build() async {
    // Cache for short duration as stats change frequently
    ref.cacheFor(_shortCacheDuration);

    final service = ref.watch(hybridLibraryServiceProvider);
    await service.initialize();

    final stats = await service.getStatistics();

    // Auto-refresh after cache duration
    Timer(_shortCacheDuration, () {
      ref.invalidateSelf();
    });

    return stats;
  }

  // Method to refresh statistics manually
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// Structure cache provider (longer cache as it changes less frequently)
@riverpod
class StructureCache extends _$StructureCache {
  @override
  Future<SheetStructureData> build() async {
    // Cache for long duration as structure changes infrequently
    ref.cacheFor(_longCacheDuration);

    final repository = StructureRepository();
    final structure = await repository.loadStructureFromSheets();

    // Auto-refresh after cache duration
    Timer(_longCacheDuration, () {
      ref.invalidateSelf();
    });

    return structure;
  }

  // Method to refresh structure manually
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

// Categories cache provider (derived from structure)
@riverpod
Future<List<String>> categoriesCache(CategoriesCacheRef ref) async {
  final structure = await ref.watch(structureCacheProvider.future);
  final categoriesData = structure.keyStructure['categories'];

  if (categoriesData != null && categoriesData['options'] is List) {
    return List<String>.from(categoriesData['options']);
  }

  return <String>[];
}

// Connection status provider
@riverpod
class ConnectionStatus extends _$ConnectionStatus {
  @override
  ConnectionMode build() {
    // Listen to hybrid service for connection changes
    final service = ref.watch(hybridLibraryServiceProvider);

    // Set up listener for mode changes
    service.onModeChanged = (mode) {
      state = mode;
    };

    return service.currentMode;
  }

  void updateMode(ConnectionMode mode) {
    state = mode;
  }
}

// Search cache provider for recent searches
@riverpod
class SearchCache extends _$SearchCache {
  @override
  Map<String, List<Book>> build() {
    // Cache search results for quick access
    ref.cacheFor(_shortCacheDuration);
    return {};
  }

  Future<List<Book>> search(String query) async {
    // Check if we have cached results for this query
    if (state.containsKey(query)) {
      return state[query]!;
    }

    // Perform search
    final service = ref.read(hybridLibraryServiceProvider);
    await service.initialize();

    final searchResults = await service.searchBooks(query);
    final books =
        searchResults.map((bookMap) => Book.fromMap(bookMap)).toList();

    // Cache the results
    state = {...state, query: books};

    return books;
  }

  void clearCache() {
    state = {};
  }
}

// App preferences cache
@riverpod
class AppPreferencesCache extends _$AppPreferencesCache {
  @override
  Map<String, dynamic> build() {
    return {
      'theme_mode': 'light',
      'language': 'ar',
      'last_sync': null,
      'cache_enabled': true,
    };
  }

  void updatePreference(String key, dynamic value) {
    state = {...state, key: value};
  }

  T? getPreference<T>(String key) {
    return state[key] as T?;
  }
}

// Recent books provider (for quick access)
@riverpod
Future<List<Book>> recentBooks(RecentBooksRef ref) async {
  final books = await ref.watch(booksCacheProvider.future);

  // Return most recent 10 books
  final sortedBooks = List<Book>.from(books)
    ..sort((a, b) =>
        b.bookName.compareTo(a.bookName)); // Simple sort, can be improved

  return sortedBooks.take(10).toList();
}

// Popular categories provider (derived from statistics)
@riverpod
Future<List<MapEntry<String, int>>> popularCategories(
    PopularCategoriesRef ref) async {
  final stats = await ref.watch(statisticsCacheProvider.future);

  final categories = stats['categories'] as List? ?? [];
  final categoryStats = <String, int>{};

  for (final category in categories) {
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

  final sortedEntries = categoryStats.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sortedEntries.take(5).toList();
}

// Popular authors provider (derived from statistics)
@riverpod
Future<List<MapEntry<String, int>>> popularAuthors(
    PopularAuthorsRef ref) async {
  final stats = await ref.watch(statisticsCacheProvider.future);

  final authors = stats['authors'] as List? ?? [];
  final authorStats = <String, int>{};

  for (final author in authors) {
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

  final sortedEntries = authorStats.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sortedEntries.take(5).toList();
}

// Cache refresh provider for manual refresh operations
@riverpod
class CacheManager extends _$CacheManager {
  @override
  bool build() {
    return false; // Not refreshing initially
  }

  Future<void> refreshAll() async {
    state = true; // Set refreshing state

    try {
      // Invalidate all caches
      ref.invalidate(booksCacheProvider);
      ref.invalidate(statisticsCacheProvider);
      ref.invalidate(structureCacheProvider);
      ref.invalidate(searchCacheProvider);

      // Wait for all to refresh
      await Future.wait([
        ref.read(booksCacheProvider.future),
        ref.read(statisticsCacheProvider.future),
        ref.read(structureCacheProvider.future),
      ]);
    } finally {
      state = false; // Clear refreshing state
    }
  }

  Future<void> refreshBooks() async {
    await ref.read(booksCacheProvider.notifier).refresh();
  }

  Future<void> refreshStatistics() async {
    await ref.read(statisticsCacheProvider.notifier).refresh();
  }

  Future<void> refreshStructure() async {
    await ref.read(structureCacheProvider.notifier).refresh();
  }

  void clearSearchCache() {
    ref.read(searchCacheProvider.notifier).clearCache();
  }
}

// Extension for cache duration
extension on Ref {
  void cacheFor(Duration duration) {
    Timer(duration, invalidateSelf);
  }
}
