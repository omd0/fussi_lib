# 📚 مكتبة بيت الفصي الرقمية - Fussi Library App

A Flutter application for managing the Beit Al-Fussi Library collection with full Arabic support and Google Sheets integration.

## ✨ Features

- 🌍 **Arabic-First Design**: Full RTL (Right-to-Left) support
- 📝 **Smart Form Input**: Intuitive book entry with validation
- 📊 **Google Sheets Integration**: Direct sync with library spreadsheet
- 🎨 **Modern UI**: Clean Material Design with Cairo font
- 📱 **Responsive Layout**: Works on all screen sizes

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

4. **Run the app**
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
- **Fonts**: Google Fonts (Cairo)
- **API**: Google Sheets API v4
- **Authentication**: Service Account
- **Architecture**: Clean, modular structure

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

## 🌟 Coming Soon

- 📖 **Library Browser**: View all books in the collection
- 🔍 **Advanced Search**: Find books by multiple criteria
- 📊 **Analytics Dashboard**: Library statistics and insights
- 🌙 **Dark Mode**: Theme switching support
- 💾 **Offline Mode**: SQLite local storage with sync

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