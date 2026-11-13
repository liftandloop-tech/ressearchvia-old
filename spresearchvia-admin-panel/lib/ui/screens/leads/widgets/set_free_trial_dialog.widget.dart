import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.config.dart';
import '../../../../controllers/leads/leads.controller.dart';
import '../../../../models/lead.model.dart';

class SetFreeTrialDialog extends StatefulWidget {
  final LeadModel lead;
  final LeadsController controller;

  const SetFreeTrialDialog({
    super.key,
    required this.lead,
    required this.controller,
  });

  @override
  State<SetFreeTrialDialog> createState() => _SetFreeTrialDialogState();
}

class _SetFreeTrialDialogState extends State<SetFreeTrialDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.lead.freeTrialStartDate ?? DateTime.now();
    _endDate = widget.lead.freeTrialEndDate ?? DateTime.now().add(const Duration(days: 7));
  }

  void _applyPreset(int days) {
    final now = DateTime.now();
    setState(() {
      _startDate = now;
      _endDate = now.add(Duration(days: days));
    });
  }

  void _clearTrial() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final success = await widget.controller.updateLeadFreeTrial(
      widget.lead.id,
      _startDate,
      _endDate,
    );
    setState(() => _isSaving = false);
    if (success && mounted) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.card_giftcard, color: AppTheme.primaryBlue, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Free Trial Setup - ${widget.lead.fullName.isNotEmpty ? widget.lead.fullName : widget.lead.mobileNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Configure the free trial window for research advisory access.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Presets
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('+7 Days', style: TextStyle(fontSize: 12)),
                  onPressed: () => _applyPreset(7),
                ),
                ActionChip(
                  label: const Text('+14 Days', style: TextStyle(fontSize: 12)),
                  onPressed: () => _applyPreset(14),
                ),
                ActionChip(
                  label: const Text('+30 Days', style: TextStyle(fontSize: 12)),
                  onPressed: () => _applyPreset(30),
                ),
                ActionChip(
                  label: const Text('Clear Trial', style: TextStyle(fontSize: 12, color: AppTheme.errorRed)),
                  onPressed: _clearTrial,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _startDate != null ? dateFormat.format(_startDate!) : 'Not set',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? (_startDate?.add(const Duration(days: 7)) ?? DateTime.now()),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.event, size: 18),
                      ),
                      child: Text(
                        _endDate != null ? dateFormat.format(_endDate!) : 'Not set',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Free Trial'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

