# Project Structure Guide | دليل هيكل المشروع

## Overview | نظرة عامة

This document provides a comprehensive overview of the Fussi Library project structure, detailing the organization of files, directories, and their purposes. This guide is essential for developers contributing to the project.

<div dir="rtl">
هذا المستند يقدم نظرة شاملة على هيكل مشروع مكتبة فصي، مع تفصيل تنظيم الملفات والمجلدات والغرض منها. هذا الدليل ضروري للمطورين المساهمين في المشروع.
</div>

---

## 📁 Root Directory Structure | هيكل المجلد الجذر

```
fussi_lib/
├── 📱 android/           # Android platform files
├── 🍎 ios/              # iOS platform files  
├── 🖥️  linux/            # Linux platform files
├── 🍎 macos/            # macOS platform files
├── 🪟 windows/          # Windows platform files
├── 📚 lib/              # Main Dart source code
├── 📖 docs/             # Documentation
├── 🎨 assets/           # Images, fonts, credentials
├── 🧪 test/             # Test files
├── 📦 release/          # Build artifacts and release notes
├── 🔧 scripts/          # Build and deployment scripts
├── 📄 pubspec.yaml      # Project configuration
├── 📄 analysis_options.yaml # Linting rules
└── 📄 README.md         # Project overview
```

---

## 📚 lib/ Directory Structure | هيكل مجلد lib

### 🏗️ Core Architecture | البنية الأساسية

```
lib/
├── 📄 main.dart                    # Application entry point
├── 🔧 constants/
│   └── app_constants.dart          # App-wide constants
├── 📊 models/                      # Data models
├── 🔧 services/                    # Business logic services
├── 📱 screens/                     # UI screens/pages
├── 🧩 widgets/                     # Reusable UI components
├── 🔄 providers/                   # State management
└── 🛠️  utils/                      # Utility functions
```

---

## 📊 Models | النماذج

**Purpose:** Data structure definitions and business entities
**الغرض:** تعريفات هيكل البيانات والكيانات التجارية

```
models/
├── 📖 book.dart              # Book entity with metadata
├── ⚙️  field_config.dart     # Field type definitions (22 types, 30+ features)
├── 📝 form_structure.dart    # Complete form definitions
├── 🔑 key_sheet_data.dart    # Google Sheets key row data
└── 📍 location_data.dart     # Library location management
```

### Key Models Overview:
- **Book**: Core library item with Arabic text support
- **FieldConfig**: Type-safe field system with 22 types and 30+ features
- **FormStructure**: Dynamic form builder with validation
- **KeySheetData**: Google Sheets integration data
- **LocationData**: Physical library organization

---

## 🔧 Services | الخدمات

**Purpose:** Business logic, API integrations, and data processing
**الغرض:** المنطق التجاري وتكامل API ومعالجة البيانات

```
services/
├── 📊 sheet_structure_service.dart     # [RENAMED] Form/browsing structure from Sheets
├── 🔄 library_sync_service.dart       # [RENAMED] Online/offline synchronization  
├── 🔍 sheet_analyzer_service.dart     # [RENAMED] Sheet structure analysis
├── 🌐 p2p_service.dart                # [RENAMED] Peer-to-peer functionality
├── 📡 google_sheets_service.dart      # Google Sheets API integration
├── 💾 local_database_service.dart     # SQLite local storage
├── ⚡ cache_service.dart              # Intelligent caching system
├── 🏗️  structure_loader_service.dart  # Dynamic structure loading
└── 📄 README_STRUCTURE_LOADER.md     # Structure loader documentation
```

### Recent Service Renamings 🔄:
- `enhanced_dynamic_service.dart` → `sheet_structure_service.dart` 
- `hybrid_library_service.dart` → `library_sync_service.dart`
- `dynamic_sheets_service.dart` → `sheet_analyzer_service.dart`
- `enhanced_p2p_service.dart` → `p2p_service.dart`

### Service Responsibilities:
- **SheetStructureService**: Loads and manages form/browsing structure from Google Sheets
- **LibrarySyncService**: Handles online/offline synchronization with smart fallbacks
- **SheetAnalyzerService**: Analyzes sheet structure and creates field mappings
- **P2PService**: Manages peer-to-peer data sharing between devices
- **GoogleSheetsService**: Direct API integration with Google Sheets
- **LocalDatabaseService**: SQLite operations and offline storage
- **CacheService**: Intelligent caching with Riverpod integration

---

## 📱 Screens | الشاشات

**Purpose:** Main application screens and user interfaces
**الغرض:** شاشات التطبيق الرئيسية وواجهات المستخدم

