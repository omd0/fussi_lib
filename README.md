# 📚 مكتبة فصي | Fussi Library

<div dir="rtl" lang="ar">

تطبيق Flutter لإدارة مجموعة مكتبة بيت الفصي مع دعم كامل للعربية وتكامل Google Sheets.

</div>

A Flutter application for managing the Beit Al-Fussi Library collection with full Arabic support, dynamic forms, and Google Sheets integration.

## ✨ الميزات | Features

<div dir="rtl" lang="ar">

- 🌍 **تصميم عربي أولاً**: دعم كامل للكتابة من اليمين إلى اليسار
- 📝 **نماذج ديناميكية**: إدخال ذكي للكتب مع حقول قابلة للتخصيص
- 📊 **تكامل Google Sheets**: مزامنة مباشرة مع جدول المكتبة
- 🎨 **واجهة حديثة**: تصميم Material نظيف مع خط Cairo
- 📱 **تخطيط متجاوب**: يعمل على جميع أحجام الشاشات
- 🔄 **مشاركة P2P**: مشاركة البيانات بين الأجهزة
- 🔍 **بحث متقدم**: البحث والتصفية المتقدمة

</div>

- 🌍 **Arabic-First Design**: Full RTL (Right-to-Left) support
- 📝 **Dynamic Forms**: Smart book entry with customizable fields
- 📊 **Google Sheets Integration**: Direct sync with library spreadsheet
- 🎨 **Modern UI**: Clean Material Design with Cairo font
- 📱 **Responsive Layout**: Works on all screen sizes
- 🔄 **P2P Sharing**: Device-to-device data sharing
- 🔍 **Advanced Search**: Advanced search and filtering capabilities

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (3.1.0 or higher)
- Google Cloud Console access
- Git

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd fussi_lib
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup Google Sheets credentials**
   - Follow the guide in `assets/credentials/README.md`
   - Add your `service-account-key.json` file to `assets/credentials/`

4. **Generate code (Required for first run)**
```bash
dart run build_runner build --delete-conflicting-outputs
```

5. **Run the app**
```bash
flutter run
```

## 📱 Screenshots

### Home Screen
- Welcome card with library branding
- Quick action buttons for main functions
- Clean, Arabic-centered design

### Add Book Form
- All form fields in Arabic
- Dropdown for book categories
- Real-time validation
- Loading states and feedback

## 🛠 Technical Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Riverpod 3 with code generation
- **Fonts**: Google Fonts (Cairo)
- **API**: Google Sheets API v4
- **Authentication**: Service Account
- **Architecture**: Clean, modular structure
- **Code Generation**: Riverpod Generator + Build Runner

## 📁 Project Structure

```
fussi_lib/
├── lib/
│   ├── constants/          # App-wide constants
│   ├── models/            # Data models
│   ├── screens/           # UI screens
│   ├── services/          # API services
│   ├── widgets/           # Reusable widgets
│   └── main.dart          # App entry point
├── assets/
│   ├── credentials/       # Google Sheets credentials
│   └── fonts/            # Custom fonts (if needed)
└── pubspec.yaml          # Dependencies
```

## 🔧 Configuration

### Google Sheets Setup
The app connects to this Google Sheet:
`https://docs.google.com/spreadsheets/d/1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY/edit`

### Sheet Structure
| Column | Arabic Header | Purpose |
|--------|---------------|---------|
| A | الموقع في المكتبة | Library Location |
| B | التصنيف | Category |
| C | اسم الكتاب | Book Name |
| D | اسم المؤلف | Author Name |
| E | مختصر تعريفي | Brief Description |

## 🔧 Development

### Code Generation

This project uses **Riverpod Generator** for automatic code generation. The following files require code generation:

- `lib/services/cache_service.dart` → `lib/services/cache_service.g.dart`
- Other service files with `@riverpod` annotations

#### Running Code Generation

**First time setup:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Watch mode (for development):**
```bash
dart run build_runner watch
```

**Clean and rebuild:**
```bash
dart run build_runner clean
dart run build_runner build
```

#### When to Run Code Generation

- After cloning the repository
- After adding new `@riverpod` providers
- After modifying existing `@riverpod` providers
- When you see build errors related to missing `.g.dart` files

#### Troubleshooting Code Generation

If you encounter build errors like:
```
Error: Can't use 'lib/services/cache_service.g.dart' as a part, because it has no 'part of' declaration.
```

Run the code generation command:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Dependencies

The project uses these key development dependencies:
- `build_runner`: ^2.4.7 - Code generation runner
- `riverpod_generator`: ^2.4.2 - Riverpod code generation
- `riverpod_lint`: ^2.3.12 - Linting rules for Riverpod

## 🎨 Design System

### Colors
- **Primary**: #1E3A8A (Deep Blue)
- **Secondary**: #10B981 (Emerald Green)
- **Accent**: #3B82F6 (Blue)
- **Background**: #F8FAFC (Light Gray)

### Typography
- **Font Family**: Cairo (Google Fonts)
- **RTL Support**: Full right-to-left layout
- **Responsive**: Adapts to different screen sizes

## 🔒 Security

- Service account credentials are used for API access
- Credentials file is git-ignored for security
- No user data is stored locally

## 📖 الوثائق | Documentation

<div dir="rtl" lang="ar">

### للمطورين
- **[دليل المطور](docs/dev/README.md)**: دليل شامل للتطوير والصيانة
- **[أنواع الحقول والميزات](docs/dev/FIELD_TYPES_AND_FEATURES_GUIDE.md)**: دليل كامل لأنواع الحقول
- **[بنية Google Sheets](docs/dev/GOOGLE_SHEETS_STRUCTURE_GUIDE.md)**: دليل تكامل Google Sheets
- **[ملخص النظام المحسن](docs/dev/ENHANCED_FIELD_SYSTEM_SUMMARY.md)**: ملخص تطبيق النظام

### للمستخدمين
- **[دليل المستخدم](docs/user/README.md)**: دليل شامل للاستخدام
- **[دليل التثبيت](docs/user/INSTALLATION_GUIDE.md)**: خطوات التثبيت والإعداد

</div>

### For Developers
- **[Developer Guide](docs/dev/README.md)**: Comprehensive development and maintenance guide
- **[Field Types & Features](docs/dev/FIELD_TYPES_AND_FEATURES_GUIDE.md)**: Complete field types guide
- **[Google Sheets Structure](docs/dev/GOOGLE_SHEETS_STRUCTURE_GUIDE.md)**: Google Sheets integration guide
- **[Enhanced System Summary](docs/dev/ENHANCED_FIELD_SYSTEM_SUMMARY.md)**: System implementation summary

### For Users
- **[User Guide](docs/user/README.md)**: Comprehensive usage guide
- **[Installation Guide](docs/user/INSTALLATION_GUIDE.md)**: Installation and setup steps

## 🌟 Coming Soon

- 📊 **Analytics Dashboard**: Library statistics and insights
- 🌙 **Dark Mode**: Theme switching support
- 💾 **Enhanced Offline Mode**: Improved local storage capabilities

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter any issues:
1. Check the `assets/credentials/README.md` for setup instructions
2. Ensure your Google Sheets API is properly configured
3. Verify the spreadsheet permissions
4. Create an issue in this repository

---

**Built with ❤️ for Beit Al-Fussi Library**

*Smart but Simple - ذكي لكن بسيط* 