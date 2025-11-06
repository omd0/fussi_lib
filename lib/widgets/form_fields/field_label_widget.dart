import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/field_config.dart';

/// Centralized field label widget to eliminate duplicates
class FieldLabelWidget extends StatelessWidget {
  final FieldConfig field;
  final bool isRequired;
  final bool isLocked;
  final bool showIcon;
  final bool showFeatureBadges;
  final int maxFeatureBadges;

  const FieldLabelWidget({
    super.key,
    required this.field,
    this.isRequired = false,
    this.isLocked = false,
    this.showIcon = true,
    this.showFeatureBadges = true,
    this.maxFeatureBadges = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showIcon) ...[
          Icon(
            _getFieldIcon(),
            size: 16,
            color:
                isLocked ? AppConstants.primaryColor : AppConstants.hintColor,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          '${field.displayName}${isRequired ? ' *' : ''}',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                isLocked ? AppConstants.primaryColor : AppConstants.textColor,
          ),
        ),
        if (showFeatureBadges && field.features.isNotEmpty) ...[
          const SizedBox(width: 8),
          ...field.features
              .take(maxFeatureBadges)
              .map((feature) => _buildFeatureBadge(feature)),
        ],
      ],
    );
  }

  IconData _getFieldIcon() {
    switch (field.type) {
      case FieldType.text:
        if (field.hasFeature(FieldFeature.long)) {
          return Icons.description;
        } else if (field.hasFeature(FieldFeature.md)) {
          return Icons.text_format;
        }
        return Icons.text_fields;
      case FieldType.textarea:
        return Icons.description;
      case FieldType.number:
        return Icons.numbers;
      case FieldType.email:
        return Icons.email;
      case FieldType.phone:
        return Icons.phone;
      case FieldType.url:
        return Icons.link;
      case FieldType.password:
        return Icons.lock;
      case FieldType.dropdown:
        return Icons.arrow_drop_down;
      case FieldType.autocomplete:
        return Icons.search;
      case FieldType.locationCompound:
        return Icons.location_on;
      case FieldType.date:
        return Icons.calendar_today;
      case FieldType.time:
        return Icons.access_time;
      case FieldType.datetime:
        return Icons.event;
      case FieldType.checkbox:
        return Icons.check_box;
      case FieldType.radio:
        return Icons.radio_button_checked;
      case FieldType.slider:
        return Icons.tune;
      case FieldType.rating:
        return Icons.star;
      case FieldType.color:
        return Icons.palette;
      case FieldType.file:
        return Icons.upload_file;
      case FieldType.image:
        return Icons.add_photo_alternate;
      case FieldType.barcode:
        return Icons.qr_code_scanner;
      case FieldType.qrcode:
        return Icons.qr_code;
    }
  }

  Widget _buildFeatureBadge(FieldFeature feature) {
    Color badgeColor;
    String badgeText;

    switch (feature) {
      case FieldFeature.required:
        badgeColor = Colors.red;
        badgeText = 'مطلوب';
        break;
      case FieldFeature.plus:
        badgeColor = AppConstants.primaryColor;
        badgeText = 'إضافة جديد';
        break;
      case FieldFeature.md:
        badgeColor = AppConstants.secondaryColor;
        badgeText = 'Markdown';
        break;
      case FieldFeature.long:
        badgeColor = AppConstants.primaryColor;
        badgeText = 'نص طويل';
        break;
      case FieldFeature.readonly:
        badgeColor = Colors.orange;
        badgeText = 'للقراءة فقط';
        break;
      case FieldFeature.searchable:
        badgeColor = Colors.blue;
        badgeText = 'قابل للبحث';
        break;
      case FieldFeature.unique:
        badgeColor = Colors.purple;
        badgeText = 'فريد';
        break;
      case FieldFeature.hidden:
        badgeColor = Colors.grey;
        badgeText = 'مخفي';
        break;
      case FieldFeature.sortable:
        badgeColor = Colors.blue;
        badgeText = 'قابل للترتيب';
        break;
      case FieldFeature.filterable:
        badgeColor = Colors.green;
        badgeText = 'قابل للتصفية';
        break;
      case FieldFeature.encrypted:
        badgeColor = Colors.orange;
        badgeText = 'مشفر';
        break;
      case FieldFeature.cached:
        badgeColor = Colors.teal;
        badgeText = 'مخزن مؤقت';
        break;
      case FieldFeature.indexed:
        badgeColor = Colors.indigo;
        badgeText = 'مفهرس';
        break;
      case FieldFeature.validated:
        badgeColor = Colors.pink;
        badgeText = 'محقق';
        break;
      case FieldFeature.formatted:
        badgeColor = Colors.cyan;
        badgeText = 'منسق';
        break;
      case FieldFeature.conditional:
        badgeColor = Colors.amber;
        badgeText = 'شرطي';
        break;
      case FieldFeature.calculated:
        badgeColor = Colors.deepPurple;
        badgeText = 'محسوب';
        break;
      case FieldFeature.localized:
        badgeColor = Colors.lightBlue;
        badgeText = 'محلي';
        break;
      case FieldFeature.versioned:
        badgeColor = Colors.brown;
        badgeText = 'مُصدر';
        break;
      case FieldFeature.audited:
        badgeColor = Colors.deepOrange;
        badgeText = 'مراجع';
        break;
      case FieldFeature.rich:
        badgeColor = Colors.purpleAccent;
        badgeText = 'غني';
        break;
      case FieldFeature.preview:
        badgeColor = Colors.lightGreen;
        badgeText = 'معاينة';
        break;
      case FieldFeature.bulk:
        badgeColor = Colors.blueGrey;
        badgeText = 'مجمع';
        break;
      case FieldFeature.export:
        badgeColor = Colors.lime;
        badgeText = 'تصدير';
        break;
      case FieldFeature.import:
        badgeColor = Colors.yellow;
        badgeText = 'استيراد';
        break;
      case FieldFeature.sync:
        badgeColor = Colors.tealAccent;
        badgeText = 'مزامنة';
        break;
      case FieldFeature.realtime:
        badgeColor = Colors.redAccent;
        badgeText = 'وقت حقيقي';
        break;
      case FieldFeature.offline:
        badgeColor = Colors.grey;
        badgeText = 'غير متصل';
        break;
      case FieldFeature.backup:
        badgeColor = Colors.greenAccent;
        badgeText = 'نسخ احتياطي';
        break;
      case FieldFeature.row:
        badgeColor = Colors.blue;
        badgeText = 'صف';
        break;
      case FieldFeature.col:
        badgeColor = Colors.green;
        badgeText = 'عمود';
        break;
      case FieldFeature.compress:
        badgeColor = Colors.orangeAccent;
        badgeText = 'مضغوط';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: GoogleFonts.cairo(
          fontSize: 10,
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
