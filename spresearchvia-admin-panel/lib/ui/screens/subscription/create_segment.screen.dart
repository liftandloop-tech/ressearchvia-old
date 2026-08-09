import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/subscription/create_segment.controller.dart';
import 'package:spresearch_web/controllers/subscription/subscription_navigation.controller.dart';
import 'package:spresearch_web/models/segment.model.dart';

class CreateSegmentScreen extends StatelessWidget {
  final SegmentModel? segmentToEdit;

  const CreateSegmentScreen({super.key, this.segmentToEdit});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateSegmentController());
    // Initialize controller with segment data if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.init(segmentToEdit);
    });

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          Get.find<SubscriptionNavigationController>().goBack(),
                      icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                    ),
                    SizedBox(width: AppTheme.spacing8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.isEditing
                              ? 'Update Segment'
                              : AppStrings.createNewSegment,
                          style: AppTheme.h2Style.copyWith(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create or modify trading and research segments used in plans and reports.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
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
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: AppStrings.segmentName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(
                                        color: AppTheme.errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: controller.segmentNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter segment name';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText:
                                      'e.g., Index Future / Stock Option / Equity Cash',
                                  hintStyle: TextStyle(color: AppTheme.gray300),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: controller.descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Enter a brief description or purpose of this segment.',
                            hintStyle: TextStyle(color: AppTheme.gray300),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: AppTheme.gray200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: AppTheme.gray200),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Obx(
                          () => Switch(
                            value: controller.isActive.value,
                            onChanged: (value) =>
                                controller.isActive.value = value,
                            activeColor: AppTheme.successGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.status,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Obx(
                          () => Text(
                            controller.isActive.value
                                ? '(${AppStrings.active})'
                                : '(${AppStrings.inactive})',
                            style: TextStyle(
                              fontSize: 12,
                              color: controller.isActive.value
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: controller.resetForm,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: AppTheme.gray200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(AppStrings.reset, style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () =>
                      Get.find<SubscriptionNavigationController>().goBack(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: AppTheme.gray200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    AppStrings.cancel,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.saveSegment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
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
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            controller.isEditing
                                ? 'Update Segment'
                                : 'Save Segment',
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
