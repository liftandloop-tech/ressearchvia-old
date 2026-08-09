import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';

class BenefitsCard extends StatelessWidget {
  const BenefitsCard({
    super.key,
    required this.benefits,
    this.title = 'What you\'ll continue to get:',
  });

  final List<String> benefits;
  final String title;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppTheme.profileCardBackground,
        borderRadius: BorderRadius.circular(responsive.radius(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: responsive.sp(14),
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlueDark,
            ),
          ),
          SizedBox(height: responsive.hp(1.5)),
          ...benefits.map(
            (benefit) => Padding(
              padding: responsive.padding(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successGreen,
                    size: responsive.sp(20),
                  ),
                  SizedBox(width: responsive.wp(3)),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: responsive.sp(14),
                        color: AppTheme.primaryBlueDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
