import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class CollapsibleSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int? count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const CollapsibleSection({
    super.key,
    required this.title,
    this.subtitle,
    this.count,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 24,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 8),

                Text(
                  count != null ? '$title ($count)' : title,
                  style: AppTheme.h5Style.copyWith(color: AppTheme.primaryBlue),
                ),
                const Spacer(),

                if (subtitle != null)
                  Text(subtitle!, style: AppTheme.bodySmallStyle),
              ],
            ),
          ),
        ),

        if (isExpanded) child,
      ],
    );
  }
}
