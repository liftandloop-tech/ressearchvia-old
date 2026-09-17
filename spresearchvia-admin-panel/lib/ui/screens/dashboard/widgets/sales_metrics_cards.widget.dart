import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';

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
              _buildMetricCard(
                title: 'Total Sales Revenue',
                value: currencyFormatter.format(totalSales),
                icon: Icons.payments_rounded,
                color: AppTheme.primaryBlue,
                badge: 'Live',
                badgeColor: Colors.green,
                subtitle: 'Overall generated sales volume',
                width: cardWidth,
              ),
              _buildMetricCard(
                title: 'Purchases',
                value: totalOrders.toString(),
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFF10B981),
                badge: 'Active',
                badgeColor: Colors.teal,
                subtitle: 'Completed purchase transactions',
                width: cardWidth,
              ),
              _buildMetricCard(
                title: 'Active Sales Staff',
                value: activeStaff.toString(),
                icon: Icons.groups_rounded,
                color: Colors.purple,
                badge: 'Staff',
                badgeColor: Colors.purple,
                subtitle: 'Representatives handling clients',
                width: cardWidth,
              ),
              _buildMetricCard(
                title: 'Average Order Value (AOV)',
                value: currencyFormatter.format(avgOrderVal),
                icon: Icons.trending_up_rounded,
                color: Colors.orange,
                badge: 'AOV',
                badgeColor: Colors.orange,
                subtitle: 'Average revenue per order',
                width: cardWidth,
              ),
              _buildMetricCard(
                title: 'Sales Conversion Rate',
                value: '$conversion%',
                icon: Icons.pie_chart_rounded,
                color: Colors.indigo,
                badge: 'Conversion',
                badgeColor: Colors.indigo,
                subtitle: 'Orders generated per assigned client',
                width: cardWidth,
              ),
              _buildMetricCard(
                title: 'Top Performing Staff',
                value: topStaffName,
                icon: Icons.stars_rounded,
                color: Colors.amber.shade800,
                badge: topStaffRevenue,
                badgeColor: Colors.amber.shade900,
                subtitle: 'Top sales representative spotlight',
                width: cardWidth,
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String badge,
    required Color badgeColor,
    required String subtitle,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.gray600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
