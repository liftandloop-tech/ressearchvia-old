import 'package:flutter/material.dart';

class KycVerificationCard extends StatelessWidget {
  const KycVerificationCard({
    super.key,
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(icon),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: _getIconColor(icon), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xff374151),
            ),
          ),
        ],
      ),
    );
  }

  Color _getIconBackgroundColor(IconData icon) {
    if (icon == Icons.phone_android_outlined) {
      return const Color(0xffFEF3C7);
    } else if (icon == Icons.description_outlined) {
      return const Color(0xffD1FAE5);
    } else if (icon == Icons.verified_outlined) {
      return const Color(0xffDEE7F7);
    }
    return const Color(0xffF3F4F6);
  }

  Color _getIconColor(IconData icon) {
    if (icon == Icons.phone_android_outlined) {
      return const Color(0xffF59E0B);
    } else if (icon == Icons.description_outlined) {
      return const Color(0xff10B981);
    } else if (icon == Icons.verified_outlined) {
      return const Color(0xff3B82F6);
    }
    return const Color(0xff6B7280);
  }
}
