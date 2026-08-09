import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';

class SegmentPageButton extends StatelessWidget {
  final int page;
  final bool isActive;
  final SubscriptionController controller;

  const SegmentPageButton({
    super.key,
    required this.page,
    required this.isActive,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.setSegmentsPage(page),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryBlue
              : AppTheme.white.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              color: isActive ? AppTheme.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
