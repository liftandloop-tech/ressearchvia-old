import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String type;

  const StatusBadge({super.key, required this.status, this.type = 'default'});

  Color get _backgroundColor {
    final statusLower = status.toLowerCase();

    switch (type) {
      case 'subscription':
        if (statusLower == 'active') return AppTheme.lightGreen;
        if (statusLower == 'expired') return AppTheme.errorRed;
        if (statusLower == 'cancelled') return AppTheme.gray500;
        return AppTheme.warningYellow;

      case 'kyc':
        if (statusLower == 'verified') return AppTheme.lightGreen;
        if (statusLower == 'rejected') return AppTheme.errorRed;
        return AppTheme.warningYellow;

      case 'report':
        if (statusLower == 'published') return AppTheme.lightGreen;
        if (statusLower == 'unpublished') return AppTheme.errorRed;
        if (statusLower == 'draft') return AppTheme.warningYellow;
        return AppTheme.gray500;

      case 'payment':
        if (statusLower == 'completed' || statusLower == 'success') {
          return AppTheme.lightGreen;
        }
        if (statusLower == 'failed') {
          return AppTheme.errorRed;
        }
        if (statusLower == 'pending') {
          return AppTheme.warningYellow;
        }
        return AppTheme.gray500;

      case 'renewal':
        if (statusLower == 'renewed') return AppTheme.lightGreen;
        if (statusLower == 'not renewed') return AppTheme.errorRed;
        if (statusLower.contains('expiring')) return AppTheme.warningYellow;
        return AppTheme.gray500;

      case 'staff':
        if (statusLower == 'active') return AppTheme.lightGreen;
        if (statusLower == 'inactive') return AppTheme.errorRed;
        return AppTheme.gray500;

      default:
        return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusTiny),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
