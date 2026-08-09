import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'package:spresearch_web/ui/screens/subscription/widgets/segments_table.widget.dart';
import 'package:spresearch_web/ui/screens/subscription/widgets/segments_pagination.widget.dart';

class ExistingSegments extends StatelessWidget {
  final SubscriptionController controller;

  const ExistingSegments({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border.all(color: AppTheme.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.existingSegments,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.quickReferenceSegments,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          SegmentsTable(controller: controller),
          const SizedBox(height: 16),
          SegmentsPagination(controller: controller),
        ],
      ),
    );
  }
}
