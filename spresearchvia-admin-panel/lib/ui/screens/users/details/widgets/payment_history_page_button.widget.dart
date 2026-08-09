import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PaymentHistoryPageButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onTap;

  const PaymentHistoryPageButton({
    super.key,
    required this.text,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusTiny),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : AppTheme.gray300,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTheme.captionStyle.copyWith(
              color: isActive ? AppTheme.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
