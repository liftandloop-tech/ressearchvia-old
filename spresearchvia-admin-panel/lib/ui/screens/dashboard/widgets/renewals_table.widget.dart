import 'package:flutter/material.dart';
// Refresh
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard_management.controller.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';

class RenewalsTable extends StatelessWidget {
  const RenewalsTable({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final currentPage = 1.obs;
    const int itemsPerPage = 10;

    return Obx(() {
      final isLoading = dashboardController.isLoading;
      if (isLoading) {
        return Column(
          children: [
            const TitleRow(),
            const SizedBox(height: 8),
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        );
      }

      final totalItems = dashboardController.filteredRenewalsList.length;
      final totalPages = (totalItems / itemsPerPage).ceil();
      final startIndex = (currentPage.value - 1) * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, totalItems);

      // Handle empty list case
      if (totalItems == 0) {
        return Column(
          children: [
            const TitleRow(),
            const SizedBox(height: 32),
            Text(
              'No results found',
              style: TextStyle(
                color: AppTheme.gray600,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      }

      final paginatedList = dashboardController.filteredRenewalsList.sublist(
        startIndex,
        endIndex,
      );

      return Column(
        children: [
          const TitleRow(),
          for (int i = 0; i < paginatedList.length; i++)
            ClientListTile(item: paginatedList[i], index: i),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${startIndex + 1}-$endIndex of $totalItems clients',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.gray600,
                  fontFamily: 'Poppins',
                ),
              ),
              Row(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: currentPage.value > 1
                            ? () => currentPage.value--
                            : null,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.gray100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: currentPage.value > 1
                                ? AppTheme.gray700
                                : AppTheme.gray400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(totalPages > 5 ? 5 : totalPages, (
                        index,
                      ) {
                        final pageNum = currentPage.value <= 3
                            ? index + 1
                            : currentPage.value + index - 2;
                        if (pageNum > totalPages) {
                          return const SizedBox.shrink();
                        }
                        final isActive = pageNum == currentPage.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => currentPage.value = pageNum,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.primaryBlue
                                    : AppTheme.white,
                                borderRadius: BorderRadius.circular(6),
                                border: isActive
                                    ? null
                                    : Border.all(color: AppTheme.gray300),
                              ),
                              child: Center(
                                child: Text(
                                  '$pageNum',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isActive
                                        ? AppTheme.white
                                        : AppTheme.gray700,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: currentPage.value < totalPages
                            ? () => currentPage.value++
                            : null,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.gray100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: currentPage.value < totalPages
                                ? AppTheme.gray700
                                : AppTheme.gray400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });
  }
}

class TitleRow extends StatelessWidget {
  const TitleRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 17,
            child: Text(
              'Client Name',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'Email',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              'Mobile Number',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              'KYC Status',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Created At',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Assign Manager',
              style: TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClientListTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const ClientListTile({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final kycStatusColors = _getKycStatusColors(item['kycStatus'] ?? 'Pending');

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
              item['name'] ?? 'Unknown',
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
              item['email'] ?? 'No Email',
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
              _formatPhoneNumber(item['phone'] ?? ''),
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
                  item['kycStatus'].toString().capitalizeFirst ?? 'Pending',
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
              item['createdAt'] ?? '-',
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
                  String? currentValue = item['managerId'];
                  if (currentValue != null &&
                      !dmController.staffList.any(
                        (staff) => staff.id == currentValue,
                      )) {
                    currentValue = null;
                  }

                  return DropdownButton<String>(
                    value: currentValue,
                    hint: Text(
                      item['manager'] ?? 'Select',
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
                        dmController.assignManager(item['id'], v);
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

    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Check if it starts with 91 and has more than 10 digits (likely 12 digits total)
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }

    // Format as +91 XXXXXXXXXX
    return '+91 $cleaned';
  }
}
