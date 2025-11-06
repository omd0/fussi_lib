import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const BarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final _textController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _simulateBarcodeScan() async {
    setState(() {
      _isScanning = true;
    });

    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate scanned barcode
    const mockBarcode = "9781234567890";
    _textController.text = mockBarcode;
    widget.onBarcodeScanned(mockBarcode);

    setState(() {
      _isScanning = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'تم مسح الكود: $mockBarcode',
              style: GoogleFonts.cairo(),
            ),
          ),
          backgroundColor: AppConstants.secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              const Spacer(),
              Text(
                'ماسح الكود الشريطي',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacing8),
              const Icon(
                Icons.qr_code_scanner,
                color: AppConstants.primaryColor,
                size: 24,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacing16),

          // Barcode input field
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _textController,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppConstants.textColor,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل أو امسح الكود الشريطي...',
                hintStyle: GoogleFonts.cairo(
                  color: AppConstants.hintColor,
                ),
                prefixIcon: const Icon(
                  Icons.qr_code,
                  color: AppConstants.primaryColor,
                ),
                suffixIcon: _isScanning
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: AppConstants.primaryColor,
                        ),
                        onPressed: _simulateBarcodeScan,
                        tooltip: 'مسح الكود',
                      ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  widget.onBarcodeScanned(value);
                }
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  widget.onBarcodeScanned(value);
                }
              },
            ),
          ),

          const SizedBox(height: AppConstants.spacing12),

          // Scan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _simulateBarcodeScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.qr_code_scanner, size: 20),
              label: Text(
                _isScanning ? 'جاري المسح...' : 'مسح الكود الشريطي',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.spacing8),

          // Info text
          Text(
            'يمكنك مسح الكود الشريطي أو إدخاله يدوياً لتعبئة معلومات الكتاب تلقائياً',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppConstants.hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
