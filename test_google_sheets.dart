import 'dart:io';
import 'dart:convert';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

// Configuration
const String spreadsheetId = '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';
const String mainSheetRange = 'الفهرس!A:G'; // Correct Arabic sheet name
const String keySheetRange = 'مفتاح!A:H'; // Key sheet range
const String credentialsPath = 'assets/credentials/service-account-key.json';

Future<void> main() async {
  print('🔍 بدء اختبار Google Sheets المباشر (التحقق من موقع المؤلفين)...\n');

  try {
    // Step 1: Check credentials
    print('📋 الخطوة 1: فحص ملف الاعتماد');
    final credentialsFile = File(credentialsPath);
    if (!await credentialsFile.exists()) {
      print('❌ ملف الاعتماد غير موجود في: $credentialsPath');
      print('   تأكد من وجود الملف في المسار الصحيح');
      return;
    }
    print('✅ ملف الاعتماد موجود');

    // Step 2: Load credentials
    print('\n📋 الخطوة 2: تحميل بيانات الاعتماد');
    final credentialsJson = await credentialsFile.readAsString();
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    print('✅ تم تحميل بيانات الاعتماد');
    print('   البريد الإلكتروني: ${credentials.email}');

    // Step 3: Authenticate
    print('\n📋 الخطوة 3: المصادقة مع Google APIs');
    final scopes = [SheetsApi.spreadsheetsScope];
    final client = await clientViaServiceAccount(credentials, scopes);
    print('✅ تم إنشاء العميل المصادق');

    // Step 4: Create Sheets API instance
    print('\n📋 الخطوة 4: إنشاء واجهة Sheets API');
    final sheetsApi = SheetsApi(client);
    print('✅ تم إنشاء واجهة Sheets API');

    // Step 5: Get spreadsheet info to see available sheets
    print('\n📋 الخطوة 5: الحصول على معلومات الجدول');
    final spreadsheet = await sheetsApi.spreadsheets.get(spreadsheetId);
    print('✅ عنوان الجدول: ${spreadsheet.properties?.title}');
    print('📋 الأوراق المتاحة:');
    for (final sheet in spreadsheet.sheets ?? []) {
      print(
          '   - ${sheet.properties?.title} (ID: ${sheet.properties?.sheetId})');
    }

    // Step 6: Test main data sheet
    await _testMainDataSheet(sheetsApi);

    // Step 7: Test Key sheet (مفتاح) - THIS IS THE IMPORTANT PART
    await _testKeySheet(sheetsApi);

    client.close();
  } catch (e, stackTrace) {
    print('\n❌ خطأ في التحليل: $e');
    print('نوع الخطأ: ${e.runtimeType}');
    print('تفاصيل الخطأ:\n$stackTrace');
  }
}

Future<void> _testMainDataSheet(SheetsApi sheetsApi) async {
  print('\n🏠 اختبار الورقة الرئيسية (البيانات)');

  try {
    // Try different possible sheet names
    final possibleRanges = [
      'الفهرس!A:G',
      'Sheet1!A:G',
      'الورقة1!A:G',
      'A:G' // Default range
    ];

    dynamic response;
    String usedRange = '';

    for (final range in possibleRanges) {
      try {
        print('   محاولة النطاق: $range');
        response =
            await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
        usedRange = range;
        print('   ✅ نجح مع النطاق: $range');
        break;
      } catch (e) {
        print('   ❌ فشل مع النطاق: $range');
        continue;
      }
    }

    if (response?.values == null || response.values!.isEmpty) {
      print('❌ لا توجد بيانات في الورقة الرئيسية');
      return;
    }

    final data = response.values!;
    print('✅ تم جلب ${data.length} صف من البيانات الرئيسية');

    // Analyze main data structure
    if (data.isNotEmpty) {
      final headerRow = data[0];
      print('\n📊 صف العناوين الرئيسي (${headerRow.length} عمود):');
      for (int i = 0; i < headerRow.length; i++) {
        final columnLetter = String.fromCharCode(65 + i);
        print('   العمود $columnLetter: "${headerRow[i]}"');
      }

      // Check for authors in main data (Column E)
      print('\n👥 فحص المؤلفين في البيانات الرئيسية (العمود E):');
      final authors = <String>{};
      for (int i = 1; i < data.length && i <= 10; i++) {
        final row = data[i];
        if (row.length > 4) {
          final author = row[4].toString().trim();
          if (author.isNotEmpty && author != 'لا يوجد' && author != 'N/A') {
            authors.add(author);
            print('   الصف $i: "$author"');
          }
        }
      }
      print('📚 إجمالي المؤلفين المختلفين في العينة: ${authors.length}');
      print('📝 قائمة المؤلفين: ${authors.toList()..sort()}');
    }
  } catch (e) {
    print('❌ خطأ في اختبار الورقة الرئيسية: $e');
  }
}

