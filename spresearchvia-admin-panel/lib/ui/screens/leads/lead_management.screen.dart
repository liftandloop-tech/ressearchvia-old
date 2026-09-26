import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/leads/leads.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:spresearch_web/models/lead.model.dart';
import 'package:spresearch_web/models/lead_pool.model.dart';
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
            Builder(
              builder: (context) {
                final authUser = Get.find<AuthController>().user.value;
                final canViewPools = (authUser?.isAdmin == true) || (authUser?.has('leads.view_pools') ?? false);
                final canBulkUpload = (authUser?.isAdmin == true) || (authUser?.has('leads.bulk_upload') ?? false);
                final canBulkAssign = (authUser?.isAdmin == true) || (authUser?.has('leads.bulk_assign') ?? false);
                final canCreateLead = (authUser?.isAdmin == true) || (authUser?.has('leads.create') ?? false);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 1180;

                    final actionButtons = <Widget>[
                      IconButton(
                        onPressed: () => controller.fetchLeads(),
                        icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                        tooltip: 'Refresh Leads',
                      ),
                      if (canViewPools) ...[
                        const SizedBox(width: 8),
                        Button(
                          title: 'Lead Pools',
                          buttonType: ButtonType.blue,
                          icon: Icons.workspaces_outlined,
                          onTap: () => _showLeadPoolsDialog(context, controller),
                        ),
                      ],
                      if (canBulkUpload) ...[
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
                      ],
                      if (canBulkAssign)
                        Obx(() {
                          if (controller.selectedLeadIds.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Button(
                              title: 'Bulk Assign (${controller.selectedLeadIds.length})',
                              buttonType: ButtonType.blue,
                              icon: Icons.assignment_ind_rounded,
                              onTap: () {
                                _showSearchableRMDialog(context, controller, onSelected: (rmId) {
                                  controller.bulkAssignRM(rmId);
                                });
                              },
                            ),
                          );
                        }),
                      if (canCreateLead) ...[
                        const SizedBox(width: 8),
                        Button(
                          title: 'Add New Lead',
                          buttonType: ButtonType.green,
                          icon: Icons.add,
                          onTap: () => _showAddLeadDialog(context, controller),
                        ),
                      ],
                    ];

                    final titleColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Lead Management',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track pipeline, manage distribution pools, and assign relationships',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleColumn,
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 4,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: actionButtons,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: titleColumn),
                        const SizedBox(width: 16),
                        Wrap(
                          spacing: 4,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: actionButtons,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Fresh Lead Pull Panel
            Builder(
              builder: (context) {
                final currentUser = Get.find<AuthController>().user.value;
                final isStaffRM = (currentUser?.isAdmin ?? false) == false && (currentUser?.isDirector ?? false) == false;
                final canPull = (currentUser?.isAdmin ?? false) || (currentUser?.isDirector ?? false) || isStaffRM || (currentUser?.has('leads.pull') ?? false);
                if (!canPull) return const SizedBox();
                return Column(
                  children: [
                    _buildPullPanel(controller),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Filters Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.gray200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 1050;

                    final searchField = TextField(
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
                    );

                    final stageFilter = Obx(
                      () {
                        const stages = ['All Stages', 'New', 'Contacted', 'Interested', 'Qualified', 'Demo / Meeting Scheduled', 'Demo / Meeting Completed', 'Proposal Sent', 'Negotiation', 'Follow-up', 'Won', 'Lost', 'On Hold', 'Not Interested', 'Invalid'];
                        final curStage = controller.selectedStage.value;
                        final safeStage = (stages.contains(curStage) || curStage.isEmpty) ? curStage : '';
                        return DropdownButtonFormField<String>(
                          key: ValueKey(safeStage),
                          isExpanded: true,
                          initialValue: safeStage,
                          hint: const Text('Filter Stage'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.gray300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: stages
                              .map((stage) => DropdownMenuItem(
                                    value: stage == 'All Stages' ? '' : stage,
                                    child: Text(stage),
                                  ))
                              .toList(),
                          onChanged: (val) => controller.updateFilters(stage: val ?? ''),
                        );
                      },
                    );

                    final poolFilter = Obx(
                      () {
                        final currentPoolId = controller.selectedFilterPoolId.value;
                        final poolItems = [
                          const DropdownMenuItem(value: '', child: Text('All Pools')),
                          ...controller.leadPoolsList.map((pool) => DropdownMenuItem(
                                value: pool.id,
                                child: Text(pool.name, overflow: TextOverflow.ellipsis),
                              )),
                        ];
                        final safePoolId = poolItems.any((item) => item.value == currentPoolId) ? currentPoolId : '';
                        return DropdownButtonFormField<String>(
                          key: ValueKey(safePoolId),
                          isExpanded: true,
                          initialValue: safePoolId,
                          hint: const Text('Filter Pool'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.gray300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          items: poolItems,
                          onChanged: (val) => controller.updateFilters(poolId: val ?? ''),
                        );
                      },
                    );

                    final rmFilter = Obx(() {
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
                    });

                    final resetBtn = TextButton.icon(
                      onPressed: () => controller.resetFilters(),
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Reset'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                    );

                    if (isCompact) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: searchField),
                              const SizedBox(width: 8),
                              resetBtn,
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: stageFilter),
                              const SizedBox(width: 12),
                              Expanded(child: poolFilter),
                              const SizedBox(width: 12),
                              Expanded(child: rmFilter),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(flex: 2, child: searchField),
                        const SizedBox(width: 16),
                        Expanded(child: stageFilter),
                        const SizedBox(width: 16),
                        Expanded(child: poolFilter),
                        const SizedBox(width: 16),
                        Expanded(child: rmFilter),
                        const SizedBox(width: 16),
                        resetBtn,
                      ],
                    );
                  },
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
                              DataColumn2(label: Text('Pool'), size: ColumnSize.M),
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
                                        color: _getStageColor(lead.stage).withValues(alpha: 0.1),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        lead.leadPoolName ?? 'Fresh Leads',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.indigo,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                                        Builder(
                                          builder: (context) {
                                            final authUser = Get.find<AuthController>().user.value;
                                            final canFollowUp = (authUser?.isAdmin == true) || (authUser?.has('leads.follow_up') ?? false);
                                            if (!canFollowUp) return const SizedBox.shrink();
                                            return IconButton(
                                              icon: const Icon(Icons.edit_note, color: AppTheme.primaryBlue, size: 20),
                                              tooltip: 'Log Follow-up',
                                              onPressed: () => _showFollowUpDialog(context, controller, lead),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Builder(
                                      builder: (context) {
                                        final authUser = Get.find<AuthController>().user.value;
                                        final canUpdate = (authUser?.isAdmin == true) || (authUser?.has('leads.update') ?? false);
                                        if (!canUpdate) return const SizedBox.shrink();
                                        return IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.grey, size: 18),
                                          tooltip: 'Edit details',
                                          onPressed: () => _showAddLeadDialog(context, controller, lead: lead),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        );
                                      },
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
      final pools = controller.leadPoolsList;
      final selectedPoolId = controller.selectedPullPoolId.value;
      final selectedPool = pools.firstWhereOrNull((p) => p.id == selectedPoolId) ??
          (pools.isNotEmpty ? pools.first : null);

      final pullSize = selectedPool?.pullSize ?? 20;
      final maxStaff = selectedPool?.maxPerStaff ?? controller.freshMax.value;
      final myCount = selectedPool?.myLeads ?? controller.myFresh.value;
      final available = selectedPool?.availableLeads ?? controller.freshAvailable.value;
      final poolName = selectedPool?.name ?? 'Fresh Leads';

      final atLimit = myCount >= maxStaff;
      final noLeads = available == 0;
      final pulling = controller.isPulling.value;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
        ),
        color: AppTheme.primaryBlue.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 980;

                  final titleSection = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: AppTheme.primaryBlue, size: 28),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Lead Distribution Pool: $poolName',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (selectedPool?.isDefaultFresh == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Text('Default', style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Available in Pool: $available (Batch: $pullSize leads)',
                              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final controlsSection = Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Pool selector dropdown if multiple pools
                      if (pools.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isDense: true,
                              value: pools.any((p) => p.id == selectedPool?.id) ? selectedPool?.id : (pools.isNotEmpty ? pools.first.id : null),
                              hint: const Text('Select Pool'),
                              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
                              style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                              items: pools.map((p) {
                                return DropdownMenuItem<String>(
                                  value: p.id,
                                  child: Text('${p.name} (${p.availableLeads} avail)'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  controller.selectedPullPoolId.value = val;
                                  controller.fetchPullStats();
                                }
                              },
                            ),
                          ),
                        ),
                      // My count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: atLimit ? Colors.red.shade50 : AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'My Leads: $myCount / $maxStaff',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: atLimit ? Colors.red.shade700 : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      // Pull button
                      if (atLimit)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text('Limit Reached', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                        )
                      else if (noLeads)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Text('No Leads Available', style: TextStyle(color: Colors.orange.shade700, fontSize: 12.5)),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: pulling ? null : () => controller.pullLeadsFromSelectedPool(),
                          icon: pulling
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.download_rounded, size: 16),
                          label: Text(pulling ? 'Pulling...' : 'Pull ($pullSize) Leads'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleSection,
                        const SizedBox(height: 12),
                        controlsSection,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: titleSection),
                      const SizedBox(width: 16),
                      controlsSection,
                    ],
                  );
                },
              ),
              // Feedback message
              if (controller.pullMessage.value.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  controller.pullMessage.value,
                  style: TextStyle(
                    fontSize: 13,
                    color: controller.pullMessage.value.contains('reached') || controller.pullMessage.value.contains('No')
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w500,
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
      controller.assignLeadPoolId.value = lead.leadPoolId ?? '';
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
                // Target Lead Pool Selection
                Obx(() {
                  final currentPoolId = controller.assignLeadPoolId.value;
                  final poolItems = [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Default (Fresh Leads)'),
                    ),
                    ...controller.leadPoolsList.map((pool) => DropdownMenuItem<String>(
                          value: pool.id,
                          child: Text(pool.name),
                        )),
                  ];
                  final safePoolId = poolItems.any((p) => p.value == currentPoolId) ? currentPoolId : '';
                  return Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(safePoolId),
                          initialValue: safePoolId,
                          decoration: const InputDecoration(
                            labelText: 'Target Lead Pool',
                            border: OutlineInputBorder(),
                          ),
                          items: poolItems,
                          onChanged: (val) => controller.assignLeadPoolId.value = val ?? '',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showCreateLeadPoolDialog(context, controller),
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue),
                        tooltip: 'Create New Pool',
                      ),
                    ],
                  );
                }),
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
                    key: ValueKey(controller.leadStage.value),
                    initialValue: controller.leadStage.value,
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
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
                                      color: Colors.blue.withValues(alpha: 0.1),
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
                                      color: _getFollowUpStatusColor(logItem.status).withValues(alpha: 0.1),
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
                                        color: Colors.purple.withValues(alpha: 0.1),
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
                        key: ValueKey(controller.followUpType.value),
                        initialValue: controller.followUpType.value,
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
                        key: ValueKey(controller.followUpStatus.value),
                        initialValue: controller.followUpStatus.value,
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
              ),
            ],
          ),
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
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
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

  void _showLeadPoolsDialog(BuildContext context, LeadsController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width > 840 ? 780 : MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.workspaces_outlined, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lead Pools Management',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage custom lead pools, batch pull limits, and staff capacity quotas',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Button(
                    title: '+ New Pool',
                    buttonType: ButtonType.green,
                    icon: Icons.add,
                    onTap: () => _showCreateLeadPoolDialog(context, controller),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Pools List
              Expanded(
                child: Obx(() {
                  if (controller.isPoolsLoading.value && controller.leadPoolsList.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.leadPoolsList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No lead pools found', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Create a custom pool to categorize leads and customize pull rules.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: controller.leadPoolsList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final pool = controller.leadPoolsList[idx];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: pool.isDefaultFresh ? AppTheme.primaryBlue.withValues(alpha: 0.3) : AppTheme.gray200,
                            width: pool.isDefaultFresh ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        pool.name,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                      ),
                                      if (pool.isDefaultFresh)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Text(
                                            'System Default',
                                            style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      if (pool.isGlobal)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.teal.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.public, size: 11, color: Colors.teal.shade700),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Global (All Staff)',
                                                style: TextStyle(fontSize: 10, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.purple.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.groups_outlined, size: 11, color: Colors.purple.shade700),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Team Pool (${pool.createdByName ?? 'Owner\'s Team'})',
                                                style: TextStyle(fontSize: 10, color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.download_rounded, size: 20, color: Colors.green),
                                      tooltip: 'Pull (${pool.pullSize}) Leads From ${pool.name}',
                                      onPressed: () {
                                        controller.pullLeadsFromSelectedPool(poolId: pool.id);
                                      },
                                    ),
                                    if (pool.canEdit)
                                      IconButton(
                                        icon: const Icon(Icons.tune_rounded, size: 20, color: AppTheme.primaryBlue),
                                        tooltip: 'Edit Pool Limits & Details',
                                        onPressed: () => _showEditLeadPoolDialog(context, controller, pool),
                                      ),
                                    if (pool.canDelete)
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                                        tooltip: 'Delete Pool',
                                        onPressed: () {
                                          Get.defaultDialog(
                                            title: 'Delete Lead Pool',
                                            middleText: 'Are you sure you want to delete "${pool.name}"? This action cannot be undone and pool must be empty.',
                                            textConfirm: 'Delete',
                                            textCancel: 'Cancel',
                                            confirmTextColor: Colors.white,
                                            buttonColor: Colors.red,
                                            onConfirm: () async {
                                              Get.back();
                                              await controller.deleteCustomLeadPool(pool.id);
                                            },
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            if (pool.description != null && pool.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                pool.description!,
                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 14),
                            // Metrics Badges Row
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _buildPoolBadge(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Available Leads',
                                  value: '${pool.availableLeads}',
                                  color: Colors.green,
                                ),
                                _buildPoolBadge(
                                  icon: Icons.layers_outlined,
                                  label: 'Total Leads',
                                  value: '${pool.totalLeads}',
                                  color: Colors.blueGrey,
                                ),
                                _buildPoolBadge(
                                  icon: Icons.download_rounded,
                                  label: 'Batch Pull Size',
                                  value: '${pool.pullSize} leads/fetch',
                                  color: Colors.indigo,
                                ),
                                _buildPoolBadge(
                                  icon: Icons.people_alt_outlined,
                                  label: 'Max Staff Cap',
                                  value: '${pool.maxPerStaff} leads',
                                  color: Colors.deepPurple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close', style: TextStyle(fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoolBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showCreateLeadPoolDialog(BuildContext context, LeadsController controller) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final pullSizeCtrl = TextEditingController(text: '20');
    final maxStaffCtrl = TextEditingController(text: '100');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: MediaQuery.of(context).size.width > 520 ? 460 : MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.add_business_outlined, color: AppTheme.primaryBlue, size: 19),
                  ),
                  const SizedBox(width: 10),
                  const Text('Create Custom Lead Pool', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Colors.blue.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pool Access & Distribution: Pools created by Admin are globally accessible to all staff. Pools created by Managers/Team Leads are isolated to the creator and their reporting team.',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Pool Name *',
                  hintText: 'e.g. VIP Campaigns, Inbound Webinars',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Notes on channel, audience, or purpose',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 15, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  const Text('Lead Distribution Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pullSizeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Pull Size (batch) *',
                        hintText: '20',
                        helperText: 'Leads per staff fetch',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxStaffCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Max Per Staff *',
                        hintText: '100',
                        helperText: 'Staff capacity cap',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Button(
                    title: 'Create Pool',
                    buttonType: ButtonType.green,
                    onTap: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        Get.snackbar('Validation', 'Pool name is required', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }
                      final pullSize = int.tryParse(pullSizeCtrl.text.trim());
                      if (pullSize == null || pullSize <= 0) {
                        Get.snackbar('Validation', 'Pull size must be a positive number', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }
                      final maxStaff = int.tryParse(maxStaffCtrl.text.trim());
                      if (maxStaff == null || maxStaff <= 0) {
                        Get.snackbar('Validation', 'Max staff capacity must be a positive number', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }
                      final success = await controller.createCustomLeadPool(
                        name,
                        descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        pullSize: pullSize,
                        maxPerStaff: maxStaff,
                      );
                      if (success) {
                        Get.back();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  void _showEditLeadPoolDialog(BuildContext context, LeadsController controller, LeadPoolModel pool) {
    final nameCtrl = TextEditingController(text: pool.name);
    final descCtrl = TextEditingController(text: pool.description ?? '');
    final pullSizeCtrl = TextEditingController(text: pool.pullSize.toString());
    final maxStaffCtrl = TextEditingController(text: pool.maxPerStaff.toString());

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: MediaQuery.of(context).size.width > 520 ? 460 : MediaQuery.of(context).size.width * 0.92,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 19),
                  ),
                  const SizedBox(width: 10),
                  Text('Edit Pool: ${pool.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                enabled: !pool.isDefaultFresh,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Pool Name',
                  helperText: pool.isDefaultFresh ? 'System pool name cannot be changed' : null,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 15, color: AppTheme.primaryBlue),
                  const SizedBox(width: 6),
                  const Text('Lead Distribution Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pullSizeCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Pull Size (batch) *',
                        helperText: 'Leads per staff fetch',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxStaffCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Max Per Staff *',
                        helperText: 'Staff capacity cap',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Button(
                    title: 'Update Pool',
                    buttonType: ButtonType.blue,
                    onTap: () async {
                      final pullSize = int.tryParse(pullSizeCtrl.text.trim());
                      if (pullSize == null || pullSize <= 0) {
                        Get.snackbar('Validation', 'Pull size must be a positive number', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }
                      final maxStaff = int.tryParse(maxStaffCtrl.text.trim());
                      if (maxStaff == null || maxStaff <= 0) {
                        Get.snackbar('Validation', 'Max staff capacity must be a positive number', backgroundColor: Colors.orange.withValues(alpha: 0.1));
                        return;
                      }
                      final updateData = <String, dynamic>{
                        if (!pool.isDefaultFresh) 'name': nameCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'pullSize': pullSize,
                        'maxPerStaff': maxStaff,
                      };
                      final success = await controller.updateCustomLeadPool(pool.id, updateData);
                      if (success) {
                        Get.back();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
