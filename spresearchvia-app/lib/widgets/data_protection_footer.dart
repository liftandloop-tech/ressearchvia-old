import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/responsive.dart';

class DataProtectionFooter extends StatelessWidget {
  const DataProtectionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      padding: responsive.padding(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: AppTheme.textGrey,
                size: responsive.sp(16),
              ),
              SizedBox(width: responsive.wp(1)),
              Text(
                'Bank-grade security',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: responsive.sp(12),
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
          SizedBox(width: responsive.wp(4)),
          Row(
            children: [
              Icon(
                Icons.lock_outlined,
                color: AppTheme.textGrey,
                size: responsive.sp(16),
              ),
              SizedBox(width: responsive.wp(1)),
              Text(
                '256-bit encryption',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: responsive.sp(12),
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
