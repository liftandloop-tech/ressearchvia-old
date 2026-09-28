import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class FilterDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData? icon;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;
  final double labelFontSize;

  const FilterDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.onTap,
    this.height = 36,
    this.fontSize = 12,
    this.labelFontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueItems = items.toSet().toList();
    final effectiveValue = uniqueItems.contains(value)
        ? value
        : (uniqueItems.isNotEmpty ? uniqueItems.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        onTap != null
            ? Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: height,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.gray300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          icon ?? Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppTheme.gray500,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: effectiveValue != null &&
                      effectiveValue != 'All Staff' &&
                      effectiveValue != 'All Departments' &&
                      effectiveValue != 'All' &&
                      effectiveValue != 'All Time'
                  ? AppTheme.primaryBlue.withOpacity(0.5)
                  : AppTheme.gray300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isExpanded: true,
              isDense: true,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              dropdownColor: Colors.white,
              menuMaxHeight: 320,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              icon: Icon(
                icon ?? Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppTheme.gray500,
              ),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              items: uniqueItems
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: e == effectiveValue
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: e == effectiveValue
                              ? AppTheme.primaryBlue
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: uniqueItems.isEmpty ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
