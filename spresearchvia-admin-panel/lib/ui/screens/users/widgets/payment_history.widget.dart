import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user_payment.controller.dart';
import 'package:spresearch_web/controllers/subscription/manage_subscription.controller.dart';
import 'package:spresearch_web/ui/screens/users/widgets/payment_table_header.widget.dart';
import 'package:spresearch_web/ui/screens/users/widgets/payment_table_row.widget.dart';

class PaymentHistory extends StatelessWidget {
  final String? userId;
  final bool showEditColumn;
  const PaymentHistory({super.key, this.userId, this.showEditColumn = true});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserPaymentController());

    if (userId != null && userId!.isNotEmpty) {
      controller.fetchPaymentHistory(userId!);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.paymentHistoryPreview,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error.value.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    controller.error.value,
                    style: AppTheme.bodyTextStyle.copyWith(
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              );
            }

            if (controller.paymentHistory.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'No payment history found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              );
            }

            final totalItems = controller.totalPayments.value;
            final totalPages = (totalItems / controller.itemsPerPage).ceil();
            final payments = controller.paymentHistory;
            final startIndex =
                ((controller.currentPage.value - 1) * controller.itemsPerPage)
                    .clamp(0, payments.length);
            final endIndex = (startIndex + controller.itemsPerPage).clamp(
              0,
              payments.length,
            );
            final currentPayments = payments.sublist(startIndex, endIndex);

            return Column(
              children: [
                Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: AppTheme.gray200),
                  ),
                  columnWidths: {
                    0: FlexColumnWidth(1.2), // Type
                    1: FlexColumnWidth(1.8), // Plan Name
                    2: FlexColumnWidth(1.5), // Segment
                    3: FlexColumnWidth(1), // Amount
                    4: FlexColumnWidth(1.2), // Date
                    5: FlexColumnWidth(1.2), // Status
                    if (showEditColumn) 6: FlexColumnWidth(0.6), // Actions
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.gray50),
                      children: [
                        PaymentTableHeader(AppStrings.type),
                        PaymentTableHeader(AppStrings.planName),
                        PaymentTableHeader(AppStrings.segmentName),
                        PaymentTableHeader(AppStrings.amount),
                        PaymentTableHeader(AppStrings.date),
                        PaymentTableHeader(AppStrings.status),
                        if (showEditColumn) PaymentTableHeader('Edit'),
                      ],
                    ),
                    ...currentPayments.map((payment) {
                      return PaymentTableRow(
                        showEdit: showEditColumn,
                        onEdit:
                            (showEditColumn &&
                                payment['paymentIntentId'] != null)
                            ? () => Get.find<ManageSubscriptionController>()
                                  .showCorrectionDialog(payment)
                            : null,
                        type: payment['type'] ?? 'PLAN',
                        planName: payment['planName'] ?? '-',
                        segmentName: payment['segmentName'] ?? '-',
                        amount: '₹${payment['amount'] ?? 0}',
                        date:
                            payment['date']?.toString().split('T')[0] ?? 'N/A',
                        status: (payment['status'] ?? 'N/A')
                            .toString()
                            .toUpperCase(),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIndex + 1} to $endIndex of $totalItems results',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: controller.currentPage.value > 1
                              ? controller.previousPage
                              : null,
                          child: Text('Previous'),
                        ),
                        ...List.generate(totalPages, (index) {
                          final pageNumber = index + 1;
                          final isCurrent =
                              controller.currentPage.value == pageNumber;

                          return InkWell(
                            onTap: () => controller.goToPage(pageNumber),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppTheme.primaryBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$pageNumber',
                                style: TextStyle(
                                  color: isCurrent
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          );
                        }),
                        TextButton(
                          onPressed: controller.currentPage.value < totalPages
                              ? controller.nextPage
                              : null,
                          child: Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
