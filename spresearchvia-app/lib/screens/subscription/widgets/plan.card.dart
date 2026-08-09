import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/app_dimensions.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.planName,
    required this.amount,
    required this.validity,
    required this.selected,
    this.popular = false,
    required this.onTap,
  });
  final String planName, validity;
  final int amount;
  final bool popular, selected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: responsive.padding(all: AppDimensions.paddingLarge),
        decoration: BoxDecoration(
          color: selected ? AppTheme.backgroundLightBlue : Colors.white,
          border: Border.all(
            width: AppDimensions.borderThick,
            color: selected ? AppTheme.primaryBlue : AppTheme.borderGrey,
          ),
          borderRadius: BorderRadius.circular(responsive.radius(AppDimensions.radiusMedium)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    planName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: responsive.sp(18),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(AppDimensions.spacing8)),
                Container(
                  width: responsive.spacing(24),
                  height: responsive.spacing(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppTheme.primaryBlue : Colors.white,
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryBlue
                          : AppTheme.borderGrey,
                      width: AppDimensions.borderThick,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: responsive.spacing(10),
                            height: responsive.spacing(10),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppDimensions.spacing12)),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: responsive.spacing(AppDimensions.spacing8),
              children: [
                Text(
                  '₹${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: responsive.sp(28),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlueDark,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: responsive.spacing(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '(Excluding GST)',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: responsive.sp(13),
                          color: AppTheme.textGrey,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(AppDimensions.spacing4)),
                      Icon(
                        Icons.info,
                        size: responsive.spacing(AppDimensions.iconSmall),
                        color: AppTheme.textGrey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppDimensions.spacing8)),
            if (validity.contains('Key features:'))
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: validity.split('Key features:')[0]),
                    const TextSpan(
                      text: 'Key features:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textBlack,
                      ),
                    ),
                    TextSpan(text: validity.split('Key features:')[1]),
                  ],
                ),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: responsive.sp(14),
                  color: AppTheme.textGrey,
                  height: 1.5,
                ),
              )
            else
              Text(
                validity,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: responsive.sp(14),
                  color: AppTheme.textGrey,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
