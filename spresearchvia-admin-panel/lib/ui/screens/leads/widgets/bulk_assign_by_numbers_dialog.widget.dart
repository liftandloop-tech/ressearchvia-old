import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/theme.config.dart';
import '../../../../controllers/leads/leads.controller.dart';

class BulkAssignByNumbersDialog extends StatefulWidget {
  final LeadsController controller;

  const BulkAssignByNumbersDialog({super.key, required this.controller});

  @override
  State<BulkAssignByNumbersDialog> createState() => _BulkAssignByNumbersDialogState();
}

class _BulkAssignByNumbersDialogState extends State<BulkAssignByNumbersDialog> {
  final _pasteController = TextEditingController();
  final List<String> _uniqueNumbers = [];
  int _duplicateCount = 0;
  int _invalidCount = 0;
  bool _isSubmitting = false;
  String? _selectedRMId;

  @override
  void initState() {
    super.initState();
    // Default to the first active staff member if available
    final activeStaff = widget.controller.staffList
        .where((s) => s.status.toLowerCase() == 'active')
        .toList();
    if (activeStaff.isNotEmpty) {
      _selectedRMId = activeStaff.first.id;
    }
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  /// Normalizes any input phone number (10, 11, 12, or 13 digits) to standard 10 digits
  String? _normalizePhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 10) {
      return clean;
    }
    // 11 digits (e.g. 09876543210 -> strip leading 0)
    if (clean.length == 11 && clean.startsWith('0')) {
      return clean.substring(1);
    }
    // 12 digits with 91 (e.g. 919876543210 -> strip 91)
    if (clean.length == 12 && clean.startsWith('91')) {
      return clean.substring(2);
    }
    // 13 digits with +91 or 091 (e.g. 0919876543210 -> strip 091)
    if (clean.length == 13 && clean.startsWith('091')) {
      return clean.substring(3);
    }
    if (clean.length > 10) {
      return clean.substring(clean.length - 10);
    }
    return null;
  }

  void _parsePastedText(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _uniqueNumbers.clear();
        _duplicateCount = 0;
        _invalidCount = 0;
      });
      return;
    }

    final rawTokens = text.split(RegExp(r'[\r\n,;\t]+'));
    final seen = <String>{};
    final valid = <String>[];
    int duplicates = 0;
    int invalids = 0;

    for (final raw in rawTokens) {
      final token = raw.trim();
      if (token.isEmpty) continue;

      final normalized = _normalizePhone(token);
      if (normalized != null && normalized.length == 10) {
        if (seen.contains(normalized)) {
          duplicates++;
        } else {
          seen.add(normalized);
          valid.add(normalized);
        }
      } else {
        invalids++;
      }
    }

    setState(() {
      _uniqueNumbers.clear();
      _uniqueNumbers.addAll(valid);
      _duplicateCount = duplicates;
      _invalidCount = invalids;
    });
  }

  Future<void> _submitBulkAssign() async {
    if (_uniqueNumbers.isEmpty) {
      Get.snackbar('Error', 'Please paste at least one valid phone number');
      return;
    }
    if (_selectedRMId == null || _selectedRMId!.isEmpty) {
      Get.snackbar('Error', 'Please select a target Relationship Manager (RM)');
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.controller.bulkAssignByNumbers(
      rawNumbers: _uniqueNumbers.join('\n'),
      assignedRM: _selectedRMId!,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeStaff = widget.controller.staffList
        .where((s) => s.status.toLowerCase() == 'active')
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 12,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment_ind_rounded,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bulk Lead Assign (Copy & Paste)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paste phone numbers to reassign leads in bulk',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Instructions Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Paste numbers separated by new lines (Enter), commas, or tabs. Numbers with +91, 91, or leading 0 will automatically normalize to 10 digits.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Textarea for pasting numbers
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _pasteController,
                      maxLines: 8,
                      minLines: 5,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Paste numbers here...\n9896269863\n+91 9876543210\n919876543211, 9876543212',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'monospace', fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.gray300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onChanged: _parsePastedText,
                    ),
                    const SizedBox(height: 10),

                    // Metrics Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                          label: Text(
                            'Valid 10-Digit: ${_uniqueNumbers.length}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 12),
                          ),
                          backgroundColor: Colors.green.shade50,
                          side: BorderSide(color: Colors.green.shade200),
                        ),
                        if (_duplicateCount > 0)
                          Chip(
                            avatar: const Icon(Icons.copy_rounded, size: 16, color: Colors.orange),
                            label: Text(
                              'Duplicates: $_duplicateCount',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                            ),
                            backgroundColor: Colors.orange.shade50,
                            side: BorderSide(color: Colors.orange.shade200),
                          ),
                        if (_invalidCount > 0)
                          Chip(
                            avatar: const Icon(Icons.error_outline, size: 16, color: Colors.red),
                            label: Text(
                              'Invalid: $_invalidCount',
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                            ),
                            backgroundColor: Colors.red.shade50,
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Target RM Selector (Active Staff only)
                    const Text(
                      'Assign To Relationship Manager (Active Staff Only):',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRMId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppTheme.gray300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: activeStaff.map((staff) {
                        return DropdownMenuItem<String>(
                          value: staff.id,
                          child: Row(
                            children: [
                              Text(
                                staff.name,
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  staff.role.isNotEmpty ? staff.role : staff.department,
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedRMId = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (_isSubmitting || _uniqueNumbers.isEmpty || _selectedRMId == null)
                      ? null
                      : _submitBulkAssign,
                  icon: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.assignment_turned_in_rounded, size: 18),
                  label: Text(_isSubmitting
                      ? 'Assigning...'
                      : 'Assign ${_uniqueNumbers.length} Leads'),
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
        ),
      ),
    );
  }
}
