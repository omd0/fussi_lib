import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';
import '../models/location_data.dart';
import '../services/sheet_structure_service.dart';

enum LocationSelectorMode { popup, inline }

/// Main Location Selector Widget with enhanced dynamic integration
class LocationSelectorWidget extends ConsumerStatefulWidget {
  final String title;
  final String? selectedLocation;
  final Function(String?) onLocationSelected;
  final LocationSelectorMode mode;
  final bool isRequired;
  final String? placeholder;

  const LocationSelectorWidget({
    super.key,
    this.title = 'موقع الكتاب',
    this.selectedLocation,
    required this.onLocationSelected,
    this.mode = LocationSelectorMode.popup,
    this.isRequired = false,
    this.placeholder,
  });

  @override
  ConsumerState<LocationSelectorWidget> createState() =>
      _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState
    extends ConsumerState<LocationSelectorWidget> {
  String? _selectedRow;
  String? _selectedCol;

  @override
  void initState() {
    super.initState();
    _parseSelectedLocation();
  }

  @override
  void didUpdateWidget(LocationSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation) {
      _parseSelectedLocation();
    }
  }

  void _parseSelectedLocation() {
    if (widget.selectedLocation?.isNotEmpty == true) {
      final match =
          RegExp(r'^([A-Z]+)(\d+)$').firstMatch(widget.selectedLocation!);
      if (match != null) {
        _selectedCol = match.group(1);
        _selectedRow = match.group(2);
      }
    } else {
      _selectedRow = null;
      _selectedCol = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationDataAsync = ref.watch(locationDataProvider);

    return locationDataAsync.when(
      loading: () => LocationSelector.buildLoadingState(),
      error: (error, stack) =>
          LocationSelector.buildErrorState(error.toString()),
      data: (locationData) {
        if (locationData == null) {
          return LocationSelector.buildErrorState('لا توجد بيانات موقع متاحة');
        }

        return widget.mode == LocationSelectorMode.popup
            ? _buildPopupButton(locationData)
            : _buildInlineSelector(locationData);
      },
    );
  }

  Widget _buildPopupButton(LocationData locationData) {
    final hasSelection = _selectedRow != null && _selectedCol != null;
    final selectedLocation = hasSelection ? '$_selectedCol$_selectedRow' : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLocationSelectionPopup(locationData),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildLocationIcon(hasSelection),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildLocationText(hasSelection, selectedLocation)),
                Icon(Icons.keyboard_arrow_left,
                    color: AppConstants.hintColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIcon(bool hasSelection) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasSelection
            ? AppConstants.primaryColor.withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.location_on,
        color: hasSelection ? AppConstants.primaryColor : Colors.grey.shade600,
        size: 20,
      ),
    );
  }

  Widget _buildLocationText(bool hasSelection, String? selectedLocation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasSelection
              ? 'الموقع المحدد'
              : widget.placeholder ?? 'اختر موقع الكتاب',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasSelection
                ? AppConstants.primaryColor
                : AppConstants.textColor,
          ),
        ),
        if (hasSelection) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              selectedLocation!,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 2),
          Text(
            'اضغط لفتح خريطة المكتبة',
            style:
                GoogleFonts.cairo(fontSize: 12, color: AppConstants.hintColor),
          ),
        ],
      ],
    );
  }

  Widget _buildInlineSelector(LocationData locationData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on,
                  color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LocationSelector.buildMiniGrid(
              locationData, _selectedRow, _selectedCol, (row, col) {
            setState(() {
              _selectedRow = row;
              _selectedCol = col;
            });
            widget.onLocationSelected('$col$row');
          }),
        ],
      ),
    );
  }

  void _showLocationSelectionPopup(LocationData locationData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? localSelectedRow = _selectedRow;
        String? localSelectedCol = _selectedCol;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return LocationSelectionDialog(
              title: widget.title,
              locationData: locationData,
              selectedRow: localSelectedRow,
              selectedCol: localSelectedCol,
              onLocationSelected: (row, col) {
                setDialogState(() {
                  localSelectedRow = row;
                  localSelectedCol = col;
                });
                setState(() {
                  _selectedRow = row;
                  _selectedCol = col;
                });
              },
              onConfirm: () {
                if (localSelectedRow != null && localSelectedCol != null) {
                  widget
                      .onLocationSelected('$localSelectedCol$localSelectedRow');
                }
                Navigator.of(context).pop();
              },
              onClear: () {
                setDialogState(() {
                  localSelectedRow = null;
                  localSelectedCol = null;
                });
                setState(() {
                  _selectedRow = null;
                  _selectedCol = null;
                });
                widget.onLocationSelected(null);
              },
            );
          },
        );
      },
    );
  }
}

