import 'package:flutter/material.dart';

class AppTheme {
  // Base Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Primary Blues
  static const Color primaryBlue = Color(0xFF11416B);
  static const Color darkBlue = Color(0xFF111827);
  static const Color navyBlue = Color(0xFF163174);
  static const Color lightBlue = Color(0xFF1D4ED8);
  static const Color skyBlue = Color(0xFF2563EB);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color paleBlue = Color(0xFF4B5563);

  // Greens
  static const Color successGreen = Color(0xFF2C7F38);
  static const Color darkGreen = Color(0xFF166534);
  static const Color mediumGreen = Color(0xFF15803D);
  static const Color lightGreen = Color(0xFF16A34A);
  static const Color paleGreen = Color(0xFFDCFCE7);
  static const Color mintGreen = Color(0xFFBBF7D0);

  // Reds
  static const Color errorRed = Color(0xFFEF4444);
  static const Color darkRed = Color(0xFFDC2626);
  static const Color crimsonRed = Color(0xFF9A3412);
  static const Color lightRed = Color(0xFFD9534F);

  // Yellows/Oranges
  static const Color warningYellow = Color(0xFFCA8A04);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color amber = Color(0xFFEAB308);
  static const Color lightYellow = Color(0xFFFEF3C7);
  static const Color paleYellow = Color(0xFFFFF7ED);
  static const Color orange = Color(0xFFEA580C);
  static const Color darkOrange = Color(0xFF854D0E);
  static const Color lightOrange = Color(0xFFF97316);
  static const Color peach = Color(0xFFFCA5A5);
  static const Color upgradeGreen = Color(0xFF10B981);

  // Grays
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Purples
  static const Color purple = Color(0xFF6366F1);
  static const Color darkPurple = Color(0xFFA855F7);
  static const Color purpleAvatar = Color(0xFF9B59B6);

  // Pinks
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkAvatar = Color(0xFFE91E63);

  // Teals
  static const Color teal = Color(0xFF10B981);

  // Additional UI Colors from Figma
  static const Color actionCardBlue = Color(0xFF5DADE2);
  static const Color actionCardGreen = Color(0xFF28A745);
  static const Color actionCardLightGreen = Color(
    0xFF58D68D,
  ); // Added new color
  static const Color actionCardNavy = Color(0xFF2E5A87);
  static const Color loginBackground = Color(0xFF8FA8BB);
  static const Color infoButtonBlue = Color(0xFF0066FF);
  static const Color orangeNotification = Color(0xFFF39C12);
  static const Color lightGreenBg = Color(0xFFF0FDF4);
  static const Color lightBlueBg = Color(0xFFEFF6FF);

  // Background Colors
  static const Color backgroundColor = gray50;
  static const Color backgroundLight = gray50;
  static const Color cardColor = white;
  static const Color cardBgWhite = white;
  static const Color welcomeCardColor = primaryBlue;

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = gray500;
  static const Color textTertiary = gray400;
  static const Color textWhite = white;
  static const Color textDark = Color(0xFF374151);

  // Border Colors
  static const Color border = gray200;
  static const Color borderLight = Color(0xFFE9ECEF);
  static const Color borderDark = Color(0xFFCED4DA);
  static const Color borderGray = Color(0xFFADAEBC);

