import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import 'package:spresearch_web/services/subscription.service.dart';
import 'package:spresearch_web/models/subscription_plan.model.dart';
import 'package:spresearch_web/models/user.model.dart'; // Import for passing User if needed

class AssignEntitlementsDialog extends StatefulWidget {
  final String userId;
  final String currentRegStatus;

  const AssignEntitlementsDialog({
    super.key,
    required this.userId,
    required this.currentRegStatus,
  });

  @override
  State<AssignEntitlementsDialog> createState() =>
      _AssignEntitlementsDialogState();
}

class _AssignEntitlementsDialogState extends State<AssignEntitlementsDialog> {
  final UserManagementController _controller =
      Get.find<UserManagementController>();
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();

  String? _selectedRegType;
  final List<String> _selectedPlanIds = [];
  List<SubscriptionPlanModel> _availablePlans = [];
  bool _isLoadingPlans = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    // Fetch active plans. Pagination might be an issue if there are many, but usually plans are few.
    // We'll set pageSize to 100 to get most.
    final result = await _subscriptionService.getSubscriptionPlans(
      pageSize: 100,
      status: 'active',
    );
    setState(() {
      _availablePlans = result.plans;
      _isLoadingPlans = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canAssignReg = widget.currentRegStatus != 'ACTIVE';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assign Entitlements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Registration Section
            if (canAssignReg) ...[
              Text(
                'Registration (Entry Gate)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRegType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  hintText: 'Select Registration Type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'YEARLY',
                    child: Text('Silver Registration'),
                  ),
                  DropdownMenuItem(
                    value: 'LIFETIME',
                    child: Text('Gold Registration'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRegType = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Registration is already ACTIVE",
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Plans Section
            Text(
              'Assign Plans (Content Gate)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _isLoadingPlans
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: _availablePlans.length,
                      itemBuilder: (context, index) {
                        final plan = _availablePlans[index];
                        final isSelected = _selectedPlanIds.contains(plan.id);
                        return CheckboxListTile(
                          title: Text(plan.planName),
                          subtitle: Text(
                            'ID: ${plan.id} | ${plan.duration} Days',
                          ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedPlanIds.add(plan.id);
                              } else {
                                _selectedPlanIds.remove(plan.id);
                              }
                            });
                          },
                          activeColor: AppTheme.primary,
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: AppTheme.primary.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Assignments'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_selectedRegType == null && _selectedPlanIds.isEmpty) {
      Get.snackbar(
        'No Changes',
        'Please select a registration type or plans to assign.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSaving = true);

    final Map<String, dynamic> updateData = {};
    if (_selectedRegType != null) {
      updateData['registrationType'] = _selectedRegType;
    }
    if (_selectedPlanIds.isNotEmpty) {
      updateData['newPlanIds'] = _selectedPlanIds;
    }

    final success = await _controller.updateUser(widget.userId, updateData);

    setState(() => _isSaving = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        'User entitlements updated successfully.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update user entitlements.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