Future<void> _testKeySheet(SheetsApi sheetsApi) async {
  print('\n🔑 اختبار ورقة المفتاح (Key Sheet) - البحث عن المؤلفين');

  try {
    // Try different possible Key sheet names and ranges
    final possibleRanges = [
      'مفتاح!A:H',
      'Key!A:H',
      'مفتاح!A:Z',
      'Key!A:Z',
      'مفتاح!A1:H20',
      'Key!A1:H20'
    ];

    dynamic response;
    String usedRange = '';

    for (final range in possibleRanges) {
      try {
        print('   محاولة نطاق المفتاح: $range');
        response =
            await sheetsApi.spreadsheets.values.get(spreadsheetId, range);
        usedRange = range;
        print('   ✅ نجح مع نطاق المفتاح: $range');
        break;
      } catch (e) {
        print('   ❌ فشل مع نطاق المفتاح: $range');
        continue;
      }
    }

    if (response?.values == null || response.values!.isEmpty) {
      print('❌ لا توجد بيانات في ورقة المفتاح');
      print('🔍 هذا يؤكد أن المؤلفين ليسوا في ورقة المفتاح!');
      return;
    }

    final keyData = response.values!;
    print('✅ تم جلب ${keyData.length} صف من ورقة المفتاح');

    // Analyze Key sheet structure
    print('\n📊 تحليل هيكل ورقة المفتاح:');

    if (keyData.isNotEmpty) {
      // Show header row if exists
      final headerRow = keyData[0];
      print('📋 الصف الأول (${headerRow.length} عمود):');
      for (int i = 0; i < headerRow.length; i++) {
        final columnLetter = String.fromCharCode(65 + i);
        print('   العمود $columnLetter: "${headerRow[i]}"');
      }
    }

    // Analyze all rows in Key sheet
    print('\n🔍 فحص جميع الصفوف في ورقة المفتاح للبحث عن المؤلفين:');
    bool foundAuthors = false;

    for (int i = 0; i < keyData.length; i++) {
      final row = keyData[i];
      print('\n   الصف ${i + 1} (${row.length} عمود):');

      for (int j = 0; j < row.length; j++) {
        final columnLetter = String.fromCharCode(65 + j);
        final cellValue = row[j].toString().trim();
        print('     $columnLetter: "$cellValue"');

        // Check if this could be author data
        if (cellValue.isNotEmpty &&
            !RegExp(r'^[A-Z]$').hasMatch(cellValue) && // Not just a letter
            !RegExp(r'^\d+$').hasMatch(cellValue) && // Not just a number
            cellValue != 'تصنيفات' &&
            cellValue != 'categories' &&
            cellValue.length > 2) {
          // Check if it looks like an author name
          if (_looksLikeAuthorName(cellValue)) {
            print(
                '     🎯 محتمل أن يكون مؤلف: "$cellValue" في العمود $columnLetter');
            foundAuthors = true;
          }
        }
      }
    }

    if (!foundAuthors) {
      print('\n❌ لم يتم العثور على مؤلفين في ورقة المفتاح');
      print('🔍 هذا يؤكد أن الكود الأصلي كان خاطئاً!');
      print(
          '✅ التصحيح صحيح: المؤلفين يجب أن يأتوا من البيانات الرئيسية (العمود E)');
    } else {
      print('\n✅ تم العثور على بعض المؤلفين في ورقة المفتاح');
      print('📍 يجب التحقق من العمود المناسب');
    }

    // Save Key sheet data for analysis
    final keyDataFile = File('key_sheet_raw_data.json');
    final jsonData = {
      'spreadsheetId': spreadsheetId,
      'range': usedRange,
      'totalRows': keyData.length,
      'data': keyData
          .map((row) => row.map((cell) => cell.toString()).toList())
          .toList(),
    };

    await keyDataFile
        .writeAsString(JsonEncoder.withIndent('  ').convert(jsonData));
    print('\n💾 تم حفظ بيانات ورقة المفتاح في: key_sheet_raw_data.json');
  } catch (e) {
    print('❌ خطأ في اختبار ورقة المفتاح: $e');
    print('🔍 هذا قد يعني أن ورقة المفتاح غير موجودة أو لا تحتوي على مؤلفين');
  }
}

bool _looksLikeAuthorName(String text) {
  // Simple heuristic to detect author names
  if (text.length < 3) return false;

  // Arabic names
  if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
    return !text.contains('تصنيف') &&
        !text.contains('موقع') &&
        !text.contains('كتاب') &&
        text.split(' ').length >= 2; // At least two words
  }

  // English names
  if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(text)) {
    return text.split(' ').length >= 2; // At least two words
  }

  return false;
}

String _safeGet(List<dynamic> row, int index) {
  if (index >= row.length) return '';
  return row[index]?.toString() ?? '';
}
