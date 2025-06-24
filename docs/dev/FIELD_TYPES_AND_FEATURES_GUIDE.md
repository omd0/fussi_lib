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

# دليل أنواع الحقول والميزات | Field Types and Features Guide

<div dir="rtl" lang="ar" class="rtl-section">

## العربية | Arabic

### نظرة عامة
هذا الدليل يشرح جميع أنواع الحقول والميزات المتاحة في نظام النماذج الديناميكية. يمكن دمج أي نوع حقل مع أي مجموعة من الميزات لإنشاء حقول مخصصة ومرنة.

---

## أنواع الحقول

### 1. النص (`text`)
حقل نص أساسي لإدخال النصوص القصيرة

**أمثلة الاستخدام:**
- أسماء الكتب
- أسماء المؤلفين
- عناوين قصيرة

### 2. القائمة المنسدلة (`dropdown`)
قائمة خيارات محددة مسبقاً للاختيار من بينها

**أمثلة الاستخدام:**
- التصنيفات
- الحالة
- اللغة

### 3. الإكمال التلقائي (`autocomplete`)
حقل نص مع اقتراحات تلقائية أثناء الكتابة

**أمثلة الاستخدام:**
- أسماء المؤلفين
- دور النشر
- الكلمات المفتاحية

### 4. الموقع المركب (`locationCompound`)
حقل مخصص للمواقع المكونة من صف وعمود

**أمثلة الاستخدام:**
- مواقع الكتب في المكتبة
- مواقع التخزين

### 5. الرقم (`number`)
حقل لإدخال الأرقام والقيم العددية

**أمثلة الاستخدام:**
- عدد الصفحات
- السعر
- الكمية

### 6. التاريخ (`date`)
حقل لاختيار التاريخ

**أمثلة الاستخدام:**
- تاريخ النشر
- تاريخ الإضافة
- تاريخ الاستعارة

### 7. الوقت (`time`)
حقل لاختيار الوقت

**أمثلة الاستخدام:**
- وقت الاستعارة
- وقت الإرجاع

### 8. التاريخ والوقت (`datetime`)
حقل لاختيار التاريخ والوقت معاً

**أمثلة الاستخدام:**
- وقت آخر تحديث
- وقت الحجز

### 9. البريد الإلكتروني (`email`)
حقل مخصص لعناوين البريد الإلكتروني مع تحقق تلقائي

**أمثلة الاستخدام:**
- بريد المؤلف
- بريد الناشر

### 10. رقم الهاتف (`phone`)
حقل لأرقام الهواتف مع تنسيق تلقائي

**أمثلة الاستخدام:**
- هاتف المؤلف
- هاتف الناشر

### 11. الرابط (`url`)
حقل للروابط الإلكترونية مع تحقق تلقائي

**أمثلة الاستخدام:**
- موقع المؤلف
- رابط الكتاب الإلكتروني

### 12. كلمة المرور (`password`)
حقل آمن لكلمات المرور

**أمثلة الاستخدام:**
- كلمات مرور الحسابات
- رموز الحماية

### 13. النص الطويل (`textarea`)
حقل نص متعدد الأسطر للنصوص الطويلة

**أمثلة الاستخدام:**
- ملخص الكتاب
- الوصف
- الملاحظات

### 14. مربع الاختيار (`checkbox`)
مربعات اختيار متعددة

**أمثلة الاستخدام:**
- الفئات المتعددة
- الخصائص
- الميزات

### 15. الاختيار الواحد (`radio`)
أزرار اختيار لخيار واحد فقط

**أمثلة الاستخدام:**
- الحالة
- الأولوية
- المستوى

### 16. شريط التمرير (`slider`)
شريط تمرير للقيم الرقمية

**أمثلة الاستخدام:**
- التقييم
- المستوى
- النسبة المئوية

### 17. التقييم (`rating`)
نجوم أو رموز للتقييم

**أمثلة الاستخدام:**
- تقييم الكتاب
- مستوى الصعوبة

