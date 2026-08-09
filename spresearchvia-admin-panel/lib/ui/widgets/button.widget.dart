import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

enum ButtonType { green, blue, lightBlue, grey, red, white }

enum ButtonSize { large, medium, small }

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.title,
    required this.buttonType,
    this.onTap,
    this.icon,
    this.iconRight,
    this.showLoading = false,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
  });

  final String title;
  final ButtonType buttonType;
  final GestureTapCallback? onTap;
  final IconData? icon;
  final IconData? iconRight;
  final bool showLoading;
  final ButtonSize size;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;
    Color? borderColor;
    double height;
    double fontSize;
    FontWeight fontWeight;
    double iconSize;
    double horizontalPadding;

    switch (size) {
      case ButtonSize.large:
        height = AppTheme.buttonHeightLarge;
        fontSize = 14;
        fontWeight = FontWeight.w600;
        iconSize = 20;
        horizontalPadding = 20;
        break;
      case ButtonSize.medium:
        height = AppTheme.buttonHeightDefault;
        fontSize = 14;
        fontWeight = FontWeight.w500;
        iconSize = 18;
        horizontalPadding = 20;
        break;
      case ButtonSize.small:
        height = AppTheme.buttonHeightSmall;
        fontSize = 13;
        fontWeight = FontWeight.w500;
        iconSize = 16;
        horizontalPadding = 16;
        break;
    }

    switch (buttonType) {
      case ButtonType.green:
        backgroundColor = onTap != null
            ? AppTheme.buttonGreen
            : AppTheme.buttonGrey;
        textColor = AppTheme.textWhite;
        iconColor = AppTheme.textWhite;
        borderColor = null;
        break;

      case ButtonType.blue:
        backgroundColor = onTap != null
            ? AppTheme.infoButtonBlue
            : AppTheme.buttonGrey;
        textColor = AppTheme.textWhite;
        iconColor = AppTheme.textWhite;
        borderColor = null;
        break;

      case ButtonType.lightBlue:
        backgroundColor = onTap != null
            ? AppTheme.skyBlue
            : AppTheme.buttonGrey;
        textColor = AppTheme.textWhite;
        iconColor = AppTheme.textWhite;
        borderColor = null;
        break;

      case ButtonType.grey:
        backgroundColor = AppTheme.gray100;
        textColor = AppTheme.textPrimary;
        iconColor = AppTheme.textPrimary;
        borderColor = null;
        break;

      case ButtonType.red:
        backgroundColor = onTap != null
            ? AppTheme.buttonRed
            : AppTheme.buttonGrey;
        textColor = AppTheme.textWhite;
        iconColor = AppTheme.textWhite;
        borderColor = null;
        break;

      case ButtonType.white:
        backgroundColor = AppTheme.white;
        textColor = AppTheme.textPrimary;
        iconColor = AppTheme.textPrimary;
        borderColor = AppTheme.gray300;
        break;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          width: fullWidth ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
            border: borderColor != null
                ? Border.all(color: borderColor, width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: iconSize),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  fontFamily: 'Poppins',
                ),
              ),
              if (iconRight != null) ...[
                const SizedBox(width: 8),
                Icon(iconRight, color: iconColor, size: iconSize),
              ],
              if (showLoading) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LinkTextIcon extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Widget? icon;

  const LinkTextIcon({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Text(text, style: AppTheme.linkTextStyle),
        ],
      ),
    );
  }
}
