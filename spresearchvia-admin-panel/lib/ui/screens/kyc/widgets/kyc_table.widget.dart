import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/kyc/kyc_manager.controller.dart';
import 'kyc_table_header.widget.dart';

class KycTable extends StatelessWidget {
  const KycTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<KycManagerController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Obx(
                    () => Checkbox(
                      value: controller.selectAll.value,
                      onChanged: (_) => controller.toggleSelectAll(),
                      activeColor: AppTheme.primaryBlue,
                    ),
                  ),
                  Text(
                    AppStrings.selectAll,
                    style: AppTheme.tableDataStyle.copyWith(
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '0 selected',
                    style: AppTheme.cardTitleStyle.copyWith(
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(),
            ],
          ),

          const SizedBox(height: 24),

          Table(
            columnWidths: const {
              0: FixedColumnWidth(50),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: [
                  const SizedBox(),
                  KycTableHeader(text: AppStrings.userId),
                  KycTableHeader(text: AppStrings.customerName),
                  KycTableHeader(text: AppStrings.documentType),
                  KycTableHeader(text: AppStrings.submissionDate),
                  KycTableHeader(text: AppStrings.status),
                  KycTableHeader(text: AppStrings.actions),
                ],
              ),
              _buildKYCRow(
                controller,
                0,
                'USR-001',
                'John Doe',
                'Aadhar',
                '2025-01-15',
                'Pending',
                AppTheme.pendingColor,
              ),
              _buildKYCRow(
                controller,
                1,
                'USR-002',
                'Jane Smith',
                'PAN',
                '2025-01-14',
                'Approved',
                AppTheme.successColor,
              ),
              _buildKYCRow(
                controller,
                2,
                'USR-003',
                'Mike Johnson',
                'Aadhar',
                '2025-01-13',
                'Rejected',
                AppTheme.errorColor,
              ),
              _buildKYCRow(
                controller,
                3,
                'USR-004',
                'Sarah Wilson',
                'PAN',
                '2025-01-12',
                'Pending',
                AppTheme.pendingColor,
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing 1 to 10 of 97 results',
                style: AppTheme.copyrightStyle,
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text('Previous', style: AppTheme.copyrightStyle),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '1',
                      style: AppTheme.tableHeaderStyle.copyWith(
                        color: AppTheme.whiteTextColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text('2', style: AppTheme.copyrightStyle),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text('3', style: AppTheme.copyrightStyle),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text('Next', style: AppTheme.copyrightStyle),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildKYCRow(
    KycManagerController controller,
    int index,
    String userId,
    String customerName,
    String docType,
    String date,
    String status,
    Color statusColor,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Obx(
            () => Checkbox(
              value: controller.selectedItems[index],
              onChanged: (_) => controller.toggleItem(index),
              activeColor: AppTheme.primaryBlue,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(userId, style: AppTheme.tableDataStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(customerName, style: AppTheme.tableDataStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(docType, style: AppTheme.tableDataStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(date, style: AppTheme.tableDataStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: AppTheme.tableHeaderStyle.copyWith(
                color: AppTheme.whiteTextColor,
                fontSize: 10,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'View Details',
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
