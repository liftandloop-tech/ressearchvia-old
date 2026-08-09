import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard_management.controller.dart';
import 'package:spresearch_web/config/theme.config.dart';

class RenewalRow extends StatelessWidget {
  final Map<String, dynamic> renewal;

  const RenewalRow({super.key, required this.renewal});

  @override
  Widget build(BuildContext context) {
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  border: Border.all(color: AppTheme.gray300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Obx(() {
                  final dmController =
                      Get.find<DashboardManagementController>();
                  // Ensure the current value exists in the list of items
                  String? currentValue = renewal['managerId'];
                  if (currentValue != null &&
                      !dmController.staffList.any(
                        (staff) => staff.id == currentValue,
                      )) {
                    currentValue = null;
                  }

                  return DropdownButton<String>(
                    value: currentValue,
                    hint: Text(
                      renewal['manager'] ?? 'Select',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    isExpanded: true,
                    itemHeight: null,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppTheme.gray600,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return dmController.staffList.map<Widget>((staff) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                staff.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                staff.department.isNotEmpty
                                    ? staff.department
                                    : 'Unassigned',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.gray500,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    items: dmController.staffList.map((staff) {
                      return DropdownMenuItem<String>(
                        value: staff.id,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                staff.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                staff.department.isNotEmpty
                                    ? staff.department
                                    : 'Unassigned',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.gray500,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        dmController.assignManager(renewal['id'], v);
                      }
                    },
                  );
                }),
              ),
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
