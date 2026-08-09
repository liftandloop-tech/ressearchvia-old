import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class DashboardLogo extends StatelessWidget {
  const DashboardLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/sp_logo.png',
      height: 32,
      errorBuilder: (context, error, stackTrace) => Row(
        children: [
          Text(
            'SP',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          Text(
            'RESEARCH',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.successGreen,
            ),
          ),
          Text(
            'VIA PVT. LTD.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
