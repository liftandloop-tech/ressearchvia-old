import 'package:flutter/material.dart';
import '../../../core/models/subscription_history.dart';
import 'status_badge.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.planName,
    required this.startDate,
    this.remainingAmount,
    required this.amountPaid,
    required this.validityDays,
    required this.perDayCost,
    required this.headerStatus,
    this.footerStatus,
    this.isPartial = false,
    this.onViewInstallments,
    this.onPayInstallment,
    this.onTap,
  });

  final String planName;
  final String startDate; // Renamed from paymentDate
  final String? remainingAmount;
  final String amountPaid;
  final String validityDays;
  final String perDayCost;
  final SubscriptionStatus headerStatus;
  final SubscriptionStatus? footerStatus;
  final bool isPartial;
  final VoidCallback? onViewInstallments;
  final VoidCallback? onPayInstallment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    String formatDate(String value) {
      try {
        if (value.trim().isEmpty) return '-';

        // Try to parse as ISO date
        final dt = DateTime.tryParse(value);
        if (dt != null) {
          final localDt = dt.toLocal();
          const months = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          final dd = localDt.day.toString().padLeft(2, '0');
          final mon = months[localDt.month - 1];
          final yyyy = localDt.year.toString();
          return '$dd $mon $yyyy';
        }

        // If not ISO, return as-is (already formatted like "Jan 1, 2025")
        return value;
      } catch (_) {
        return value;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffE5E7EB), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Plan Name - Segment Name + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff163174),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isPartial)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: const Text(
                            "PARTIAL PAYMENT",
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: headerStatus),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xffE5E7EB)),
            const SizedBox(height: 12),

            // Row 2: Start Date & Plan Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Date',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      Text(
                        formatDate(startDate),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plan Duration',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      Text(
                        validityDays,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: Per Day Cost & Plan Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Per Day Cost',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      Text(
                        perDayCost,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plan Status',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      Text(
                         // Display readable status
                         headerStatus == SubscriptionStatus.active ? 'Active' :
                         headerStatus == SubscriptionStatus.expired ? 'Expired' :
                         headerStatus == SubscriptionStatus.failed ? 'Failed' :
                         headerStatus == SubscriptionStatus.pending ? 'Pending' : 
                         headerStatus == SubscriptionStatus.suspended ? 'Suspended' : 'Success',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: headerStatus == SubscriptionStatus.active ? const Color(0xff16A34A) :
                                 headerStatus == SubscriptionStatus.expired ? const Color(0xffEF4444) :
                                 headerStatus == SubscriptionStatus.suspended ? const Color(0xffF59E0B) :
                                 const Color(0xff6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 4: Total Service Price & Remaining Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Service Price ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      Text(
                        amountPaid,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remaining Amount',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      Text(
                        remainingAmount?.isNotEmpty == true ? remainingAmount! : '-',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPartial && (onViewInstallments != null || onPayInstallment != null)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xffE5E7EB)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onViewInstallments != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewInstallments,
                        icon: const Icon(Icons.list_alt, size: 18),
                        label: const Text("View History"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff163174),
                          side: const BorderSide(color: Color(0xff163174)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  if (onViewInstallments != null && onPayInstallment != null)
                    const SizedBox(width: 12),
                  if (onPayInstallment != null && (headerStatus == SubscriptionStatus.active || headerStatus == SubscriptionStatus.pending))
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPayInstallment,
                        icon: const Icon(Icons.add_card, size: 18),
                        label: const Text("Pay Installment"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff163174),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
