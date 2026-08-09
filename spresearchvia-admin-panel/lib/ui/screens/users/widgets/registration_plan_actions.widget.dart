import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/subscription/manage_subscription.controller.dart';

class RegistrationPlanActions extends StatefulWidget {
  final ManageSubscriptionController controller;
  const RegistrationPlanActions({super.key, required this.controller});

  @override
  State<RegistrationPlanActions> createState() =>
      _RegistrationPlanActionsState();
}

class _RegistrationPlanActionsState extends State<RegistrationPlanActions> {
  String? selectedRegType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Registration Plan Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(() {
            final user = widget.controller.userDetails.value;
            final currentRegStatus = user?.registrationStatus ?? 'PENDING';
            final currentRegType = user?.registrationType ?? 'N/A';
            bool isRegActive = currentRegStatus.toUpperCase() == 'ACTIVE';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRegActive)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Color(0xFFD4EDDA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color(0xFFC3E6CB)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF155724),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current: ',
                                    style: TextStyle(
                                      color: Color(0xFF155724),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    currentRegType.toUpperCase().contains(
                                          'YEARLY',
                                        )
                                        ? 'Silver Registration'
                                        : currentRegType.toUpperCase().contains(
                                            'LIFETIME',
                                          )
                                        ? 'Gold Registration'
                                        : currentRegType,
                                    style: TextStyle(color: Color(0xFF155724)),
                                  ),
                                  const Spacer(),
                                  if (isRegActive) _buildStatusBadge('Active'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            (() {
                              final regSubs = widget
                                  .controller
                                  .userSubscriptions
                                  .where((s) {
                                    final name =
                                        s['packageName']
                                            ?.toString()
                                            .toLowerCase() ??
                                        '';
                                    return name.contains('registration');
                                  })
                                  .toList();

                              if (regSubs.isEmpty) return const SizedBox();

                              // Sort to get the most relevant one: active > suspended > expired
                              regSubs.sort((a, b) {
                                final sA =
                                    a['status']?.toString().toLowerCase() ?? '';
                                final sB =
                                    b['status']?.toString().toLowerCase() ?? '';
                                if (sA == 'active') return -1;
                                if (sB == 'active') return 1;
                                if (sA == 'suspended') return -1;
                                if (sB == 'suspended') return 1;
                                return 0;
                              });

                              final regSub = regSubs.first;
                              final planId = regSub['_id'];
                              final status =
                                  regSub['status']?.toString().toLowerCase() ??
                                  'unknown';

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDateField(
                                          context,
                                          'Start Date',
                                          widget
                                                  .controller
                                                  .startDateControllers[planId]
                                                  ?.text ??
                                              '',
                                          () => widget.controller.pickDate(
                                            context,
                                            planId,
                                            true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDateField(
                                          context,
                                          'End Date',
                                          (widget
                                                          .controller
                                                          .endDateControllers[planId]
                                                          ?.text
                                                          .isEmpty ??
                                                      true) &&
                                                  currentRegType
                                                      .toUpperCase()
                                                      .contains('LIFETIME')
                                              ? 'Lifetime'
                                              : widget
                                                        .controller
                                                        .endDateControllers[planId]
                                                        ?.text ??
                                                    '',
                                          () => widget.controller.pickDate(
                                            context,
                                            planId,
                                            false,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status == 'active')
                                        OutlinedButton(
                                          onPressed: () => widget.controller
                                              .suspendSubscription(
                                                widget
                                                    .controller
                                                    .currentUserId
                                                    .value,
                                                planId,
                                              ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.warningOrange,
                                            side: BorderSide(
                                              color: AppTheme.warningOrange,
                                            ),
                                          ),
                                          child: const Text(
                                            'Suspend Registration',
                                          ),
                                        ),
                                      if (status == 'suspended')
                                        OutlinedButton(
                                          onPressed: () => widget.controller
                                              .activateSubscription(
                                                widget
                                                    .controller
                                                    .currentUserId
                                                    .value,
                                                planId,
                                              ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.successGreen,
                                            side: BorderSide(
                                              color: AppTheme.successGreen,
                                            ),
                                          ),
                                          child: const Text(
                                            'Activate Registration',
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              );
                            })(),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (!isRegActive || (selectedRegType != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedRegType,
                            decoration: InputDecoration(
                              labelText: 'Select New Registration Type',
                              hintText: 'Upgrade/Downgrade Plan',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: AppTheme.gray300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
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
                            onChanged: (val) {
                              setState(() => selectedRegType = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedRegType == null
                              ? null
                              : () async {
                                  await widget.controller.assignRegistration(
                                    selectedRegType!,
                                  );
                                  setState(() {
                                    selectedRegType = null;
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            isRegActive ? 'Update Plan' : 'Assign Registration',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gray300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isEmpty ? 'Select Date' : value,
                  style: TextStyle(fontSize: 14),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppTheme.successGreen;
        break;
      case 'expired':
        color = AppTheme.gray400;
        break;
      case 'suspended':
        color = AppTheme.warningOrange;
        break;
      case 'cancelled':
        color = AppTheme.errorRed;
        break;
      default:
        color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status.capitalizeFirst!,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
