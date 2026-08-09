import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'current_badge.dart';
import 'plan_detail_row.dart';

class CurrentPlanCard extends StatelessWidget {
  const CurrentPlanCard({
    super.key,
    required this.planName,
    required this.description,
    required this.price,
    required this.validity,
    required this.expiryDate,
  });

  final String planName;
  final String description;
  final String price;
  final String validity;
  final String expiryDate;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueDark,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlueDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const CurrentBadge(),
                ],
              ),
              const SizedBox(height: 20),
              PlanDetailRow(label: 'Price', value: price, isExpiry: false),
              const SizedBox(height: 12),
              PlanDetailRow(
                label: 'Validity',
                value: validity,
                isExpiry: false,
              ),
              const SizedBox(height: 12),
              PlanDetailRow(
                label: 'Expires on',
                value: expiryDate,
                isExpiry: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
