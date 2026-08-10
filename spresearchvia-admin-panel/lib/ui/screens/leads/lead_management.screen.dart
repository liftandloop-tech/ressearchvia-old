import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/leads/leads.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:spresearch_web/models/lead.model.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/models/staff.model.dart';

class LeadManagementScreen extends StatelessWidget {
  const LeadManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeadsController());

    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Text(
                  'Lead Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => controller.fetchLeads(),
                  icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
                  tooltip: 'Refresh Leads',
                ),
                const SizedBox(width: 8),
                Button(
                  title: 'Bulk Upload',
                  buttonType: ButtonType.blue,
                  icon: Icons.upload_file,
                  onTap: () => controller.pickAndUploadBulkLeads(),
                ),
                const SizedBox(width: 8),
                Button(
                  title: 'Download Template',
                  buttonType: ButtonType.blue,
                  icon: Icons.download,
                  onTap: () => controller.downloadTemplate(),
                ),
                const SizedBox(width: 12),
                Obx(() {
                  if (controller.selectedLeadIds.isEmpty) return const SizedBox();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Button(
                        title: 'Bulk Assign (${controller.selectedLeadIds.length})',
                        buttonType: ButtonType.blue,
                        icon: Icons.assignment_ind_rounded,
                        onTap: () {
                          _showSearchableRMDialog(context, controller, onSelected: (rmId) {
                            controller.bulkAssignRM(rmId);
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  );
                }),
                Button(
                  title: 'Add New Lead',
                  buttonType: ButtonType.green,
                  icon: Icons.add,
                  onTap: () => _showAddLeadDialog(context, controller),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fresh Lead Pull Panel (only shown to regular staff/RMs, not admins/directors)
            if (Get.find<AuthController>().user.value?.isAdmin == false &&
                Get.find<AuthController>().user.value?.isDirector == false) ...[
              _buildPullPanel(controller),
              const SizedBox(height: 24),
            ],

            // Filters Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.gray200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (val) => controller.updateFilters(search: val),
                        decoration: InputDecoration(
                          hintText: 'Search Name, Mobile, Email...',
                          prefixIcon: Icon(Icons.search, color: AppTheme.gray400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.gray300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Stage Filter
                    Expanded(
                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          value: controller.selectedStage.value.isEmpty ? null : controller.selectedStage.value,
                          hint: const Text('Filter Stage'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.gray300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: ['New', 'Contacted', 'Interested', 'Qualified', 'Demo / Meeting Scheduled', 'Demo / Meeting Completed', 'Proposal Sent', 'Negotiation', 'Follow-up', 'Won', 'Lost', 'On Hold', 'Not Interested', 'Invalid']
                              .map((stage) => DropdownMenuItem(value: stage, child: Text(stage)))
                              .toList(),
                          onChanged: (val) => controller.updateFilters(stage: val ?? ''),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // RM Filter
                    Expanded(
                      child: Obx(() {
                        final currentRMId = controller.selectedRMId.value;
                        final currentRM = controller.staffList.firstWhereOrNull((s) => s.id == currentRMId);
                        final label = currentRM != null ? '${currentRM.name} (${currentRM.role})' : 'Filter Assigned RM';

                        return InkWell(
                          onTap: () {
                            _showSearchableRMDialog(
                              context,
                              controller,
                              unassignedLabel: 'All (Show All Leads)',
                              unassignedSubtitle: 'Click to clear RM filter',
                              onSelected: (rmId) {
                                controller.updateFilters(rmId: rmId ?? '');
                              },
                            );
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.gray300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: currentRM != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppTheme.gray600),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => controller.resetFilters(),
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Reset'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Leads Table
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.leadsList.isEmpty) {
                  return Center(
                    child: Text(
                      'No leads found matching query.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.gray200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 900,
                            onSelectAll: (selected) {
                              controller.toggleAllLeads(controller.leadsList);
                            },
                            columns: const [
                              DataColumn2(label: Text('Full Name'), size: ColumnSize.L),
                              DataColumn2(label: Text('Mobile')),
                              DataColumn2(label: Text('Stage')),
                              DataColumn2(label: Text('Assigned RM')),
                              DataColumn2(label: Text('Location')),
                              DataColumn2(label: Text('Follow-ups')),
                              DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                            ],
                            rows: controller.leadsList.map((lead) {
                              return DataRow(
                                selected: controller.selectedLeadIds.contains(lead.id),
                                onSelectChanged: (selected) {
                                  controller.toggleLeadSelection(lead.id);
                                },
                                cells: [
                                  DataCell(
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lead.fullName,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        if (lead.emailAddress != null)
                                          Text(
                                            lead.emailAddress!,
                                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  DataCell(Text(lead.mobileNumber)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: _getStageColor(lead.stage).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: lead.stage,
                                          dropdownColor: Colors.white,
                                          style: TextStyle(
                                            color: _getStageColor(lead.stage),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color: _getStageColor(lead.stage),
                                            size: 16,
                                          ),
                                          isDense: true,
                                          items: const ['New', 'Contacted', 'Interested', 'Qualified', 'Demo / Meeting Scheduled', 'Demo / Meeting Completed', 'Proposal Sent', 'Negotiation', 'Follow-up', 'Won', 'Lost', 'On Hold', 'Not Interested', 'Invalid']
                                              .map((s) => DropdownMenuItem<String>(
                                                    value: s,
                                                    child: Text(
                                                      s,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null && val != lead.stage) {
                                              controller.updateLeadStage(lead.id, val);
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Get.find<AuthController>().user.value?.isAdmin == true ||
                                            Get.find<AuthController>().user.value?.isDirector == true
                                        ? InkWell(
                                            onTap: () {
                                              _showSearchableRMDialog(context, controller, onSelected: (rmId) {
                                                controller.selectedLeadIds.clear();
                                                controller.selectedLeadIds.add(lead.id);
                                                controller.bulkAssignRM(rmId);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppTheme.gray300),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      lead.assignedRMName ?? 'Unassigned',
                                                      style: TextStyle(
                                                        color: lead.assignedRMName == null ? AppTheme.gray500 : AppTheme.textPrimary,
                                                        fontStyle: lead.assignedRMName == null ? FontStyle.italic : FontStyle.normal,
                                                        fontSize: 13,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.keyboard_arrow_down, size: 14, color: AppTheme.gray600),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Text(lead.assignedRMName ?? 'Unassigned'),
                                  ),
                                  DataCell(Text(
                                    [lead.city, lead.state].where((x) => x != null && x.isNotEmpty).join(', '),
                                  )),
                                  DataCell(
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            lead.followUps.isEmpty
                                                ? 'None'
                                                : 'Last: ${lead.followUps.last.notes}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_note, color: AppTheme.primaryBlue, size: 20),
                                          tooltip: 'Log Follow-up',
                                          onPressed: () => _showFollowUpDialog(context, controller, lead),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.grey, size: 18),
                                      tooltip: 'Edit details',
                                      onPressed: () => _showAddLeadDialog(context, controller, lead: lead),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        // Simple Pagination
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Page ${controller.currentPage.value}'),
                            IconButton(
                              onPressed: controller.currentPage.value > 1
                                  ? () {
                                      controller.currentPage.value--;
                                      controller.fetchLeads();
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            IconButton(
                              onPressed: (controller.currentPage.value * controller.itemsPerPage) < controller.totalLeads.value
                                  ? () {
                                      controller.currentPage.value++;
                                      controller.fetchLeads();
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPullPanel(LeadsController controller) {
    return Obx(() {
      final atLimit = controller.myFresh.value >= controller.freshMax.value;
      final noLeads = controller.freshAvailable.value == 0;
      final pulling = controller.isPulling.value;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.25)),
        ),
        color: AppTheme.primaryBlue.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppTheme.primaryBlue, size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fresh Lead Distribution',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available in Pool: ${controller.freshAvailable.value}',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              // My Fresh counter badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: atLimit ? Colors.red.shade50 : AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'My Fresh Leads: ${controller.myFresh.value} / ${controller.freshMax.value}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: atLimit ? Colors.red.shade700 : AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Pull button
              if (atLimit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text('Limit Reached', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                )
              else if (noLeads)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text('No Leads Available', style: TextStyle(color: Colors.orange.shade700, fontSize: 13)),
                )
              else
                ElevatedButton.icon(
                  onPressed: pulling ? null : () => controller.pullFreshLeads(),
                  icon: pulling
                      ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(pulling ? 'Pulling...' : 'Pull Fresh Leads'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              // Feedback message
              if (controller.pullMessage.value.isNotEmpty) ...[
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    controller.pullMessage.value,
                    style: TextStyle(
                      fontSize: 13,
                      color: controller.pullMessage.value.contains('reached') || controller.pullMessage.value.contains('No')
                          ? Colors.orange.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'New':
        return AppTheme.primaryBlue;
      case 'Contacted':
        return Colors.amber.shade700;
      case 'Interested':
        return Colors.teal;
      case 'Qualified':
        return Colors.blueAccent;
      case 'Demo / Meeting Scheduled':
        return Colors.deepPurple;
      case 'Demo / Meeting Completed':
        return Colors.purple;
      case 'Proposal Sent':
        return Colors.indigo;
      case 'Negotiation':
        return Colors.orange;
      case 'Follow-up':
        return Colors.blueGrey;
      case 'Won':
        return Colors.green;
      case 'Lost':
        return Colors.red;
      case 'On Hold':
        return Colors.grey;
      case 'Not Interested':
        return Colors.brown;
      case 'Invalid':
        return Colors.black54;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _showAddLeadDialog(BuildContext context, LeadsController controller, {LeadModel? lead}) {
    if (lead != null) {
      controller.nameController.text = lead.fullName;
      controller.phoneController.text = lead.mobileNumber;
      controller.emailController.text = lead.emailAddress ?? '';
      controller.cityController.text = lead.city ?? '';
      controller.stateController.text = lead.state ?? '';
      controller.assignRMId.value = lead.assignedRMId ?? '';
      controller.leadStage.value = lead.stage;
    } else {
      controller.resetForm();
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  lead != null ? 'Edit Lead Details' : 'Add New Lead',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller.nameController,
                  decoration: const InputDecoration(labelText: 'Full Name (Optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.phoneController,
                  decoration: const InputDecoration(labelText: 'Mobile Number *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                // RM Assign
                Obx(() {
                  final currentRMId = controller.assignRMId.value;
                  final currentRM = controller.staffList.firstWhereOrNull((s) => s.id == currentRMId);
                  final label = currentRM != null ? '${currentRM.name} (${currentRM.role})' : 'None (Unassigned)';

                  return InkWell(
                    onTap: () {
                      _showSearchableRMDialog(context, controller, onSelected: (rmId) {
                        controller.assignRMId.value = rmId ?? '';
                      });
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Assign Relationship Manager',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      child: Text(label, style: const TextStyle(fontSize: 14)),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // Stage Selection
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.leadStage.value,
                    decoration: const InputDecoration(labelText: 'Lead Stage', border: OutlineInputBorder()),
                    items: ['New', 'Contacted', 'Interested', 'Qualified', 'Demo / Meeting Scheduled', 'Demo / Meeting Completed', 'Proposal Sent', 'Negotiation', 'Follow-up', 'Won', 'Lost', 'On Hold', 'Not Interested', 'Invalid']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => controller.leadStage.value = val ?? 'New',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.cityController,
                  decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.stateController,
                  decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    Button(
                      title: 'Save',
                      buttonType: ButtonType.green,
                      onTap: () => controller.saveLead(existingId: lead?.id),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getFollowUpStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Completed':
        return Colors.green;
      case 'Rescheduled':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      case 'Skipped':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _showFollowUpDialog(BuildContext context, LeadsController controller, LeadModel lead) {
    controller.followUpNotesController.clear();
    controller.followUpDate.value = DateTime.now().add(const Duration(days: 1));
    controller.followUpType.value = 'Call';
    controller.followUpStatus.value = 'Pending';

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Follow-up for ${lead.fullName}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (lead.followUps.isNotEmpty) ...[
                const Text(
                  'Previous Follow-up Logs',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    border: Border.all(color: const Color(0xFFDEE2E6)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: lead.followUps.length,
                    separatorBuilder: (context, index) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final logItem = lead.followUps[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm').format(logItem.createdAt),
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      logItem.followUpType,
                                      style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getFollowUpStatusColor(logItem.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      logItem.status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getFollowUpStatusColor(logItem.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (logItem.nextFollowUpDate != null) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Next: ${DateFormat('yyyy-MM-dd').format(logItem.nextFollowUpDate!)}',
                                        style: const TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            logItem.notes,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF212529)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.followUpType.value,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        items: [
                          'Call', 'WhatsApp', 'SMS', 'Email', 'Video Call', 'Schedule Meeting',
                          'Send Brochure', 'Send Pricing', 'Send Proposal', 'Send Demo',
                          'Product Demo', 'Site Visit', 'Payment Follow-up', 'Document Follow-up',
                          'Contract Follow-up', 'Check Customer Requirement', 'Manager Follow-up',
                          'Renewal Follow-up', 'No Follow-up Required'
                        ].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => controller.followUpType.value = val ?? 'Call',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.followUpStatus.value,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                        items: ['Pending', 'Completed', 'Rescheduled', 'Cancelled', 'Skipped']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                        onChanged: (val) => controller.followUpStatus.value = val ?? 'Pending',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.followUpNotesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Follow-up Notes *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Date picker selector
              Obx(
                () => ListTile(
                  title: const Text('Next Action/Follow-up Date'),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(controller.followUpDate.value)),
                  trailing: const Icon(Icons.calendar_today),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppTheme.gray300),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: controller.followUpDate.value,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      controller.followUpDate.value = picked;
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  Button(
                    title: 'Submit',
                    buttonType: ButtonType.blue,
                    onTap: () => controller.addFollowUpLog(lead.id),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchableRMDialog(
    BuildContext context,
    LeadsController controller, {
    required Function(String? rmId) onSelected,
    String unassignedLabel = 'None (Leave Unassigned)',
    String unassignedSubtitle = 'Click to unassign lead',
  }) {
    final searchController = TextEditingController();
    final searchQuery = ''.obs;

    final filteredDirectors = <StaffModel>[].obs;
    final filteredManagers = <StaffModel>[].obs;
    final filteredStaff = <StaffModel>[].obs;
    final filteredOthers = <StaffModel>[].obs;

    void updateFilteredLists(String query) {
      final q = query.trim().toLowerCase();
      final allStaff = controller.staffList;

      filteredDirectors.value = allStaff
          .where((s) => s.role.toLowerCase() == 'director' && (q.isEmpty || s.name.toLowerCase().contains(q) || s.email.toLowerCase().contains(q)))
          .toList();

      filteredManagers.value = allStaff
          .where((s) => s.role.toLowerCase() == 'manager' && (q.isEmpty || s.name.toLowerCase().contains(q) || s.email.toLowerCase().contains(q)))
          .toList();

      filteredStaff.value = allStaff
          .where((s) => (s.role.toLowerCase() == 'staff' || s.role.toLowerCase() == 'rm' || s.role.toLowerCase() == 'relationship manager') && (q.isEmpty || s.name.toLowerCase().contains(q) || s.email.toLowerCase().contains(q)))
          .toList();

      filteredOthers.value = allStaff
          .where((s) => s.role.toLowerCase() != 'director' && s.role.toLowerCase() != 'manager' && s.role.toLowerCase() != 'staff' && s.role.toLowerCase() != 'rm' && s.role.toLowerCase() != 'relationship manager' && (q.isEmpty || s.name.toLowerCase().contains(q) || s.email.toLowerCase().contains(q)))
          .toList();
    }

    updateFilteredLists('');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Relationship Manager',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (val) {
                  searchQuery.value = val;
                  updateFilteredLists(val);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final noResults = filteredDirectors.isEmpty &&
                      filteredManagers.isEmpty &&
                      filteredStaff.isEmpty &&
                      filteredOthers.isEmpty;

                  if (noResults) {
                    return const Center(
                      child: Text('No RMs found matching your query.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade100,
                          child: const Icon(Icons.person_off_rounded, color: Colors.grey),
                        ),
                        title: Text(unassignedLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(unassignedSubtitle, style: const TextStyle(fontSize: 11)),
                        onTap: () {
                          onSelected(null);
                          Get.back();
                        },
                      ),
                      const Divider(),

                      if (filteredDirectors.isNotEmpty) ...[
                        _buildGroupHeader('Directors', Colors.blue.shade700),
                        ...filteredDirectors.map((s) => _buildStaffRow(s, onSelected)),
                      ],

                      if (filteredManagers.isNotEmpty) ...[
                        _buildGroupHeader('Managers', Colors.teal.shade700),
                        ...filteredManagers.map((s) => _buildStaffRow(s, onSelected)),
                      ],

                      if (filteredStaff.isNotEmpty) ...[
                        _buildGroupHeader('Relationship Managers / Staff', Colors.indigo.shade700),
                        ...filteredStaff.map((s) => _buildStaffRow(s, onSelected)),
                      ],

                      if (filteredOthers.isNotEmpty) ...[
                        _buildGroupHeader('Others', Colors.orange.shade700),
                        ...filteredOthers.map((s) => _buildStaffRow(s, onSelected)),
                      ],
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildStaffRow(StaffModel s, Function(String? id) onSelected) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
        child: Text(s.name.substring(0, 1).toUpperCase(), style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
      ),
      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.email, style: const TextStyle(fontSize: 12)),
          if (s.department.isNotEmpty)
            Text(s.department, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(s.role, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
      ),
      onTap: () {
        onSelected(s.id);
        Get.back();
      },
    );
  }
}
