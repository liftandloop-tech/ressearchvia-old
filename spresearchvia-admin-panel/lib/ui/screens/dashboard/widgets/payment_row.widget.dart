import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PaymentRow extends TableRow {
  PaymentRow({super.key, required Map<String, dynamic> payment})
    : super(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    (payment['user'] != null && payment['user'].isNotEmpty)
                        ? payment['user'][0]
                        : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(payment['user'] ?? 'Unknown'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(payment['plan'] ?? ''),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(payment['amount'] ?? ''),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(payment['date'] ?? ''),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        payment['status'] == 'Completed' ||
                            payment['status'] == 'Success'
                        ? AppTheme.successBg
                        : payment['status'] == 'Failed'
                        ? AppTheme.errorBg
                        : AppTheme.warningBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment['status'],
                    style: TextStyle(
                      color:
                          payment['status'] == 'Completed' ||
                              payment['status'] == 'Success'
                          ? AppTheme.success
                          : payment['status'] == 'Failed'
                          ? AppTheme.error
                          : AppTheme.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
