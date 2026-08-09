import 'package:flutter/material.dart';

class CurrentBadge extends StatelessWidget {
  const CurrentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffE5E7EB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'CURRENT',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xff163174),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