/// Static utilities for Location Selection
class LocationSelector {
  /// Build loading state widget
  static Widget buildLoadingState() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.hintColor.withOpacity(0.3)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// Build error state widget
  static Widget buildErrorState(String error) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        color: Colors.red.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          'خطأ: $error',
          style: GoogleFonts.cairo(color: Colors.red),
        ),
      ),
    );
  }

  /// Build mini grid for preview
  static Widget buildMiniGrid(
    LocationData locationData,
    String? selectedRow,
    String? selectedCol,
    Function(String, String) onLocationSelected,
  ) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: buildLocationGrid(
        locationData,
        selectedRow,
        selectedCol,
        onLocationSelected,
        isCompact: true,
      ),
    );
  }

  /// Build full location grid
  static Widget buildLocationGrid(
    LocationData locationData,
    String? selectedRow,
    String? selectedCol,
    Function(String, String) onLocationSelected, {
    bool isCompact = false,
  }) {
    if (locationData.rows.isEmpty || locationData.columns.isEmpty) {
      return Center(
        child: Text(
          'لا توجد بيانات كافية لعرض الشبكة',
          style: GoogleFonts.cairo(color: AppConstants.hintColor),
        ),
      );
    }

    final layoutInfo =
        _detectLayoutFromData(locationData.rows, locationData.columns);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 16),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: isCompact ? 1 : 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 6 : 14),
        child: Column(
          children: [
            _buildGridHeaders(layoutInfo, isCompact),
            Expanded(
              child: _buildGridContent(
                layoutInfo,
                selectedRow,
                selectedCol,
                onLocationSelected,
                isCompact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildGridHeaders(
      Map<String, dynamic> layoutInfo, bool isCompact) {
    return Container(
      height: isCompact ? 25 : 50,
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Container(
            width: isCompact ? 25 : 50,
            decoration: BoxDecoration(
              color: Colors.orange.shade200,
              border: Border.all(color: Colors.orange.shade300),
            ),
          ),
          ...layoutInfo['topHeaders'].map<Widget>((header) => Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade300)),
                  child: Center(
                    child: Text(
                      header,
                      style: GoogleFonts.cairo(
                        fontSize: isCompact ? 10 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  static Widget _buildGridContent(
    Map<String, dynamic> layoutInfo,
    String? selectedRow,
    String? selectedCol,
    Function(String, String) onLocationSelected,
    bool isCompact,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: layoutInfo['sideHeaders'].map<Widget>((sideHeader) {
          return Container(
            height: isCompact ? 25 : 60,
            child: Row(
              children: [
                _buildRowHeader(sideHeader, isCompact),
                ...layoutInfo['topHeaders'].map<Widget>((topHeader) {
                  return _buildGridCell(
                    layoutInfo,
                    sideHeader,
                    topHeader,
                    selectedRow,
                    selectedCol,
                    onLocationSelected,
                    isCompact,
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildRowHeader(String sideHeader, bool isCompact) {
    return Container(
      width: isCompact ? 25 : 50,
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Center(
        child: Text(
          sideHeader,
          style: GoogleFonts.cairo(
            fontSize: isCompact ? 10 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
      ),
    );
  }

  static Widget _buildGridCell(
    Map<String, dynamic> layoutInfo,
    String sideHeader,
    String topHeader,
    String? selectedRow,
    String? selectedCol,
    Function(String, String) onLocationSelected,
    bool isCompact,
  ) {
    final actualRow = layoutInfo['rowIsTop'] ? topHeader : sideHeader;
    final actualCol = layoutInfo['rowIsTop'] ? sideHeader : topHeader;
    final isSelected = selectedRow == actualRow && selectedCol == actualCol;

    return Expanded(
      child: InkWell(
        onTap: () => onLocationSelected(actualRow, actualCol),
        child: Container(
          height: double.infinity,
          margin: EdgeInsets.all(isCompact ? 1 : 2),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryColor
                : _getShelfColor(actualCol, actualRow),
            borderRadius: BorderRadius.circular(isCompact ? 4 : 8),
            border: Border.all(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.8)
                  : Colors.grey.shade300,
              width: isSelected ? (isCompact ? 1 : 2) : (isCompact ? 0.5 : 1),
            ),
            boxShadow: isSelected && !isCompact
                ? [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book,
                  size: isCompact ? 8 : 20,
                  color: isSelected
                      ? Colors.white
                      : AppConstants.primaryColor.withOpacity(0.6),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$actualCol$actualRow',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppConstants.textColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _detectLayoutFromData(
      List<String> rows, List<String> columns) {
    final rowIsNumber = rows.isNotEmpty && int.tryParse(rows.first) != null;
    final colIsNumber =
        columns.isNotEmpty && int.tryParse(columns.first) != null;

    if (rowIsNumber && !colIsNumber) {
      return {
        'rowIsTop': false,
        'topHeaders': columns,
        'sideHeaders': rows,
      };
    } else if (!rowIsNumber && colIsNumber) {
      return {
        'rowIsTop': true,
        'topHeaders': columns,
        'sideHeaders': rows,
      };
    } else {
      return {
        'rowIsTop': false,
        'topHeaders': columns,
        'sideHeaders': rows,
      };
    }
  }

  static Color _getShelfColor(String col, String row) {
    final hash = (col.hashCode + row.hashCode).abs();
    final colors = [
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.purple.shade50,
      Colors.orange.shade50,
      Colors.teal.shade50,
      Colors.indigo.shade50,
    ];
    return colors[hash % colors.length];
  }
}

/// Location Selection Dialog
class LocationSelectionDialog extends StatelessWidget {
  final String title;
  final LocationData locationData;
  final String? selectedRow;
  final String? selectedCol;
  final Function(String?, String?) onLocationSelected;
  final VoidCallback onConfirm;
  final VoidCallback onClear;

  const LocationSelectionDialog({
    super.key,
    required this.title,
    required this.locationData,
    this.selectedRow,
    this.selectedCol,
    required this.onLocationSelected,
    required this.onConfirm,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              Expanded(
                child: LocationSelector.buildLocationGrid(
                  locationData,
                  selectedRow,
                  selectedCol,
                  onLocationSelected,
                ),
              ),
              const SizedBox(height: 20),
              if (selectedRow != null && selectedCol != null) ...[
                _buildSelectedLocationDisplay(),
                const SizedBox(height: 16),
              ],
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.location_on, color: AppConstants.primaryColor, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'اختر موقع الكتاب في المكتبة',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSelectedLocationDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            'الموقع المحدد: ',
            style:
                GoogleFonts.cairo(fontSize: 16, color: AppConstants.textColor),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$selectedCol$selectedRow',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'مسح التحديد',
              style:
                  GoogleFonts.cairo(fontSize: 16, color: Colors.grey.shade700),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed:
                selectedRow != null && selectedCol != null ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'تأكيد الاختيار',
              style:
                  GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