```
screens/
├── 🏠 home_screen.dart              # Main dashboard with statistics
├── ➕ add_book_screen.dart          # Dynamic book addition form
├── ✏️  edit_book_screen.dart        # Book editing interface
├── 📚 library_browser_screen.dart   # Book browsing and search
└── 📊 statistics_screen.dart       # Analytics and insights
```

### Screen Features:
- **HomeScreen**: Dashboard with connection status and quick actions
- **AddBookScreen**: Dynamic form generation from Google Sheets structure
- **EditBookScreen**: Book modification with field locking capabilities
- **LibraryBrowserScreen**: Advanced search, filtering, and browsing
- **StatisticsScreen**: Library analytics with visual charts

---

## 🧩 Widgets | المكونات

**Purpose:** Reusable UI components and specialized widgets
**الغرض:** مكونات واجهة المستخدم القابلة لإعادة الاستخدام والمكونات المتخصصة

```
widgets/
├── 🎯 adaptive_form_widget.dart        # [RENAMED] Dynamic form renderer
├── 🏗️  field_builder_widget.dart       # Individual field builder
├── 📍 location_selector_widget.dart    # Library location picker
├── 💬 smart_location_input.dart        # Intelligent location input
├── 🌐 p2p_status_widget.dart          # P2P connection status
├── 📖 physical_bookshelf_widget.dart   # Physical shelf visualization
├── 🏗️  structure_loader_widget.dart    # Structure loading demos
├── 📝 arabic_form_field.dart          # Arabic text input support
├── 📷 barcode_scanner_widget.dart     # Barcode scanning component
└── 📂 form_fields/                    # Specialized field widgets
    ├── 📝 text_field_widget.dart      # Text input components
    ├── 📋 dropdown_field_widget.dart  # Dropdown and autocomplete
    └── 🎛️  interactive_field_widget.dart # Sliders, ratings, checkboxes
```

### Recent Widget Renamings 🔄:
- `dynamic_form_widget.dart` → `adaptive_form_widget.dart`

