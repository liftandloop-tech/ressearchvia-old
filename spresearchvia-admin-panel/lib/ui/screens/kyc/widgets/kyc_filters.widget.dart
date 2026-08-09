import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/kyc/kyc_manager.controller.dart';

class KycFilters extends StatelessWidget {
  const KycFilters({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KycManagerController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.status, style: AppTheme.labelStyle),
                    const SizedBox(height: 8),
                    Obx(
                      () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.inputFillColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.inputBorderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.selectedStatus.value,
                            onChanged: (value) =>
                                controller.updateStatus(value!),
                            items:
                                [
                                      AppStrings.allStatus,
                                      AppStrings.approved,
                                      AppStrings.rejected,
                                    ]
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: AppTheme.inputStyle.copyWith(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.documentType,
                      style: AppTheme.labelStyle.copyWith(
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.inputFillColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.inputBorderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: controller.selectedDocumentType.value,
                            onChanged: (value) =>
                                controller.updateDocumentType(value!),
                            items:
                                [
                                      'All Types',
                                      'Aadhar',
                                      'PAN',
                                      'Passport',
                                      'Driver License',
                                    ]
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          type,
                                          style: AppTheme.inputStyle.copyWith(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.fromDate,
                      style: AppTheme.labelStyle.copyWith(
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.fromDateController,
                      decoration: AppTheme.inputDecoration('mm/dd/yyyy')
                          .copyWith(
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              size: 16,
                            ),
                          ),
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.toDate,
                      style: AppTheme.labelStyle.copyWith(
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.toDateController,
                      decoration: AppTheme.inputDecoration('mm/dd/yyyy')
                          .copyWith(
                            suffixIcon: const Icon(
                              Icons.calendar_today,
                              size: 16,
                            ),
                          ),
                      style: const TextStyle(fontFamily: 'Poppins'),
                      onChanged: (v) {
                        // KYC controller needs listener or direct call
                        controller.applyFilters();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(' ', style: TextStyle(fontSize: 13, height: 1.5)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: controller.resetFilters,
                    style: AppTheme.secondaryButtonStyle,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.reset,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
