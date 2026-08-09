import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';

class PlanDisplayCard extends StatelessWidget {
  const PlanDisplayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.priceUnit,
    required this.validity,
    this.originalPrice,
    this.badge,
    this.isSelected = false,
    this.isDark = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final String priceUnit;
  final String validity;
  final String? originalPrice;
  final String? badge;
  final bool isSelected;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: responsive.padding(all: AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.primaryBlueDark : Colors.white,
          border: Border.all(color: AppTheme.borderGrey, width: AppDimensions.borderThin),
          borderRadius: BorderRadius.circular(responsive.radius(AppDimensions.radiusLarge)),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 2),
              blurRadius: 8,
              color: AppTheme.shadowLight,
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
                        title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: responsive.sp(20),
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.primaryBlueDark,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(AppDimensions.spacing4)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: responsive.sp(14),
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: responsive.spacing(AppDimensions.spacing12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (originalPrice != null) ...[
                      Text(
                        originalPrice!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: responsive.sp(14),
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.5),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(2)),
                    ],
                    Text(
                      price,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: responsive.sp(28),
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.primaryBlueDark,
                      ),
                    ),
                    Text(
                      priceUnit,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: responsive.sp(12),
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppDimensions.spacing16)),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: responsive.spacing(AppDimensions.spacing8),
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryGreen,
                  size: responsive.spacing(AppDimensions.iconMedium),
                ),
                Text(
                  validity,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: responsive.sp(14),
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppTheme.primaryBlueDark,
                  ),
                ),
              ],
            ),
            if (badge != null) ...[
              SizedBox(height: responsive.spacing(AppDimensions.spacing12)),
              Container(
                padding: responsive.padding(
                  horizontal: AppDimensions.spacing12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff1E4A7C),
                  borderRadius: BorderRadius.circular(responsive.radius(AppDimensions.radiusSmall)),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: responsive.sp(12),
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
