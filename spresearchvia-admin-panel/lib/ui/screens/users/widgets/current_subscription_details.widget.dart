import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/subscription/manage_subscription.controller.dart';
import 'package:collection/collection.dart';

class CurrentSubscriptionDetails extends StatelessWidget {
  final ManageSubscriptionController controller;

  const CurrentSubscriptionDetails({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
                'User Subscriptions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (controller.currentUserId.value.isNotEmpty) {
                    controller.showAddPlanDialog(
                      context,
                      controller.currentUserId.value,
                    );
                  }
                },
                icon: Icon(Icons.add, size: 16),
                label: Text('Add Plan'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            final subscriptions = controller.userSubscriptions.where((sub) {
              final name = sub['packageName']?.toString().toLowerCase() ?? '';
              final grantReason =
                  sub['grantReason']?.toString().toUpperCase() ?? '';
              final isTrial =
                  sub['isTrial'] == true || grantReason == 'REGISTRATION_TRIAL';

              // Only hide registration plans that are NOT trials
              if (name.contains('registration')) {
                return isTrial;
              }
              return true;
            }).toList();

            if (subscriptions.isEmpty) {
              return const Text('No segment subscriptions found.');
            }

            return Column(
              children: subscriptions.map((sub) {
                final planId = sub['_id'];
                final userId = sub['userId'];
                final status =
                    sub['status']?.toString().toLowerCase() ?? 'unknown';

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.gray200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Header: Plan Name, Price, Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    sub['isTrial'] == true
                                        ? 'Registration Trial'
                                        : (sub['packageName'] ??
                                              'Unknown Plan'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (sub['isTrial'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.amber[300]!,
                                        ),
                                      ),
                                      child: Text(
                                        'TRIAL',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (() {
                                  final segId = sub['segmentId'];
                                  final seg = controller.segments
                                      .firstWhereOrNull((s) => s.id == segId);
                                  return seg?.segmentName ??
                                      sub['segmentName'] ??
                                      'Unknown Segment';
                                })(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Text(
                                      'Paid: ₹${sub['basicAmount'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if ((sub['isPartial'] == true) ||
                                      (sub['packageName']
                                          .toString()
                                          .toLowerCase()
                                          .contains('partial')))
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.orange[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.pie_chart,
                                            size: 12,
                                            color: Colors.orange[800],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Partial',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange[900],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.blue[200]!,
                                        ),
                                      ),
                                      child: Text(
                                        'Full Access',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue[900],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if ((sub['isPartial'] == true) ||
                                  (sub['packageName']
                                      .toString()
                                      .toLowerCase()
                                      .contains('partial'))) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.orange[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Partial Payment Details',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[900],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (sub['totalPlanAmount'] != null) ...[
                                        Text(
                                          'Standard Total Price (Plan + GST): ₹${sub['totalPlanAmount']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (sub['gstAmount'] != null)
                                          Text(
                                            '(Includes GST: ₹${sub['gstAmount']})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        'Amount Paid: ₹${sub['basicAmount'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (sub['totalPlanAmount'] != null)
                                        Text(
                                          'Remaining Amount: ₹${((sub['totalPlanAmount'] is num ? sub['totalPlanAmount'] : 0) - (sub['basicAmount'] is num ? sub['basicAmount'] : 0))}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red[800],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              if (sub['remarks'] != null &&
                                  sub['remarks'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Remarks: ${sub['remarks']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.indigo.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Date Fields
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              context,
                              'Start Date',
                              controller.startDateControllers[planId]?.text ??
                                  '',
                              () => controller.pickDate(context, planId, true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              context,
                              'End Date',
                              controller.endDateControllers[planId]?.text ?? '',
                              () => controller.pickDate(context, planId, false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Actions
                      if (status == 'active' || status == 'suspended')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (status == 'active')
                              OutlinedButton(
                                onPressed: () => controller.suspendSubscription(
                                  controller.currentUserId.value,
                                  planId,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.warningOrange,
                                  side: BorderSide(
                                    color: AppTheme.warningOrange,
                                  ),
                                ),
                                child: const Text('Suspend'),
                              ),
                            if (status == 'suspended')
                              OutlinedButton(
                                onPressed: () =>
                                    controller.activateSubscription(
                                      controller.currentUserId.value,
                                      planId,
                                    ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.successGreen,
                                  side: BorderSide(
                                    color: AppTheme.successGreen,
                                  ),
                                ),
                                child: const Text('Activate'),
                              ),
                            if (status == 'active' &&
                                ((sub['isPartial'] == true) ||
                                    (sub['packageName']
                                        .toString()
                                        .toLowerCase()
                                        .contains('partial')))) ...[
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {
                                  controller.triggerTopUp(
                                    controller.currentUserId.value,
                                    sub['_id'],
                                    sub['packageName'] ?? 'Plan',
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: BorderSide(color: Colors.orange),
                                ),
                                child: const Text('Add Money'),
                              ),
                            ],
                            if (sub['paymentIntentId'] != null &&
                                controller.isAdmin) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => controller
                                    .showSubscriptionCorrectionDialog(sub),
                                icon: Icon(Icons.edit, size: 16),
                                label: const Text('Edit Plan/Dates'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[50],
                                  foregroundColor: Colors.blue[900],
                                  elevation: 0,
                                  side: BorderSide(color: Colors.blue[100]!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    controller.showCorrectionDialog(sub),
                                icon: Icon(Icons.edit_note, size: 16),
                                label: const Text('Correct Amount'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo[50],
                                  foregroundColor: Colors.indigo[900],
                                  elevation: 0,
                                  side: BorderSide(color: Colors.indigo[100]!),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gray300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isEmpty ? 'Select Date' : value,
                  style: TextStyle(fontSize: 14),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = AppTheme.successGreen;
        break;
      case 'expired':
        color = AppTheme.gray400;
        break;
      case 'suspended':
        color = AppTheme.warningOrange;
        break;
      case 'cancelled':
        color = AppTheme.errorRed;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.capitalizeFirst!,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
