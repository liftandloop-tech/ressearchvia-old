import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';

import 'package:spresearch_web/ui/widgets/skeleton_loader.widget.dart';

class StaffOrdersTable extends StatelessWidget {
  const StaffOrdersTable({super.key});

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
      final list = controller.filteredStaffOrders;

      if (isLoading && list.isEmpty) {
        return const SizedBox(
          height: 400,
          child: TableSkeleton(rowCount: 6, columnCount: 6),
        );
      }
      final totalItems = list.length;
      final totalPages = totalItems > 0 ? (totalItems / itemsPerPage).ceil() : 1;
      final startIndex = (currentPage.value - 1) * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, totalItems);
      final pagedList = totalItems > 0 ? list.sublist(startIndex, endIndex) : [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    'Order ID',
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
                    'Client Name & Contact',
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
                    'Plan / Package',
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
                    'Assigned Staff',
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
                    'Amount',
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
                  'No staff orders found matching criteria.',
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
                final amount = (item['amount'] ?? 0).toDouble();
                final status = (item['status'] ?? 'active').toString();

                Color badgeColor = Colors.green;
                if (status.toLowerCase() == 'active' ||
                    status.toLowerCase() == 'paid') {
                  badgeColor = Colors.green;
                } else if (status.toLowerCase() == 'pending') {
                  badgeColor = Colors.orange;
                } else {
                  badgeColor = Colors.red;
                }

                String formattedDate = '-';
                if (item['createdAt'] != null) {
                  try {
                    final dt = DateTime.parse(item['createdAt'].toString()).toLocal();
                    formattedDate = DateFormat('dd MMM yyyy').format(dt);
                  } catch (e) {
                    formattedDate = item['createdAt'].toString();
                  }
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
                        width: 110,
                        child: Text(
                          item['orderId'] ?? 'ORD-000000',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['clientName'] ?? 'Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['clientPhone']} • ${item['clientEmail']}',
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['packageName'] ?? 'Standard Plan',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.gray900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Date: $formattedDate',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          item['staffName'] ?? 'Unassigned',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.gray800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          currencyFormatter.format(amount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gray900,
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
                            status.toUpperCase(),
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
                  'Showing ${startIndex + 1} to $endIndex of $totalItems orders',
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
