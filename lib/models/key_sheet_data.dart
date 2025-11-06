/// Represents a row in the Google Sheets key sheet
class KeySheetRow {
  final int rowIndex;
  final Map<String, String> values;

  KeySheetRow({
    required this.rowIndex,
    required this.values,
  });

  /// Get value for a specific column header
  String getValue(String header) => values[header] ?? '';

  /// Check if this row has any non-empty values
  bool get hasData => values.values.any((value) => value.trim().isNotEmpty);

  /// Get all non-empty values
  List<String> get nonEmptyValues =>
      values.values.where((value) => value.trim().isNotEmpty).toList();

  factory KeySheetRow.fromRawData(
      int rowIndex, List<String> headers, List<String> rowData) {
    final values = <String, String>{};

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].trim();
      final value = i < rowData.length ? rowData[i].trim() : '';
      if (header.isNotEmpty) {
        values[header] = value;
      }
    }

    return KeySheetRow(rowIndex: rowIndex, values: values);
  }
}

/// Represents the complete key sheet structure
class KeySheetData {
  final List<String> headers;
  final List<String> fieldTypes;
  final List<KeySheetRow> dataRows;

  KeySheetData({
    required this.headers,
    required this.fieldTypes,
    required this.dataRows,
  });

  /// Get all unique values for a specific column
  Set<String> getColumnValues(String header) {
    final values = <String>{};
    for (final row in dataRows) {
      final value = row.getValue(header);
      if (_isValidValue(value)) {
        values.add(value);
      }
    }
    return values;
  }

  /// Get field type for a specific header
  String getFieldType(String header) {
    final index = headers.indexOf(header);
    if (index >= 0 && index < fieldTypes.length) {
      return fieldTypes[index].trim();
    }
    return '';
  }

  /// Check if a header exists
  bool hasHeader(String header) => headers.contains(header);

  /// Get non-empty headers
  List<String> get nonEmptyHeaders =>
      headers.where((header) => header.trim().isNotEmpty).toList();

  bool _isValidValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed == '-') return false;
    if (trimmed == 'N/A') return false;
    if (trimmed == 'لا يوجد') return false;
    if (trimmed == 'null') return false;
    if (trimmed.toLowerCase() == 'none') return false;
    return true;
  }

  factory KeySheetData.fromRawData(List<List<String>> rawData) {
    if (rawData.length < 2) {
      throw ArgumentError(
          'Key sheet must have at least 2 rows (headers + field types)');
    }

    final headers = rawData[0].map((h) => h.toString().trim()).toList();
    final fieldTypes = rawData.length > 1
        ? rawData[1].map((t) => t.toString().trim()).toList()
        : <String>[];

    final dataRows = <KeySheetRow>[];
    for (int i = 2; i < rawData.length; i++) {
      final rowData = rawData[i].map((cell) => cell.toString()).toList();
      final row = KeySheetRow.fromRawData(i, headers, rowData);
      if (row.hasData) {
        dataRows.add(row);
      }
    }

    return KeySheetData(
      headers: headers,
      fieldTypes: fieldTypes,
      dataRows: dataRows,
    );
  }
}
