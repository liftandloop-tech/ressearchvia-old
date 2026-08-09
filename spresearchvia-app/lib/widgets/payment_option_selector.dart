import 'package:flutter/material.dart';
import '../core/models/payment.options.dart';
import '../core/theme/app_theme.dart';

class PaymentOptionSelector extends StatelessWidget {
  const PaymentOptionSelector({
    super.key,
    required this.selectedMethod,
    required this.onChoose,
  });

  final PaymentMethod? selectedMethod;
  final void Function(PaymentMethod) onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 15),
        ...PaymentOption.options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PaymentMethodTile(
              icon: option.icon,
              title: option.title,
              selected: selectedMethod == option.method,
              onTap: () => onChoose(option.method),
            ),
          );
        }),
      ],
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.backgroundLightBlue : Colors.white,
          border: Border.all(
            width: 2,
            color: selected ? AppTheme.primaryBlue : AppTheme.borderGrey,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? AppTheme.primaryBlue : AppTheme.textGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? AppTheme.primaryBlueDark
                      : AppTheme.textGrey,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppTheme.primaryBlue : Colors.white,
                border: Border.all(
                  color: selected ? AppTheme.primaryBlue : AppTheme.borderGrey,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