### Widget Hierarchy:
- **AdaptiveFormWidget**: Main form renderer supporting 22+ field types
- **FieldBuilderWidget**: Individual field component factory
- **FormFields/**: Specialized components extracted from the main form widget
- **LocationSelector**: Sophisticated location management for library organization
- **P2PStatusWidget**: Real-time connection monitoring

---

## 🔄 Providers | موفري الحالة

**Purpose:** State management using Riverpod
**الغرض:** إدارة الحالة باستخدام Riverpod

```
providers/
└── 🎨 theme_provider.dart           # App theming and dark mode
```

---

## 🛠️ Utils | الأدوات المساعدة

**Purpose:** Utility functions and helper methods
**الغرض:** الوظائف المساعدة والطرق المساعدة

```
utils/
└── 🔤 arabic_text_utils.dart        # Arabic text processing utilities
```

---

## 📖 Documentation Structure | هيكل التوثيق

```
docs/
├── 👨‍💻 dev/                          # Developer documentation
│   ├── 📄 README.md                # Developer guide overview
│   ├── 🏗️  PROJECT_STRUCTURE_GUIDE.md # This document
│   ├── 🔧 ENHANCED_FIELD_SYSTEM_SUMMARY.md # Field system overview
│   ├── 📋 FIELD_TYPES_AND_FEATURES_GUIDE.md # Comprehensive field guide
│   ├── 📊 GOOGLE_SHEETS_STRUCTURE_GUIDE.md # Sheets integration guide
│   └── 🚀 RELEASE_PROCESS_GUIDE.md # Release and deployment guide
├── 👤 user/                         # User documentation
│   ├── 📄 README.md                # User guide overview
│   └── 📥 INSTALLATION_GUIDE.md    # Installation instructions
├── 🌐 Web Documentation Files       # GitHub Pages documentation
│   ├── 📄 index.html              # Documentation website
│   ├── 🎨 styles.css              # Website styling
│   ├── ⚡ script.js               # Interactive features
│   └── 🖼️  icons/                 # Website icons and favicon
└── 📄 README.md                    # Main project README
```

---

## 🎨 Assets Structure | هيكل الأصول

```
assets/
├── 🔐 credentials/                  # API keys and service accounts
├── 🔤 fonts/                       # Custom fonts for Arabic support
└── 🖼️ images/                      # App icons and images
```

---

## 🧪 Test Structure | هيكل الاختبارات

```
test/
└── 🏗️ structure_test.dart          # Structure validation tests
```

---

## 📦 Release Structure | هيكل الإصدارات

```
release/
├── 📱 *.apk, *.aab                 # Android build artifacts
├── 📋 RELEASE_NOTES_*.md           # Version release notes
├── 📥 INSTALLATION_GUIDE.md        # Installation instructions
├── ☑️  PLAY_STORE_CHECKLIST.md     # Publishing checklist
├── 🎯 BETA_TESTING_GUIDE.md        # Beta testing instructions
└── 📤 UPLOAD_READY_*.md            # Release preparation status
```

---

## 🔧 Configuration Files | ملفات التكوين

```
Root Files:
├── 📄 pubspec.yaml              # Dependencies and project config
├── 📄 analysis_options.yaml    # Dart/Flutter linting rules
├── 📄 .gitignore               # Git ignore patterns
├── 📊 TODO.md                  # Project roadmap and tasks
├── 🧹 CLEANUP_SUMMARY.md       # Code cleanup documentation
├── 📈 FIELD_SYSTEM_STATUS.md   # Field system implementation status
└── 📋 IMPLEMENTATION_SUMMARY.md # High-level implementation overview
```

---

## 🚀 Key Features by Module | الميزات الرئيسية حسب الوحدة

### 📊 **Models Layer**
- **22 Field Types**: text, dropdown, autocomplete, number, date, etc.
- **30+ Features**: required, searchable, encrypted, cached, etc.
- **Type Safety**: Enum-based with compile-time checking
- **Arabic Support**: RTL text handling and validation

### 🔧 **Services Layer**
- **Smart Synchronization**: Online/offline with automatic fallbacks
- **Dynamic Structure Loading**: Google Sheets-driven form generation
- ⚡ **Performance Caching**: Intelligent caching with expiration
- **P2P Sharing**: Device-to-device data synchronization

### 📱 **UI Layer**
- **Adaptive Forms**: Dynamic form generation from sheet structure
- **Material Design 3**: Modern UI with Arabic RTL support
- **Advanced Components**: Location selectors, barcode scanning
- **Responsive Design**: Works across different screen sizes

### 🔄 **State Management**
- **Riverpod Integration**: Modern reactive state management  
- **Provider Architecture**: Clean separation of concerns
- **Auto-disposal**: Automatic resource management

---

## 🔄 Recent Major Changes | التغييرات الرئيسية الأخيرة

### File Renamings (2024):
1. **Services Layer Improvements**:
   - More descriptive and purpose-driven names
   - Eliminated vague terms like "enhanced", "dynamic", "hybrid"
   - Better discoverability and maintainability

2. **Widget Organization**:
   - Extracted form field components into specialized widgets
   - Improved modularity and reusability
   - Better separation of concerns

3. **Documentation Updates**:
   - Updated all import statements across the codebase
   - Regenerated code-generated files (cache_service.g.dart)
   - Updated inline documentation and comments

---

## 🎯 Architecture Principles | مبادئ البنية

1. **🔒 Type Safety**: Extensive use of enums and strong typing
2. **🔄 Reactivity**: Riverpod-based reactive state management
3. **🌐 Internationalization**: Arabic-first with English support
4. **📱 Cross-Platform**: Flutter targeting mobile and desktop
5. **🔧 Modularity**: Clean separation between layers
6. **⚡ Performance**: Intelligent caching and lazy loading
7. **🛡️ Robustness**: Graceful error handling and fallbacks

---

## 📈 Future Roadmap | خارطة الطريق المستقبلية

### Planned Improvements:
- [ ] **Advanced Field Features**: Implement remaining 30+ field features
- [ ] **Performance Optimization**: Enhanced caching and background sync
- [ ] **Testing Coverage**: Comprehensive unit and integration tests
- [ ] **Documentation**: Complete API documentation generation
- [ ] **CI/CD Pipeline**: Automated testing and deployment
- [ ] **Web Support**: PWA for browser-based access

---

## 🤝 Contributing Guidelines | إرشادات المساهمة

### Development Workflow:
1. **Follow naming conventions** established in recent refactoring
2. **Update documentation** when adding new features
3. **Write tests** for new functionality
4. **Use Arabic comments** for business logic
5. **Follow Dart/Flutter best practices**

### Code Organization:
- Keep related functionality in appropriate directories
- Use descriptive file and class names
- Maintain clear separation between models, services, and UI
- Document complex business logic in both Arabic and English

---

*This structure guide serves as the foundation for understanding and contributing to the Fussi Library project. For specific implementation details, refer to the individual documentation files in each section.*

*يعتبر هذا الدليل الهيكلي الأساس لفهم والمساهمة في مشروع مكتبة فصي. للحصول على تفاصيل التنفيذ المحددة، راجع ملفات التوثيق الفردية في كل قسم.* 