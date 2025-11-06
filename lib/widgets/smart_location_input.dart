import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// Smart location input widget using DATA MODEL approach
/// Handles location selection with rows, columns, and rooms
class SmartLocationInput extends StatefulWidget {
  final String? selectedLocation;
  final Function(String?) onLocationSelected;
  final List<String> rowOptions;
  final List<String> columnOptions;
  final List<String> roomOptions;
  final String title;
  final String placeholder;
  final bool isRequired;
  final bool isEnabled;
  final bool showTitle;
  final LocationInputMode mode;

  const SmartLocationInput({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
    this.rowOptions = const [],
    this.columnOptions = const [],
    this.roomOptions = const [],
    this.title = 'الموقع',
    this.placeholder = 'اختر الموقع',
    this.isRequired = false,
    this.isEnabled = true,
    this.showTitle = true,
    this.mode = LocationInputMode.popup,
  });

  @override
  State<SmartLocationInput> createState() => _SmartLocationInputState();
}

/// Location input modes using data model approach
enum LocationInputMode {
  popup, // Full popup dialog
  inline, // Inline dropdowns
  compact, // Single compact selector
  grid, // Grid layout
}

/// Location data model for smart input
class LocationSelection {
  final String? room;
  final String? row;
  final String? column;

  const LocationSelection({
    this.room,
    this.row,
    this.column,
  });

  /// Generate location string from components
  String get locationString {
    final parts = <String>[];
    if (room != null && room!.isNotEmpty) parts.add(room!);
    if (row != null && row!.isNotEmpty) parts.add(row!);
    if (column != null && column!.isNotEmpty) parts.add(column!);
    return parts.join('-');
  }

  /// Parse location string into components
  static LocationSelection fromString(String? locationStr) {
    if (locationStr == null || locationStr.isEmpty) {
      return const LocationSelection();
    }

    final parts = locationStr.split('-');
    return LocationSelection(
      room: parts.isNotEmpty ? parts[0] : null,
      row: parts.length > 1 ? parts[1] : null,
      column: parts.length > 2 ? parts[2] : null,
    );
  }

  bool get isEmpty => room == null && row == null && column == null;
  bool get isComplete => row != null && column != null;
}

