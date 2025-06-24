<style>
.rtl-section {
  direction: rtl;
  text-align: right;
  font-family: 'Arial', 'Tahoma', sans-serif;
}
.ltr-section {
  direction: ltr;
  text-align: left;
  font-family: 'Arial', 'Helvetica', sans-serif;
}
.code-block {
  direction: ltr;
  text-align: left;
}
</style>

# دليل المطور | Developer Guide

<div dir="rtl" lang="ar" class="rtl-section">

## نظرة عامة للمطورين
هذا الدليل مخصص للمطورين الذين يعملون على مكتبة فصي. يحتوي على جميع المعلومات التقنية والإرشادات اللازمة لتطوير وصيانة التطبيق.

## البنية التقنية

### المكونات الأساسية
- **النماذج الديناميكية**: نظام مرن لإنشاء نماذج قابلة للتخصيص
- **خدمة Google Sheets**: تكامل مع Google Sheets لإدارة البيانات
- **قاعدة البيانات المحلية**: تخزين محلي للبيانات باستخدام SQLite
- **نظام P2P**: مشاركة البيانات بين الأجهزة
- **واجهة المستخدم**: واجهة حديثة مبنية على Flutter

### نماذج البيانات

#### KeySheetRow
نموذج لتمثيل صفوف مفتاح البيانات:
```dart
class KeySheetRow {
  final String columnA;
  final String columnB;
  final String columnC;
  // ... المزيد من الحقول
}
```

#### FieldConfig
إعداد الحقول الديناميكية:
```dart
class FieldConfig {
  final String name;
  final String displayName;
  final FieldType type;
  final List<FieldFeature> features;
  final List<String> options;
}
```

### أنواع الحقول المدعومة
- **النص**: حقول نصية بسيطة
- **القائمة المنسدلة**: خيارات محددة مسبقاً
- **الإكمال التلقائي**: اقتراحات ديناميكية
- **الموقع المركب**: مواقع الكتب (صف + عمود)
- **الرقم**: قيم رقمية
- **التاريخ والوقت**: تواريخ وأوقات
- **الملفات والصور**: رفع الوسائط

### الميزات المتقدمة
- **إضافة جديد**: زر لإضافة خيارات جديدة
- **التنسيق**: دعم Markdown
- **التحقق**: قواعد التحقق المخصصة
- **البحث والتصفية**: إمكانيات بحث متقدمة

## التطوير

### متطلبات التطوير
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Git

### إعداد البيئة
<div class="code-block">

```bash
# استنساخ المشروع
git clone [repository-url]
cd fussi_lib

# تثبيت التبعيات
flutter pub get

# تشغيل التطبيق
flutter run
```

</div>

### بنية الملفات
```
lib/
├── models/          # نماذج البيانات
├── services/        # الخدمات
├── screens/         # شاشات التطبيق
├── widgets/         # مكونات واجهة المستخدم
├── providers/       # إدارة الحالة
└── utils/           # أدوات مساعدة
```

### اختبار التطبيق
<div class="code-block">

```bash
# تشغيل الاختبارات
flutter test

# اختبار Google Sheets
dart test_google_sheets.dart

# اختبار الكشف الديناميكي
dart test_dynamic_detection.dart
```

</div>

## إرشادات المساهمة

### قواعد الكود
- استخدم أسماء متغيرات وصفية
- اكتب تعليقات باللغة العربية والإنجليزية
- اتبع معايير Dart/Flutter
- اختبر جميع التغييرات

### عملية المراجعة
1. إنشاء فرع جديد للميزة
2. تطوير وتجربة التغييرات
3. كتابة الاختبارات
4. إرسال Pull Request
5. مراجعة الكود
6. دمج التغييرات

## استكشاف الأخطاء

### مشاكل شائعة
- **خطأ Google Sheets API**: تحقق من بيانات الاعتماد
- **مشاكل قاعدة البيانات**: تحقق من صيغة SQL
- **أخطاء P2P**: تحقق من إعدادات الشبكة

### سجلات التطبيق
استخدم `flutter logs` لمتابعة سجلات التطبيق في الوقت الفعلي.

## الأمان

### حماية البيانات
- تشفير البيانات الحساسة
- استخدام HTTPS لجميع الاتصالات
- التحقق من صحة المدخلات
- حماية API keys

### أفضل الممارسات
- فحص الأذونات قبل الوصول للبيانات
- تسجيل العمليات الحساسة
- استخدام التوكينز المؤقتة
- تحديث التبعيات بانتظام

