import 'package:flutter/material.dart';
import '../../../core/models/research_report.dart';
import 'report_update_card.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
    required this.onTap,
    required this.onView,
    this.updates = const [],
    this.isLocked = false,
  });

  final String title;
  final String category;
  final String date;
  final String description;
  final VoidCallback onTap;
  final VoidCallback onView;
  final List<ReportUpdate> updates;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    // Determine latest update status for card accent
    final latestUpdate = updates.isNotEmpty ? updates.last : null;
    final latestStatus = latestUpdate?.normalizedStatus;

    Color? leftBorderColor;
    Color? latestBadgeColor;
    Color? latestBadgeBg;
    Color? latestBadgeBorder;
    String? latestLabel;
    IconData? latestIcon;

    if (latestStatus == 'stoploss_hit') {
      leftBorderColor = const Color(0xFFDC2626);
      latestBadgeColor = const Color(0xFFDC2626);
      latestBadgeBg = const Color(0xFFFEF2F2);
      latestBadgeBorder = const Color(0xFFFCA5A5);
      latestLabel = 'Stoploss Hit';
      latestIcon = Icons.cancel_outlined;
    } else if (latestStatus == 'target_achieved') {
      leftBorderColor = const Color(0xFF16A34A);
      latestBadgeColor = const Color(0xFF16A34A);
      latestBadgeBg = const Color(0xFFF0FDF4);
      latestBadgeBorder = const Color(0xFF86EFAC);
      latestLabel = 'Target Achieved';
      latestIcon = Icons.check_circle_outline;
    } else if (latestStatus == 'partial_profit') {
      leftBorderColor = const Color(0xFFEA580C);
      latestBadgeColor = const Color(0xFFEA580C);
      latestBadgeBg = const Color(0xFFFFF7ED);
      latestBadgeBorder = const Color(0xFFFDBA74);
      latestLabel = 'Partial Profit';
      latestIcon = Icons.monetization_on_outlined;
    }

    final baseCard = GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leftBorderColor != null)
                Container(
                  width: 4.5,
                  color: leftBorderColor,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff163174),
                                  ),
                                ),
                                if (latestLabel != null && latestBadgeColor != null) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: latestBadgeBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: latestBadgeBorder!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(latestIcon, size: 12, color: latestBadgeColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          latestLabel,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: latestBadgeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: onView,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xff2C7F38),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.visibility,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff6B7280),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff4B5563),
                          height: 1.5,
                        ),
                      ),
                      if (updates.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 14,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Updates (${updates.length}):',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...updates.reversed.map(
                          (update) => ReportUpdateCard(
                            update: update,
                            compact: true,
                            margin: const EdgeInsets.only(top: 6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Wrap with blur overlay if locked
    if (isLocked) {
      return Stack(
        children: [
          baseCard,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: const Color(0xff163174).withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content published before\nyour plan started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff163174).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return baseCard;
  }
}
