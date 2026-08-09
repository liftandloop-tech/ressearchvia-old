import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final bool showSubtitle;
  final bool fullWidth;

  const AppLogo({
    super.key,
    this.fontSize = 24,
    this.showSubtitle = true,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/sp_logo.png',
      height: fullWidth ? null : fontSize * 1.5,
      width: fullWidth ? double.infinity : null,
      fit: fullWidth ? BoxFit.contain : null,
      errorBuilder: (context, error, stackTrace) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SP',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            'RESEARCH',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.greenButtonColor,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            'VIA PVT. LTD.',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
