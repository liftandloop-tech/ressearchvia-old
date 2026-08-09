import 'package:flutter/material.dart';

abstract class AppTheme {
  static const Color primaryBlue = Color(0xff11416B);
  static const Color primaryBlueDark = Color(0xff163174);
  static const Color primaryGreen = Color(0xFF2C7F38);
  static const Color successGreen = Color(0xff22C55E);

  static const Color backgroundWhite = Colors.white;
  static const Color backgroundLightBlue = Color(0xffEFF6FF);

  static const Color profileCardBackground = Color(0xffF9FAFB);

  static const Color textBlack = Colors.black;
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xff6B7280);
  static const Color textGreyLight = Color(0xff9CA3AF);

  static const Color borderGrey = Color(0xffE5E7EB);
  static const Color borderBlue = primaryBlue;

  static const Color success = Color(0xFF2C7F38);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xff11416B);

  static const Color errorBackground = Color(0xffFEF2F2);
  static const Color errorBorder = Color(0xffFECACA);
  static const Color infoBackground = Color(0xffF3F4F6);
  static const Color infoBorder = Color(0xffD1D5DB);
  static const Color infoText = Color(0xff374151);

  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowMedium = Colors.black.withValues(alpha: 0.1);
  static Color shadowDark = Colors.black.withValues(alpha: 0.2);

  static const Color buttonGreen = primaryGreen;
  static const Color buttonBlue = primaryBlue;
  static Color buttonDisabled = Colors.grey.shade400;

  static const Color iconGrey = Color(0xff9CA3AF);
  static const Color iconRed = Color(0xFFDC2626);
  static const Color dividerGrey = Color(0xffE5E7EB);
}
