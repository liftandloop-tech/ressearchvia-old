import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/controllers/notifications/push_notifications.controller.dart';
import 'package:intl/intl.dart';

class NotificationHistoryPanel extends StatelessWidget {
  const NotificationHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PushNotificationsController());

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notification & Email History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: controller.fetchNotificationHistory,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh History',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isLoadingHistory.value &&
                controller.notificationHistory.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.notificationHistory.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off,
                        size: 48,
                        color: AppTheme.gray300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No history found',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppTheme.gray50),
                columns: const [
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Sent At')),
                  DataColumn(label: Text('Title / Subject')),
                  DataColumn(label: Text('Audience')),
                  DataColumn(label: Text('Success / Total')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: controller.notificationHistory.map((item) {
                  final type = item['type'] ?? 'push';
                  final sentAt = DateTime.tryParse(
                    item['sentAt']?.toString() ?? '',
                  )?.toLocal();
                  final formattedDate = sentAt != null
                      ? DateFormat('MMM dd, hh:mm a').format(sentAt)
                      : 'Unknown';

                  final successCount = item['successCount'] ?? 0;
                  final recipientCount = item['recipientCount'] ?? 0;
                  final status = item['status'] ?? 'sent';

                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type == 'email'
                                  ? Icons.email_outlined
                                  : Icons.notifications_active_outlined,
                              size: 16,
                              color: type == 'email'
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(type.toString().toUpperCase()),
                          ],
                        ),
                      ),
                      DataCell(Text(formattedDate)),
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Text(
                            item['title'] ?? 'No Title',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(item['audience'] ?? 'All')),
                      DataCell(Text('$successCount / $recipientCount')),
                      DataCell(_buildStatusBadge(status)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 20),
                          onPressed: () => _showDetailsDialog(context, item),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'sent':
        color = Colors.green;
        break;
      case 'partially_failed':
        color = Colors.orange;
        break;
      case 'failed':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    Get.dialog(
      AlertDialog(
        title: Text(item['title'] ?? 'Notification Details'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Message:', item['message'] ?? ''),
                const Divider(),
                _detailRow('Audience:', item['audience'] ?? ''),
                _detailRow(
                  'Recipient Count:',
                  item['recipientCount']?.toString() ?? '0',
                ),
                _detailRow(
                  'Success Count:',
                  item['successCount']?.toString() ?? '0',
                ),
                _detailRow(
                  'Failure Count:',
                  item['failureCount']?.toString() ?? '0',
                ),
                if (item['imageUrl'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Image:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Image.network(
                    AppConfig.buildImageUrl(item['imageUrl']),
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Delivery Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatJson(item['details']),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatJson(dynamic json) {
    if (json == null) return 'No details available';
    try {
      // Basic formatting if it's a map
      if (json is Map || json is List) {
        return json
            .toString(); // For now just toString, could use JsonEncoder for pretty print
      }
      return json.toString();
    } catch (e) {
      return json.toString();
    }
  }
}
