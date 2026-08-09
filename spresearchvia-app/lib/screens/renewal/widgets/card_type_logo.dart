import 'package:flutter/material.dart';

class CardTypeLogo extends StatelessWidget {
  const CardTypeLogo({super.key, required this.cardType});

  final String cardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xff1A1F71),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          cardType,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
