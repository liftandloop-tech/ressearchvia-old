import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class StaffTableHeaderCell extends StatelessWidget {
  final String text;
  final Widget? filterIcon;

  const StaffTableHeaderCell({
    super.key,
    required this.text,
    this.filterIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (filterIcon != null) ...[
            const SizedBox(width: 4),
            filterIcon!,
          ],
        ],
      ),
    );
  }
}
