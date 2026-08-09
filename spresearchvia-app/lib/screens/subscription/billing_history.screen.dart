import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/billing_history.controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_styles.dart';
import '../../core/routes/app_routes.dart';

class BillingHistoryScreen extends StatelessWidget {
  const BillingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BillingHistoryController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Billing History'),
        elevation: 0,
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textBlack,
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchBillingHistory,
        child: Obx(() {
          if (controller.isLoading.value && controller.billingHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.billingHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No billing history found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.billingHistory.length,
            itemBuilder: (context, index) {
              final item = controller.billingHistory[index];
              return _BillingCard(item: item);
            },
          );
        }),
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _BillingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item['status'] ?? 'CREATED';
    final dateStr = item['purchaseDate'] ?? '';
    final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final amountPaid = item['amountPaid'] ?? 0;
    final totalAmount = item['totalAmount'] ?? 0;
    String planName = item['planName'] ?? 'Plan Purchase';
    if (planName.toLowerCase() == 'silver') {
      planName = 'Silver Registration';
    } else if (planName.toLowerCase() == 'gold') {
      planName = 'Gold Registration';
    }
    final isInvoiceAvailable = item['isInvoiceAvailable'] ?? false;
    final invoiceId = item['invoiceId'];

    final basePaid = item['baseAmountPaid'] ?? (amountPaid / 1.18);
    final gstPaid = item['gstAmountPaid'] ?? (amountPaid - (amountPaid / 1.18));
    final baseTotal = item['baseTotalAmount'] ?? (totalAmount / 1.18);
    final gstTotal = item['gstTotalAmount'] ?? (totalAmount - (totalAmount / 1.18));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  planName,
                  style: AppStyles.heading3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          _IconText(
            icon: Icons.calendar_today_outlined,
            text: formattedDate,
          ),
          const SizedBox(height: 8),
          _IconText(
            icon: Icons.currency_rupee_outlined,
            text: 'Paid: ₹${basePaid.toStringAsFixed(2)} + ₹${gstPaid.toStringAsFixed(2)} / Total: ₹${baseTotal.toStringAsFixed(2)} + ₹${gstTotal.toStringAsFixed(2)}',
          ),
          if (isInvoiceAvailable && invoiceId != null) ...[
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to receipt screen with invoiceId as argument
                  Get.toNamed(
                    AppRoutes.receipt, 
                    arguments: {
                      'invoiceId': invoiceId,
                      'planName': planName,
                    },
                  );
                },
                icon: const Icon(Icons.download_for_offline_outlined, size: 20),
                label: const Text('View Invoice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status.toUpperCase()) {
      case 'PAID':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'PARTIAL':
        color = Colors.orange;
        label = 'Partial';
        break;
      case 'FAILED':
      case 'REJECTED':
        color = Colors.red;
        label = status.toUpperCase() == 'REJECTED' ? 'Rejected' : 'Failed';
        break;
      case 'VERIFICATION_PENDING':
      case 'PENDING_BANK_TRANSFER':
        color = Colors.amber;
        label = 'Processing';
        break;
      case 'CREATED':
        color = Colors.grey;
        label = 'Initiated';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ),
      ],
    );
  }
}
