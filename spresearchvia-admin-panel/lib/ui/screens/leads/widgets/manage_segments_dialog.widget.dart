import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/theme.config.dart';
import '../../../../controllers/leads/leads.controller.dart';
import '../../../../models/lead.model.dart';

class ManageSegmentsDialog extends StatefulWidget {
  final LeadModel lead;
  final LeadsController controller;

  const ManageSegmentsDialog({
    super.key,
    required this.lead,
    required this.controller,
  });

  @override
  State<ManageSegmentsDialog> createState() => _ManageSegmentsDialogState();
}

class _ManageSegmentsDialogState extends State<ManageSegmentsDialog> {
  final Set<String> _selectedIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.lead.segmentIds);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final success = await widget.controller.assignLeadSegments(
      widget.lead.id,
      _selectedIds.toList(),
    );
    setState(() => _isSaving = false);
    if (success && mounted) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.controller.segmentsList;

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
                const Icon(Icons.category_outlined, color: AppTheme.primaryBlue, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Assign Segments - ${widget.lead.fullName.isNotEmpty ? widget.lead.fullName : widget.lead.mobileNumber}',
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
              'Select trading segments applicable to this lead (e.g., Equity, Futures, Options):',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            if (segments.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: const Text('No active segments available in the system.'),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gray200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: segments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final segment = segments[index];
                    final isChecked = _selectedIds.contains(segment.id);
                    return CheckboxListTile(
                      value: isChecked,
                      activeColor: AppTheme.primaryBlue,
                      title: Text(segment.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: segment.description != null && segment.description!.isNotEmpty
                          ? Text(segment.description!, style: const TextStyle(fontSize: 11.5, color: AppTheme.gray500))
                          : null,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(segment.id);
                          } else {
                            _selectedIds.remove(segment.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
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
                      : const Text('Save Segments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
