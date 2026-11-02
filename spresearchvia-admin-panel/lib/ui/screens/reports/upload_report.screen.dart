import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
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

    if (reportToEdit != null) {
      controller.loadReportData(reportToEdit!);
    } else {
      controller.resetForm();
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Header
            Row(
              children: [
                IconButton(
                  onPressed: () => navController.goBack(),
                  icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.isEditMode.value ? 'Edit Report' : 'Upload Report',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Obx(
                      () => Text(
                        controller.isEditMode.value ? 'Update report details' : 'Create and upload a new financial report',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Form Container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gray200),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Title, Report Type, Segments (outside), Plans (outside)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Report Title
                            RichText(
                              text: const TextSpan(
                                text: 'Report Title',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                children: [
                                  TextSpan(text: ' *', style: TextStyle(color: AppTheme.errorRed)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 40,
                              child: TextField(
                                controller: controller.titleController,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Enter report title',
                                  hintStyle: const TextStyle(color: AppTheme.gray300, fontSize: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: AppTheme.gray200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 2. Report Type (Trading Calls vs Detailed Reports)
                            Row(
                              children: [
                                const Text(
                                  'Report Type:',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Obx(
                                  () => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => controller.selectedReportType.value = 'Trading calls',
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                controller.selectedReportType.value == 'Trading calls'
                                                    ? Icons.radio_button_checked
                                                    : Icons.radio_button_unchecked,
                                                color: AppTheme.primaryBlue,
                                                size: 17,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Trading Calls',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: controller.selectedReportType.value == 'Trading calls'
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      InkWell(
                                        onTap: () => controller.selectedReportType.value = 'Detailed Reports',
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                controller.selectedReportType.value == 'Detailed Reports'
                                                    ? Icons.radio_button_checked
                                                    : Icons.radio_button_unchecked,
                                                color: AppTheme.primaryBlue,
                                                size: 17,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Detailed Reports',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: controller.selectedReportType.value == 'Detailed Reports'
                                                      ? FontWeight.w600
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
                            const SizedBox(height: 10),

                            // 3. SEGMENT SELECTION (Directly from outside, NO POPUP)
                            _buildInlineSegmentSelector(controller),
                            const SizedBox(height: 10),

                            // 4. PLAN SELECTION (Directly from outside, NO POPUP)
                            _buildInlinePlanSelector(controller),
                          ],
                        ),
                      ),

                      const SizedBox(width: 22),

                      // RIGHT COLUMN: Short Upload File, Description, Add Update, YouTube Link
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Upload File Block (SHORT & COMPACT)
                            Obx(() {
                              final isTradingCall = controller.selectedReportType.value.toLowerCase().contains('trading');
                              return RichText(
                                text: TextSpan(
                                  text: isTradingCall ? 'Upload File (Optional)' : 'Upload File',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                  children: [
                                    if (!isTradingCall)
                                      const TextSpan(text: ' *', style: TextStyle(color: AppTheme.errorRed)),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 5),
                            _buildCompactUploadBox(controller),
                            const SizedBox(height: 10),

                            // 2. Description (Spacious)
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 130,
                              child: TextField(
                                controller: controller.descriptionController,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                style: const TextStyle(fontSize: 13.5, height: 1.4),
                                decoration: InputDecoration(
                                  hintText: 'Enter report description...',
                                  hintStyle: const TextStyle(color: AppTheme.gray300, fontSize: 13),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: AppTheme.gray200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 3. Add New Update (for Trading Calls)
                            Obx(() {
                              final isTradingCall = controller.selectedReportType.value.toLowerCase().contains('trading');
                              if (!controller.isEditMode.value && !isTradingCall) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Existing Updates History (if edit mode)
                                  if (controller.existingUpdates.isNotEmpty) ...[
                                    const Text(
                                      'Update History',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      constraints: const BoxConstraints(maxHeight: 70),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.gray200),
                                      ),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        itemCount: controller.existingUpdates.length,
                                        separatorBuilder: (context, idx) => const SizedBox(height: 4),
                                        itemBuilder: (context, idx) {
                                          final u = controller.existingUpdates[idx];
                                          return Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE2E8F0),
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  u['status'] ?? 'Update',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  u['text'] ?? '',
                                                  style: const TextStyle(fontSize: 11.5),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                u['timestamp'] ?? '',
                                                style: const TextStyle(fontSize: 10, color: Colors.black45),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  const Text(
                                    'Add New Update',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _buildUpdateStatusRadio(
                                        controller: controller,
                                        label: 'Stoploss Hit',
                                        value: 'stoploss_hit',
                                        color: const Color(0xFFDC2626),
                                        bgColor: const Color(0xFFFEF2F2),
                                        icon: Icons.cancel_outlined,
                                      ),
                                      _buildUpdateStatusRadio(
                                        controller: controller,
                                        label: 'Target Achieved',
                                        value: 'target_achieved',
                                        color: const Color(0xFF16A34A),
                                        bgColor: const Color(0xFFF0FDF4),
                                        icon: Icons.check_circle_outline,
                                      ),
                                      _buildUpdateStatusRadio(
                                        controller: controller,
                                        label: 'Partial Profit',
                                        value: 'partial_profit',
                                        color: const Color(0xFFEA580C),
                                        bgColor: const Color(0xFFFFF7ED),
                                        icon: Icons.monetization_on_outlined,
                                      ),
                                      _buildUpdateStatusRadio(
                                        controller: controller,
                                        label: 'General Update',
                                        value: 'general',
                                        color: AppTheme.primaryBlue,
                                        bgColor: AppTheme.gray50,
                                        icon: Icons.edit_note,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: controller.newUpdateController,
                                      style: const TextStyle(fontSize: 12.5),
                                      decoration: InputDecoration(
                                        hintText: 'Enter update message...',
                                        hintStyle: const TextStyle(color: AppTheme.gray300, fontSize: 12.5),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: AppTheme.gray200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              );
                            }),

                            // 4. YouTube Video Link (Optional)
                            const Text(
                              'YouTube Video Link (Optional)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 38,
                              child: TextField(
                                controller: controller.youtubeUrlController,
                                style: const TextStyle(fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: 'Paste YouTube link (e.g. Shorts or Long video)',
                                  hintStyle: const TextStyle(color: AppTheme.gray300, fontSize: 12.5),
                                  prefixIcon: const Icon(Icons.video_library_outlined, size: 16, color: Color(0xFFDC2626)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: AppTheme.gray200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppTheme.gray200),
                  const SizedBox(height: 12),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => navController.goBack(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          side: const BorderSide(color: AppTheme.gray300),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value ? null : controller.submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  controller.isEditMode.value ? 'Update Report' : 'Upload Report',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// INLINE SEGMENT SELECTOR (Checkboxes directly on the form, NO POPUP)
  Widget _buildInlineSegmentSelector(UploadReportController controller) {
    return Obx(() {
      final isLoading = controller.isLoadingSegments.value;
      final segments = controller.segments;
      final selectedIds = controller.selectedSegmentIds;
      final isAllSelected = segments.isNotEmpty && selectedIds.length == segments.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: const TextSpan(
                  text: 'Segment',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  children: [
                    TextSpan(text: ' *', style: TextStyle(color: AppTheme.errorRed)),
                  ],
                ),
              ),
              if (segments.isNotEmpty)
                InkWell(
                  onTap: () => controller.toggleAllSegments(!isAllSelected),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isAllSelected,
                          onChanged: (val) => controller.toggleAllSegments(val ?? false),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          activeColor: AppTheme.primaryBlue,
                        ),
                        const Text(
                          'All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${selectedIds.length}/${segments.length})',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 115,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: isLoading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : segments.isEmpty
                    ? const Center(
                        child: Text(
                          'No segments available',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 2,
                            children: segments.map((seg) {
                              final id = seg['_id'] as String;
                              final name = (seg['segmentName'] ?? 'Unknown').toString();
                              final isChecked = selectedIds.contains(id);

                              return InkWell(
                                onTap: () => controller.toggleSegment(id),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: isChecked,
                                        onChanged: (_) => controller.toggleSegment(id),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        activeColor: AppTheme.primaryBlue,
                                      ),
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                          color: isChecked ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      );
    });
  }

  /// INLINE PLAN SELECTOR (Checkboxes directly on the form, NO POPUP)
  Widget _buildInlinePlanSelector(UploadReportController controller) {
    return Obx(() {
      final isLoading = controller.isLoadingPlans.value;
      final plans = controller.filteredPlans;
      final selectedIds = controller.selectedPlanIds;
      final hasSegments = controller.selectedSegmentIds.isNotEmpty;
      final isAllSelected = plans.isNotEmpty && selectedIds.length == plans.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Plan',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (plans.isNotEmpty)
                InkWell(
                  onTap: () => controller.toggleAllPlans(!isAllSelected),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isAllSelected,
                          onChanged: (val) => controller.toggleAllPlans(val ?? false),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          activeColor: AppTheme.primaryBlue,
                        ),
                        const Text(
                          'All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${selectedIds.length}/${plans.length})',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 115,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: isLoading
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : !hasSegments
                    ? const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Color(0xFF94A3B8)),
                            SizedBox(width: 6),
                            Text(
                              'Select segment(s) above to display plans',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    : plans.isEmpty
                        ? const Center(
                            child: Text(
                              'No plans found for selected segment(s)',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          )
                        : Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 2,
                                children: plans.map((plan) {
                                  final id = plan['id'] as String;
                                  final name = (plan['name'] ?? 'Unknown').toString();
                                  final isChecked = selectedIds.contains(id);

                                  return InkWell(
                                    onTap: () => controller.togglePlan(id),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: isChecked,
                                            onChanged: (_) => controller.togglePlan(id),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                            activeColor: AppTheme.primaryBlue,
                                          ),
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                              color: isChecked ? AppTheme.primaryBlue : AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
          ),
        ],
      );
    });
  }

  /// COMPACT SHORT UPLOAD BOX (Height ~64px)
  Widget _buildCompactUploadBox(UploadReportController controller) {
    return Obx(() {
      final fileName = controller.uploadedFileName.value;
      final hasFile = fileName.isNotEmpty && !controller.isFileRemoved.value;

      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasFile ? const Color(0xFF93C5FD) : AppTheme.gray200,
            width: 1.5,
          ),
        ),
        child: hasFile
            ? Row(
                children: [
                  const Icon(Icons.insert_drive_file_rounded, color: AppTheme.primaryBlue, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: controller.previewFile,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Click to preview attached file',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Preview File',
                    icon: const Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryBlue),
                    onPressed: controller.previewFile,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Remove file',
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFDC2626)),
                    onPressed: controller.removeFile,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: controller.pickFile,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Change', style: TextStyle(fontSize: 11)),
                  ),
                ],
              )
            : InkWell(
                onTap: controller.pickFile,
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E7FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drag & drop or click to choose file',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Supported: PDF, PNG, JPG, MP4, WEBP (Max 50MB)',
                            style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.pickFile,
                      icon: const Icon(Icons.folder_open, size: 14),
                      label: const Text('Browse', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
      );
    });
  }

  Widget _buildUpdateStatusRadio({
    required UploadReportController controller,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Obx(() {
      final isSelected = controller.selectedUpdateStatus.value == value;
      return InkWell(
        onTap: () => controller.selectUpdateStatus(value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 14,
                color: isSelected ? color : AppTheme.gray300,
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 13, color: isSelected ? color : AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