  // Status Colors
  static const Color success = successGreen;
  static const Color successBg = Color(0xFFD4EDDA);
  static const Color statusSuccess = successGreen;
  static const Color statusSuccessLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningBg = Color(0xFFFFF3CD);
  static const Color statusWarning = warningYellow;
  static const Color statusWarningLight = Color(0xFFFEF3C7);
  static const Color error = errorRed;
  static const Color errorBg = Color(0xFFF8D7DA);
  static const Color statusError = errorRed;
  static const Color statusErrorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF5B9BD5);
  static const Color infoBg = Color(0xFFE3F2FD);
  static const Color pendingColor = warningYellow;

  // Button Colors
  static const Color buttonGreen = successGreen;
  static const Color buttonBlue = primaryBlue;
  static const Color buttonLightBlue = skyBlue;
  static const Color buttonGrey = gray500;
  static const Color buttonRed = errorRed;

  // Icon Colors
  static const Color iconGrey = gray500;
  static const Color iconDark = gray700;

  // Input Colors
  static const Color inputFill = Color(0xFFF8F9FA);
  static const Color inputBorder = borderDark;
  static const Color inputFocus = primaryBlue;

  // Legacy Aliases (for backward compatibility)
  static const Color whiteTextColor = textWhite;
  static const Color subtitleTextColor = textSecondary;
  static const Color textColor = textPrimary;
  static const Color borderColor = borderLight;
  static const Color cardBorderColor = white;
  static const Color successColor = success;
  static const Color errorColor = error;
  static const Color warningColor = warning;
  static const Color greenButtonColor = buttonGreen;
  static const Color inputBorderColor = inputBorder;
  static const Color inputFocusColor = inputFocus;
  static const Color inputFillColor = inputFill;
  static const Color iconColor = iconGrey;
  static const Color switchActiveColor = success;
  static const Color primaryColor = primaryBlue;
  static const Color primary = primaryBlue;
  static const Color whiteColor = textWhite;

  // Text Styles
  static const TextStyle welcomeTextStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textWhite,
    fontFamily: 'Poppins',
  );

  static const TextStyle dateTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textWhite,
    fontFamily: 'Poppins',
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    fontFamily: 'Poppins',
  );

  static const TextStyle cardValueStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle navItemStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    fontFamily: 'Poppins',
  );

  static const TextStyle navItemActiveStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryBlue,
    fontFamily: 'Poppins',
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textWhite,
    fontFamily: 'Poppins',
  );

  static const TextStyle tableHeaderStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    fontFamily: 'Poppins',
  );

  static const TextStyle tableDataStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle inputStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle copyrightStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    fontFamily: 'Poppins',
  );

  static const TextStyle h1Style = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle h2Style = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle h3Style = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle h4Style = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle h5Style = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle bodyLargeStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle bodySmallStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    fontFamily: 'Poppins',
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    fontFamily: 'Poppins',
  );

  static const TextStyle tinyStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    fontFamily: 'Poppins',
  );

  // Button Styles - Exact heights from Figma
  static ButtonStyle primaryButtonStyleLarge = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: primaryBlue,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: primaryBlue,
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static ButtonStyle primaryButtonStyleSmall = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: primaryBlue,
    minimumSize: const Size(0, 36),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  );

  static ButtonStyle greenButtonStyleLarge = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: buttonGreen,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  static ButtonStyle greenButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: buttonGreen,
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static ButtonStyle greenButtonStyleSmall = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: buttonGreen,
    minimumSize: const Size(0, 36),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  );

  static ButtonStyle blueButtonStyleLarge = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: infoButtonBlue,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  static ButtonStyle blueButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: infoButtonBlue,
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: textPrimary,
    backgroundColor: white,
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: gray300, width: 1),
    ),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static ButtonStyle grayButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: textPrimary,
    backgroundColor: gray100,
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration welcomeCardDecoration = BoxDecoration(
    color: primaryBlue,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration statsCardDecoration(Color bgColor) {
    return BoxDecoration(
      color: white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: gray200, width: 1),
    );
  }

  static BoxDecoration actionCardDecoration(Color bgColor) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
    );
  }

  static BoxDecoration whiteCardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: gray200, width: 1),
  );

  static BoxDecoration fileUploadDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: gray300, width: 2, style: BorderStyle.solid),
  );

  static InputDecoration inputDecoration(
    String hintText, {
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? labelText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorRed, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: gray700,
      ),
      hintStyle: const TextStyle(fontSize: 13, color: gray400),
    );
  }

  static InputDecoration inputDecorationLarge(
    String hintText, {
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? labelText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: gray300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: gray700,
      ),
      hintStyle: const TextStyle(fontSize: 14, color: gray400),
    );
  }

  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1200;

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;

  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;
  static const double cardWidth = 400;
  static const double cardPadding = 32;

  // Component Heights from Figma
  static const double buttonHeightLarge = 44;
  static const double buttonHeightDefault = 40;
  static const double buttonHeightSmall = 36;
  static const double inputHeightLarge = 48;
  static const double inputHeightDefault = 44;
  static const double inputHeightCompact = 40;
  static const double navBarHeight = 60;
  static const double tableHeaderHeight = 48;
  static const double tableRowHeight = 60;
  static const double modalWidthSmall = 420;
  static const double modalWidthMedium = 520;
  static const double modalWidthLarge = 600;
  static const double avatarSizeLarge = 80;
  static const double avatarSizeMedium = 48;
  static const double avatarSizeSmall = 36;
  static const double iconSizeLarge = 24;
  static const double iconSizeDefault = 20;
  static const double iconSizeSmall = 18;
  static const double iconSizeExtraSmall = 16;
  static const double checkboxSize = 18;
  static const double badgeHeight = 24;
  static const double borderRadiusLarge = 12;
  static const double borderRadiusDefault = 8;
  static const double borderRadiusSmall = 6;
  static const double borderRadiusTiny = 4;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint &&
        MediaQuery.of(context).size.width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return spacing16;
    if (isTablet(context)) return spacing24;
    return spacing32;
  }

  static ButtonStyle warningButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: warning,
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  static ButtonStyle errorButtonStyleLarge = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: error,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  static ButtonStyle errorButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: textWhite,
    backgroundColor: error,
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
  );

  // Modal & Shadow Decorations
  static BoxDecoration modalDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );

  static BoxShadow modalShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.15),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  static const TextStyle titleTextStyle = sectionTitleStyle;
  static const TextStyle titleSmallTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    fontFamily: 'Poppins',
  );
  static const TextStyle subtitleTextStyle = cardTitleStyle;
  static const TextStyle bodyTextStyle = tableDataStyle;
  static const TextStyle labelTextStyle = labelStyle;
  static const TextStyle linkTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryBlue,
    fontFamily: 'Poppins',
  );
  static const TextStyle copyrightTextStyle = copyrightStyle;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: gray50,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}
