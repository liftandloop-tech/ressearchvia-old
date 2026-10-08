import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/theme.config.dart';
import '../../../../controllers/leads/leads.controller.dart';

class BulkUploadDialog extends StatefulWidget {
  final LeadsController controller;
  final int initialTab;

  const BulkUploadDialog({
    super.key,
    required this.controller,
    this.initialTab = 0,
  });

  @override
  State<BulkUploadDialog> createState() => _BulkUploadDialogState();
}

class _BulkUploadDialogState extends State<BulkUploadDialog> {
  late int _activeTab;

  // Quick Paste State (Create Leads)
  final _pasteController = TextEditingController();
  final List<String> _validNumbers = [];
  final List<Map<String, String>> _previewItems = [];
  int _duplicateCount = 0;
  int _invalidCount = 0;
  bool _isSubmitting = false;

  // Options for Ingestion
  String _duplicateStrategy = 'skip';
  String? _assignedRM;
  String _leadStage = 'New';
  String? _selectedLeadPoolId;
  List<dynamic> _leadPools = [];
  bool _isLoadingPools = true;

  // Quick Paste State (Assign Leads to RM)
  final _assignPasteController = TextEditingController();
  final List<String> _assignUniqueNumbers = [];
  int _assignDuplicateCount = 0;
  int _assignInvalidCount = 0;
  bool _isAssignSubmitting = false;
  String? _targetAssignRMId;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _fetchLeadPools();

