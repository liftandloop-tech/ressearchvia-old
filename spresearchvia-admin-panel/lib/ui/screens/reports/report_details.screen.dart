import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/reports/reports_navigation.controller.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/services/report.service.dart';
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
                      if (canUpdateReport) ...[
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showAddUpdateDialog(context, report),
                              icon: const Icon(Icons.add_circle_outline, size: 16),
                              label: const Text('Add Update'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                            ),
                            const SizedBox(width: 12),
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
                      ],
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
                      if (report.updates.isNotEmpty || report.reportType.toLowerCase().contains('trading')) ...[
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        'Updates History (${report.updates.length})',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (canUpdateReport)
                                    ElevatedButton.icon(
                                      onPressed: () => _showAddUpdateDialog(context, report),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Update'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF16A34A),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (report.updates.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gray50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.gray200),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No updates posted yet for this trading call.',
                                      style: TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ),
                                )
                              else
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
                                    cardBorder = AppTheme.gray200;
                                    badgeColor = AppTheme.primaryBlue;
                                    badgeLabel = 'Update';
                                    badgeIcon = Icons.info_outline;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: cardBorder, width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: badgeColor.withValues(alpha: 0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            width: 4.5,
                                            color: badgeColor,
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 9,
                                                          vertical: 3.5,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: badgeColor,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(badgeIcon, size: 13, color: Colors.white),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              badgeLabel,
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w600,
                                                                color: Colors.white,
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
                                                  if ((update['text'] ?? '').isNotEmpty) ...[
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      update['text'] ?? '',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: AppTheme.textPrimary,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
                                        ? AppTheme.statusErrorLight.withValues(
                                            alpha: 0.8,
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

  void _showAddUpdateDialog(BuildContext context, ReportModel report) {
    final updateTextController = TextEditingController();
    final selectedStatus = 'stoploss_hit'.obs;
    final isSubmitting = false.obs;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_comment_rounded, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Add Update to Trading Call', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Update Status:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Obx(() => Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildDialogStatusRadio(
                      label: 'Stoploss Hit',
                      value: 'stoploss_hit',
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEF2F2),
                      icon: Icons.cancel_outlined,
                      selectedStatus: selectedStatus,
                      onSelect: (val) {
                        selectedStatus.value = val;
                        if (updateTextController.text.trim().isEmpty) {
                          updateTextController.text = 'Kindly Exit, SL Triggered';
                        }
                      },
                    ),
                    _buildDialogStatusRadio(
                      label: 'Target Achieved',
                      value: 'target_achieved',
                      color: const Color(0xFF16A34A),
                      bgColor: const Color(0xFFF0FDF4),
                      icon: Icons.check_circle_outline,
                      selectedStatus: selectedStatus,
                      onSelect: (val) {
                        selectedStatus.value = val;
                        if (updateTextController.text.trim().isEmpty) {
                          updateTextController.text = 'Target Achieved, Book Profit';
                        }
                      },
                    ),
                    _buildDialogStatusRadio(
                      label: 'Partial Profit',
                      value: 'partial_profit',
                      color: const Color(0xFFEA580C),
                      bgColor: const Color(0xFFFFF7ED),
                      icon: Icons.monetization_on_outlined,
                      selectedStatus: selectedStatus,
                      onSelect: (val) {
                        selectedStatus.value = val;
                        if (updateTextController.text.trim().isEmpty) {
                          updateTextController.text = 'Book Partial Profit';
                        }
                      },
                    ),
                  ],
                )),
                const SizedBox(height: 16),
                const Text('Update Message:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: updateTextController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter update message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Obx(() => ElevatedButton(
              onPressed: isSubmitting.value ? null : () async {
                final text = updateTextController.text.trim();
                if (text.isEmpty) {
                  Get.snackbar('Error', 'Please enter update message');
                  return;
                }
                isSubmitting.value = true;
                final reportService = Get.find<ReportService>();
                final success = await reportService.updateReport(
                  id: report.id,
                  title: report.title,
                  categoryId: report.segmentId,
                  planIds: report.planArray,
                  reportType: report.reportType,
                  description: report.description,
                  newUpdate: text,
                  newUpdateStatus: selectedStatus.value,
                  youtubeUrl: report.youtubeUrl,
                );
                isSubmitting.value = false;
                if (success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  if (Get.isRegistered<ReportController>()) {
                    Get.find<ReportController>().fetchReports();
                  }
                  Get.snackbar('Success', 'Update added successfully');
                  Get.find<ReportsNavigationController>().goBack();
                } else {
                  Get.snackbar('Error', 'Failed to add update');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Update'),
            )),
          ],
        );
      },
    );
  }

  Widget _buildDialogStatusRadio({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required RxString selectedStatus,
    required Function(String) onSelect,
  }) {
    final isSelected = selectedStatus.value == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : AppTheme.gray200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? color : AppTheme.gray300,
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 14, color: isSelected ? color : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
