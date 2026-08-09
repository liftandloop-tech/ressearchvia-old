import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ReportsTableHeaderCell extends StatelessWidget {
  final String title;

  const ReportsTableHeaderCell({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10, // Slightly smaller font to fit narrow columns
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.unfold_more_rounded, size: 12, color: AppTheme.gray400),
        ],
      ),
    );
  }
}
