import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.config.dart';
import '../../../../models/lead.model.dart';
import '../../../../models/call_log.model.dart';
import '../../../../services/telephony.service.dart';
import '../../../../controllers/auth/auth.controller.dart';
import '../../../../controllers/leads/leads.controller.dart';
import '../../../widgets/button.widget.dart';

class ClickToCallDialog extends StatefulWidget {
  final LeadModel lead;
  final VoidCallback? onFollowUpSaved;

  const ClickToCallDialog({
    super.key,
    required this.lead,
    this.onFollowUpSaved,
  });

  @override
  State<ClickToCallDialog> createState() => _ClickToCallDialogState();
}

class _ClickToCallDialogState extends State<ClickToCallDialog> with SingleTickerProviderStateMixin {
  final TelephonyService _telephonyService = Get.isRegistered<TelephonyService>()
      ? Get.find<TelephonyService>()
      : Get.put(TelephonyService(), permanent: true);

  late TabController _tabController;
  final TextEditingController _extensionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _callStatus = 'idle'; // idle, initiating, ringing, on-call, completed, failed
  String? _currentCallId;
  String? _currentCallLogId;
  int _callDurationSeconds = 0;
  Timer? _timer;
  Timer? _pollTimer;

  bool _isHangupLoading = false;
  bool _isSaveFollowUpLoading = false;
  String _selectedStage = '';
  DateTime? _nextFollowUpDate;

  List<CallLogModel> _leadCallLogs = [];
  bool _isLoadingHistory = false;

  final List<String> _stages = [
    'New', 'Contacted', 'Interested', 'Qualified',
    'Demo / Meeting Scheduled', 'Demo / Meeting Completed',
    'Proposal Sent', 'Negotiation', 'Follow-up', 'Won', 'Lost',
    'On Hold', 'Not Interested', 'Invalid'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedStage = widget.lead.stage;

    // Pre-fill extension from current authenticated staff profile or fallback to 101
    final currentUser = Get.isRegistered<AuthController>() ? Get.find<AuthController>().user.value : null;
    final staffExt = currentUser?.rawJson?['telephonyExtension']?.toString() ?? '101';
    _extensionController.text = staffExt;

    _fetchCallHistory();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollTimer?.cancel();
    _extensionController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCallHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await _telephonyService.getLeadCalls(widget.lead.id);
    if (mounted) {
      setState(() {
        _leadCallLogs = history;
        _isLoadingHistory = false;
      });
    }
  }

  void _startDurationTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _stopDurationTimer() {
    _timer?.cancel();
    _pollTimer?.cancel();
  }