class _SmartLocationInputState extends State<SmartLocationInput> {
  LocationSelection _selection = const LocationSelection();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selection = LocationSelection.fromString(widget.selectedLocation);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) _buildTitle(),
        if (widget.showTitle) const SizedBox(height: 8),
        _buildLocationInput(),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: AppConstants.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.title}${widget.isRequired ? ' *' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
          ),
        ),
        if (_selection.isComplete) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Text(
              'مكتمل',
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationInput() {
    switch (widget.mode) {
      case LocationInputMode.inline:
        return _buildInlineMode();
      case LocationInputMode.compact:
        return _buildCompactMode();
      case LocationInputMode.grid:
        return _buildGridMode();
      case LocationInputMode.popup:
      default:
        return _buildPopupMode();
    }
  }

  Widget _buildPopupMode() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selection.isComplete
              ? Colors.green.withOpacity(0.3)
              : AppConstants.hintColor.withOpacity(0.2),
        ),
        gradient: _selection.isComplete
            ? LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.05),
                  Colors.green.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.isEnabled ? _showLocationDialog : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: _selection.isComplete
                      ? Colors.green
                      : AppConstants.hintColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selection.isEmpty
                            ? widget.placeholder
                            : _getLocationDisplayText(),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: _selection.isEmpty
                              ? AppConstants.hintColor
                              : AppConstants.textColor,
                          fontWeight: _selection.isComplete
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (_selection.isComplete) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getLocationBreakdown(),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppConstants.hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  _selection.isComplete
                      ? Icons.check_circle
                      : Icons.arrow_drop_down,
                  color: _selection.isComplete
                      ? Colors.green
                      : AppConstants.hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineMode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.hintColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (widget.roomOptions.isNotEmpty) ...[
            _buildDropdown(
              'الغرفة',
              _selection.room,
              widget.roomOptions,
              (value) => _updateSelection(room: value),
              Icons.meeting_room,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'الصف',
                  _selection.row,
                  widget.rowOptions,
                  (value) => _updateSelection(row: value),
                  Icons.view_stream,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  'العمود',
                  _selection.column,
                  widget.columnOptions,
                  (value) => _updateSelection(column: value),
                  Icons.view_column,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMode() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.hintColor.withOpacity(0.2),
        ),
      ),
      child: ExpansionTile(
        leading: Icon(Icons.location_on, color: AppConstants.primaryColor),
        title: Text(
          _selection.isEmpty ? widget.placeholder : _getLocationDisplayText(),
          style: GoogleFonts.cairo(
            color: _selection.isEmpty
                ? AppConstants.hintColor
                : AppConstants.textColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildInlineMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.hintColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          if (widget.roomOptions.isNotEmpty) ...[
            Text(
              'اختر الغرفة:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildGridOptions(
              widget.roomOptions,
              _selection.room,
              (value) => _updateSelection(room: value),
              Colors.blue,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'اختر الصف:',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildGridOptions(
            widget.rowOptions,
            _selection.row,
            (value) => _updateSelection(row: value),
            Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'اختر العمود:',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildGridOptions(
            widget.columnOptions,
            _selection.column,
            (value) => _updateSelection(column: value),
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(fontSize: 14),
        prefixIcon: Icon(icon, size: 16, color: AppConstants.hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: AppConstants.hintColor.withOpacity(0.2)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, style: GoogleFonts.cairo(fontSize: 14)),
        );
      }).toList(),
      onChanged: widget.isEnabled ? onChanged : null,
    );
  }

  Widget _buildGridOptions(
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
    Color color,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: widget.isEnabled ? () => onChanged(option) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              option,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppConstants.textColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _updateSelection({String? room, String? row, String? column}) {
    setState(() {
      _selection = LocationSelection(
        room: room ?? _selection.room,
        row: row ?? _selection.row,
        column: column ?? _selection.column,
      );
    });
    widget.onLocationSelected(_selection.locationString);
  }

  String _getLocationDisplayText() {
    if (_selection.isEmpty) return widget.placeholder;
    return _selection.locationString;
  }

  String _getLocationBreakdown() {
    final parts = <String>[];
    if (_selection.room != null) parts.add('غرفة: ${_selection.room}');
    if (_selection.row != null) parts.add('صف: ${_selection.row}');
    if (_selection.column != null) parts.add('عمود: ${_selection.column}');
    return parts.join(' • ');
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => _LocationDialog(
        title: widget.title,
        initialSelection: _selection,
        roomOptions: widget.roomOptions,
        rowOptions: widget.rowOptions,
        columnOptions: widget.columnOptions,
        onLocationSelected: (selection) {
          setState(() => _selection = selection);
          widget.onLocationSelected(selection.locationString);
        },
      ),
    );
  }
}

/// Smart location dialog using data model approach
class _LocationDialog extends StatefulWidget {
  final String title;
  final LocationSelection initialSelection;
  final List<String> roomOptions;
  final List<String> rowOptions;
  final List<String> columnOptions;
  final Function(LocationSelection) onLocationSelected;

  const _LocationDialog({
    required this.title,
    required this.initialSelection,
    required this.roomOptions,
    required this.rowOptions,
    required this.columnOptions,
    required this.onLocationSelected,
  });

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late LocationSelection _selection;
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredRows = [];
  List<String> _filteredColumns = [];

  @override
  void initState() {
    super.initState();
    _selection = widget.initialSelection;
    _filteredRows = widget.rowOptions;
    _filteredColumns = widget.columnOptions;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogHeader(),
              const SizedBox(height: 20),
              if (widget.roomOptions.isNotEmpty) ...[
                _buildRoomSelector(),
                const SizedBox(height: 16),
              ],
              _buildSearchField(),
              const SizedBox(height: 16),
              Expanded(child: _buildLocationGrid()),
              const SizedBox(height: 20),
              _buildDialogActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: AppConstants.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر ${widget.title}',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                ),
              ),
              if (_selection.isComplete) ...[
                const SizedBox(height: 4),
                Text(
                  'الموقع المحدد: ${_selection.locationString}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: AppConstants.hintColor),
        ),
      ],
    );
  }

  Widget _buildRoomSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الغرفة:',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.roomOptions.map((room) {
              final isSelected = _selection.room == room;
              return GestureDetector(
                onTap: () => _updateSelection(room: room),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    room,
                    style: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : AppConstants.textColor,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'ابحث عن الموقع...',
        hintStyle: GoogleFonts.cairo(color: AppConstants.hintColor),
        prefixIcon: Icon(Icons.search, color: AppConstants.hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppConstants.hintColor.withOpacity(0.2)),
        ),
      ),
      style: GoogleFonts.cairo(),
      onChanged: _filterLocations,
    );
  }

  Widget _buildLocationGrid() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_filteredRows.isNotEmpty) ...[
            _buildSectionHeader('الصفوف', Icons.view_stream, Colors.green),
            const SizedBox(height: 8),
            _buildLocationSection(_filteredRows, _selection.row,
                (value) => _updateSelection(row: value), Colors.green),
            const SizedBox(height: 16),
          ],
          if (_filteredColumns.isNotEmpty) ...[
            _buildSectionHeader('الأعمدة', Icons.view_column, Colors.orange),
            const SizedBox(height: 8),
            _buildLocationSection(_filteredColumns, _selection.column,
                (value) => _updateSelection(column: value), Colors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(
    List<String> options,
    String? selectedValue,
    Function(String) onTap,
    Color color,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onTap(option),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                option,
                style: GoogleFonts.cairo(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppConstants.textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _selection.isComplete
                ? () {
                    widget.onLocationSelected(_selection);
                    Navigator.pop(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('تأكيد', style: GoogleFonts.cairo()),
          ),
        ),
      ],
    );
  }

  void _updateSelection({String? room, String? row, String? column}) {
    setState(() {
      _selection = LocationSelection(
        room: room ?? _selection.room,
        row: row ?? _selection.row,
        column: column ?? _selection.column,
      );
    });
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRows = widget.rowOptions;
        _filteredColumns = widget.columnOptions;
      } else {
        _filteredRows = widget.rowOptions
            .where((row) => row.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _filteredColumns = widget.columnOptions
            .where((col) => col.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }
}
