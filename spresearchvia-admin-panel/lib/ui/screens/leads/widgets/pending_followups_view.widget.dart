import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../../config/theme.config.dart';
import '../../../../controllers/leads/leads.controller.dart';
import '../../../../models/lead.model.dart';
import 'click_to_call_dialog.widget.dart';
import 'lead_detail_dialog.widget.dart';

class PendingFollowUpsView extends StatelessWidget {
  final LeadsController controller;

  const PendingFollowUpsView({
    super.key,
    required this.controller,
  });

  void _showCompleteDialog(BuildContext context, PendingFollowUpModel followUp) {
    final notesCtrl = TextEditingController();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 22),
                  const SizedBox(width: 10),
                  const Text('Complete Follow-up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Get.back()),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Lead: ${followUp.fullName} (${followUp.mobileNumber})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Completion Notes / Outcome',
                  hintText: 'e.g. Call attended, client requested demo on Monday...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.completeFollowUp(followUp.leadId, followUp.followUpId, notesCtrl.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Mark Complete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, PendingFollowUpModel followUp) {
    final notesCtrl = TextEditingController();
    DateTime rescheduleDate = DateTime.now().add(const Duration(days: 1));

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 22),
                      const SizedBox(width: 10),
                      const Text('Reschedule Follow-up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => Get.back()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lead: ${followUp.fullName} (${followUp.mobileNumber})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: rescheduleDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        if (!context.mounted) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(rescheduleDate),
                        );
                        if (time != null) {
                          setState(() {
                            rescheduleDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        } else {
                          setState(() => rescheduleDate = picked);
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'New Follow-up Date & Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        DateFormat.yMMMd().add_jm().format(rescheduleDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Reschedule Reason',
                      hintText: 'e.g. Prospect busy in meeting, asked to call tomorrow',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.rescheduleFollowUp(
                            followUp.leadId,
                            followUp.followUpId,
                            rescheduleDate,
                            notesCtrl.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirm Reschedule'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Toolbar Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(bottom: BorderSide(color: AppTheme.gray200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notification_important_outlined, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Obx(() => Text(
                      'Pending Follow-ups (${controller.totalPendingFollowUps.value})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    )),
                const SizedBox(width: 16),
                Obx(() => FilterChip(
                      selected: controller.pendingFollowUpsOverdueOnly.value,
                      label: const Text('Overdue Only', style: TextStyle(fontSize: 12)),
                      selectedColor: AppTheme.errorRed.withValues(alpha: 0.15),
                      checkmarkColor: AppTheme.errorRed,
                      labelStyle: TextStyle(
                        color: controller.pendingFollowUpsOverdueOnly.value ? AppTheme.errorRed : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        controller.fetchPendingFollowUps(isOverdue: val);
                      },
                    )),
                const Spacer(),
                Tooltip(
                  message: 'Refresh Follow-ups',
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: AppTheme.primaryBlue),
                    onPressed: () => controller.fetchPendingFollowUps(),
                  ),
                ),
              ],
            ),
          ),

          // Table Content
          Expanded(
            child: Obx(() {
              if (controller.isPendingFollowUpsLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
              }

              final items = controller.pendingFollowUpsList;
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.done_all, size: 54, color: AppTheme.gray400),
                      const SizedBox(height: 12),
                      const Text(
                        'All caught up! No pending follow-ups found.',
                        style: TextStyle(fontSize: 15, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DataTable2(
                  columnSpacing: 10,
                  horizontalMargin: 10,
                  minWidth: 1050,
                  headingRowHeight: 44,
                  dataRowHeight: 52,
                  headingRowColor: WidgetStateProperty.all(AppTheme.backgroundLight),
                  border: TableBorder(
                    horizontalInside: BorderSide(color: AppTheme.border, width: 1),
                  ),
                  columns: const [
                    DataColumn2(label: Text('Client Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), size: ColumnSize.M),
                    DataColumn2(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), fixedWidth: 140),
                    DataColumn2(label: Text('Assigned To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), fixedWidth: 140),
                    DataColumn2(label: Text('Follow-up Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), fixedWidth: 175),
                    DataColumn2(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), fixedWidth: 100),
                    DataColumn2(label: Text('Description / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), size: ColumnSize.L),
                    DataColumn2(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), fixedWidth: 110),
                    DataColumn2(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), fixedWidth: 100),
                  ],
                  rows: items.map((f) {
                    return DataRow(
                      cells: [
                        DataCell(
                          InkWell(
                            onTap: () async {
                              final fullLead = controller.leadsList.firstWhereOrNull((l) => l.id == f.leadId);
                              if (fullLead != null) {
                                Get.dialog(LeadDetailDialog(lead: fullLead, controller: controller));
                              }
                            },
                            child: Text(
                              f.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(f.mobileNumber, style: const TextStyle(fontSize: 12.5)),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.phone_in_talk, color: Colors.green, size: 16),
                                tooltip: 'Call',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  final fullLead = controller.leadsList.firstWhereOrNull((l) => l.id == f.leadId);
                                  if (fullLead != null) {
                                    Get.dialog(ClickToCallDialog(lead: fullLead));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(f.assignedRMName ?? 'Unassigned', style: const TextStyle(fontSize: 12.5))),
                        DataCell(
                          Row(
                            children: [
                              Flexible(child: Text(dateFormat.format(f.followUpDate), style: const TextStyle(fontSize: 12))),
                              if (f.isOverdue) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorRed.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('OVERDUE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
                                ),
                              ],
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.gray100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(f.followUpType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        DataCell(Text(f.notes, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(f.status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: AppTheme.successGreen, size: 19),
                                tooltip: 'Mark Completed',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showCompleteDialog(context, f),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.schedule, color: AppTheme.primaryBlue, size: 19),
                                tooltip: 'Reschedule',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showRescheduleDialog(context, f),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
