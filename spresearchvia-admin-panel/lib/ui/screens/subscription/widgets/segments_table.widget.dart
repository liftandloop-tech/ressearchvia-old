import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'package:spresearch_web/controllers/subscription/subscription_navigation.controller.dart';
import 'package:spresearch_web/ui/screens/subscription/widgets/segment_header.widget.dart';
import 'package:spresearch_web/ui/screens/subscription/widgets/segment_row.widget.dart';
import 'package:spresearch_web/models/segment.model.dart';

class SegmentsTable extends StatelessWidget {
  final SubscriptionController controller;

  const SegmentsTable({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingSegments.value) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
          ),
        );
      }

      if (controller.segments.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No segments found',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
            ),
          ),
        );
      }

      return Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: AppTheme.gray200),
          top: BorderSide(color: AppTheme.gray200),
          bottom: BorderSide(color: AppTheme.gray200),
        ),
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1),
        },
        children: [
          SegmentHeader(),
          ...controller.paginatedSegments.asMap().entries.map((entry) {
            final segment = entry.value;

            // Determine category based on segment name
            String category =
                segment.segmentName.toLowerCase().contains('index')
                ? 'Trading'
                : segment.segmentName.toLowerCase().contains('cash')
                ? 'Trading'
                : segment.segmentName.toLowerCase().contains('custom')
                ? 'Investment'
                : 'Trading';

            return SegmentRow(
              name: segment.segmentName,
              category: category,
              status: segment.formattedStatus,
              date:
                  '${segment.createdAt.year}-${segment.createdAt.month.toString().padLeft(2, '0')}-${segment.createdAt.day.toString().padLeft(2, '0')}',
              statusColor: segment.formattedStatus == 'Active'
                  ? AppTheme.successGreen
                  : AppTheme.errorRed,
              onEdit: () => Get.find<SubscriptionNavigationController>()
                  .showCreateSegment(segmentToEdit: segment),
              onDelete: () => _confirmDelete(context, controller, segment),
            );
          }),
        ],
      );
    });
  }

  void _confirmDelete(
    BuildContext context,
    SubscriptionController controller,
    SegmentModel segment,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Segment'),
        content: Text(
          'Are you sure you want to delete "${segment.segmentName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (Get.isSnackbarOpen) {
                Get.closeAllSnackbars();
              }
              Get.back(); // Close dialog
              controller.deleteSegment(segment.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
