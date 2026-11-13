import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.config.dart';
import '../../../../controllers/leads/leads.controller.dart';
import '../../../../models/lead.model.dart';
import 'manage_segments_dialog.widget.dart';
import 'set_free_trial_dialog.widget.dart';
import 'click_to_call_dialog.widget.dart';

class LeadDetailDialog extends StatefulWidget {
  final LeadModel lead;
  final LeadsController controller;

  const LeadDetailDialog({
    super.key,
    required this.lead,
    required this.controller,
  });

  @override
  State<LeadDetailDialog> createState() => _LeadDetailDialogState();
}

class _LeadDetailDialogState extends State<LeadDetailDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LeadModel _currentLead;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentLead = widget.lead;
    widget.controller.fetchLeadTimeline(widget.lead.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshLeadData() {
    final updated = widget.controller.leadsList.firstWhereOrNull((l) => l.id == _currentLead.id);
    if (updated != null && mounted) {
      setState(() => _currentLead = updated);
    }
  }

  Color _getStageColor(String stage) {
    switch (stage) {
      case 'New': return Colors.blue;
      case 'App Onboarded': return Colors.teal;
      case 'Contacted': return Colors.indigo;
      case 'Interested': return Colors.green;
      case 'Qualified': return Colors.teal;
      case 'Won': return Colors.green.shade800;
      case 'Lost': return Colors.red;
      case 'Not Interested': return Colors.red.shade700;
      case 'Invalid': return Colors.grey;
      default: return AppTheme.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd().add_jm();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 680,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _currentLead.fullName.isNotEmpty ? _currentLead.fullName : 'Unnamed Lead',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getStageColor(_currentLead.stage).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _currentLead.stage,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStageColor(_currentLead.stage),
                              ),
                            ),
                          ),
                          if (_currentLead.isAppUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('APP USER', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_currentLead.mobileNumber} ${_currentLead.emailAddress != null ? "• ${_currentLead.emailAddress}" : ""}',
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_in_talk, color: Colors.green, size: 20),
                  tooltip: 'Call Lead (Airtel Virtual SIM)',
                  onPressed: () {
                    Get.dialog(
                      ClickToCallDialog(
                        lead: _currentLead,
                        onFollowUpSaved: () {
                          widget.controller.fetchLeads();
                          _refreshLeadData();
                        },
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab bar
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.gray500,
              indicatorColor: AppTheme.primaryBlue,
              tabs: const [
                Tab(icon: Icon(Icons.info_outline, size: 16), text: 'Overview'),
                Tab(icon: Icon(Icons.timeline, size: 16), text: 'Activity Timeline'),
                Tab(icon: Icon(Icons.category_outlined, size: 16), text: 'Segments & Trial'),
                Tab(icon: Icon(Icons.history, size: 16), text: 'Follow-ups'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(dateFormat),
                  _buildTimelineTab(dateFormat),
                  _buildSegmentsAndTrialTab(),
                  _buildFollowUpsTab(dateFormat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(DateFormat dateFormat) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Contact Information'),
          _buildInfoGrid([
            _buildInfoTile('Full Name', _currentLead.fullName.isNotEmpty ? _currentLead.fullName : '—'),
            _buildInfoTile('Mobile Number', _currentLead.mobileNumber),
            _buildInfoTile('Alternate Mobile', _currentLead.alternateMobile ?? '—'),
            _buildInfoTile('Email Address', _currentLead.emailAddress ?? '—'),
            _buildInfoTile('City', _currentLead.city ?? '—'),
            _buildInfoTile('State', _currentLead.state ?? '—'),
            _buildInfoTile('Remarks / Description', _currentLead.remarks.isNotEmpty ? _currentLead.remarks : 'None'),
          ]),
          const SizedBox(height: 20),
          _buildSectionHeader('Lead Attribution & Source'),
          _buildInfoGrid([
            _buildInfoTile('Campaign Name', _currentLead.campaignName ?? 'None'),
            _buildInfoTile('Lead Vendor', _currentLead.leadVendorName ?? 'None'),
            _buildInfoTile('Lead Pool', _currentLead.leadPoolName ?? 'Fresh Leads'),
            _buildInfoTile('Lead Source Type', _currentLead.leadSource),
            _buildInfoTile('Created Date', dateFormat.format(_currentLead.createdAt)),
            _buildInfoTile('Assigned RM', _currentLead.assignedRMName ?? 'Unassigned'),
          ]),
        ],
      ),
    );
  }

  // --- TAB 2: ACTIVITY TIMELINE ---
  Widget _buildTimelineTab(DateFormat dateFormat) {
    return Obx(() {
      if (widget.controller.isTimelineLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
      }
      final timeline = widget.controller.selectedLeadTimeline;
      if (timeline.isEmpty) {
        return const Center(child: Text('No activity timeline recorded for this lead yet.'));
      }

      return ListView.builder(
        itemCount: timeline.length,
        itemBuilder: (context, index) {
          final event = timeline[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: _getTimelineEventColor(event.eventType).withValues(alpha: 0.15),
                      child: Icon(_getTimelineEventIcon(event.eventType), size: 14, color: _getTimelineEventColor(event.eventType)),
                    ),
                    if (index < timeline.length - 1)
                      Container(width: 2, height: 36, color: AppTheme.gray300),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.gray50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              dateFormat.format(event.createdAt),
                              style: const TextStyle(fontSize: 11, color: AppTheme.gray500),
                            ),
                          ],
                        ),
                        if (event.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(event.description, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
                        ],
                        if (event.performedByName != null) ...[
                          const SizedBox(height: 4),
                          Text('By: ${event.performedByName}', style: const TextStyle(fontSize: 11, color: AppTheme.gray500, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  // --- TAB 3: SEGMENTS & TRIAL ---
  Widget _buildSegmentsAndTrialTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segment Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Assigned Segments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Get.dialog<bool>(
                          ManageSegmentsDialog(lead: _currentLead, controller: widget.controller),
                        );
                        if (res == true) _refreshLeadData();
                      },
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Manage Segments'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_currentLead.segmentNames.isEmpty)
                  const Text('No segments assigned to this lead yet.', style: TextStyle(color: AppTheme.gray500, fontSize: 12.5))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _currentLead.segmentNames
                        .map((s) => Chip(
                              label: Text(s, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Free Trial Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Free Trial Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (_currentLead.hasActiveFreeTrial)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: const Text('ACTIVE TRIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                          )
                        else if (_currentLead.freeTrialEndDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: const Text('EXPIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                          ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Get.dialog<bool>(
                          SetFreeTrialDialog(lead: _currentLead, controller: widget.controller),
                        );
                        if (res == true) _refreshLeadData();
                      },
                      icon: const Icon(Icons.date_range, size: 14),
                      label: const Text('Set / Update Trial'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_currentLead.freeTrialStartDate == null && _currentLead.freeTrialEndDate == null)
                  const Text('No free trial dates have been set for this lead.', style: TextStyle(color: AppTheme.gray500, fontSize: 12.5))
                else
                  Row(
                    children: [
                      _buildInfoTile('Start Date', _currentLead.freeTrialStartDate != null ? DateFormat.yMMMd().format(_currentLead.freeTrialStartDate!) : '—'),
                      const SizedBox(width: 24),
                      _buildInfoTile('End Date', _currentLead.freeTrialEndDate != null ? DateFormat.yMMMd().format(_currentLead.freeTrialEndDate!) : '—'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 4: FOLLOW-UPS ---
  Widget _buildFollowUpsTab(DateFormat dateFormat) {
    final followUps = _currentLead.followUps;

    return Column(
      children: [
        if (followUps.isEmpty)
          const Expanded(child: Center(child: Text('No follow-up notes logged yet.')))
        else
          Expanded(
            child: ListView.separated(
              itemCount: followUps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final f = followUps[idx];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(f.followUpType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (f.status == 'Completed' ? Colors.green : Colors.orange).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(f.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: f.status == 'Completed' ? Colors.green : Colors.orange)),
                              ),
                            ],
                          ),
                          Text(dateFormat.format(f.followUpDate), style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(f.notes, style: const TextStyle(fontSize: 12.5)),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        children: children,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Color _getTimelineEventColor(String type) {
    switch (type) {
      case 'LEAD_CREATED': return AppTheme.successGreen;
      case 'LEAD_ASSIGNED': return AppTheme.primaryBlue;
      case 'STATUS_UPDATED': return Colors.purple;
      case 'FOLLOW_UP_ADDED': return Colors.orange;
      case 'FOLLOW_UP_UPDATED': return Colors.amber.shade800;
      case 'SEGMENT_ASSIGNED': return Colors.teal;
      case 'FREE_TRIAL_UPDATED': return Colors.cyan.shade800;
      case 'LEAD_OVERWRITTEN': return Colors.indigo;
      default: return AppTheme.gray500;
    }
  }

  IconData _getTimelineEventIcon(String type) {
    switch (type) {
      case 'LEAD_CREATED': return Icons.add_circle_outline;
      case 'LEAD_ASSIGNED': return Icons.person_add_alt_1;
      case 'STATUS_UPDATED': return Icons.swap_horiz;
      case 'FOLLOW_UP_ADDED': return Icons.phone_forwarded;
      case 'FOLLOW_UP_UPDATED': return Icons.done_all;
      case 'SEGMENT_ASSIGNED': return Icons.category;
      case 'FREE_TRIAL_UPDATED': return Icons.card_giftcard;
      case 'LEAD_OVERWRITTEN': return Icons.refresh;
      default: return Icons.event_note;
    }
  }
}
