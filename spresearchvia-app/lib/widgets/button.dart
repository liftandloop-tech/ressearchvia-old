import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/app_styles.dart';
import '../core/constants/app_dimensions.dart';
import '../core/utils/responsive.dart';

enum ButtonType { green, blue, blueBorder, greyBorder, red }

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.title,
    required this.buttonType,
    this.onTap,
    this.icon,
    this.iconRight,
    this.showLoading = false,
  });

  final String title;
  final ButtonType buttonType;
  final GestureTapCallback? onTap;
  final IconData? icon;
  final IconData? iconRight;
  final bool showLoading;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    Color backgroundColor;
    Color textColor;
    Color iconColor;
    Color? borderColor;

    switch (buttonType) {
      case ButtonType.green:
        backgroundColor = onTap != null
            ? AppTheme.buttonGreen
            : AppTheme.buttonDisabled;
        textColor = AppTheme.textWhite;
        iconColor = AppTheme.textWhite;
        borderColor = null;
        break;

      case ButtonType.blue:
        backgroundColor = onTap != null
            ? AppTheme.buttonBlue
            : AppTheme.buttonDisabled;
        textColor = AppTheme.textWhite;
        iconColor = AppTheme.textWhite;
        borderColor = null;
        break;

      case ButtonType.blueBorder:
        backgroundColor = AppTheme.backgroundWhite;
        textColor = AppTheme.primaryBlue;
        iconColor = AppTheme.primaryBlue;
        borderColor = AppTheme.primaryBlue;
        break;

      case ButtonType.greyBorder:
        backgroundColor = AppTheme.backgroundWhite;
        textColor = AppTheme.textBlack;
        iconColor = AppTheme.textBlack;
        borderColor = AppTheme.borderGrey;
        break;

      case ButtonType.red:
        backgroundColor = onTap != null ? Colors.red : AppTheme.buttonDisabled;
        textColor = AppTheme.textWhite;
        iconColor = AppTheme.textWhite;
        borderColor = null;
        break;
    }

    final buttonHeight = responsive.spacing(AppDimensions.buttonHeight);
    final borderRadius = responsive.radius(AppDimensions.radiusButton);
    final iconSize = responsive.spacing(AppDimensions.iconMedium);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: buttonHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderColor != null
              ? Border.all(
                  color: borderColor,
                  width: AppDimensions.borderMedium,
                )
              : null,
          boxShadow: buttonType == ButtonType.greyBorder
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.shadowMedium,
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: AppTheme.shadowMedium,
                    blurRadius: 3,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: iconSize),
              SizedBox(width: responsive.spacing(AppDimensions.spacing8)),
            ],
            Text(
              title,
              style: AppStyles.button.copyWith(
                color: textColor,
                fontSize: responsive.sp(16),
              ),
            ),
            if (iconRight != null) ...[
              SizedBox(width: responsive.spacing(AppDimensions.spacing8)),
              Icon(iconRight, color: iconColor, size: iconSize),
            ],
            if (showLoading) ...[
              SizedBox(width: responsive.spacing(AppDimensions.spacing8)),
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