### 18. اللون (`color`)
منتقي الألوان

**أمثلة الاستخدام:**
- لون التصنيف
- لون التمييز

### 19. الملف (`file`)
رفع الملفات

**أمثلة الاستخدام:**
- ملفات PDF
- المستندات

### 20. الصورة (`image`)
رفع وعرض الصور

**أمثلة الاستخدام:**
- غلاف الكتاب
- صورة المؤلف

### 21. الباركود (`barcode`)
قراءة وإنشاء الباركود

**أمثلة الاستخدام:**
- رقم ISBN
- رموز المنتجات

### 22. رمز QR (`qrcode`)
قراءة وإنشاء رموز QR

**أمثلة الاستخدام:**
- روابط سريعة
- معلومات الكتاب

---

## الميزات

### 1. إضافة جديد (`plus`)
يضيف زر "إضافة جديد" للحقول المنسدلة

### 2. تنسيق (`md`)
يدعم تنسيق النص باستخدام Markdown

### 3. نص طويل (`long`)
نص متعدد الأسطر للمحتوى الطويل

### 4. مطلوب (`required`)
حقل إجباري يجب ملؤه

### 5. للقراءة فقط (`readonly`)
حقل للقراءة فقط لا يمكن تعديله

### 6. مخفي (`hidden`)
حقل مخفي لا يظهر في النموذج

### 7. قابل للبحث (`searchable`)
يمكن البحث في محتوى هذا الحقل

### 8. قابل للترتيب (`sortable`)
يمكن ترتيب البيانات حسب هذا الحقل

### 9. قابل للتصفية (`filterable`)
يمكن تصفية البيانات حسب هذا الحقل

### 10. فريد (`unique`)
قيمة فريدة لا يمكن تكرارها

### 11. مشفر (`encrypted`)
البيانات مشفرة للحماية

### 12. محفوظ مؤقتاً (`cached`)
البيانات محفوظة مؤقتاً لتحسين الأداء

### 13. مُتحقق (`validated`)
يحتوي على قواعد تحقق مخصصة

### 14. منسق (`formatted`)
يحتوي على تنسيق مخصص للعرض

### 15. شرطي (`conditional`)
يظهر أو يختفي حسب قيم حقول أخرى

### 16. محسوب (`calculated`)
قيمة محسوبة تلقائياً من حقول أخرى

### 17. مفهرس (`indexed`)
مفهرس لتحسين أداء البحث

### 18. متعدد اللغات (`localized`)
يدعم عدة لغات

### 19. متعدد الإصدارات (`versioned`)
يحتفظ بتاريخ التغييرات

### 20. مراقب (`audited`)
يراقب ويسجل جميع التغييرات

### 21. نص غني (`rich`)
محرر نص غني مع أدوات تنسيق متقدمة

### 22. معاينة (`preview`)
يعرض معاينة للمحتوى

### 23. عمليات مجمعة (`bulk`)
يدعم العمليات المجمعة

### 24. قابل للتصدير (`export`)
يمكن تصدير بياناته

### 25. قابل للاستيراد (`import`)
يمكن استيراد بيانات إليه

### 26. متزامن (`sync`)
يتزامن مع أنظمة خارجية

### 27. فوري (`realtime`)
يحدث البيانات في الوقت الفعلي

### 28. يعمل بدون إنترنت (`offline`)
يعمل بدون اتصال بالإنترنت

### 29. نسخ احتياطي (`backup`)
ينشئ نسخ احتياطية تلقائياً

### 30. مضغوط (`compress`)
يضغط البيانات لتوفير المساحة

---

## أمثلة التطبيق

### مثال 1: حقل اسم الكتاب
<div class="code-block">

```dart
FieldConfig(
  name: 'book_title',
  displayName: 'اسم الكتاب',
  type: FieldType.text,
  features: [
    FieldFeature.required,
    FieldFeature.searchable,
    FieldFeature.unique
  ]
)
```

</div>

### مثال 2: حقل التصنيف مع إضافة جديد
<div class="code-block">

