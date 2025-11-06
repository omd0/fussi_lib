import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
import '../../models/field_config.dart';
import '../../form/validators/form_validators.dart';
import '../../utils/arabic_text_utils.dart';
import '../../widgets/form_fields/field_label_widget.dart';

/// Autocomplete field widget extracted from adaptive_form_widget.
class AutocompleteFieldWidget extends StatefulWidget {
  final FieldConfig field;
  final TextEditingController controller;
  final Future<List<String>> Function(FieldConfig) getAutocompleteOptions;
  final Function(FieldConfig, String) onFieldChanged;
  final bool Function(String) isRequiredField;

  const AutocompleteFieldWidget({
    super.key,
    required this.field,
    required this.controller,
    required this.getAutocompleteOptions,
    required this.onFieldChanged,
    required this.isRequiredField,
  });

  @override
  State<AutocompleteFieldWidget> createState() => _AutocompleteFieldWidgetState();
}

class _AutocompleteFieldWidgetState extends State<AutocompleteFieldWidget> {
  @override
  Widget build(BuildContext context) {
    final isDynamicField = widget.field.isDynamic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabelWidget(
          field: widget.field,
          isRequired: widget.isRequiredField(widget.field.name),
          isLocked: false,
          showIcon: true,
          showFeatureBadges: true,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDynamicField
                  ? AppConstants.primaryColor.withOpacity(0.4)
                  : AppConstants.hintColor.withOpacity(0.3),
            ),
          ),
          child: FutureBuilder<List<String>>(
            future: widget.getAutocompleteOptions(widget.field),
            builder: (context, snapshot) {
              final options = snapshot.data ?? widget.field.options;
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              // Show loading indicator when data is loading
              if (isLoading && options.isEmpty) {
                return Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'جاري تحميل الخيارات...',
                        style: GoogleFonts.cairo(
                          color: AppConstants.hintColor,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return options.take(5);
                  }

                  // Enhanced Arabic text matching with fuzzy search
                  return options.where((String option) {
                    return ArabicTextUtils.arabicFuzzyMatch(
                        option, textEditingValue.text);
                  });
                },
                onSelected: (String selection) {
                  widget.controller.text = selection;
                  widget.onFieldChanged(widget.field, selection);
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController fieldController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted) {
                  // Only set initial value if not already set to avoid cursor issues
                  if (fieldController.text != widget.controller.text) {
                    fieldController.text = widget.controller.text;
                  }

                  fieldController.addListener(() {
                    widget.controller.text = fieldController.text;
                    widget.onFieldChanged(widget.field, fieldController.text);
                  });

                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: 'اكتب أو اختر ${widget.field.displayName}',
                      hintStyle: GoogleFonts.cairo(
                        color: AppConstants.hintColor,
                      ),
                      suffixIcon: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.arrow_drop_down,
                              color: AppConstants.hintColor,
                            ),
                    ),
                    style: GoogleFonts.cairo(),
                    validator: widget.isRequiredField(widget.field.name)
                        ? (value) => value == null || value.isEmpty
                            ? 'يرجى إدخال ${widget.field.displayName}'
                            : null
                        : null,
                  );
                },
                optionsViewBuilder: (BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          maxWidth: MediaQuery.of(context).size.width - 40,
                        ),
                        child: options.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'لا توجد خيارات متاحة',
                                  style: GoogleFonts.cairo(
                                    color: AppConstants.hintColor,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(
                                      option,
                                      style: GoogleFonts.cairo(),
                                    ),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

