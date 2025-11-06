import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// Physical Bookshelf Widget - Visual representation of actual library layout
class PhysicalBookshelfWidget extends StatefulWidget {
  final String? selectedLocation;
  final Function(String?) onLocationSelected;
  final List<String> rowOptions;
  final List<String> columnOptions;
  final List<String> roomOptions;
  final String title;
  final bool showTitle;
  final bool isEnabled;
  final Map<String, int>? bookCounts; // Number of books per location
  final bool showBookCounts;
  final double shelfHeight;
  final double shelfWidth;

  const PhysicalBookshelfWidget({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
    this.rowOptions = const [],
    this.columnOptions = const [],
    this.roomOptions = const [],
    this.title = 'اختر الموقع من الرف',
    this.showTitle = true,
    this.isEnabled = true,
    this.bookCounts,
    this.showBookCounts = true,
    this.shelfHeight = 120.0,
    this.shelfWidth = 80.0,
  });

  @override
  State<PhysicalBookshelfWidget> createState() =>
      _PhysicalBookshelfWidgetState();
}

class _PhysicalBookshelfWidgetState extends State<PhysicalBookshelfWidget>
    with TickerProviderStateMixin {
  String? _selectedLocation;
  String? _hoveredLocation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.selectedLocation;

    // Animation for selected location pulse
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (_selectedLocation != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PhysicalBookshelfWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation) {
      _selectedLocation = widget.selectedLocation;
      if (_selectedLocation != null) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) _buildTitle(),
        if (widget.showTitle) const SizedBox(height: 16),
        _buildPhysicalShelf(),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 16),
          _buildSelectedLocationInfo(),
        ],
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.auto_stories,
            color: AppConstants.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalShelf() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.brown.shade100,
            Colors.brown.shade50,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.brown.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Library Header
          _buildLibraryHeader(),
          const SizedBox(height: 20),

          // Rooms (if available)
          if (widget.roomOptions.isNotEmpty) ...[
            _buildRoomsSection(),
            const SizedBox(height: 20),
          ],

          // Physical Shelf Layout
          _buildShelfLayout(),
        ],
      ),
    );
  }

  Widget _buildLibraryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.brown.shade600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_library, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            'مكتبة فوسي',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsSection() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: widget.roomOptions.map((room) => _buildRoomChip(room)).toList(),
    );
  }

  Widget _buildRoomChip(String room) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.room, color: Colors.blue.shade700, size: 14),
          const SizedBox(width: 4),
          Text(
            room,
            style: GoogleFonts.cairo(
              color: Colors.blue.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfLayout() {
    // Create a grid representing the physical bookshelf
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown.shade400, width: 1),
      ),
      child: Column(
        children: [
          // Column headers (A, B, C, etc.)
          _buildColumnHeaders(),

          // Shelf rows with books
          ...widget.rowOptions.map((row) => _buildShelfRow(row)),

          // Base of the shelf
          _buildShelfBase(),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.brown.shade300,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Row label space
          SizedBox(width: 50),
          // Column labels
          ...widget.columnOptions.map((column) => Expanded(
                child: Center(
                  child: Text(
                    column,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildShelfRow(String row) {
    return Container(
      height: widget.shelfHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.brown.shade400, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Row label
          Container(
            width: 50,
            height: widget.shelfHeight,
            decoration: BoxDecoration(
              color: Colors.brown.shade400,
              border: Border(
                right: BorderSide(color: Colors.brown.shade500, width: 1),
              ),
            ),
            child: Center(
              child: Text(
                row,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Shelf sections for each column
          ...widget.columnOptions
              .map((column) => _buildShelfSection(row, column)),
        ],
      ),
    );
  }

  Widget _buildShelfSection(String row, String column) {
    final location = '$column$row';
    final isSelected = _selectedLocation == location;
    final isHovered = _hoveredLocation == location;
    final bookCount = widget.bookCounts?[location] ?? 0;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredLocation = location),
        onExit: (_) => setState(() => _hoveredLocation = null),
        child: GestureDetector(
          onTap: widget.isEnabled ? () => _selectLocation(location) : null,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isSelected ? _pulseAnimation.value : 1.0,
                child: Container(
                  height: widget.shelfHeight,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient:
                        _getShelfGradient(isSelected, isHovered, bookCount),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getShelfBorderColor(isSelected, isHovered),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      if (isSelected || isHovered)
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Books visualization
                      _buildBooksVisualization(bookCount),

                      // Location label
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            location,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Book count badge
                      if (widget.showBookCounts && bookCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getBookCountColor(bookCount),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              bookCount.toString(),
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Selection indicator
                      if (isSelected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBooksVisualization(int bookCount) {
    if (bookCount == 0) {
      return Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: Colors.grey.shade400,
          size: 24,
        ),
      );
    }

    // Create visual representation of books
    final booksPerRow = 4;
    final rows = (bookCount / booksPerRow).ceil();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: List.generate(
          rows.clamp(0, 3), // Max 3 rows to fit in shelf
          (rowIndex) => Expanded(
            child: Row(
              children: List.generate(
                (rowIndex == rows - 1)
                    ? bookCount - (rowIndex * booksPerRow)
                    : booksPerRow,
                (bookIndex) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: _getRandomBookColor(
                          rowIndex * booksPerRow + bookIndex),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getRandomBookColor(int index) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
    ];
    return colors[index % colors.length];
  }

  LinearGradient _getShelfGradient(
      bool isSelected, bool isHovered, int bookCount) {
    if (isSelected) {
      return LinearGradient(
        colors: [
          Colors.green.shade200,
          Colors.green.shade100,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (isHovered) {
      return LinearGradient(
        colors: [
          AppConstants.primaryColor.withOpacity(0.3),
          AppConstants.primaryColor.withOpacity(0.1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (bookCount > 0) {
      return LinearGradient(
        colors: [
          Colors.amber.shade100,
          Colors.amber.shade50,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return LinearGradient(
        colors: [
          Colors.grey.shade200,
          Colors.grey.shade100,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  Color _getShelfBorderColor(bool isSelected, bool isHovered) {
    if (isSelected) return Colors.green;
    if (isHovered) return AppConstants.primaryColor;
    return Colors.grey.shade300;
  }

  Color _getBookCountColor(int count) {
    if (count >= 10) return Colors.red;
    if (count >= 5) return Colors.orange;
    return Colors.green;
  }

  Widget _buildShelfBase() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: Colors.brown.shade500,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Text(
          'قاعدة الرف',
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade100,
            Colors.green.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الموقع المحدد',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedLocation!,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (widget.showBookCounts && widget.bookCounts != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${widget.bookCounts![_selectedLocation] ?? 0} كتاب',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _selectLocation(String location) {
    setState(() {
      _selectedLocation = _selectedLocation == location ? null : location;
    });

    if (_selectedLocation != null) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }

    widget.onLocationSelected(_selectedLocation);
  }
}
