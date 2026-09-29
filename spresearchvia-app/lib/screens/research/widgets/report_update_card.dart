import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/research_report.dart';

class ReportUpdateCard extends StatelessWidget {
  final ReportUpdate update;
  final EdgeInsetsGeometry? margin;
  final bool compact;

  const ReportUpdateCard({
    super.key,
    required this.update,
    this.margin,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = update.normalizedStatus;

    Color bgColor;
    Color borderColor;
    Color badgeColor;
    String label;
    IconData icon;

    switch (status) {
      case 'stoploss_hit':
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFCA5A5);
        badgeColor = const Color(0xFFDC2626);
        label = 'Stoploss Hit';
        icon = Icons.cancel_outlined;
        break;
      case 'target_achieved':
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFF86EFAC);
        badgeColor = const Color(0xFF16A34A);
        label = 'Target Achieved';
        icon = Icons.check_circle_outline;
        break;
      case 'partial_profit':
        bgColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFFDBA74);
        badgeColor = const Color(0xFFEA580C);
        label = 'Partial Profit';
        icon = Icons.monetization_on_outlined;
        break;
      default:
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        badgeColor = const Color(0xFF475569);
        label = 'Update';
        icon = Icons.info_outline;
        break;
    }

    final formattedTime = DateFormat('dd/MM/yyyy hh:mm a').format(update.timestamp);

    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.only(bottom: compact ? 8 : 12),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 8,
                  vertical: compact ? 2 : 3,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: compact ? 11 : 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: compact ? 11 : 13,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: compact ? 10 : 11,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (update.text.isNotEmpty) ...[
            SizedBox(height: compact ? 6 : 8),
            Text(
              update.text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: compact ? 12 : 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
