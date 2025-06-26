/// Represents location data extracted from key sheet
class LocationData {
  final List<String> rows;
  final List<String> columns;
  final List<String> rooms; // Support for room selection

  LocationData({
    required this.rows,
    required this.columns,
    this.rooms = const [],
  });

  bool get isComplete => rows.isNotEmpty && columns.isNotEmpty;

  /// Check if this location system supports rooms
  bool get hasRooms => rooms.isNotEmpty;

  /// Generate all possible location combinations
  List<String> generateCombinations() {
    final combinations = <String>[];
    for (final row in rows) {
      for (final column in columns) {
        combinations.add('$row$column');
      }
    }
    return combinations..sort();
  }

  /// Generate room-aware location combinations
  List<String> generateRoomCombinations() {
    if (!hasRooms) return generateCombinations();

    final combinations = <String>[];
    for (final room in rooms) {
      for (final row in rows) {
        for (final column in columns) {
          combinations.add('$room-$row$column');
        }
      }
    }
    return combinations..sort();
  }

  /// Get combinations for a specific room
  List<String> getCombinationsForRoom(String room) {
    final combinations = <String>[];
    for (final row in rows) {
      for (final column in columns) {
        combinations.add('$room-$row$column');
      }
    }
    return combinations..sort();
  }
}
