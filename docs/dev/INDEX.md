# Developer Documentation Index | فهرس توثيق المطورين

## 📚 Available Documentation Files | ملفات التوثيق المتاحة

### 🏗️ Architecture & Structure | البنية والهيكل

| File | Description | Size | Language |
|------|-------------|------|----------|
| **[README.md](./README.md)** | Main developer guide overview | 387 lines | Arabic/English |
| **[PROJECT_STRUCTURE_GUIDE.md](./PROJECT_STRUCTURE_GUIDE.md)** | Comprehensive project structure documentation | - | Arabic/English |

### 🔧 Technical Systems | الأنظمة التقنية

| File | Description | Size | Language |
|------|-------------|------|----------|
| **[ENHANCED_FIELD_SYSTEM_SUMMARY.md](./ENHANCED_FIELD_SYSTEM_SUMMARY.md)** | Field system overview (22 types, 30+ features) | 160 lines | Arabic/English |
| **[FIELD_TYPES_AND_FEATURES_GUIDE.md](./FIELD_TYPES_AND_FEATURES_GUIDE.md)** | Comprehensive field types and features guide | 877 lines | Arabic/English |
| **[GOOGLE_SHEETS_STRUCTURE_GUIDE.md](./GOOGLE_SHEETS_STRUCTURE_GUIDE.md)** | Google Sheets integration guide | 165 lines | Arabic/English |

### 🚀 Release & Deployment | الإصدار والنشر

| File | Description | Size | Language |
|------|-------------|------|----------|
| **[RELEASE_PROCESS_GUIDE.md](./RELEASE_PROCESS_GUIDE.md)** | Release and deployment procedures | 434 lines | Arabic/English |

---

## 🗂️ Documentation Categories | فئات التوثيق

### 🎯 **Getting Started** | البدء
Start with **[README.md](./README.md)** for an overview, then read **[PROJECT_STRUCTURE_GUIDE.md](./PROJECT_STRUCTURE_GUIDE.md)** to understand the codebase organization.

### 🔧 **Technical Deep Dive** | التعمق التقني
- **Field System**: Read [ENHANCED_FIELD_SYSTEM_SUMMARY.md](./ENHANCED_FIELD_SYSTEM_SUMMARY.md) first, then [FIELD_TYPES_AND_FEATURES_GUIDE.md](./FIELD_TYPES_AND_FEATURES_GUIDE.md) for details
- **Google Sheets Integration**: See [GOOGLE_SHEETS_STRUCTURE_GUIDE.md](./GOOGLE_SHEETS_STRUCTURE_GUIDE.md)

### 🚀 **Deployment** | النشر
Follow the **[RELEASE_PROCESS_GUIDE.md](./RELEASE_PROCESS_GUIDE.md)** for building and releasing the application.

---

## 📋 Quick Reference | مرجع سريع

### Recent Changes | التغييرات الأخيرة
- ✅ **File Renamings**: Services have been renamed for better clarity
- ✅ **Structure Documentation**: Added comprehensive project structure guide
- ✅ **Updated Dependencies**: Code generation files regenerated

### Key Services | الخدمات الرئيسية
```
Services (Renamed):
├── sheet_structure_service.dart    # [was: enhanced_dynamic_service.dart] 
├── library_sync_service.dart       # [was: hybrid_library_service.dart]
├── sheet_analyzer_service.dart     # [was: dynamic_sheets_service.dart]
└── p2p_service.dart                # [was: enhanced_p2p_service.dart]
```

### Field System | نظام الحقول
- **22 Field Types**: From basic text to advanced barcode/QR
- **30+ Features**: Plus buttons, markdown, validation, encryption, etc.
- **Type-Safe**: Enum-based with compile-time checking

---

## 🤝 Contributing | المساهمة

1. **Read the structure guide** to understand the codebase
2. **Follow naming conventions** established in recent refactoring
3. **Update documentation** when adding features
4. **Test thoroughly** and run `flutter analyze`

---

## 📞 Support | الدعم

For questions about the documentation or codebase structure:
- Review the relevant documentation file above
- Check the [main project README](../../README.md)
- Ensure you have the latest code with updated file names

---

*Last Updated: 2024 - Following major code cleanup and file renamings*
*آخر تحديث: 2024 - بعد تنظيف الكود الرئيسي وإعادة تسمية الملفات* 