```dart
FieldConfig(
  name: 'category',
  displayName: 'التصنيف',
  type: FieldType.dropdown,
  features: [
    FieldFeature.plus,
    FieldFeature.required,
    FieldFeature.filterable
  ],
  options: ['أدب', 'علوم', 'تاريخ', 'فلسفة']
)
```

</div>

### مثال 3: حقل الملاحظات الغنية
<div class="code-block">

```dart
FieldConfig(
  name: 'notes',
  displayName: 'الملاحظات',
  type: FieldType.textarea,
  features: [
    FieldFeature.rich,
    FieldFeature.long,
    FieldFeature.preview,
    FieldFeature.versioned
  ]
)
```

</div>

### مثال 4: حقل التقييم
<div class="code-block">

```dart
FieldConfig(
  name: 'rating',
  displayName: 'التقييم',
  type: FieldType.rating,
  features: [
    FieldFeature.searchable,
    FieldFeature.sortable,
    FieldFeature.filterable
  ]
)
```

</div>

### مثال 5: حقل غلاف الكتاب
<div class="code-block">

```dart
FieldConfig(
  name: 'cover_image',
  displayName: 'غلاف الكتاب',
  type: FieldType.image,
  features: [
    FieldFeature.preview,
    FieldFeature.compress,
    FieldFeature.backup
  ]
)
```

</div>

---

## دمج الميزات

يمكن دمج أي مجموعة من الميزات مع أي نوع حقل لإنشاء حقول مخصصة:

**أمثلة الدمج الشائعة:**
- `text + required + searchable + unique` = حقل نص إجباري فريد قابل للبحث
- `dropdown + plus + filterable + cached` = قائمة منسدلة مع إضافة جديد وتصفية وحفظ مؤقت
- `textarea + rich + preview + versioned` = نص طويل غني مع معاينة وإصدارات
- `number + validated + formatted + calculated` = رقم مُتحقق ومنسق ومحسوب
- `file + encrypted + backup + compress` = ملف مشفر مع نسخ احتياطي ومضغوط

---

## الاستخدام في Google Sheets

لاستخدام هذه الأنواع والميزات في Google Sheets، استخدم الصيغة التالية في الصف الثاني (صف أنواع الحقول):

**صيغة الكتابة:**
<div class="code-block">

```
نوع_الحقل ميزة1 ميزة2 ميزة3
```

</div>

**أمثلة:**
- `text required searchable` = نص مطلوب قابل للبحث
- `dropdown plus filterable` = قائمة منسدلة مع إضافة جديد وتصفية
- `textarea rich long preview` = نص طويل غني مع معاينة
- `number validated formatted` = رقم مُتحقق ومنسق
- `image preview compress backup` = صورة مع معاينة وضغط ونسخ احتياطي

---

## الملاحظات التقنية

- جميع أنواع الحقول متوافقة مع النظام الحالي
- الميزات الجديدة تتطلب تحديثات إضافية في واجهة المستخدم
- بعض الميزات مثل `encrypted` و `sync` تتطلب تطوير خاص
- الميزات `realtime` و `offline` تحتاج إلى بنية تحتية إضافية

---

## خارطة الطريق

### المرحلة 1
- ✅ أنواع الحقول الأساسية
- ✅ الميزات الأساسية
- ✅ التكامل مع Google Sheets

### المرحلة 2
- 🔄 أنواع الحقول المتقدمة
- 🔄 الميزات المتقدمة
- 🔄 واجهة المستخدم المحسنة

### المرحلة 3
- ⏳ الميزات المتقدمة جداً
- ⏳ التكامل مع أنظمة خارجية
- ⏳ الذكاء الاصطناعي

---

## الدعم والمساعدة

لأي استفسارات أو مساعدة في استخدام أنواع الحقول والميزات، يرجى مراجعة:
- الوثائق التقنية
- أمثلة التطبيق
- دليل المطور

---

</div>

<div dir="ltr" lang="en" class="ltr-section">

## English

