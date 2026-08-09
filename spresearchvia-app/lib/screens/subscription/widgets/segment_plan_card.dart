import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class SegmentPlanCard extends StatelessWidget {
  const SegmentPlanCard({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.perDay,
    required this.benefits,
    required this.isSelected,
    this.badge,
    this.isPopular = false,
    this.onTap,
  });

  final String id;
  final String name, description, amount, perDay;
  final List<String> benefits;
  final bool isSelected;
  final String? badge;
  final bool isPopular;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final isHNI = name == 'HNI Custom Plan';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.radius(16)),
      child: Container(
        padding: responsive.padding(all: 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(responsive.radius(16)),
          color: isSelected
              ? AppTheme.primaryGreen.withValues(alpha: 0.05)
              : AppTheme.backgroundWhite,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: responsive.wp(2.5),
                  height: responsive.wp(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPopular
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(width: responsive.wp(2.5)),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: responsive.sp(18),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      if (isHNI) ...[
                        SizedBox(width: responsive.wp(1)),
                        Icon(
                          Icons.info_outline,
                          size: responsive.sp(16),
                          color: AppTheme.textGrey,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey,
                  size: responsive.sp(24),
                ),
              ],
            ),
            SizedBox(height: responsive.hp(0.75)),
            Text(
              description,
              style: TextStyle(
                fontSize: responsive.sp(12),
                color: AppTheme.textBlack,
              ),
            ),
            SizedBox(height: responsive.hp(2)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        amount,
                        style: TextStyle(
                          fontSize: responsive.sp(24),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      if (isHNI)
                        Text(
                          '(Excl. GST)',
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: AppTheme.textGrey,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      perDay.split('\n')[0],
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    if (perDay.contains('\n'))
                      Text(
                        perDay.split('\n')[1],
                        style: TextStyle(
                          fontSize: responsive.sp(12),
                          color: AppTheme.textGrey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: responsive.hp(2)),
            for (String benefit in benefits)
              Padding(
                padding: responsive.padding(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: responsive.sp(18),
                    ),
                    SizedBox(width: responsive.wp(2)),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          fontSize: responsive.sp(14),
                          color: AppTheme.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
