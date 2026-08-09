import 'package:flutter/material.dart';

import 'button.dart';

class ReminderPopup extends StatelessWidget {
  const ReminderPopup({
    super.key,
    required this.onClose,
    required this.onRenew,
    required this.daysRemaining,
  });

  final void Function() onClose;
  final void Function() onRenew;
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onClose,
                  child: Icon(
                    Icons.close,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0x1A11416B),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF11416B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your subscription\nexpires in ${daysRemaining == 0 ? 'today' : '$daysRemaining day${daysRemaining == 1 ? '' : 's'}'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Renew now to continue access to premium research and analytics',
              textAlign: TextAlign.center,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Button(
              title: 'Renew Now',
              buttonType: ButtonType.green,
              onTap: onRenew,
            ),
            const SizedBox(height: 12),
            Button(
              title: 'Remind Me Later',
              buttonType: ButtonType.greyBorder,
              onTap: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
