import 'dart:io';
import 'dart:convert';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';

// Configuration
const String spreadsheetId = '1-TXwGU-Rku_a6Dx4C5rFvNNPWOs3TvD75JY8Y0byGsY';
const String sheetRange = 'الورقة1!A:G';
const String credentialsPath = 'assets/credentials/service-account-key.json';

Future<void> main() async {
  print('🔍 بدء اختبار Google Sheets المباشر...\n');

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

    // Step 5: Test connection and get data
    print('\n📋 الخطوة 5: اختبار الاتصال وجلب البيانات');
    print('   معرف الجدول: $spreadsheetId');
    print('   النطاق: $sheetRange');

    final response = await sheetsApi.spreadsheets.values.get(
      spreadsheetId,
      sheetRange,
    );

    if (response.values == null || response.values!.isEmpty) {
      print('❌ لا توجد بيانات في الجدول');
      client.close();
      return;
    }

    final data = response.values!;
    print('✅ تم جلب ${data.length} صف من البيانات');

    // Step 6: Analyze structure
    print('\n📋 الخطوة 6: تحليل هيكل البيانات');

    // Analyze header row
    if (data.isNotEmpty) {
      final headerRow = data[0];
      print('📊 صف العناوين (${headerRow.length} عمود):');
      for (int i = 0; i < headerRow.length; i++) {
        final columnLetter = String.fromCharCode(65 + i); // A, B, C, etc.
        print('   العمود $columnLetter: "${headerRow[i]}"');
      }

      // Expected structure
      print('\n📋 الهيكل المتوقع:');
      print('   العمود A: الموقع في المكتبة');
      print('   العمود B: [فارغ أو موقع إضافي]');
      print('   العمود C: التصنيف');
      print('   العمود D: اسم الكتاب');
      print('   العمود E: اسم المؤلف');
      print('   العمود F: رقم الجزء');
      print('   العمود G: مختصر تعريفي');

      // Analyze data rows
      print('\n📋 تحليل صفوف البيانات:');
      int validRows = 0;
      int invalidRows = 0;
      int emptyRows = 0;

      for (int i = 1; i < data.length; i++) {
        final row = data[i];

        // Skip completely empty rows
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          emptyRows++;
          continue;
        }

        if (i <= 10) {
          // Show details for first 10 rows
          print('\n   الصف $i (${row.length} عمود):');

          if (row.length >= 7) {
            print('     A: "${_safeGet(row, 0)}" (الموقع)');
            print('     B: "${_safeGet(row, 1)}" (إضافي)');
            print('     C: "${_safeGet(row, 2)}" (التصنيف)');
            print('     D: "${_safeGet(row, 3)}" (اسم الكتاب)');
            print('     E: "${_safeGet(row, 4)}" (اسم المؤلف)');
            print('     F: "${_safeGet(row, 5)}" (رقم الجزء)');
            print('     G: "${_safeGet(row, 6)}" (مختصر تعريفي)');

            // Check if row has essential data
            final bookName = _safeGet(row, 3).trim();
            final authorName = _safeGet(row, 4).trim();

            if (bookName.isNotEmpty && authorName.isNotEmpty) {
              print('     ✅ صف صالح');
              validRows++;
            } else {
              print('     ❌ صف غير صالح (اسم الكتاب أو المؤلف فارغ)');
              invalidRows++;
            }
          } else {
            print('     ❌ عدد الأعمدة غير كافي (${row.length} من 7)');
            for (int j = 0; j < row.length; j++) {
              final columnLetter = String.fromCharCode(65 + j);
              print('       $columnLetter: "${row[j]}"');
            }
            invalidRows++;
          }
        } else {
          // Just count remaining rows
          final bookName = _safeGet(row, 3).trim();
          final authorName = _safeGet(row, 4).trim();

          if (row.length >= 7 && bookName.isNotEmpty && authorName.isNotEmpty) {
            validRows++;
          } else {
            invalidRows++;
          }
        }
      }

      if (data.length > 11) {
        print('\n   ... و ${data.length - 11} صف إضافي تم تحليلها');
      }

      print('\n📊 ملخص البيانات:');
      print('   إجمالي الصفوف: ${data.length}');
      print('   صف العناوين: 1');
      print('   صفوف البيانات: ${data.length - 1}');
      print('   الصفوف الصالحة: $validRows');
      print('   الصفوف غير الصالحة: $invalidRows');
      print('   الصفوف الفارغة: $emptyRows');

      // Step 7: Test Book creation
      print('\n📋 الخطوة 7: اختبار إنشاء كائنات الكتب');
      int successfulBooks = 0;
      int failedBooks = 0;

      for (int i = 1; i < data.length && i <= 5; i++) {
        final row = data[i];

        // Skip empty rows
        if (row.isEmpty ||
            row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }

        try {
          if (row.length >= 7) {
            final book = {
              'libraryLocation': _safeGet(row, 0),
              'category': _safeGet(row, 2),
              'bookName': _safeGet(row, 3),
              'authorName': _safeGet(row, 4),
              'briefDescription': _safeGet(row, 6),
            };

            if (book['bookName']!.trim().isNotEmpty &&
                book['authorName']!.trim().isNotEmpty) {
              print(
                  '   ✅ كتاب ${i}: "${book['bookName']}" - "${book['authorName']}"');
              print('      الموقع: "${book['libraryLocation']}"');
              print('      التصنيف: "${book['category']}"');
              print('      الوصف: "${book['briefDescription']}"');
              successfulBooks++;
            } else {
              print('   ❌ كتاب ${i}: بيانات ناقصة');
              failedBooks++;
            }
          } else {
            print('   ❌ كتاب ${i}: عدد أعمدة غير كافي');
            failedBooks++;
          }
        } catch (e) {
          print('   ❌ كتاب ${i}: خطأ في الإنشاء - $e');
          failedBooks++;
        }
      }

      print('\n📊 نتائج إنشاء الكتب:');
      print('   نجح: $successfulBooks');
      print('   فشل: $failedBooks');

      // Step 8: Generate code fixes
      print('\n📋 الخطوة 8: تحليل المشاكل واقتراح الحلول');

      if (validRows > 0) {
        print('✅ Google Sheets يحتوي على بيانات صالحة');
        print('✅ يمكن قراءة البيانات وإنشاء الكتب');

        if (invalidRows > 0) {
          print('⚠️ يوجد ${invalidRows} صف غير صالح');
          print('   نصائح لتحسين البيانات:');
          print('   - تأكد من ملء اسم الكتاب (العمود D)');
          print('   - تأكد من ملء اسم المؤلف (العمود E)');
          print('   - تأكد من وجود 7 أعمدة في كل صف');
        }

        print('\n🔧 الكود يجب أن يعمل مع هذا الهيكل');
      } else {
        print('❌ لا توجد بيانات صالحة');
        print('   المشاكل المحتملة:');
        print('   - البيانات في أعمدة خاطئة');
        print('   - أسماء الكتب أو المؤلفين فارغة');
        print('   - عدد الأعمدة غير صحيح');
      }
    }

    // Step 9: Export raw data for debugging
    print('\n📋 الخطوة 9: تصدير البيانات الخام للتحليل');
    final rawDataFile = File('google_sheets_raw_data.json');
    final jsonData = {
      'spreadsheetId': spreadsheetId,
      'range': sheetRange,
      'totalRows': data.length,
      'data': data
          .map((row) => row.map((cell) => cell.toString()).toList())
          .toList(),
    };

    await rawDataFile
        .writeAsString(JsonEncoder.withIndent('  ').convert(jsonData));
    print('✅ تم حفظ البيانات الخام في: google_sheets_raw_data.json');

    print('\n🏁 انتهى التحليل بنجاح!');

    client.close();
  } catch (e, stackTrace) {
    print('\n❌ خطأ في التحليل: $e');
    print('نوع الخطأ: ${e.runtimeType}');
    print('تفاصيل الخطأ:\n$stackTrace');
  }
}

String _safeGet(List<dynamic> row, int index) {
  if (index >= row.length) return '';
  return row[index]?.toString() ?? '';
}
