import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PlanDropdown extends StatelessWidget {
  final String? label;
  final String value;
  final List<String> items;
  final Function(String) onChanged;
  final bool required;

  const PlanDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );

    if (label == null) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryBlue,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(fontSize: 13, color: AppTheme.errorRed),
              ),
          ],
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
