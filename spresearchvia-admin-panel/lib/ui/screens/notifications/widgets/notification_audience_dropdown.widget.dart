import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class NotificationAudienceDropdown extends StatelessWidget {
  final String value;
  final Function(String?) onChanged;

  const NotificationAudienceDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
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
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
          items:
              const [
                    'All Users',
                    'Active Users',
                    'Expired Users',
                    'Premium Users',
                  ]
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
