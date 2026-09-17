import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';

class StaffSalesLeaderboardTable extends StatelessWidget {
  const StaffSalesLeaderboardTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final currentPage = 1.obs;
    const int itemsPerPage = 10;
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Obx(() {
      final isLoading = controller.isLoading;
      if (isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      final list = controller.filteredStaffPerformance;
      final totalItems = list.length;
      final totalPages = totalItems > 0 ? (totalItems / itemsPerPage).ceil() : 1;
      final startIndex = (currentPage.value - 1) * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, totalItems);
      final pagedList = totalItems > 0 ? list.sublist(startIndex, endIndex) : [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    'Rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Staff Representative',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Department',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Assigned Clients',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Orders Generated',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total Sales Revenue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    'Status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.gray700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (totalItems == 0)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'No staff sales performance records found matching criteria.',
                  style: TextStyle(color: AppTheme.gray600, fontSize: 14),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pagedList.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppTheme.gray200,
              ),
              itemBuilder: (context, index) {
                final item = pagedList[index];
                final rank = startIndex + index + 1;
                final totalSales = (item['totalSalesAmount'] ?? 0).toDouble();
                final ordersCount = item['ordersCount'] ?? 0;
                final clientsCount = item['assignedClients'] ?? 0;

                Color badgeColor = Colors.grey;
                String badgeText = 'Inactive';
                if (totalSales > 100000) {
                  badgeColor = Colors.green;
                  badgeText = 'Top Seller';
                } else if (totalSales > 0 || ordersCount > 0) {
                  badgeColor = Colors.blue;
                  badgeText = 'Active Seller';
                } else if (clientsCount > 0) {
                  badgeColor = Colors.orange;
                  badgeText = 'Assigned';
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : AppTheme.gray50,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: rank <= 3
                                ? AppTheme.primaryBlue
                                : AppTheme.gray600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Staff Member',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${item['staffId']} • ${item['email']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['department'] ?? 'Sales',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.gray800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$clientsCount Clients',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '$ordersCount Orders',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray900,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          currencyFormatter.format(totalSales),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: badgeColor.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            badgeText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 16),

          // Pagination Controls
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${startIndex + 1} to $endIndex of $totalItems staff members',
                  style: const TextStyle(fontSize: 13, color: AppTheme.gray600),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: currentPage.value > 1
                          ? () => currentPage.value--
                          : null,
                    ),
                    Text(
                      'Page ${currentPage.value} of $totalPages',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: currentPage.value < totalPages
                          ? () => currentPage.value++
                          : null,
                    ),
                  ],
                ),
              ],
            ),
        ],
      );
    });
  }
}