### Overview
This guide explains all available field types and features in the dynamic forms system. Any field type can be combined with any set of features to create customized and flexible fields.

---

## Field Types

### 1. Text (`text`)
Basic text field for short text input

**Use Cases:**
- Book titles
- Author names
- Short titles

### 2. Dropdown (`dropdown`)
Predefined list of options to choose from

**Use Cases:**
- Categories
- Status
- Language

### 3. Autocomplete (`autocomplete`)
Text field with automatic suggestions while typing

**Use Cases:**
- Author names
- Publishers
- Keywords

### 4. Location Compound (`locationCompound`)
Specialized field for locations consisting of row and column

**Use Cases:**
- Book locations in library
- Storage locations

### 5. Number (`number`)
Field for entering numbers and numeric values

**Use Cases:**
- Page count
- Price
- Quantity

### 6. Date (`date`)
Field for date selection

**Use Cases:**
- Publication date
- Addition date
- Borrowing date

### 7. Time (`time`)
Field for time selection

**Use Cases:**
- Borrowing time
- Return time

### 8. Date Time (`datetime`)
Field for date and time selection

**Use Cases:**
- Last update time
- Reservation time

### 9. Email (`email`)
Specialized field for email addresses with automatic validation

**Use Cases:**
- Author email
- Publisher email

### 10. Phone (`phone`)
Field for phone numbers with automatic formatting

**Use Cases:**
- Author phone
- Publisher phone

### 11. URL (`url`)
Field for web links with automatic validation

**Use Cases:**
- Author website
- E-book link

### 12. Password (`password`)
Secure field for passwords

**Use Cases:**
- Account passwords
- Security codes

### 13. Text Area (`textarea`)
Multi-line text field for long text

**Use Cases:**
- Book summary
- Description
- Notes

### 14. Checkbox (`checkbox`)
Multiple selection checkboxes

**Use Cases:**
- Multiple categories
- Properties
- Features

### 15. Radio (`radio`)
Radio buttons for single selection

**Use Cases:**
- Status
- Priority
- Level

### 16. Slider (`slider`)
Slider for numeric values

**Use Cases:**
- Rating
- Level
- Percentage

### 17. Rating (`rating`)
Stars or symbols for rating

**Use Cases:**
- Book rating
- Difficulty level

### 18. Color (`color`)
Color picker

**Use Cases:**
- Category color
- Highlight color

### 19. File (`file`)
File upload

**Use Cases:**
- PDF files
- Documents

### 20. Image (`image`)
Image upload and display

**Use Cases:**
- Book cover
- Author photo

### 21. Barcode (`barcode`)
Barcode reading and generation

**Use Cases:**
- ISBN number
- Product codes

### 22. QR Code (`qrcode`)
QR code reading and generation

**Use Cases:**
- Quick links
- Book information

---

## Features

### 1. Add New (`plus`)
Adds "Add New" button to dropdown fields

### 2. Markdown (`md`)
Supports text formatting using Markdown

### 3. Long Text (`long`)
Multi-line text for long content

### 4. Required (`required`)
Mandatory field that must be filled

### 5. Read Only (`readonly`)
Read-only field that cannot be edited

### 6. Hidden (`hidden`)
Hidden field that doesn't appear in the form

### 7. Searchable (`searchable`)
Content of this field can be searched

### 8. Sortable (`sortable`)
Data can be sorted by this field

### 9. Filterable (`filterable`)
Data can be filtered by this field

### 10. Unique (`unique`)
Unique value that cannot be duplicated

### 11. Encrypted (`encrypted`)
Data is encrypted for security

### 12. Cached (`cached`)
Data is cached for improved performance

### 13. Validated (`validated`)
Contains custom validation rules

### 14. Formatted (`formatted`)
Contains custom formatting for display

### 15. Conditional (`conditional`)
Shows or hides based on other field values

### 16. Calculated (`calculated`)
Value calculated automatically from other fields

### 17. Indexed (`indexed`)
Indexed for improved search performance

