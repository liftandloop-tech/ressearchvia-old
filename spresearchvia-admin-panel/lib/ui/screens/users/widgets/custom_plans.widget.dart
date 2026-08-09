import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/subscription/manage_subscription.controller.dart';
import 'custom_plan_item.widget.dart';

class CustomPlans extends StatelessWidget {
  final ManageSubscriptionController controller;
  const CustomPlans({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HNI Customised Plans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create personalised plans for exclusive clients with flexible pricing and duration.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.add, size: 16),
                    label: Text(
                      'Add New Custom Plan',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() {
            if (controller.availablePlans.isEmpty) {
              return const Text('No custom plans available.');
            }
            return Column(
              children: controller.availablePlans.asMap().entries.map((entry) {
                final index = entry.key;
                final plan = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomPlanItem(
                    controller: controller,
                    index: index,
                    title: plan.planName,
                    price: '₹${plan.price}',
                    duration: '${plan.duration} ${plan.day}',
                    status: plan.planStatus,
                    isActive: plan.planStatus.toLowerCase() == 'active',
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}
