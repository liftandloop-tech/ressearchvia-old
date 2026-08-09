import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ActivityLogDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String) onChanged;

  const ActivityLogDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing12,
            vertical: AppTheme.spacing12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            borderSide: BorderSide(color: AppTheme.gray200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            borderSide: BorderSide(color: AppTheme.gray200),
          ),
          isDense: true,
        ),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: AppTheme.bodySmallStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (val) => val != null ? onChanged(val) : null,
      ),
    );
  }
}
