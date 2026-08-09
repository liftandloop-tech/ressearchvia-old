import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/reports/upload_report.controller.dart';
import 'package:spresearch_web/controllers/reports/reports_navigation.controller.dart';

import 'package:spresearch_web/models/report.model.dart';

class UploadReportScreen extends StatelessWidget {
  final ReportModel? reportToEdit;

  const UploadReportScreen({super.key, this.reportToEdit});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UploadReportController());
    final navController = Get.find<ReportsNavigationController>();

    // If editing, load data. Use addPostFrameCallback to avoid build conflicts if needed,
    // or just call it. Since controller is just put, it's safe.
    if (reportToEdit != null) {
      controller.loadReportData(reportToEdit!);
    } else {
      controller.resetForm();
    }

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
                  onPressed: () => navController.goBack(),
                  icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                ),
                SizedBox(width: AppTheme.spacing8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.isEditMode.value
                            ? 'Edit Report'
                            : AppStrings.uploadReportTitle,
                        style: AppTheme.h2Style.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        controller.isEditMode.value
                            ? 'Update report details'
                            : AppStrings.uploadReportDescReports,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: AppStrings.reportTitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            children: [
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppTheme.errorRed),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: TextField(
                            controller: controller.titleController,
                            decoration: InputDecoration(
                              hintText: 'Enter report title',
                              hintStyle: TextStyle(color: AppTheme.gray300),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                            text: 'Segment',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            children: [
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: AppTheme.errorRed),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray200),
                            borderRadius: BorderRadius.circular(6),
                            color: controller.isLoadingSegments.value
                                ? AppTheme.gray50
                                : Colors.white,
                          ),
                          child: Obx(
                            () => controller.isLoadingSegments.value
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Loading segments...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : controller.segments.isEmpty
                                ? Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No segments available',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text(
                                              'Select Segments',
                                            ),
                                            content: SizedBox(
                                              width: 300,
                                              height: 400,
                                              child: Column(
                                                children: [
                                                  Obx(
                                                    () => CheckboxListTile(
                                                      title: const Text(
                                                        'Select All',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      value:
                                                          controller
                                                              .segments
                                                              .isNotEmpty &&
                                                          controller
                                                                  .selectedSegmentIds
                                                                  .length ==
                                                              controller
                                                                  .segments
                                                                  .length,
                                                      onChanged:
                                                          (
                                                            bool? value,
                                                          ) => controller
                                                              .toggleAllSegments(
                                                                value ?? false,
                                                              ),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                    ),
                                                  ),
                                                  const Divider(height: 1),
                                                  Expanded(
                                                    child: Obx(
                                                      () => ListView.builder(
                                                        itemCount: controller
                                                            .segments
                                                            .length,
                                                        itemBuilder: (context, index) {
                                                          final segment =
                                                              controller
                                                                  .segments[index];
                                                          final id =
                                                              segment['_id']
                                                                  as String;
                                                          final name =
                                                              segment['segmentName'] ??
                                                              'Unknown';
                                                          return Obx(
                                                            () => CheckboxListTile(
                                                              title: Text(name),
                                                              value: controller
                                                                  .selectedSegmentIds
                                                                  .contains(id),
                                                              onChanged: (_) =>
                                                                  controller
                                                                      .toggleSegment(
                                                                        id,
                                                                      ),
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              controlAffinity:
                                                                  ListTileControlAffinity
                                                                      .leading,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Done'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Obx(() {
                                            if (controller
                                                .selectedSegmentIds
                                                .isEmpty) {
                                              return Text(
                                                'Select Segments',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.gray300,
                                                ),
                                              );
                                            }
                                            if (controller
                                                    .selectedSegmentIds
                                                    .length ==
                                                1) {
                                              final id = controller
                                                  .selectedSegmentIds
                                                  .first;
                                              final seg = controller.segments
                                                  .firstWhere(
                                                    (s) => s['_id'] == id,
                                                    orElse: () => {},
                                                  );
                                              return Text(
                                                seg['segmentName'] ?? 'Unknown',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              );
                                            }
                                            return Text(
                                              '${controller.selectedSegmentIds.length} segments selected',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textPrimary,
                                              ),
                                            );
                                          }),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Plan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray200),
                            borderRadius: BorderRadius.circular(6),
                            color: controller.isLoadingPlans.value
                                ? AppTheme.gray50
                                : Colors.white,
                          ),
                          child: Obx(
                            () => controller.isLoadingPlans.value
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Loading plans...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : controller.selectedSegmentIds.isEmpty
                                ? Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: AppTheme.primaryBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Select a segment first',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : controller.filteredPlans.isEmpty
                                ? Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No plans available for this segment',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : InkWell(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Select Plans'),
                                            content: SizedBox(
                                              width: 300,
                                              height: 400,
                                              child: Column(
                                                children: [
                                                  Obx(
                                                    () => CheckboxListTile(
                                                      title: const Text(
                                                        'Select All',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      value:
                                                          controller
                                                              .filteredPlans
                                                              .isNotEmpty &&
                                                          controller
                                                                  .selectedPlanIds
                                                                  .length ==
                                                              controller
                                                                  .filteredPlans
                                                                  .length,
                                                      onChanged:
                                                          (
                                                            bool? value,
                                                          ) => controller
                                                              .toggleAllPlans(
                                                                value ?? false,
                                                              ),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                    ),
                                                  ),
                                                  const Divider(height: 1),
                                                  Expanded(
                                                    child: Obx(
                                                      () => ListView.builder(
                                                        itemCount: controller
                                                            .filteredPlans
                                                            .length,
                                                        itemBuilder: (context, index) {
                                                          final plan = controller
                                                              .filteredPlans[index];
                                                          final id =
                                                              plan['id']
                                                                  as String;
                                                          final name =
                                                              plan['name'] ??
                                                              'Unknown';
                                                          final segmentName =
                                                              plan['segmentName'] ??
                                                              '';
                                                          return Obx(
                                                            () => CheckboxListTile(
                                                              title: Text(name),
                                                              subtitle: Text(
                                                                segmentName,
                                                                style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                              value: controller
                                                                  .selectedPlanIds
                                                                  .contains(id),
                                                              onChanged: (_) =>
                                                                  controller
                                                                      .togglePlan(
                                                                        id,
                                                                      ),
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              controlAffinity:
                                                                  ListTileControlAffinity
                                                                      .leading,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Done'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Obx(() {
                                            if (controller
                                                .selectedPlanIds
                                                .isEmpty) {
                                              return Text(
                                                'Select Plans',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.gray300,
                                                ),
                                              );
                                            }
                                            if (controller
                                                    .selectedPlanIds
                                                    .length ==
                                                1) {
                                              final id = controller
                                                  .selectedPlanIds
                                                  .first;
                                              final plan = controller.allPlans
                                                  .firstWhere(
                                                    (p) => p['id'] == id,
                                                    orElse: () => {},
                                                  );
                                              return Text(
                                                plan['name'] ?? 'Unknown',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              );
                                            }
                                            return Text(
                                              '${controller.selectedPlanIds.length} plans selected',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textPrimary,
                                              ),
                                            );
                                          }),
                                        ),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.reportType,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(
                          () => Wrap(
                            spacing: 32,
                            runSpacing: 12,
                            children: [
                              InkWell(
                                onTap: () =>
                                    controller.selectedReportType.value =
                                        'Trading calls',
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        controller.selectedReportType.value ==
                                                'Trading calls'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: AppTheme.primaryBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Trading Calls',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                          fontWeight:
                                              controller
                                                      .selectedReportType
                                                      .value ==
                                                  'Trading calls'
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () =>
                                    controller.selectedReportType.value =
                                        'Detailed Reports',
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        controller.selectedReportType.value ==
                                                'Detailed Reports'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: AppTheme.primaryBlue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Detailed Reports',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textPrimary,
                                          fontWeight:
                                              controller
                                                      .selectedReportType
                                                      .value ==
                                                  'Detailed Reports'
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => RichText(
                            text: TextSpan(
                              text: AppStrings.uploadFile,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                              children: [
                                if (controller.selectedReportType.value ==
                                    'Detailed Reports')
                                  TextSpan(
                                    text: '*',
                                    style: TextStyle(color: AppTheme.errorRed),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: BoxConstraints(
                            minHeight: 240,
                            maxHeight: 280,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.gray200,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE3F2FD),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.cloud_upload_outlined,
                                    color: AppTheme.primaryBlue,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Obx(
                                  () => Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: InkWell(
                                          onTap:
                                              controller
                                                      .uploadedFileName
                                                      .value
                                                      .isNotEmpty &&
                                                  !controller
                                                      .isFileRemoved
                                                      .value
                                              ? controller.previewFile
                                              : null,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 2,
                                            ),
                                            child: Text(
                                              controller
                                                      .uploadedFileName
                                                      .value
                                                      .isEmpty
                                                  ? AppStrings.dragDropFile
                                                  : controller
                                                        .uploadedFileName
                                                        .value,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    controller
                                                            .uploadedFileName
                                                            .value
                                                            .isNotEmpty &&
                                                        !controller
                                                            .isFileRemoved
                                                            .value
                                                    ? AppTheme.primaryBlue
                                                    : AppTheme.textPrimary,
                                                decoration:
                                                    controller
                                                            .uploadedFileName
                                                            .value
                                                            .isNotEmpty &&
                                                        !controller
                                                            .isFileRemoved
                                                            .value
                                                    ? TextDecoration.underline
                                                    : null,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (controller
                                          .uploadedFileName
                                          .value
                                          .isNotEmpty)
                                        IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: AppTheme.errorRed,
                                            size: 20,
                                          ),
                                          onPressed: controller.removeFile,
                                          tooltip: 'Remove file',
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  AppStrings.clickToChoose,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppStrings.supportedFormats,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: controller.pickFile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    AppStrings.browseFiles,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: TextField(
                            controller: controller.descriptionController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: 'Enter report description...',
                              hintStyle: TextStyle(color: AppTheme.gray300),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.reportDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),

                        Obx(() {
                          if (!controller.isEditMode.value)
                            return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text(
                                'Update History',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (controller.existingUpdates.isNotEmpty) ...[
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.gray200),
                                    borderRadius: BorderRadius.circular(6),
                                    color: AppTheme.gray50,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.all(12),
                                    itemCount:
                                        controller.existingUpdates.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final update =
                                          controller.existingUpdates[index];
                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.gray200,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              update['text'] ?? '',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              update['timestamp'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.black45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              Text(
                                'Add New Update',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                child: TextField(
                                  controller: controller.newUpdateController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Enter new latest update message...',
                                    hintStyle: TextStyle(
                                      color: AppTheme.gray300,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: AppTheme.gray200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: AppTheme.gray200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),

                        const SizedBox(height: 24),
                        Text(
                          'YouTube Video Link (Optional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: TextField(
                            controller: controller.youtubeUrlController,
                            decoration: InputDecoration(
                              hintText:
                                  'Paste YouTube link (e.g. Shorts or Long video)',
                              hintStyle: TextStyle(color: AppTheme.gray300),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: AppTheme.gray200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            controller.isEditMode.value ? 'Update' : 'Upload',
                            style: TextStyle(fontSize: 14),
                          ),
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
