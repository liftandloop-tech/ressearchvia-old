import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';

class AlertItem extends StatelessWidget {
  final String label;
  final bool enabled;
  final ValueChanged<bool?>? onChanged;

  const AlertItem({
    super.key,
    required this.label,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Checkbox(
                value: enabled,
                onChanged: onChanged ?? (v) {},
                activeColor: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                enabled ? AppStrings.enabled : AppStrings.disabled,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: enabled
                      ? AppTheme.successGreen
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