  Future<void> _initiateCall() async {
    final ext = _extensionController.text.trim();
    if (ext.isEmpty) {
      Get.snackbar('Extension Required', 'Please enter your extension number to place the call.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.amber.shade100);
      return;
    }

    setState(() {
      _callStatus = 'initiating';
      _callDurationSeconds = 0;
    });

    final res = await _telephonyService.initiateClickToCall(
      leadId: widget.lead.id,
      extension: ext,
    );

    if (!res.success || res.callId == null) {
      setState(() => _callStatus = 'failed');
      Get.snackbar('Call Failed', res.message ?? 'Could not initiate call',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
      return;
    }

    if (mounted) {
      setState(() {
        _currentCallId = res.callId;
        _currentCallLogId = res.callLogId;
        _callStatus = 'ringing';
      });
    }

    _startDurationTimer();
    _startStatusPolling(res.callId!);
  }

  void _startStatusPolling(String callId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _callStatus == 'completed' || _callStatus == 'failed') {
        timer.cancel();
        return;
      }

      final statusRes = await _telephonyService.getCallStatus(callId);
      if (statusRes.success && mounted) {
        setState(() {
          _callStatus = statusRes.status;
          if (statusRes.durationSeconds > 0) {
            _callDurationSeconds = statusRes.durationSeconds;
          }
        });

        if (statusRes.status == 'completed' || statusRes.status == 'cancelled' || statusRes.status == 'failed') {
          _stopDurationTimer();
          _fetchCallHistory();
        }
      }
    });
  }

  Future<void> _hangupCall() async {
    if (_currentCallId == null) return;
    setState(() => _isHangupLoading = true);

    await _telephonyService.hangupCall(_currentCallId!);
    _stopDurationTimer();

    if (mounted) {
      setState(() {
        _callStatus = 'completed';
        _isHangupLoading = false;
      });
      _fetchCallHistory();
    }
  }

  Future<void> _saveFollowUp() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      Get.snackbar('Notes Required', 'Please enter notes for this call before submitting.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.amber.shade100);
      return;
    }

    setState(() => _isSaveFollowUpLoading = true);

    bool success = false;
    if (_currentCallLogId != null) {
      success = await _telephonyService.logCallFollowUp(
        callLogId: _currentCallLogId!,
        notes: notes,
        status: 'Completed',
        nextFollowUpDate: _nextFollowUpDate,
        stage: _selectedStage,
      );
    } else {
      // Fallback direct follow-up via LeadsController if call wasn't tracked
      final leadsController = Get.isRegistered<LeadsController>() ? Get.find<LeadsController>() : null;
      if (leadsController != null) {
        success = await leadsController.leadService.addFollowUp(
          widget.lead.id,
          notes,
          DateTime.now(),
          followUpType: 'Call',
          status: 'Completed',
          nextFollowUpDate: _nextFollowUpDate,
        );
        if (_selectedStage.isNotEmpty && _selectedStage != widget.lead.stage) {
          await leadsController.leadService.updateLead(widget.lead.id, {'stage': _selectedStage});
        }
      }
    }

    setState(() => _isSaveFollowUpLoading = false);

    if (success) {
      Get.snackbar('Success', 'Call follow-up logged successfully!',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
      widget.onFollowUpSaved?.call();
      if (Get.isRegistered<LeadsController>()) {
        Get.find<LeadsController>().fetchLeads();
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Get.snackbar('Error', 'Failed to save follow-up details',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'on-call':
      case 'connected':
        return Colors.green;
      case 'ringing':
      case 'initiating':
        return Colors.amber.shade700;
      case 'completed':
        return AppTheme.primaryBlue;
      case 'failed':
      case 'busy':
      case 'unanswered':
        return Colors.red;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SelectionArea(
        child: Container(
          width: 620,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Icon(Icons.phone_in_talk, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virtual SIM Click-to-Call',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        'Airtel Cloud Telephony • Lead: ${widget.lead.fullName}',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab bar for Active Call vs Call History
            Container(
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Dial & Session'),
                  Tab(text: 'Call History'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab View
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDialAndSessionTab(),
                  _buildCallHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDialAndSessionTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recipient Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    widget.lead.fullName.isNotEmpty ? widget.lead.fullName[0].toUpperCase() : 'L',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.lead.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.call, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(widget.lead.mobileNumber, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          if (widget.lead.city != null && widget.lead.city!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text('•  ${widget.lead.city}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                // Extension field
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _extensionController,
                    enabled: _callStatus == 'idle' || _callStatus == 'failed',
                    decoration: const InputDecoration(
                      labelText: 'My Ext',
                      hintText: '101',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Live Call State Banner
          if (_callStatus != 'idle') ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: _getStatusColor(_callStatus).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _getStatusColor(_callStatus).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getStatusColor(_callStatus),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _callStatus.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(_callStatus),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _formatDuration(_callDurationSeconds),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (_callStatus == 'ringing') ...[
                    const SizedBox(height: 8),
                    const Text('Connecting your extension handset first, then dialing lead...',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                  if (_callStatus == 'on-call') ...[
                    const SizedBox(height: 8),
                    const Text('Call is connected and active.',
                        style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                  if (_callStatus == 'completed') ...[
                    const SizedBox(height: 8),
                    const Text('Call has ended. Please log your follow-up notes below.',
                        style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action Buttons: Call / Hangup
          if (_callStatus == 'idle' || _callStatus == 'failed') ...[
            Button(
              title: 'Start Click-to-Call',
              buttonType: ButtonType.green,
              icon: Icons.phone_forwarded,
              onTap: _initiateCall,
            ),
          ] else if (_callStatus == 'initiating' || _callStatus == 'ringing' || _callStatus == 'on-call') ...[
            ElevatedButton.icon(
              onPressed: _isHangupLoading ? null : _hangupCall,
              icon: _isHangupLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.call_end),
              label: const Text('End Call / Hang Up', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ] else if (_callStatus == 'completed') ...[
            OutlinedButton.icon(
              onPressed: _initiateCall,
              icon: const Icon(Icons.refresh),
              label: const Text('Redial Lead'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Follow-Up & Stage Form Section
          const Divider(),
          const SizedBox(height: 8),
          const Text('Post-Call Follow-up & Status Update',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),

          // Stage Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedStage.isNotEmpty && _stages.contains(_selectedStage) ? _selectedStage : 'Contacted',
            decoration: const InputDecoration(
              labelText: 'Update Lead Stage',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: _stages.map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStage = val);
            },
          ),
          const SizedBox(height: 12),

          // Next Follow-up Date Picker
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryBlue),
            title: Text(
              _nextFollowUpDate == null
                  ? 'Set Next Action Date (Optional)'
                  : 'Next Follow-up: ${DateFormat('dd MMM yyyy, hh:mm a').format(_nextFollowUpDate!)}',
              style: const TextStyle(fontSize: 13),
            ),
            trailing: TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 11, minute: 0),
                  );
                  setState(() {
                    _nextFollowUpDate = DateTime(
                      date.year, date.month, date.day,
                      time?.hour ?? 11, time?.minute ?? 0,
                    );
                  });
                }
              },
              child: const Text('Pick Date'),
            ),
          ),
          const SizedBox(height: 8),

          // Call Notes
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Call Notes & Discussion Summary *',
              hintText: 'Enter discussion highlights, customer requirements, interest level...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Submit Follow-Up
          Button(
            title: _isSaveFollowUpLoading ? 'Saving...' : 'Save Call Follow-up',
            buttonType: ButtonType.blue,
            icon: Icons.save,
            onTap: _isSaveFollowUpLoading ? () {} : _saveFollowUp,
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leadCallLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_missed, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text('No call records found for this lead.', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _leadCallLogs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final log = _leadCallLogs[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(log.status).withValues(alpha: 0.1),
            child: Icon(Icons.phone, color: _getStatusColor(log.status), size: 18),
          ),
          title: Row(
            children: [
              Text(
                'Ext ${log.fromDestination} → ${log.toDestination}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(log.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.status,
                  style: TextStyle(color: _getStatusColor(log.status), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                'Staff: ${log.staffName ?? 'Staff'} • Duration: ${_formatDuration(log.durationSeconds)} • ${DateFormat('dd MMM yyyy, hh:mm a').format(log.startedAt)}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              if (log.notes != null && log.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Notes: ${log.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ]
            ],
          ),
        );
      },
    );
  }
}
