import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import '../dashboard.controller.dart';
import 'payment_row.widget.dart';

class RecentPayments extends StatelessWidget {
  const RecentPayments({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final currentPage = 1.obs;
    const int itemsPerPage = 6;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Payments', style: AppTheme.sectionTitleStyle),
          const SizedBox(height: 16),
          Obx(() {
            final isLoading = controller.isLoading;
            if (isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final totalItems = controller.recentPayments.length;
            final totalPages = (totalItems / itemsPerPage).ceil();
            final startIndex = (currentPage.value - 1) * itemsPerPage;
            final endIndex = (startIndex + itemsPerPage).clamp(0, totalItems);
            final paginatedList = controller.recentPayments.sublist(
              startIndex,
              endIndex,
            );

            return Column(
              children: [
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: AppTheme.gray100,
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusDefault,
                        ),
                      ),
                      children:
                          ['Client Name', 'Plan', 'Amount', 'Date', 'Status']
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      e,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppTheme.gray700,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    ...paginatedList.map(
                      (payment) => PaymentRow(payment: payment),
                    ),
                  ],
                ),
                if (totalPages > 1) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${startIndex + 1}-$endIndex of $totalItems payments',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.gray600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: currentPage.value > 1
                                ? () => currentPage.value--
                                : null,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.gray100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                size: 20,
                                color: currentPage.value > 1
                                    ? AppTheme.gray700
                                    : AppTheme.gray400,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(totalPages > 5 ? 5 : totalPages, (
                            index,
                          ) {
                            final pageNum = currentPage.value <= 3
                                ? index + 1
                                : currentPage.value + index - 2;
                            if (pageNum > totalPages) {
                              return const SizedBox.shrink();
                            }
                            final isActive = pageNum == currentPage.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: InkWell(
                                onTap: () => currentPage.value = pageNum,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppTheme.primaryBlue
                                        : AppTheme.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: isActive
                                        ? null
                                        : Border.all(color: AppTheme.gray300),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$pageNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isActive
                                            ? AppTheme.white
                                            : AppTheme.gray700,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: currentPage.value < totalPages
                                ? () => currentPage.value++
                                : null,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.gray100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: currentPage.value < totalPages
                                    ? AppTheme.gray700
                                    : AppTheme.gray400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}
