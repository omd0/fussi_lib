# Structure Loader Service

## Overview

The Structure Loader Service is a Riverpod-based solution that loads and caches the database structure from Google Sheets at app startup. It reads from two key sheets:

1. **الفهرس (Index)** - First row contains column headers
2. **مفتاح (Key)** - Contains categories and location data

## Features

- ✅ **Automatic Loading**: Loads structure when the app starts
- ✅ **Riverpod Caching**: Uses Riverpod 3 for intelligent caching (1 hour keepAlive)
- ✅ **Fallback Support**: Uses fallback data if Google Sheets is unavailable
- ✅ **Error Handling**: Graceful error handling with fallback mechanisms
- ✅ **Auto-Refresh**: Automatically refreshes expired data
- ✅ **Multiple Providers**: Separate providers for easy access to different data types

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    App Startup                              │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              cachedStructureProvider                        │
│              (FutureProvider.autoDispose)                   │
│              • keepAlive for 1 hour                         │
│              • Auto-refresh when expired                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              StructureRepository                            │
│              • loadStructureFromSheets()                    │
│              • _loadIndexStructure() - from الفهرس          │
│              • _loadKeyStructure() - from مفتاح             │
│              • Fallback structure if loading fails          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Google Sheets API                            │
│              • Sheet: الفهرس (Index)                        │
│              • Sheet: مفتاح (Key)                           │
└─────────────────────────────────────────────────────────────┘
```

## Data Structure

### SheetStructureData Model

```dart
class SheetStructureData {
  final Map<String, List<String>> indexStructure;  // من الفهرس
  final Map<String, Map<String, dynamic>> keyStructure;  // من مفتاح
  final DateTime loadedAt;
  final String version;
  
