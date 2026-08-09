import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/models/plan.dart';
import '../core/utils/responsive.dart';
import 'info_column.dart';

class ActivePlanCard extends StatelessWidget {
  const ActivePlanCard({
    super.key,
    required this.plan,
    required this.startDateText,
    required this.remainingAmountText,
    required this.perDayCost,
    required this.totalPaid,
    required this.completionPercentage,
    required this.daysElapsed,
    required this.totalDays,
    this.onRenew,
    this.onViewInvoice,
    this.tags = const ['Index Option', 'Trader'],
  });

  final Plan plan;
  final String startDateText;
  final String remainingAmountText;
  final int perDayCost;
  final double totalPaid;
  final int completionPercentage;
  final int daysElapsed;
  final int totalDays;
  final VoidCallback? onRenew;
  final VoidCallback? onViewInvoice;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowMedium,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(responsive.radius(16)),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: AppTheme.primaryBlue, width: 6),
            ),
          ),
          child: Padding(
            padding: responsive.padding(all: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: responsive.sp(16),
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlueDark,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Container(
                      padding: responsive.padding(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          responsive.radius(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: responsive.wp(1.5),
                            height: responsive.wp(1.5),
                            decoration: const BoxDecoration(
                              color: AppTheme.successGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: responsive.wp(1.2)),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: responsive.sp(12),
                              fontWeight: FontWeight.w500,
                              color: AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.hp(1.5)),
                Row(
                  children: [
                    if (tags.isNotEmpty)
                      Container(
                        padding: responsive.padding(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.infoBackground,
                          borderRadius: BorderRadius.circular(
                            responsive.radius(6),
                          ),
                        ),
                        child: Text(
                          tags[0],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: responsive.sp(12),
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
                    if (tags.length > 1) ...[
                      SizedBox(width: responsive.wp(3)),
                      Text(
                        tags[1],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: responsive.sp(12),
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: responsive.hp(2.5)),
                Container(
                  padding: responsive.padding(all: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBackground.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(responsive.radius(8)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InfoColumn(
                          label: 'Start Date',
                          value: startDateText,
                          responsive: responsive,
                        ),
                      ),
                      Expanded(
                        child: InfoColumn(
                          label: 'Remaining Amount',
                          value: remainingAmountText,
                          responsive: responsive,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.hp(2.5)),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Container(
                          padding: responsive.padding(all: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              responsive.radius(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Per Day Cost',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: responsive.sp(12),
                                  color: AppTheme.textGrey,
                                ),
                              ),
                              SizedBox(height: responsive.hp(0.5)),
                              Text(
                                '₹$perDayCost',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: responsive.sp(20),
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlueDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: responsive.wp(3)),
                      Expanded(
                        child: Container(
                          padding: responsive.padding(all: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              responsive.radius(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Total Service Price',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: responsive.sp(12),
                                  color: AppTheme.textGrey,
                                ),
                              ),
                              SizedBox(height: responsive.hp(0.5)),
                              Text(
                                '₹${totalPaid.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: responsive.sp(20),
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                              SizedBox(height: responsive.hp(0.25)),
                              Text(
                                'Excl. GST',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: responsive.sp(10),
                                  color: AppTheme.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.hp(2.5)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Plan Duration',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: responsive.sp(12),
                        color: AppTheme.textGrey,
                      ),
                    ),
                    Text(
                      '$daysElapsed/$totalDays Days',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: responsive.sp(12),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.hp(1)),
                ClipRRect(
                  borderRadius: BorderRadius.circular(responsive.radius(4)),
                  child: LinearProgressIndicator(
                    value: completionPercentage / 100,
                    minHeight: responsive.hp(1),
                    backgroundColor: AppTheme.borderGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.successGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
