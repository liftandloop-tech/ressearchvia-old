import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? badge;

  const InfoSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.badge,
    this.headerAction,
  });

  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: AppTheme.iconSizeDefault,
                color: AppTheme.primaryBlue,
              ),
              SizedBox(width: AppTheme.spacing8),
              Text(title, style: AppTheme.h5Style),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing12,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccessLight,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusTiny,
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.statusSuccess,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (headerAction != null) ...[const Spacer(), headerAction!],
            ],
          ),
          SizedBox(height: AppTheme.spacing16),
          child,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTheme.bodySmallStyle.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTheme.bodySmallStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
