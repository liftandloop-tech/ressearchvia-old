import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';

class PaymentOption extends StatelessWidget {
  final int value;
  final RxInt groupValue;
  final String title;
  final IconData icon;

  const PaymentOption({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: groupValue.value == value
                ? AppTheme.primaryBlue
                : AppTheme.borderGrey,
          ),
          borderRadius: BorderRadius.circular(8),
          color: groupValue.value == value
              ? const Color(0xFFF0F9FF)
              : Colors.white,
        ),
        child: ListTile(
          onTap: () => groupValue.value = value,
          leading: Icon(
            groupValue.value == value
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: groupValue.value == value
                ? AppTheme.primaryBlue
                : AppTheme.textGrey,
          ),
          title: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: groupValue.value == value
                    ? AppTheme.primaryBlue
                    : AppTheme.textGrey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textBlack,
                  ),
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          dense: true,
        ),
      ),
    );
  }
}
