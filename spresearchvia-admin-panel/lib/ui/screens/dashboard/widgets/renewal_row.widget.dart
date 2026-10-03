import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard_management.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/ui/widgets/searchable_manager_dialog.widget.dart';

class RenewalRow extends StatelessWidget {
  final Map<String, dynamic> renewal;

  const RenewalRow({super.key, required this.renewal});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentUser = authController.user.value;
    final isAdmin = currentUser?.isAdmin == true;
    final canAssign = isAdmin ||
        (currentUser?.has('staff.assignment') ?? false) ||
        (currentUser?.has('staff.update') ?? false) ||
        (currentUser?.has('users.update') ?? false);
    final kycStatusColors = _getKycStatusColors(
      renewal['kycStatus'] ?? 'Pending',
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(bottom: BorderSide(color: AppTheme.gray200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 17, // Name
            child: Text(
              renewal['name'] ?? 'Unknown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 20, // Email
            child: Text(
              renewal['email'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 15, // Mobile
            child: Text(
              _formatPhoneNumber(renewal['phone'] ?? ''),
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 12, // KYC Status
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kycStatusColors['bg'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  renewal['kycStatus'].toString().capitalizeFirst ?? 'Pending',
                  style: TextStyle(
                    color: kycStatusColors['text'],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 18, // Created At
            child: Text(
              renewal['createdAt'] ?? '-',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 18, // Assign Manager
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Obx(() {
                final dmController = Get.find<DashboardManagementController>();
                final rawStaffList = dmController.staffList;
                final seenStaffIds = <String>{};
                final staffList = rawStaffList.where((s) => s.id.isNotEmpty && s.status.toLowerCase() == 'active' && seenStaffIds.add(s.id)).toList();
                final currentManagerName = renewal['manager'] ?? 'Assign Manager';
                final isAssigned = renewal['managerId'] != null || (renewal['manager'] != null && renewal['manager'] != 'Select');

                return InkWell(
                  onTap: canAssign
                      ? () {
                          showDialog(
                            context: context,
                            builder: (ctx) => SearchableManagerDialog(
                              clientName: renewal['clientName'] ?? renewal['name'] ?? 'Client',
                              currentManagerId: renewal['managerId'],
                              staffList: staffList,
                              onSelected: (staffId, staffName) {
                                dmController.assignManager(renewal['id'], staffId);
                              },
                            ),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAssigned ? const Color(0xFFF8FAFC) : Colors.white,
                      border: Border.all(color: isAssigned ? const Color(0xFFCBD5E1) : AppTheme.gray300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentManagerName,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isAssigned ? const Color(0xFF0F172A) : AppTheme.gray500,
                              fontWeight: isAssigned ? FontWeight.w600 : FontWeight.w400,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (canAssign) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.search, size: 14, color: AppTheme.gray500),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getKycStatusColors(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'verified' || lowerStatus == 'approved') {
      return {'bg': AppTheme.statusSuccessLight, 'text': AppTheme.successGreen};
    } else if (lowerStatus == 'pending') {
      return {
        'bg': AppTheme.statusWarningLight,
        'text': AppTheme.warningYellow,
      };
    } else if (lowerStatus == 'rejected') {
      return {'bg': AppTheme.statusErrorLight, 'text': AppTheme.errorRed};
    } else {
      return {'bg': AppTheme.gray100, 'text': AppTheme.gray700};
    }
  }

  String _formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }
    return '+91 $cleaned';
  }
}
