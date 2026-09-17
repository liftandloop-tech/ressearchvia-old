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

  void _showRefundBreakdownDialog(BuildContext context, Map<String, dynamic> refund) {
    final originalAmount = refund['originalAmount'] ?? refund['amount'] ?? 0;
    final refundAmount = refund['amount'] ?? 0;
    final deductionAmount = refund['deductionAmount'] ?? 0;
    final planName = refund['planName'] ?? 'Subscription Plan';
    final segmentName = refund['segmentName'] ?? '-';
    final reason = refund['reason'] ?? 'Standard Administrative Refund';
    final reasonCat = refund['reasonCategory'] ?? 'SERVICE_DISSATISFACTION';
    final txId = refund['transactionId'] ?? 'N/A';
    final dateStr = refund['date']?.toString().split('T')[0] ?? 'N/A';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.currency_exchange, color: Color(0xFF9333EA), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Refund Audit & Policy Breakdown',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
              splashRadius: 18,
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Plan & Date
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName.toString(),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Segment: $segmentName',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REFUNDED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9333EA)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown calculation card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Original Payment:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text('₹$originalAmount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Used Service Fee Retained:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text('- ₹$deductionAmount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Net Refund Paid to Client:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('₹$refundAmount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reason & Audit
              const Text('Refund Justification & Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  reason.toString(),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Reference / TX: ', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Text(txId.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const Spacer(),
                  Text('Category: $reasonCat', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserPaymentController());

    if (userId != null && userId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchPaymentHistory(userId!);
      });
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
          // Header with Filter dropdown & Refresh action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.paymentHistoryPreview,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Transaction logs, subscription payments, and client refunds',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Obx(() {
                final allCount = controller.paymentHistory.length;
                final refundCount = controller.paymentHistory.where((p) {
                  final typeStr = (p['type'] ?? '').toString().toLowerCase();
                  final statusStr = (p['status'] ?? '').toString().toUpperCase();
                  final sourceStr = (p['source'] ?? '').toString().toLowerCase();
                  return typeStr.contains('refund') || statusStr.contains('REFUND') || sourceStr == 'refund';
                }).length;
                final regCount = controller.paymentHistory.where((p) {
                  final typeStr = (p['type'] ?? '').toString().toLowerCase();
                  final planStr = (p['planName'] ?? '').toString().toLowerCase();
                  return typeStr.contains('registration') || planStr.contains('registration');
                }).length;
                final planCount = allCount - regCount - refundCount;

                return Row(
                  children: [
                    // Filter dropdown
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.filterType.value,
                          icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF475569)),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          items: [
                            DropdownMenuItem(
                              value: 'ALL',
                              child: Text('All Transactions ($allCount)'),
                            ),
                            DropdownMenuItem(
                              value: 'PLAN',
                              child: Text('Plan Subscriptions ($planCount)'),
                            ),
                            DropdownMenuItem(
                              value: 'REGISTRATION',
                              child: Text('Registrations ($regCount)'),
                            ),
                            DropdownMenuItem(
                              value: 'REFUND',
                              child: Row(
                                children: [
                                  const Icon(Icons.currency_exchange, size: 14, color: Color(0xFF9333EA)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Refunds ($refundCount)',
                                    style: const TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) controller.setFilter(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: Color(0xFF64748B)),
                      onPressed: () {
                        if (userId != null && userId!.isNotEmpty) {
                          controller.fetchPaymentHistory(userId!, forceRefresh: true);
                        }
                      },
                      tooltip: 'Refresh Transactions',
                      splashRadius: 18,
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
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

            final payments = controller.filteredPayments;

            if (payments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        controller.filterType.value == 'REFUND'
                            ? Icons.currency_exchange
                            : Icons.receipt_long_outlined,
                        size: 40,
                        color: const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.filterType.value == 'REFUND'
                            ? 'No refunds recorded for this user'
                            : 'No payment transactions found for this filter',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }

            final totalItems = payments.length;
            final totalPages = (totalItems / controller.itemsPerPage).ceil();
            final startIndex =
                ((controller.currentPage.value - 1) * controller.itemsPerPage)
                    .clamp(0, payments.length);
            final endIndex = (startIndex + controller.itemsPerPage).clamp(
              0,
              payments.length,
            );
            final currentPayments = payments.sublist(startIndex, endIndex);

            final manageCtrl = Get.isRegistered<ManageSubscriptionController>()
                ? Get.find<ManageSubscriptionController>()
                : null;
            final showActionColumn = showEditColumn;

            return Column(
              children: [
                Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: AppTheme.gray200),
                  ),
                  columnWidths: {
                    0: const FlexColumnWidth(1.2), // Type
                    1: const FlexColumnWidth(2.2), // Plan Name / Details
                    2: const FlexColumnWidth(1.4), // Segment
                    3: const FlexColumnWidth(1.2), // Amount
                    4: const FlexColumnWidth(1.2), // Date
                    5: const FlexColumnWidth(1.2), // Status
                    if (showActionColumn) 6: const FlexColumnWidth(0.9), // Actions
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
                        if (showActionColumn) PaymentTableHeader('Actions'),
                      ],
                    ),
                    ...currentPayments.map((payment) {
                      final statusUpper = (payment['status'] ?? 'N/A').toString().toUpperCase();
                      final typeUpper = (payment['type'] ?? '').toString().toUpperCase();
                      final sourceStr = (payment['source'] ?? '').toString().toLowerCase();
                      final isRefund = typeUpper.contains('REFUND') ||
                          statusUpper.contains('REFUND') ||
                          sourceStr == 'refund';

                      String? refundSubtitle;
                      if (isRefund) {
                        final orig = payment['originalAmount'];
                        final deduction = payment['deductionAmount'];
                        if (orig != null && deduction != null) {
                          refundSubtitle = 'Paid: ₹$orig | Used Service Fee: ₹$deduction';
                        } else if (payment['reason'] != null) {
                          refundSubtitle = '${payment['reason']}';
                        }
                      }

                      final amountDisplay = isRefund
                          ? '-₹${payment['amount'] ?? 0}'
                          : '₹${payment['amount'] ?? 0}';

                      return PaymentTableRow(
                        showEdit: showEditColumn,
                        isRefund: isRefund,
                        subtitle: refundSubtitle,
                        onViewDetails: isRefund ? () => _showRefundBreakdownDialog(context, payment) : null,
                        onEdit: (!isRefund &&
                                showEditColumn &&
                                payment['paymentIntentId'] != null &&
                                manageCtrl != null)
                            ? () => manageCtrl.showCorrectionDialog(payment)
                            : null,
                        type: isRefund ? 'Refund' : (payment['type'] ?? 'PLAN'),
                        planName: payment['planName'] ?? '-',
                        segmentName: payment['segmentName'] ?? '-',
                        amount: amountDisplay,
                        date: payment['date']?.toString().split('T')[0] ?? 'N/A',
                        status: isRefund ? 'REFUNDED' : statusUpper,
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
                          child: const Text('Previous'),
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
                          child: const Text('Next'),
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

