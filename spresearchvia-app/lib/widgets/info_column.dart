import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';

class InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final Responsive responsive;

  const InfoColumn({
    super.key,
    required this.label,
    required this.value,
    required this.responsive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: responsive.sp(12),
            color: AppTheme.textGrey,
          ),
        ),
        SizedBox(height: responsive.hp(0.5)),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: responsive.sp(14),
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlueDark,
          ),
        ),
      ],
    );
  }
}
