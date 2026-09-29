import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/reports/reports_navigation.controller.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import '../../../models/report.model.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ReportDetailsScreen extends StatelessWidget {
  final ReportModel report;
  const ReportDetailsScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<ReportsNavigationController>();
    final authController = Get.find<AuthController>();
    final currentUser = authController.user.value;
    final isAdmin = currentUser?.isAdmin == true;
    final canUpdateReport = isAdmin || (currentUser?.has('reports.update') ?? false);
    final canChangePublicStatus = isAdmin || (currentUser?.has('reports.change_public_status') ?? false);
    final canDeleteReport = isAdmin || (currentUser?.has('reports.delete') ?? false);
    final hasAnyAction = canUpdateReport || canChangePublicStatus || canDeleteReport;

    return Container(
      color: AppTheme.gray50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () =>
                      Get.find<ReportsNavigationController>().goBack(),
                  icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                ),
                SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                report.title,
                                style: AppTheme.h2Style.copyWith(
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: report.status == 'Published'
                                      ? AppTheme.paleGreen
                                      : AppTheme.statusErrorLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  report.status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: report.status == 'Published'
                                        ? AppTheme.successGreen
                                        : AppTheme.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '${AppStrings.reportTitle}: ${report.id}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Text(
                                '${AppStrings.category}:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                report.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (canUpdateReport)
                        ElevatedButton(
                          onPressed: () => navController.showUploadReport(
                            reportToEdit: report,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            AppStrings.uploadFile,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.gray200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Report Content',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              AppStrings.description,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.gray50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                report.description.isEmpty
                                    ? 'No description provided.'
                                    : report.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            if (report.reportOriginalName != null &&
                                report.reportOriginalName!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'File Preview',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.gray50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.picture_as_pdf,
                                        color: Color(0xFFD32F2F),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.reportOriginalName!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Document',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final controller =
                                            Get.find<ReportController>();
                                        controller.downloadReport(report);
                                      },
                                      icon: const Icon(
                                        Icons.download,
                                        size: 16,
                                      ),
                                      label: Text(
                                        AppStrings.download,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (report.youtubeUrl != null &&
                                report.youtubeUrl!.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'YouTube Video Link',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.gray50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.play_circle_filled,
                                        color: Color(0xFF1976D2),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            report.youtubeUrl!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text(
                                            'YouTube Video',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        html.window.open(
                                          report.youtubeUrl!,
                                          '_blank',
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.open_in_new,
                                        size: 16,
                                      ),
                                      label: const Text('Open Link'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (report.updates.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.gray200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    color: AppTheme.primaryBlue,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Updates History',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ...report.updates.map((update) {
                                final status = update['status'] ?? 'general';

                                Color cardBg;
                                Color cardBorder;
                                Color badgeColor;
                                String badgeLabel;
                                IconData badgeIcon;

                                if (status == 'stoploss_hit') {
                                  cardBg = const Color(0xFFFEF2F2);
                                  cardBorder = const Color(0xFFFCA5A5);
                                  badgeColor = const Color(0xFFDC2626);
                                  badgeLabel = 'Stoploss Hit';
                                  badgeIcon = Icons.cancel_outlined;
                                } else if (status == 'target_achieved') {
                                  cardBg = const Color(0xFFF0FDF4);
                                  cardBorder = const Color(0xFF86EFAC);
                                  badgeColor = const Color(0xFF16A34A);
                                  badgeLabel = 'Target Achieved';
                                  badgeIcon = Icons.check_circle_outline;
                                } else if (status == 'partial_profit') {
                                  cardBg = const Color(0xFFFFF7ED);
                                  cardBorder = const Color(0xFFFDBA74);
                                  badgeColor = const Color(0xFFEA580C);
                                  badgeLabel = 'Partial Profit';
                                  badgeIcon = Icons.monetization_on_outlined;
                                } else {
                                  cardBg = AppTheme.gray50;
                                  cardBorder = AppTheme.primaryBlue.withValues(alpha: 0.15);
                                  badgeColor = AppTheme.primaryBlue;
                                  badgeLabel = 'Update';
                                  badgeIcon = Icons.info_outline;
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cardBorder, width: 1.2),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: badgeColor.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(badgeIcon, size: 14, color: badgeColor),
                                                const SizedBox(width: 4),
                                                Text(
                                                  badgeLabel,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: badgeColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (update['timestamp'] != null &&
                                              update['timestamp']!.isNotEmpty)
                                            Text(
                                              update['timestamp']!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        update['text'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.gray200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Metadata',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.createdDate,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.createdDate,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Last Updated',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report.lastUpdated,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Uploaded By',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.gray300,
                                  child: const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  report.uploadedBy,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (hasAnyAction) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.gray200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.actions,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (canUpdateReport) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => navController.showUploadReport(
                                    reportToEdit: report,
                                  ),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text(
                                    'Edit Report',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                              if (canChangePublicStatus) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final controller =
                                        Get.find<ReportController>();
                                    await controller.togglePublishStatus(report);
                                    navController.goBack();
                                  },
                                  icon: Icon(
                                    report.status == 'Published'
                                        ? Icons.unpublished
                                        : Icons.publish,
                                    size: 18,
                                  ),
                                  label: Text(
                                    report.status == 'Published'
                                        ? 'Unpublish'
                                        : 'Publish',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: report.status == 'Published'
                                        ? AppTheme.statusErrorLight.withOpacity(
                                            0.8,
                                          )
                                        : AppTheme.successGreen,
                                    foregroundColor: report.status == 'Published'
                                        ? AppTheme.errorRed
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                              if (canDeleteReport) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Get.dialog(
                                      AlertDialog(
                                        title: const Text('Delete Report'),
                                        content: const Text(
                                          'Are you sure you want to delete this report? This action cannot be undone.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Get.back(),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              if (Get.isSnackbarOpen) {
                                                Get.closeAllSnackbars();
                                              }
                                              Get.back();
                                              final controller =
                                                  Get.find<ReportController>();
                                              final deleted = await controller
                                                  .deleteReport(report.id);
                                              if (deleted) {
                                                navController.goBack();
                                              }
                                            },
                                            child: const Text(
                                              'Delete',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text(
                                    'Delete Report',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorRed,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
