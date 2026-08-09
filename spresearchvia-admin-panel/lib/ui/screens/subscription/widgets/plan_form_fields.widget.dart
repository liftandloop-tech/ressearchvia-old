import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'plan_text_field.widget.dart';
import 'plan_dropdown.widget.dart';

class PlanFormFields extends StatelessWidget {
  final TextEditingController planNameController;
  final TextEditingController priceController;
  final TextEditingController durationController;
  final TextEditingController descriptionController;
  final String selectedPlanType;
  final String selectedDurationType;
  final bool autoRenewDefault;
  final bool isActive;
  final Function(String) onPlanTypeChanged;
  final Function(String) onDurationTypeChanged;
  final Function(bool) onAutoRenewChanged;
  final Function(bool) onActiveChanged;

  const PlanFormFields({
    super.key,
    required this.planNameController,
    required this.priceController,
    required this.durationController,
    required this.descriptionController,
    required this.selectedPlanType,
    required this.selectedDurationType,
    required this.autoRenewDefault,
    required this.isActive,
    required this.onPlanTypeChanged,
    required this.onDurationTypeChanged,
    required this.onAutoRenewChanged,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: PlanTextField(
                label: 'Plan Name',
                controller: planNameController,
                hint: 'Enter plan name',
                required: true,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: PlanDropdown(
                label: 'Select Segment',
                value: selectedPlanType,
                items: ['Select plan type', 'Basic', 'Premium', 'Enterprise'],
                onChanged: onPlanTypeChanged,
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PlanTextField(
                          controller: durationController,
                          hint: '12',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PlanDropdown(
                          value: selectedDurationType,
                          items: ['Days', 'Months', 'Years'],
                          onChanged: onDurationTypeChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: PlanTextField(
                label: 'Price',
                controller: priceController,
                hint: '₹ 29.99',
                required: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Renew Default',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: autoRenewDefault,
                        onChanged: onAutoRenewChanged,
                        activeThumbColor: AppTheme.successGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enable auto-renewal by default',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Switch(
                        value: isActive,
                        onChanged: onActiveChanged,
                        activeThumbColor: AppTheme.successGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Description',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe what\'s included in this plan...',
            hintStyle: TextStyle(fontSize: 13, color: AppTheme.gray400),
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
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
