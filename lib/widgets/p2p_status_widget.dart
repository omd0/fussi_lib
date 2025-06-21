import 'package:flutter/material.dart';
import 'dart:async';
import '../services/hybrid_library_service.dart';

class P2PStatusWidget extends StatefulWidget {
  final HybridLibraryService hybridService;

  const P2PStatusWidget({
    super.key,
    required this.hybridService,
  });

  @override
  State<P2PStatusWidget> createState() => _P2PStatusWidgetState();
}

class _P2PStatusWidgetState extends State<P2PStatusWidget> {
  String _statusMessage = '';
  int _deviceCount = 0;
  Timer? _debounceTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initializeStatusListener();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeStatusListener() {
    widget.hybridService.onStatusChanged = (status) {
      if (_disposed || !mounted) return;

      // Debounce status updates to prevent excessive rebuilds
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 200), () {
        if (_disposed || !mounted) return;
        setState(() {
          _statusMessage = status;
        });
      });
    };

    widget.hybridService.onDevicesUpdated = (devices) {
      if (_disposed || !mounted) return;

      // Only update if device count actually changed
      if (devices.length != _deviceCount) {
        setState(() {
          _deviceCount = devices.length;
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.hybridService.currentMode;

    Color statusColor;
    IconData statusIcon;

    switch (mode) {
      case ConnectionMode.online:
        statusColor = Colors.green;
        statusIcon = Icons.cloud_done;
        break;
      case ConnectionMode.p2p:
        statusColor = Colors.blue;
        statusIcon = Icons.wifi_tethering;
        break;
      case ConnectionMode.offline:
        statusColor = Colors.orange;
        statusIcon = Icons.cloud_off;
        break;
    }

    return GestureDetector(
      onTap: _showStatusDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 16,
            ),
            if (_deviceCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_deviceCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showStatusDialog() {
    final modeDescription = widget.hybridService.modeDescription;
    final devices = widget.hybridService.discoveredDevices;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حالة المزامنة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status
              Row(
                children: [
                  const Text('الحالة: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(modeDescription),
                ],
              ),
              const SizedBox(height: 8),

              // Last status message
              if (_statusMessage.isNotEmpty) ...[
                const Text('آخر حالة: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_statusMessage, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
              ],

              // Device count
              Row(
                children: [
                  const Text('الأجهزة المكتشفة: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$_deviceCount'),
                ],
              ),

              // Device list
              if (devices.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('الأجهزة:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final lastSeen = device['lastSeen'] as DateTime;
                      final timeDiff = DateTime.now().difference(lastSeen);
                      final isOnline = timeDiff.inSeconds < 30;

                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          device['deviceName'] ?? 'جهاز غير معروف',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          device['address'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.sync, size: 16),
                              onPressed: isOnline
                                  ? () => _syncWithDevice(device)
                                  : null,
                              tooltip: 'مزامنة',
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, size: 16),
                              onPressed: isOnline
                                  ? () => _sendDataToDevice(device)
                                  : null,
                              tooltip: 'إرسال',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncWithDevice(Map<String, dynamic> device) async {
    Navigator.of(context).pop(); // Close dialog
    await widget.hybridService.syncWithDevice(device);
    _showMessage('تمت المزامنة مع ${device['deviceName']}');
  }

  Future<void> _sendDataToDevice(Map<String, dynamic> device) async {
    Navigator.of(context).pop(); // Close dialog
    await widget.hybridService.sendDataToDevice(device);
    _showMessage('تم إرسال البيانات إلى ${device['deviceName']}');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