    // Default to the first active staff member if available for assignment
    final activeStaff = widget.controller.staffList
        .where((s) => s.status.toLowerCase() == 'active')
        .toList();
    if (activeStaff.isNotEmpty) {
      _targetAssignRMId = activeStaff.first.id;
    }
  }

  @override
  void dispose() {
    _pasteController.dispose();
    _assignPasteController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeadPools() async {
    try {
      final res = await widget.controller.leadService.getLeadPools();
      if (!res.status.hasError && res.body != null) {
        final pools = res.body['data'] as List? ?? [];
        if (mounted) {
          setState(() {
            _leadPools = pools;
            _isLoadingPools = false;
            if (_selectedLeadPoolId == null && _leadPools.isNotEmpty) {
              final freshPool = _leadPools.firstWhere(
                (p) => p['isSystemDefaultFresh'] == true || p['name'] == 'Fresh Leads',
                orElse: () => _leadPools.first,
              );
              _selectedLeadPoolId = freshPool['_id']?.toString();
            }
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingPools = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPools = false);
    }
  }

  /// Normalizes any input phone number (10, 11, 12, or 13 digits) to standard 10 digits
  String _normalizePhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return clean;
    }
    // 11 digits (e.g. 09876543210 -> strip leading 0)
    if (clean.length == 11 && clean.startsWith('0')) {
      return clean.substring(1);
    }
    // 12 digits (e.g. 919876543210 -> strip 91)
    if (clean.length == 12 && clean.startsWith('91')) {
      return clean.substring(2);
    }
    // 13 digits (e.g. 0919876543210 -> strip 091)
    if (clean.length == 13 && clean.startsWith('091')) {
      return clean.substring(3);
    }
    // General case: if longer than 10 digits and ends with valid 10-digit mobile starting with 6-9
    if (clean.length > 10) {
      final last10 = clean.substring(clean.length - 10);
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(last10)) {
        return last10;
      }
    }
    return clean;
  }

  void _onTextChanged(String text) {
    final seen = <String>{};
    final valid = <String>[];
    final preview = <Map<String, String>>[];
    int dups = 0;
    int invalids = 0;

    // Split on line breaks (Enter key \r\n, \r, \n, unicode breaks), commas, and semicolons
    final rawTokens = text.split(RegExp(r'[\r\n\u2028\u2029,;]+'));

    for (final token in rawTokens) {
      final trimmed = token.trim();
      if (trimmed.isEmpty) continue;

      final normalized10 = _normalizePhone(trimmed);

      // Validate: exactly 10 digits starting with 6, 7, 8, or 9
      if (normalized10.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(normalized10)) {
        if (seen.contains(normalized10)) {
          dups++;
        } else {
          seen.add(normalized10);
          valid.add(normalized10);
          if (preview.length < 50) {
            preview.add({
              'raw': trimmed,
              'normalized': normalized10,
            });
          }
        }
      } else {
        invalids++;
      }
    }

    setState(() {
      _validNumbers.clear();
      _validNumbers.addAll(valid);
      _previewItems.clear();
      _previewItems.addAll(preview);
      _duplicateCount = dups;
      _invalidCount = invalids;
    });
  }

  Future<void> _handlePasteSubmit() async {
    if (_validNumbers.isEmpty) {
      Get.snackbar(
        'No Valid Numbers',
        'Please enter or paste at least one valid 10-digit mobile number.',
        backgroundColor: Colors.amber.withOpacity(0.2),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.controller.bulkPasteLeads(
      rawText: _pasteController.text,
      leadPoolId: _selectedLeadPoolId,
      assignedRM: _assignedRM,
      stage: _leadStage,
      duplicateStrategy: _duplicateStrategy,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      Get.back();
    }
  }

  void _onAssignTextChanged(String text) {
    final seen = <String>{};
    final valid = <String>[];
    int dups = 0;
    int invalids = 0;

    final rawTokens = text.split(RegExp(r'[\r\n\u2028\u2029,;\t]+'));

    for (final raw in rawTokens) {
      final token = raw.trim();
      if (token.isEmpty) continue;

      final normalized10 = _normalizePhone(token);
      if (normalized10.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(normalized10)) {
        if (seen.contains(normalized10)) {
          dups++;
        } else {
          seen.add(normalized10);
          valid.add(normalized10);
        }
      } else {
        invalids++;
      }
    }

    setState(() {
      _assignUniqueNumbers.clear();
      _assignUniqueNumbers.addAll(valid);
      _assignDuplicateCount = dups;
      _assignInvalidCount = invalids;
    });
  }

  Future<void> _handleAssignSubmit() async {
    if (_assignUniqueNumbers.isEmpty) {
      Get.snackbar(
        'Validation Alert',
        'Please paste at least one valid 10-digit mobile number.',
        backgroundColor: Colors.amber.withOpacity(0.2),
      );
      return;
    }
    if (_targetAssignRMId == null || _targetAssignRMId!.isEmpty) {
      Get.snackbar(
        'Validation Alert',
        'Please select a target Relationship Manager (RM).',
        backgroundColor: Colors.amber.withOpacity(0.2),
      );
      return;
    }

    setState(() => _isAssignSubmitting = true);

    final success = await widget.controller.bulkAssignByNumbers(
      rawNumbers: _assignUniqueNumbers.join('\n'),
      assignedRM: _targetAssignRMId!,
    );

    if (mounted) {
      setState(() => _isAssignSubmitting = false);
      if (success) {
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Bulk Lead Operations',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Upload files, paste new leads, or bulk assign relationships',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.gray500),
                      ),
                    ],
                  ),
                ),
                // Quick Action: Download Template Button
                OutlinedButton.icon(
                  onPressed: () => widget.controller.downloadTemplate(),
                  icon: const Icon(Icons.download, size: 15),
                  label: const Text('Template', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.gray400),
                  splashRadius: 20,
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Selector (Segmented buttons)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      title: 'Upload File',
                      icon: Icons.table_chart_outlined,
                      isActive: _activeTab == 0,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'Paste to Create',
                      icon: Icons.paste_rounded,
                      isActive: _activeTab == 1,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'Paste to Assign',
                      icon: Icons.assignment_ind_rounded,
                      isActive: _activeTab == 2,
                      onTap: () => setState(() => _activeTab = 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tab Content
            Expanded(
              child: SingleChildScrollView(
                child: _activeTab == 0
                    ? _buildFileTab()
                    : (_activeTab == 1 ? _buildPasteTab() : _buildAssignTab()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.primaryBlue : AppTheme.gray500,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.primaryBlue : AppTheme.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 0: UPLOAD FILE (EXCEL / CSV) ---
  Widget _buildFileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropzone box
        InkWell(
          onTap: () {
            Get.back();
            widget.controller.pickAndUploadBulkLeads();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gray300, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, size: 36, color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Click to Browse & Upload File',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Supports .xlsx, .xls, and .csv files',
                  style: TextStyle(fontSize: 13, color: AppTheme.gray500),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    widget.controller.pickAndUploadBulkLeads();
                  },
                  icon: const Icon(Icons.file_open_outlined, size: 16),
                  label: const Text('Choose File from Device'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Template Download Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.gray200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.download_for_offline_outlined, color: AppTheme.successGreen, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Need a sample spreadsheet template?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 2),
                    Text(
                      'Download our pre-formatted CSV template with standard columns (fullName, mobileNumber, email, city, state).',
                      style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => widget.controller.downloadTemplate(),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download Template'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 1: PASTE NUMBERS (CREATE LEADS) ---
  Widget _buildPasteTab() {
    final seenStaffIds = <String>{};
    final activeStaff = widget.controller.staffList
        .where((s) => s.id.isNotEmpty && s.status.toLowerCase() == 'active' && seenStaffIds.add(s.id))
        .toList();
    final safeAssignedRM = (_assignedRM != null && activeStaff.any((s) => s.id == _assignedRM)) ? _assignedRM : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Helper notification banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.skyBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.skyBlue.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.auto_fix_high, size: 20, color: AppTheme.skyBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paste numbers one per line (Enter key) or separated by commas. Country codes (+91, 91, 091, 0) and formatting will automatically normalize to 10 digits.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Text Area for pasting
        TextField(
          controller: _pasteController,
          maxLines: 6,
          onChanged: _onTextChanged,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: "Enter or paste phone numbers here...\n\nExample:\n9876543210\n+91 98765 43211\n919876543212, 09876543213\n0919876543214",
            hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.gray400),
            filled: true,
            fillColor: AppTheme.gray50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.gray300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 10),

        // Badges summary
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildStatBadge(
              icon: Icons.check_circle_outline,
              label: '${_validNumbers.length} Valid Numbers',
              bgColor: AppTheme.successGreen.withOpacity(0.12),
              textColor: const Color(0xFF15803D),
            ),
            if (_duplicateCount > 0)
              _buildStatBadge(
                icon: Icons.copy_outlined,
                label: '$_duplicateCount Duplicates',
                bgColor: Colors.amber.withOpacity(0.15),
                textColor: Colors.amber.shade900,
              ),
            if (_invalidCount > 0)
              _buildStatBadge(
                icon: Icons.warning_amber_rounded,
                label: '$_invalidCount Invalid',
                bgColor: Colors.red.withOpacity(0.1),
                textColor: Colors.red.shade700,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Ingestion Configuration Grid
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
              const Text('Ingestion Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Target Lead Pool
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Target Lead Pool', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray600)),
                        const SizedBox(height: 6),
                        _isLoadingPools
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<String>(
                                initialValue: _selectedLeadPoolId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                                items: _leadPools.map((p) {
                                  return DropdownMenuItem<String>(
                                    value: p['_id']?.toString(),
                                    child: Text(p['name']?.toString() ?? 'Pool', overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedLeadPoolId = val),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Duplicate Handling Strategy
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Duplicate Handling', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _duplicateStrategy,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'skip', child: Text('Skip Existing', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'update', child: Text('Update Existing', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (val) => setState(() => _duplicateStrategy = val ?? 'skip'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stage Selection
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Initial Stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _leadStage,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'New', child: Text('New')),
                            DropdownMenuItem(value: 'Contacted', child: Text('Contacted')),
                            DropdownMenuItem(value: 'Interested', child: Text('Interested')),
                            DropdownMenuItem(value: 'Qualified', child: Text('Qualified')),
                          ],
                          onChanged: (val) => setState(() => _leadStage = val ?? 'New'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Assigned RM (Optional)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assign RM (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: safeAssignedRM,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Unassigned (Pool)', overflow: TextOverflow.ellipsis)),
                            ...activeStaff.map((staff) {
                              return DropdownMenuItem<String>(
                                value: staff.id,
                                child: Text('${staff.name} (${staff.role.isNotEmpty ? staff.role : "Staff"})', overflow: TextOverflow.ellipsis),
                              );
                            }),
                          ],
                          onChanged: (val) => setState(() => _assignedRM = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handlePasteSubmit,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload, size: 18),
              label: Text(_isSubmitting ? 'Uploading...' : 'Upload ${_validNumbers.length} Leads'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB 2: PASTE NUMBERS TO ASSIGN (REASSIGN EXISTING LEADS) ---
  Widget _buildAssignTab() {
    final seenStaffIds = <String>{};
    final activeStaff = widget.controller.staffList
        .where((s) => s.id.isNotEmpty && s.status.toLowerCase() == 'active' && seenStaffIds.add(s.id))
        .toList();
    final safeAssignRM = (_targetAssignRMId != null && activeStaff.any((s) => s.id == _targetAssignRMId))
        ? _targetAssignRMId
        : (activeStaff.isNotEmpty ? activeStaff.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Helper notification banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.assignment_ind_rounded, size: 20, color: AppTheme.primaryBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Paste mobile numbers of existing leads to assign them to a Relationship Manager. Country codes (+91, 91, 0) will automatically normalize.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Text Area for pasting numbers to assign
        TextField(
          controller: _assignPasteController,
          maxLines: 6,
          onChanged: _onAssignTextChanged,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: "Enter or paste phone numbers to assign...\n\nExample:\n9876543210\n+91 98765 43211\n919876543212, 09876543213",
            hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.gray400),
            filled: true,
            fillColor: AppTheme.gray50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.gray300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 10),

        // Badges summary
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildStatBadge(
              icon: Icons.check_circle_outline,
              label: '${_assignUniqueNumbers.length} Valid Numbers',
              bgColor: AppTheme.successGreen.withOpacity(0.12),
              textColor: const Color(0xFF15803D),
            ),
            if (_assignDuplicateCount > 0)
              _buildStatBadge(
                icon: Icons.copy_outlined,
                label: '$_assignDuplicateCount Duplicates Skipped',
                bgColor: Colors.amber.withOpacity(0.15),
                textColor: Colors.amber.shade900,
              ),
            if (_assignInvalidCount > 0)
              _buildStatBadge(
                icon: Icons.warning_amber_rounded,
                label: '$_assignInvalidCount Invalid',
                bgColor: Colors.red.withOpacity(0.1),
                textColor: Colors.red.shade700,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Target RM Dropdown Card
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
              const Text('Target Relationship Manager (RM)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: safeAssignRM,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: activeStaff.map((staff) {
                  return DropdownMenuItem<String>(
                    value: staff.id,
                    child: Text('${staff.name} (${staff.role.isNotEmpty ? staff.role : "Staff"})', overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _targetAssignRMId = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _isAssignSubmitting ? null : _handleAssignSubmit,
              icon: _isAssignSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.assignment_ind_rounded, size: 18),
              label: Text(_isAssignSubmitting ? 'Assigning...' : 'Assign ${_assignUniqueNumbers.length} Leads to RM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