### 18. Localized (`localized`)
Supports multiple languages

### 19. Versioned (`versioned`)
Keeps history of changes

### 20. Audited (`audited`)
Monitors and logs all changes

### 21. Rich Text (`rich`)
Rich text editor with advanced formatting tools

### 22. Preview (`preview`)
Shows preview of content

### 23. Bulk Operations (`bulk`)
Supports bulk operations

### 24. Exportable (`export`)
Data can be exported

### 25. Importable (`import`)
Data can be imported to it

### 26. Sync (`sync`)
Syncs with external systems

### 27. Real-time (`realtime`)
Updates data in real-time

### 28. Offline (`offline`)
Works without internet connection

### 29. Backup (`backup`)
Creates automatic backups

### 30. Compress (`compress`)
Compresses data to save space

---

## Implementation Examples

### Example 1: Book Title Field
```dart
FieldConfig(
  name: 'book_title',
  displayName: 'Book Title',
  type: FieldType.text,
  features: [
    FieldFeature.required,
    FieldFeature.searchable,
    FieldFeature.unique
  ]
)
```

### Example 2: Category Field with Add New
```dart
FieldConfig(
  name: 'category',
  displayName: 'Category',
  type: FieldType.dropdown,
  features: [
    FieldFeature.plus,
    FieldFeature.required,
    FieldFeature.filterable
  ],
  options: ['Literature', 'Science', 'History', 'Philosophy']
)
```

### Example 3: Rich Notes Field
```dart
FieldConfig(
  name: 'notes',
  displayName: 'Notes',
  type: FieldType.textarea,
  features: [
    FieldFeature.rich,
    FieldFeature.long,
    FieldFeature.preview,
    FieldFeature.versioned
  ]
)
```

### Example 4: Rating Field
```dart
FieldConfig(
  name: 'rating',
  displayName: 'Rating',
  type: FieldType.rating,
  features: [
    FieldFeature.searchable,
    FieldFeature.sortable,
    FieldFeature.filterable
  ]
)
```

### Example 5: Book Cover Field
```dart
FieldConfig(
  name: 'cover_image',
  displayName: 'Book Cover',
  type: FieldType.image,
  features: [
    FieldFeature.preview,
    FieldFeature.compress,
    FieldFeature.backup
  ]
)
```

---

## Feature Combinations

Any combination of features can be merged with any field type to create custom fields:

**Common Combination Examples:**
- `text + required + searchable + unique` = Required unique searchable text field
- `dropdown + plus + filterable + cached` = Dropdown with add new, filtering, and caching
- `textarea + rich + preview + versioned` = Rich long text with preview and versioning
- `number + validated + formatted + calculated` = Validated, formatted, calculated number
- `file + encrypted + backup + compress` = Encrypted file with backup and compression

---

## Usage in Google Sheets

To use these types and features in Google Sheets, use the following format in the second row (field types row):

**Writing Format:**
```
field_type feature1 feature2 feature3
```

**Examples:**
- `text required searchable` = Required searchable text
- `dropdown plus filterable` = Dropdown with add new and filtering
- `textarea rich long preview` = Rich long text with preview
- `number validated formatted` = Validated formatted number
- `image preview compress backup` = Image with preview, compression, and backup

---

## Technical Notes

- All field types are compatible with the current system
- New features require additional updates in the user interface
- Some features like `encrypted` and `sync` require special development
- Features like `realtime` and `offline` need additional infrastructure

---

## Roadmap

### Phase 1
- ✅ Basic field types
- ✅ Basic features
- ✅ Google Sheets integration

### Phase 2
- 🔄 Advanced field types
- 🔄 Advanced features
- 🔄 Enhanced user interface

### Phase 3
- ⏳ Very advanced features
- ⏳ External systems integration
- ⏳ Artificial Intelligence

---

## Support and Help

For any questions or help using field types and features, please refer to:
- Technical documentation
- Implementation examples
- Developer guide

---

*آخر تحديث | Last Updated: 2024*

</div>
