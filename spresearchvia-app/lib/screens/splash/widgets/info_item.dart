import 'package:flutter/material.dart';

class InfoItem extends StatelessWidget {
  const InfoItem({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xffdde2ec),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(icon, size: 24, color: const Color(0xff163174)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xff6B7280),
          ),
        ),
      ],
    );
  }
}
