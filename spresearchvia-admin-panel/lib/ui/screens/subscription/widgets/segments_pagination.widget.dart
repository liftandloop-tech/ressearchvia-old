import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'segment_page_numbers.widget.dart';

class SegmentsPagination extends StatelessWidget {
  final SubscriptionController controller;

  const SegmentsPagination({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.segments.isEmpty) return const SizedBox.shrink();

      final start =
          (controller.segmentsCurrentPage.value - 1) *
              controller.segmentsItemsPerPage +
          1;
      final end = start + controller.paginatedSegments.length - 1;
      final total = controller.segments.length;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${AppStrings.showing} $start ${AppStrings.to} $end ${AppStrings.of} $total ${AppStrings.results}',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          Row(
            children: [
              IconButton(
                onPressed: controller.segmentsCurrentPage.value > 1
                    ? () => controller.setSegmentsPage(
                        controller.segmentsCurrentPage.value - 1,
                      )
                    : null,
                icon: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: controller.segmentsCurrentPage.value > 1
                      ? AppTheme.textPrimary
                      : AppTheme.gray300,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              const SizedBox(width: 8),
              SegmentPageNumbers(controller: controller),
              const SizedBox(width: 8),
              IconButton(
                onPressed:
                    controller.segmentsCurrentPage.value <
                        controller.segmentsTotalPages
                    ? () => controller.setSegmentsPage(
                        controller.segmentsCurrentPage.value + 1,
                      )
                    : null,
                icon: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color:
                      controller.segmentsCurrentPage.value <
                          controller.segmentsTotalPages
                      ? AppTheme.textPrimary
                      : AppTheme.gray300,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ],
      );
    });
  }
}
