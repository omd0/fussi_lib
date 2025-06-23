# Google Sheets Structure Guide - Complete Analysis

## 📊 Spreadsheet Information
- **Title**: الفهرسة الرقمية لمكتبة بيت الفصي
- **Spreadsheet ID**: `1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY`
- **Available Sheets**: 
  - الفهرس (ID: 0) - Main data sheet
  - مفتاح (ID: 1936331824) - Key/Reference sheet

## 📚 Main Data Sheet Structure: "الفهرس"

### Range: `الفهرس!A:G`
### Columns (7 total):

| Column | Letter | Header | Description |
|--------|--------|--------|-------------|
| 1 | A | الموقع في المكتبة | Library Location | Row
| 2 | B | الموقع في المكتبة | Library Location | Column
| 3 | C | التصنيف | Category |
| 4 | D | اسم الكتاب | Book Name |
| 5 | E | اسم المؤلف | Author Name |
| 6 | F | رقم الجزء (إن توفر) | Volume Number (if available) |
| 7 | G | مختصر تعريفي | Brief Description |

### Sample Data Analysis:
- **Total Rows**: 14 (including header)
- **Authors Found**: 4 unique authors in the sample
  - إبراهيم عباس
  - ياسر بهجت  
  - مهن الهناني
  - أحمد مراد

## 🔑 Key Sheet Structure: "مفتاح"

### Range: `مفتاح!A:H`
### Purpose: Reference/mapping sheet for categories and authors

**Key Sheet Logic:**
- **Column A (الصف)**: Defines row identifiers (A, B, C, D, E, etc.)
- **Column B (العامود)**: Defines column numbers (1, 2, 3, 4, 5, etc.)  
- **Column D (تصنيفات)**: Maps categories to each row identifier
- **Column F (المؤلفين)**: Maps authors to each row identifier

This creates a coordinate system where each row identifier (A, B, C...) corresponds to both a category and an author.
### Columns (6 used):

| Column | Letter | Header | Purpose |
|--------|--------|--------|---------|
| 1 | A | الصف | Row identifier (A, B, C, D, E) |
| 2 | B | العامود | Column number (1, 2, 3, 4, 5, 6, 7, 8) |
| 3 | C | (empty) | Empty column |
| 4 | D | تصنيفات | Categories |
| 5 | E | (empty) | Empty column |
| 6 | F | المؤلفين | Authors |

### Key Sheet Data Mapping:

| Row | Column | Category | Author |
|-----|--------|----------|--------|
| A | 1 | علوم | إبراهيم عباس |
| B | 2 | إسلاميات | ياسر بهجت |
| C | 3 | إنسانيات | مهن الهناني |
| D | 4 | لغة وأدب | أحمد مراد |
| E | 5 | أعمال وإدارة | تزكية النفس والدعاء |
| - | 6 | فنون | - |
| - | 7 | ثقافة عامة | - |
| - | 8 | روايات | - |

## 🎯 Key Insights

### Author Data Location:
1. **Primary Source**: Main data sheet ("الفهرس") Column E
2. **Secondary Reference**: Key sheet ("مفتاح") Column F
3. **Important**: Authors are stored in both sheets, but main data is the authoritative source

### Categories:
- Categories are defined in the key sheet Column D
- 8 total categories identified:
  - علوم (Sciences)
  - إسلاميات (Islamic Studies)
  - إنسانيات (Humanities)
  - لغة وأدب (Language & Literature)
  - أعمال وإدارة (Business & Management)
  - فنون (Arts)
  - ثقافة عامة (General Culture)
  - روايات (Novels)

### Data Inconsistencies Found:
- Row 6 in key sheet has "تزكية النفس والدعاء" as author, which seems to be a category/topic
- Some rows in key sheet don't have corresponding authors

## 📝 Implementation Notes

### For Dynamic Sheets Service:
1. **Main Data**: Use range `الفهرس!A:G`
2. **Authors**: Extract from Column E of main data
3. **Categories**: Can be loaded from key sheet Column D or derived from main data Column C
4. **Key Sheet**: Use range `مفتاح!A:H` for reference data

### Current Code Status:
- ✅ Main data sheet access working correctly
- ✅ Author extraction from Column E confirmed
- ⚠️ Key sheet data needs cleaning (some inconsistencies)
- ✅ Category mapping available from key sheet

### Recommended Data Access Strategy:
1. Load main data from `الفهرس!A:G`
2. Extract authors from Column E of main data (authoritative source)
3. Load categories from key sheet `مفتاح!A:H` Column D
4. Use key sheet for additional reference but validate data consistency

## 🔧 Code Configuration

```dart
// Correct sheet names and ranges
const String mainSheetRange = 'الفهرس!A:G';
const String keySheetRange = 'مفتاح!A:H';

// Column mappings for main data
const int LOCATION_COLUMN = 0;      // A
const int EMPTY_COLUMN = 1;         // B
const int CATEGORY_COLUMN = 2;      // C
const int BOOK_NAME_COLUMN = 3;     // D
const int AUTHOR_COLUMN = 4;        // E
const int VOLUME_COLUMN = 5;        // F
const int DESCRIPTION_COLUMN = 6;   // G
```

---
*Analysis generated from test_google_sheets.dart on ${DateTime.now().toString()}* 