  bool get isExpired; // Returns true if data is older than 24 hours
}
```

### Index Structure (الفهرس)

Loaded from the first row of the "الفهرس" sheet:

```dart
{
  'A': ['الموقع في المكتبة'],  // Library Location
  'B': [''],                     // Additional Location
  'C': ['التصنيف'],             // Category
  'D': ['اسم الكتاب'],          // Book Name
  'E': ['اسم المؤلف'],         // Author Name
  'F': ['رقم الجزء'],           // Part Number
  'G': ['مختصر تعريفي'],       // Brief Description
}
```

### Key Structure (مفتاح)

Loaded from the "مفتاح" sheet:

```dart
{
  'categories': {
    'type': 'dropdown',
    'options': ['علوم', 'إسلاميات', 'إنسانيات', 'لغة وأدب', ...]
  },
  'locations': {
    'type': 'compound',
    'rows': ['A', 'B', 'C', 'D', 'E'],
    'columns': ['1', '2', '3', '4', '5', '6', '7', '8']
  }
}
```

## Available Providers

### 1. cachedStructureProvider
Main provider that loads and caches the complete structure data.

```dart
final structureAsync = ref.watch(cachedStructureProvider);
```

### 2. categoriesProvider
Returns a list of available categories.

```dart
final categories = await ref.watch(categoriesProvider.future);
// Returns: ['علوم', 'إسلاميات', 'إنسانيات', ...]
```

### 3. locationsProvider
Returns available location rows and columns.

```dart
final locations = await ref.watch(locationsProvider.future);
// Returns: {'rows': ['A', 'B', 'C'], 'columns': ['1', '2', '3']}
```

### 4. columnHeadersProvider
Returns column headers mapping.

```dart
final headers = await ref.watch(columnHeadersProvider.future);
// Returns: {'A': 'الموقع في المكتبة', 'C': 'التصنيف', ...}
```

### 5. structureRefreshProvider
Provides a function to manually refresh the structure.

```dart
final refresh = ref.read(structureRefreshProvider);
refresh(); // Invalidates cache and reloads from Google Sheets
```

## Usage Examples

### Basic Usage in Widget

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    
    return categoriesAsync.when(
      data: (categories) => DropdownButton<String>(
        items: categories.map((category) => 
          DropdownMenuItem(value: category, child: Text(category))
        ).toList(),
        onChanged: (value) => {},
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Manual Refresh

```dart
class RefreshButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        final refresh = ref.read(structureRefreshProvider);
        refresh();
      },
      child: Text('Refresh Structure'),
    );
  }
}
```

### Checking Structure Status

```dart
class StructureStatus extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structureAsync = ref.watch(cachedStructureProvider);
    
    return structureAsync.when(
      data: (structure) => Column(
        children: [
          Text('Loaded: ${structure.loadedAt}'),
          Text('Version: ${structure.version}'),
          Text('Expired: ${structure.isExpired}'),
        ],
      ),
      loading: () => Text('Loading structure...'),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## Caching Strategy

### Riverpod Caching
- **Duration**: 1 hour keepAlive
- **Auto-Dispose**: After 1 hour of inactivity
- **Refresh**: Manual refresh available
- **Expiration**: Data expires after 24 hours

### Cache Flow
1. App starts → Check if provider has data
2. If no data → Load from Google Sheets
3. If loading fails → Use fallback structure
4. Cache data for 1 hour
5. Auto-dispose after 1 hour of inactivity
6. Manual refresh available anytime

## Error Handling

### Fallback Mechanism
If Google Sheets loading fails, the service automatically falls back to a predefined structure:

```dart
SheetStructureData _getFallbackStructure() {
  return SheetStructureData(
    indexStructure: {
      'A': ['الموقع في المكتبة'],
      'C': ['التصنيف'],
      'D': ['اسم الكتاب'],
      // ... more columns
    },
    keyStructure: {
      'categories': {
        'type': 'dropdown',
        'options': ['علوم', 'إسلاميات', 'إنسانيات', ...],
      },
      // ... more key data
    },
    loadedAt: DateTime.now(),
    version: '1.0.0-fallback',
  );
}
```

### Error Types Handled
- Network connectivity issues
- Google Sheets API errors
- Authentication failures
- Data parsing errors
- Missing credentials

## Testing

Run the comprehensive test suite:

```bash
flutter test test/structure_test.dart
```

### Test Coverage
- ✅ Data model serialization/deserialization
- ✅ Expiration logic
- ✅ Provider functionality
- ✅ Fallback structure
- ✅ Error handling
- ✅ Complete data flow documentation

## Integration

### 1. Add to main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}
```

### 2. Use in Widgets

```dart
import '../services/structure_loader_service.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    // Use the data...
  }
}
```

## Performance Considerations

### Memory Management
- Uses `autoDispose` to prevent memory leaks
- Automatic cleanup after 1 hour of inactivity
- Efficient caching with Riverpod

### Network Efficiency
- Loads data only once at startup
- Concurrent loading of both sheets
- Graceful fallback without blocking UI

### UI Responsiveness
- Asynchronous loading
- Loading states handled
- Error states with fallback data
- Non-blocking refresh functionality

## Future Enhancements

### Potential Improvements
- [ ] Local storage caching (SharedPreferences/Hive)
- [ ] Background refresh scheduling
- [ ] Real-time updates via webhooks
- [ ] Offline-first architecture
- [ ] Compression for large datasets
- [ ] Incremental updates

### Monitoring
- [ ] Analytics for loading times
- [ ] Error tracking and reporting
- [ ] Cache hit/miss metrics
- [ ] Network usage monitoring

## Troubleshooting

### Common Issues

1. **"Credentials not found"**
   - Ensure `service-account-key.json` is in `assets/credentials/`
   - Check file permissions and format

2. **"Structure loading failed"**
   - Check internet connectivity
   - Verify Google Sheets permissions
   - Check sheet names: "الفهرس" and "مفتاح"

3. **"Fallback data being used"**
   - Normal behavior when credentials are missing
   - Check Google Sheets API status
   - Verify spreadsheet ID in constants

### Debug Information
Use `StructureDebugWidget` to see:
- Loading status
- Load timestamp
- Version information
- Expiration status
- Error details

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  googleapis: ^12.0.0
  googleapis_auth: ^1.4.1
```

## License

This service is part of the Fussi Library project and follows the same license terms. 