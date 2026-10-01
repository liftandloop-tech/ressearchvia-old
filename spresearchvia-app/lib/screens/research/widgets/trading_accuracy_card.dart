import 'package:flutter/material.dart';
import '../../../core/models/research_report.dart';
import '../../../core/theme/app_theme.dart';

class TradingAccuracyCard extends StatelessWidget {
  final TradingAccuracyStats stats;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final TradingCallOutcome? selectedOutcome;
  final ValueChanged<TradingCallOutcome?>? onSelectOutcome;
  final bool showFilterAction;

  const TradingAccuracyCard({
    super.key,
    required this.stats,
    this.title = 'Trading Calls Accuracy',
    this.subtitle,
    this.onTap,
    this.selectedOutcome,
    this.onSelectOutcome,
    this.showFilterAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasClosedCalls = stats.closedCalls > 0;
    final accuracyDisplay = hasClosedCalls
        ? '${stats.accuracyRate.toStringAsFixed(stats.accuracyRate.truncateToDouble() == stats.accuracyRate ? 0 : 1)}%'
        : (stats.totalCalls > 0 ? 'Evaluating' : '100%');

    final targetPercent = hasClosedCalls ? (stats.targetAchieved / stats.closedCalls * 100).round() : 0;
    final partialPercent = hasClosedCalls ? (stats.partiallyBooked / stats.closedCalls * 100).round() : 0;
    final slPercent = hasClosedCalls ? (stats.stoplossHit / stats.closedCalls * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: AppTheme.primaryBlueDark,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.1,
                            ),
                          ),
                          Text(
                            subtitle ?? (hasClosedCalls
                                ? '${stats.closedCalls} completed calls'
                                : (stats.totalCalls > 0 ? '${stats.totalCalls} calls active' : 'Live performance')),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Minimal Accuracy Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasClosedCalls && stats.accuracyRate >= 50
                            ? const Color(0xFFECFDF5)
                            : (hasClosedCalls ? const Color(0xFFFFFBEB) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasClosedCalls && stats.accuracyRate >= 50
                              ? const Color(0xFFA7F3D0)
                              : (hasClosedCalls ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasClosedCalls && stats.accuracyRate >= 50
                                  ? const Color(0xFF10B981)
                                  : (hasClosedCalls ? const Color(0xFFF59E0B) : const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$accuracyDisplay Accuracy',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: hasClosedCalls && stats.accuracyRate >= 50
                                  ? const Color(0xFF065F46)
                                  : (hasClosedCalls ? const Color(0xFF92400E) : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Sleek, Minimal Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 5,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: hasClosedCalls
                        ? Row(
                            children: [
                              if (stats.targetAchieved > 0)
                                Expanded(
                                  flex: stats.targetAchieved,
                                  child: Container(color: const Color(0xFF10B981)),
                                ),
                              if (stats.partiallyBooked > 0)
                                Expanded(
                                  flex: stats.partiallyBooked,
                                  child: Container(color: const Color(0xFFF59E0B)),
                                ),
                              if (stats.stoplossHit > 0)
                                Expanded(
                                  flex: stats.stoplossHit,
                                  child: Container(color: const Color(0xFFEF4444)),
                                ),
                            ],
                          )
                        : Container(color: const Color(0xFFE2E8F0)),
                  ),
                ),

                const SizedBox(height: 12),

                // 3 Minimal Metrics Breakdown Tiles
                Row(
                  children: [
                    Expanded(
                      child: _buildMinimalTile(
                        label: 'Target Hit',
                        count: stats.targetAchieved,
                        percentage: targetPercent,
                        color: const Color(0xFF059669),
                        dotColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFF0FDF4),
                        outcome: TradingCallOutcome.targetAchieved,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMinimalTile(
                        label: 'Partially Booked',
                        count: stats.partiallyBooked,
                        percentage: partialPercent,
                        color: const Color(0xFFD97706),
                        dotColor: const Color(0xFFF59E0B),
                        bgColor: const Color(0xFFFFFBEB),
                        outcome: TradingCallOutcome.partiallyBooked,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMinimalTile(
                        label: 'Stoploss Hit',
                        count: stats.stoplossHit,
                        percentage: slPercent,
                        color: const Color(0xFFDC2626),
                        dotColor: const Color(0xFFEF4444),
                        bgColor: const Color(0xFFFEF2F2),
                        outcome: TradingCallOutcome.stoplossHit,
                      ),
                    ),
                  ],
                ),

                // Active Calls footnote if present
                if (stats.active > 0 || (onTap != null && showFilterAction)) ...[
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (stats.active > 0)
                        InkWell(
                          onTap: onSelectOutcome != null
                              ? () => onSelectOutcome!(
                                    selectedOutcome == TradingCallOutcome.active
                                        ? null
                                        : TradingCallOutcome.active,
                                  )
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B82F6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${stats.active} Active ${stats.active == 1 ? "call" : "calls"} in progress',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10.5,
                                  fontWeight: selectedOutcome == TradingCallOutcome.active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (onTap != null && showFilterAction)
                        Row(
                          children: const [
                            Text(
                              'View calls',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 8,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalTile({
    required String label,
    required int count,
    required int percentage,
    required Color color,
    required Color dotColor,
    required Color bgColor,
    required TradingCallOutcome outcome,
  }) {
    final isSelected = selectedOutcome == outcome;

    final tile = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 9),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: 0.15),
          width: isSelected ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (stats.closedCalls > 0) ...[
                const SizedBox(width: 3),
                Text(
                  '($percentage%)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onSelectOutcome != null) {
      return InkWell(
        onTap: () {
          if (isSelected) {
            onSelectOutcome!(null);
          } else {
            onSelectOutcome!(outcome);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: tile,
      );
    }

    return tile;
  }
}