</div>

---

<div dir="ltr" lang="en" class="ltr-section">

## Developer Overview
This guide is designed for developers working on the Fussi Library project. It contains all technical information and guidelines necessary for developing and maintaining the application.

## Technical Architecture

### Core Components
- **Dynamic Forms**: Flexible system for creating customizable forms
- **Google Sheets Service**: Integration with Google Sheets for data management
- **Local Database**: Local data storage using SQLite
- **P2P System**: Data sharing between devices
- **User Interface**: Modern interface built with Flutter

### Data Models

#### KeySheetRow
Model for representing key data rows:
```dart
class KeySheetRow {
  final String columnA;
  final String columnB;
  final String columnC;
  // ... more fields
}
```

#### FieldConfig
Dynamic field configuration:
```dart
class FieldConfig {
  final String name;
  final String displayName;
  final FieldType type;
  final List<FieldFeature> features;
  final List<String> options;
}
```

### Supported Field Types
- **Text**: Simple text fields
- **Dropdown**: Predefined options
- **Autocomplete**: Dynamic suggestions
- **Location Compound**: Book locations (row + column)
- **Number**: Numeric values
- **Date/Time**: Dates and times
- **Files/Images**: Media upload

### Advanced Features
- **Add New**: Button to add new options
- **Formatting**: Markdown support
- **Validation**: Custom validation rules
- **Search/Filter**: Advanced search capabilities

## Development

### Development Requirements
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Git

### Environment Setup
```bash
# Clone the project
git clone [repository-url]
cd fussi_lib

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### File Structure
```
lib/
├── models/          # Data models
├── services/        # Services
├── screens/         # Application screens
├── widgets/         # UI components
├── providers/       # State management
└── utils/           # Helper utilities
```

### Testing
```bash
# Run tests
flutter test

# Test Google Sheets
dart test_google_sheets.dart

# Test dynamic detection
dart test_dynamic_detection.dart
```

## Contribution Guidelines

### Code Standards
- Use descriptive variable names
- Write comments in both Arabic and English
- Follow Dart/Flutter standards
- Test all changes

### Review Process
1. Create new feature branch
2. Develop and test changes
3. Write tests
4. Submit Pull Request
5. Code review
6. Merge changes

## Troubleshooting

### Common Issues
- **Google Sheets API Error**: Check credentials
- **Database Issues**: Check SQL syntax
- **P2P Problems**: Check network settings

### Application Logs
Use `flutter logs` to monitor application logs in real-time.

## Security

### Data Protection
- Encrypt sensitive data
- Use HTTPS for all connections
- Validate all inputs
- Protect API keys

### Best Practices
- Check permissions before data access
- Log sensitive operations
- Use temporary tokens
- Update dependencies regularly

## API Reference

### DynamicSheetsService
Main service for Google Sheets integration:

```dart
class DynamicSheetsService {
  Future<FormStructure> loadFormStructure();
  Future<List<Map<String, dynamic>>> loadBooks();
  Future<void> addBook(Map<String, dynamic> book);
}
```

### LocalDatabaseService
Local database operations:

```dart
class LocalDatabaseService {
  Future<void> insertBook(Book book);
  Future<List<Book>> getAllBooks();
  Future<void> updateBook(Book book);
  Future<void> deleteBook(int id);
}
```

## Performance Optimization

### Best Practices
- Use `const` constructors where possible
- Implement lazy loading for large datasets
- Cache frequently accessed data
- Optimize image loading and display
- Use `ListView.builder` for long lists

### Memory Management
- Dispose controllers and streams properly
- Use `AutomaticKeepAliveClientMixin` carefully
- Monitor memory usage during development
- Profile the app regularly

## Deployment

### Build Commands
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Linux
flutter build linux --release
```

### Release Checklist
- [ ] Update version numbers
- [ ] Test on multiple devices
- [ ] Update documentation
- [ ] Create release notes
- [ ] Tag the release in Git

</div>

---

## Documentation Files

### Developer Documentation
- `FIELD_TYPES_AND_FEATURES_GUIDE.md` - Complete field types and features guide
- `ENHANCED_FIELD_SYSTEM_SUMMARY.md` - Field system implementation summary
- `GOOGLE_SHEETS_STRUCTURE_GUIDE.md` - Google Sheets integration guide

### Additional Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Google Sheets API](https://developers.google.com/sheets/api)

---

*آخر تحديث | Last Updated: 2024* 