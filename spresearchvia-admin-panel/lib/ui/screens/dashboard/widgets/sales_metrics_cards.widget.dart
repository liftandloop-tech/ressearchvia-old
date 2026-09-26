import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';
import 'metric_data_popup.widget.dart';

class SalesMetricsCards extends StatelessWidget {
  const SalesMetricsCards({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Obx(() {
      final totalSales = controller.totalSalesAmount;
      final totalOrders = controller.totalOrders;
      final activeStaff = controller.activeStaffCount;
      final avgOrderVal = controller.avgOrderValue;
      final conversion = controller.conversionRate;
      final topStaff = controller.topPerformingStaff;

      final topStaffName = topStaff != null ? (topStaff['name'] ?? 'Staff Member') : 'None';
      final topStaffRevenue = topStaff != null ? currencyFormatter.format((topStaff['totalSalesAmount'] ?? 0).toDouble()) : '₹0';

      return LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1000;
          final cardWidth = isDesktop
              ? (constraints.maxWidth - 40) / 3
              : (constraints.maxWidth > 600 ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _InteractiveMetricCard(
                title: 'Total Sales Revenue',
                value: currencyFormatter.format(totalSales),
                icon: Icons.payments_rounded,
                color: AppTheme.primaryBlue,
                badge: 'Live',
                badgeColor: Colors.green,
                subtitle: 'Overall generated sales volume',
                width: cardWidth,
                onTap: () => MetricDataPopup.show(
                  context,
                  type: MetricCardType.totalSales,
                  controller: controller,
                ),
              ),
              _InteractiveMetricCard(
                title: 'Purchases',
                value: totalOrders.toString(),
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFF10B981),
                badge: 'Active',
                badgeColor: Colors.teal,
                subtitle: 'Completed purchase transactions',
                width: cardWidth,
                onTap: () => MetricDataPopup.show(
                  context,
                  type: MetricCardType.purchases,
                  controller: controller,
                ),
              ),
              _InteractiveMetricCard(
                title: 'Active Sales Staff',
                value: activeStaff.toString(),
                icon: Icons.groups_rounded,
                color: Colors.purple,
                badge: 'Staff',
                badgeColor: Colors.purple,
                subtitle: 'Representatives handling clients',
                width: cardWidth,
                onTap: () => MetricDataPopup.show(
                  context,
                  type: MetricCardType.activeStaff,
                  controller: controller,
                ),
              ),
              _InteractiveMetricCard(
                title: 'Average Order Value (AOV)',
                value: currencyFormatter.format(avgOrderVal),
                icon: Icons.trending_up_rounded,
                color: Colors.orange,
                badge: 'AOV',
                badgeColor: Colors.orange,
                subtitle: 'Average revenue per order',
                width: cardWidth,
                onTap: () => MetricDataPopup.show(
                  context,
                  type: MetricCardType.avgOrderValue,
                  controller: controller,
                ),
              ),
              _InteractiveMetricCard(
                title: 'Sales Conversion Rate',
                value: '$conversion%',
                icon: Icons.pie_chart_rounded,
                color: Colors.indigo,
                badge: 'Conversion',
                badgeColor: Colors.indigo,
                subtitle: 'Orders generated per assigned client',
                width: cardWidth,
                onTap: () => MetricDataPopup.show(
                  context,
                  type: MetricCardType.conversionRate,
                  controller: controller,
                ),
              ),
              _InteractiveMetricCard(
                title: 'Top Performing Staff',
                value: topStaffName,
                icon: Icons.stars_rounded,
                color: Colors.amber.shade800,
                badge: topStaffRevenue,
                badgeColor: Colors.amber.shade900,
                subtitle: 'Top sales representative spotlight',
                width: cardWidth,
                onTap: () => MetricDataPopup.show(
                  context,
                  type: MetricCardType.topStaff,
                  controller: controller,
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _InteractiveMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String badge;
  final Color badgeColor;
  final String subtitle;
  final double width;
  final VoidCallback onTap;

  const _InteractiveMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.badge,
    required this.badgeColor,
    required this.subtitle,
    required this.width,
    required this.onTap,
  });

  @override
  State<_InteractiveMetricCard> createState() => _InteractiveMetricCardState();
}

class _InteractiveMetricCardState extends State<_InteractiveMetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: widget.width,
          transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withValues(alpha: 0.5)
                  : AppTheme.gray200,
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: _isHovered ? 14 : 10,
                offset: Offset(0, _isHovered ? 6 : 4),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.badgeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _isHovered ? 1.0 : 0.35,
                        child: Icon(
                          Icons.open_in_new_rounded,
                          size: 15,
                          color: _isHovered ? widget.color : AppTheme.gray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gray600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _isHovered ? 1.0 : 0.0,
                    child: Text(
                      'View table →',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
