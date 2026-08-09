import 'package:flutter/material.dart';
import 'card_type_logo.dart';

class PaymentMethodCard extends StatelessWidget {
  const PaymentMethodCard({
    super.key,
    required this.cardType,
    required this.cardNumber,
    required this.expiryDate,
  });

  final String cardType;
  final String cardNumber;
  final String expiryDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          CardTypeLogo(cardType: cardType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardNumber,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expiryDate,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xff6B7280),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xff10B981), size: 24),
        ],
      ),
    );
  }
}
