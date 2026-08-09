import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../controllers/segment_plan.controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../widgets/button.dart';
import '../../../services/snackbar.service.dart';

class ActiveSegmentCard extends StatelessWidget {
  const ActiveSegmentCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SegmentPlanController>()) {
      Get.put(SegmentPlanController());
    }

    return GetX<SegmentPlanController>(
      builder: (controller) {
        final segments = controller.activeSegments;
        final hasActive = controller.hasActiveSegment.value;

        if (!hasActive || segments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff7C3AED), Color(0xff5B21B6)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No Active Segment',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Purchase a segment to access specialized features',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 24),
                Button(
                  title: 'Select a Segment',
                  buttonType: ButtonType.green,
                  onTap: () {
                    final ctrl = Get.isRegistered<SegmentPlanController>()
                        ? Get.find<SegmentPlanController>()
                        : null;
                    if (ctrl != null && ctrl.hasRegistrationPendingBalance) {
                      SnackbarService.showWarning(
                        'Please complete your registration payment before accessing plans.',
                        title: 'Registration Balance Due',
                      );
                      return;
                    }
                    Get.toNamed(AppRoutes.selectSegment);
                  },
                ),
              ],
            ),
          );
        }

        // Use the first segment for display, or improve to show multiple if needed. 
        // Showing first active segment.
        final segment = segments.first;

        // Parse segment data
        final segmentName = segment['segmentName'] ?? 'Segment';
        final validity = segment['validity'];
        final endDate = segment['endDate'] != null
            ? DateTime.parse(segment['endDate'])
            : null;

        // Calculate days remaining
        int daysRemaining = 0;
        if (endDate != null) {
          daysRemaining = endDate.difference(DateTime.now()).inDays;
          if (daysRemaining < 0) daysRemaining = 0;
        }

        final formattedEndDate = endDate != null
            ? DateFormat('MMMM dd, yyyy').format(endDate)
            : null;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff7C3AED), Color(0xff5B21B6)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    segmentName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff9333EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (validity != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Validity: $validity days',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    daysRemaining.toString(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      daysRemaining == 1 ? 'day left' : 'days left',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              if (formattedEndDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Expires on $formattedEndDate',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Button(
                title: 'View Segments',
                icon: Icons.view_list,
                onTap: () {
                  final ctrl = Get.isRegistered<SegmentPlanController>()
                      ? Get.find<SegmentPlanController>()
                      : null;
                  if (ctrl != null && ctrl.hasRegistrationPendingBalance) {
                    SnackbarService.showWarning(
                      'Please complete your registration payment before accessing plans.',
                      title: 'Registration Balance Due',
                    );
                    return;
                  }
                  Get.toNamed(AppRoutes.selectSegment);
                },
                buttonType: ButtonType.green,
              ),
            ],
          ),
        );
      },
    );
  }
}
