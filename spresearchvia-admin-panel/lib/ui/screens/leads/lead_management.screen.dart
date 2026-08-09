import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/leads/leads.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:spresearch_web/models/lead.model.dart';

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
                Button(
                  title: 'Add New Lead',
                  buttonType: ButtonType.green,
                  icon: Icons.add,
                  onTap: () => _showAddLeadDialog(context, controller),
                ),
              ],
            ),
            const SizedBox(height: 32),

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
                          items: ['New', 'Contacted', 'Onboarding', 'Converted', 'Rejected']
                              .map((stage) => DropdownMenuItem(value: stage, child: Text(stage)))
                              .toList(),
                          onChanged: (val) => controller.updateFilters(stage: val ?? ''),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // RM Filter
                    Expanded(
                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          value: controller.staffList.any((s) => s.id == controller.selectedRMId.value)
                              ? controller.selectedRMId.value
                              : null,
                          hint: const Text('Filter Assigned RM'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.gray300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: controller.staffList
                              .map((staff) => DropdownMenuItem(
                                    value: staff.id,
                                    child: Text(staff.name),
                                  ))
                              .toList(),
                          onChanged: (val) => controller.updateFilters(rmId: val ?? ''),
                        ),
                      ),
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
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStageColor(lead.stage).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        lead.stage,
                                        style: TextStyle(
                                          color: _getStageColor(lead.stage),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(lead.assignedRMName ?? 'Unassigned')),
                                  DataCell(Text(
                                    [lead.city, lead.state].where((x) => x != null && x.isNotEmpty).join(', '),
                                  )),
                                  DataCell(
                                    Text(
                                      lead.followUps.isEmpty
                                          ? 'None'
                                          : 'Last: ${lead.followUps.last.notes}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      onSelected: (val) {
                                        if (val == 'follow') {
                                          _showFollowUpDialog(context, controller, lead);
                                        } else if (val == 'edit') {
                                          _showAddLeadDialog(context, controller, lead: lead);
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'follow',
                                          child: ListTile(
                                            leading: Icon(Icons.note_add),
                                            title: Text('Add Follow-up'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit),
                                            title: Text('Edit details'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ],
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

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'New':
        return AppTheme.primaryBlue;
      case 'Contacted':
        return Colors.amber.shade700;
      case 'Onboarding':
        return Colors.orange;
      case 'Converted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
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
                  decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
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
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.staffList.any((s) => s.id == controller.assignRMId.value)
                        ? controller.assignRMId.value
                        : null,
                    hint: const Text('Assign Relationship Manager'),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: controller.staffList
                        .map((rm) => DropdownMenuItem(value: rm.id, child: Text(rm.name)))
                        .toList(),
                    onChanged: (val) => controller.assignRMId.value = val ?? '',
                  ),
                ),
                const SizedBox(height: 16),
                // Stage Selection
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.leadStage.value,
                    decoration: const InputDecoration(labelText: 'Lead Stage', border: OutlineInputBorder()),
                    items: ['New', 'Contacted', 'Onboarding', 'Converted', 'Rejected']
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

  void _showFollowUpDialog(BuildContext context, LeadsController controller, LeadModel lead) {
    controller.followUpNotesController.clear();
    controller.followUpDate.value = DateTime.now().add(const Duration(days: 1));

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 450,
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Next: ${DateFormat('yyyy-MM-dd').format(logItem.followUpDate)}',
                                  style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
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
}
