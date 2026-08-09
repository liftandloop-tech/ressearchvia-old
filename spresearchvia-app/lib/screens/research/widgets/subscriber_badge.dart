import 'package:flutter/material.dart';

class SubscriberBadge extends StatelessWidget {
  const SubscriberBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFFFBEB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium, size: 20, color: Color(0xffF59E0B)),
          SizedBox(width: 8),
          Text(
            'For subscribed users only',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xff92400E),
            ),
          ),
        ],
      ),
    );
  }
}
