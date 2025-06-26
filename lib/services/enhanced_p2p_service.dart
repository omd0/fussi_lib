import 'dart:async';
import 'dart:convert';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'local_database_service.dart';

enum P2PMode { host, client, scanning, disconnected }

class EnhancedP2PService {
  final LocalDatabaseService _localDb = LocalDatabaseService();

  FlutterP2pHost? _host;
  FlutterP2pClient? _client;

  P2PMode _currentMode = P2PMode.disconnected;
  bool _isInitialized = false;

  // State streams
  StreamSubscription<HotspotHostState>? _hostStateSubscription;
  StreamSubscription<HotspotClientState>? _clientStateSubscription;
  StreamSubscription<List<P2pClientInfo>>? _clientListSubscription;
  StreamSubscription<String>? _receivedTextsSubscription;
  StreamSubscription<List<BleDiscoveredDevice>>? _discoverySubscription;

  // Discovered devices and connected clients
  List<BleDiscoveredDevice> _discoveredDevices = [];
  List<P2pClientInfo> _connectedClients = [];

  // Callbacks
  Function(P2PMode)? onModeChanged;
  Function(String)? onStatusChanged;
  Function(List<Map<String, dynamic>>)? onDevicesUpdated;

  // Device info
  String? _deviceName;
  HotspotClientState? _currentClientState;

  // P2P Status
  bool get isInitialized => false; // Disabled
  bool get isConnected => false; // Disabled
  String get statusDescription => 'P2P معطل - يعمل في وضع Google Sheets فقط';

  // P2P Methods - All disabled
  Future<void> initialize() async {
    // P2P disabled - no initialization needed
  }

  Future<void> startDiscovery() async {
    // P2P disabled
  }

  Future<void> stopDiscovery() async {
    // P2P disabled
  }

  Future<void> startAdvertising(String serviceName) async {
    // P2P disabled
  }

  Future<void> stopAdvertising() async {
    // P2P disabled
  }

  Future<bool> connectToPeer(String peerId) async {
    // P2P disabled
    return false;
  }

  Future<void> disconnect() async {
    // P2P disabled
  }

  Future<bool> sendData(String data) async {
    // P2P disabled
    return false;
  }

  Future<List<String>> getAvailablePeers() async {
    // P2P disabled - return empty list
    return [];
  }

  Future<void> stop() async {
    // P2P disabled - nothing to stop
  }

  void dispose() {
    // Nothing to dispose for disabled P2P
  }

  Future<void> _checkAndRequestPermissions() async {
    // P2P disabled - no permissions needed
  }

  // Start as host mode (create WiFi Direct group)
  Future<void> startHostMode() async {
    // P2P disabled
  }

  // Start as client mode (scan for hosts)
  Future<void> _startClientMode() async {
    // P2P disabled
  }

  Future<void> _startScanning() async {
    // P2P disabled
  }

  // Connect to a discovered host
  Future<void> connectToHost(BleDiscoveredDevice device) async {
    // P2P disabled
  }

  // Stop all connections and streams
  Future<void> _stopAllConnections() async {
    // P2P disabled - nothing to stop
  }

  void _setMode(P2PMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      onModeChanged?.call(mode);
    }
  }

  void _handleReceivedText(String text) {
    try {
      // Try to parse as library sync data
      final data = jsonDecode(text);
      if (data['type'] == 'library_sync') {
        _handleLibrarySync(data);
      } else {
        onStatusChanged?.call('رسالة مستلمة: $text');
      }
    } catch (e) {
      // If not JSON, treat as regular message
      onStatusChanged?.call('رسالة مستلمة: $text');
    }
  }

  void _handleLibrarySync(Map<String, dynamic> data) async {
    try {
      if (data['action'] == 'request') {
        // Send our library data
        await _sendLibraryData();
      } else if (data['action'] == 'data' && data['books'] != null) {
        // Receive and process library data
        final books = data['books'] as List;
        // Process books - add to local database if not exists
        // Implementation depends on your duplicate checking logic
        onStatusChanged?.call('تم استلام بيانات المكتبة: ${books.length} كتاب');
      }
    } catch (e) {
      onStatusChanged?.call('خطأ في مزامنة المكتبة: $e');
    }
  }

  void _notifyDevicesUpdated() {
    final allDevices = <Map<String, dynamic>>[];

    // Add discovered devices (for scanning mode)
    for (final device in _discoveredDevices) {
      allDevices.add({
        'id': device.deviceName ?? 'Unknown',
        'name': device.deviceName ?? 'Unknown Device',
        'address': device.deviceName ?? 'Unknown',
        'type': 'host',
        'isConnected': false,
        'device': device,
        'lastSeen': DateTime.now(),
      });
    }

    // Add connected clients (for host mode)
    for (final client in _connectedClients) {
      allDevices.add({
        'id': client.id,
        'name': client.username,
        'address': client.id,
        'type': 'client',
        'isConnected': true,
        'device': client,
        'lastSeen': DateTime.now(),
      });
    }

    onDevicesUpdated?.call(allDevices);
  }

  // Sync library data
  Future<void> syncLibraryData() async {
    if (_currentMode == P2PMode.host && _connectedClients.isNotEmpty) {
      await _host!.broadcastText(jsonEncode({
        'type': 'library_sync',
        'action': 'request',
      }));
    } else if (_currentMode == P2PMode.client &&
        _currentClientState?.isActive == true) {
      await _client!.broadcastText(jsonEncode({
        'type': 'library_sync',
        'action': 'request',
      }));
    }
  }

  Future<void> _sendLibraryData() async {
    try {
      final books = await _localDb.getAllBooks();
      final booksData = books;

      final message = jsonEncode({
        'type': 'library_sync',
        'action': 'data',
        'books': booksData,
      });

      if (_currentMode == P2PMode.host) {
        await _host!.broadcastText(message);
      } else if (_currentMode == P2PMode.client) {
        await _client!.broadcastText(message);
      }
    } catch (e) {
      onStatusChanged?.call('خطأ في إرسال بيانات المكتبة: $e');
    }
  }

  // Request library data from other devices
  Future<void> requestLibraryData() async {
    await syncLibraryData();
  }

  // Getters
  P2PMode get currentMode => _currentMode;

  List<Map<String, dynamic>> get discoveredDevices {
    final allDevices = <Map<String, dynamic>>[];

    // Add discovered devices (for scanning mode)
    for (final device in _discoveredDevices) {
      allDevices.add({
        'id': device.deviceName ?? 'Unknown',
        'name': device.deviceName ?? 'Unknown Device',
        'address': device.deviceName ?? 'Unknown',
        'type': 'host',
        'isConnected': false,
        'device': device,
        'lastSeen': DateTime.now(),
      });
    }

    // Add connected clients (for host mode)
    for (final client in _connectedClients) {
      allDevices.add({
        'id': client.id,
        'name': client.username,
        'address': client.id,
        'type': 'client',
        'isConnected': true,
        'device': client,
        'lastSeen': DateTime.now(),
      });
    }

    return allDevices;
  }

  String? get deviceName => _deviceName;

  bool get isHost => _currentMode == P2PMode.host;
  bool get isClient => _currentMode == P2PMode.client;
  bool get isScanning => _currentMode == P2PMode.scanning;
  bool get isDisconnected => _currentMode == P2PMode.disconnected;
}
