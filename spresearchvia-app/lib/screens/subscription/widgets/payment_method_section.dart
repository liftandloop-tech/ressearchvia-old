import 'package:flutter/material.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';
import 'package:spresearchvia/services/snackbar.service.dart';
import 'package:spresearchvia/widgets/payment_method_card.dart';

class PaymentMethodSection extends StatelessWidget {
  final bool isLoadingPayment;
  final PaymentMethodData? savedPaymentMethod;

  const PaymentMethodSection({
    super.key,
    required this.isLoadingPayment,
    required this.savedPaymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingPayment) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (savedPaymentMethod == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(Icons.payment, size: 48, color: AppTheme.textGrey),
            const SizedBox(height: 12),
            const Text(
              'No payment method saved',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlueDark,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                SnackbarService.showInfo(
                  'Add payment method feature will be available soon',
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Payment Method'),
            ),
          ],
        ),
      );
    }

    return PaymentMethodCard(
      paymentMethod: savedPaymentMethod!,
      onTap: () {
        SnackbarService.showInfo(
          'Change payment method feature will be available soon',
        );
      },
    );
  }
}
