import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'package:spresearch_web/controllers/users/users_table.controller.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'table_pagination.widget.dart';
import 'user_data_row.dart';
import 'user_table_header_cell.widget.dart';
import 'user_column_filter.widget.dart';

class UsersTable extends StatelessWidget {
  const UsersTable({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserController>();
    final userManagementController = Get.find<UserManagementController>();
    final tableController = Get.put(UsersTableController());

    return Obx(() {
      final authController = Get.find<AuthController>();
      final isDirector = authController.user.value?.isDirector ?? false;
      final canManageSubscription = (authController.user.value?.isAdmin == true) ||
          (authController.user.value?.has('subscriptions.activate') ?? false) ||
          (authController.user.value?.has('subscriptions.revoke') ?? false) ||
          (authController.user.value?.has('subscriptions.view') ?? false);
      final users = controller.filteredUsers;
      final totalCount = userManagementController.totalCount.value;
      final pageSize = userManagementController.pageSize.value;
      final totalPages = (totalCount / pageSize).ceil();

      final displayedUsers = users;
      final isLoading = userManagementController.isLoading.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (isLoading)
              const LinearProgressIndicator(
                minHeight: 3,
                color: AppTheme.primaryBlue,
                backgroundColor: AppTheme.border,
              ),
            if (isLoading && displayedUsers.isEmpty)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              )
            else if (displayedUsers.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              Expanded(
                child: DataTable2(
                  columnSpacing: 10,
                  horizontalMargin: 12,
                  minWidth: 850,
                  headingRowHeight: 48,
                  dataRowHeight: 54,
                  headingRowColor: WidgetStateProperty.all(
                    AppTheme.backgroundLight,
                  ),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: AppTheme.border,
                      width: 1,
                    ),
                  ),
                  columns: [
                    DataColumn2(
                      fixedWidth: 115,
                      label: const UserTableHeaderCell(
                        title: 'Created At',
                        sortKey: 'createdAt',
                        filterWidget: UserColumnFilter(
                          columnKey: 'createdAt',
                          columnName: 'Created At',
                        ),
                      ),
                    ),
                    DataColumn2(
                      size: ColumnSize.M,
                      label: const UserTableHeaderCell(
                        title: 'Name',
                        sortKey: 'name',
                        filterWidget: UserColumnFilter(
                          columnKey: 'name',
                          columnName: 'Name',
                        ),
                      ),
                    ),
                    DataColumn2(
                      size: ColumnSize.M,
                      label: const UserTableHeaderCell(
                        title: 'Mobile No.',
                        sortKey: 'mobile',
                        filterWidget: UserColumnFilter(
                          columnKey: 'mobile',
                          columnName: 'Mobile No.',
                        ),
                      ),
                    ),
                    DataColumn2(
                      size: ColumnSize.M,
                      label: const UserTableHeaderCell(
                        title: 'KYC Status',
                        sortKey: 'kycStatus',
                        filterWidget: UserColumnFilter(
                          columnKey: 'kycStatus',
                          columnName: 'KYC Status',
                        ),
                        isCenter: true,
                      ),
                    ),
                    if (!isDirector && canManageSubscription)
                      DataColumn2(
                        fixedWidth: 125,
                        label: const UserTableHeaderCell(
                          title: 'Subscription',
                          isCenter: true,
                        ),
                      ),
                    DataColumn2(
                      size: ColumnSize.M,
                      label: const UserTableHeaderCell(
                        title: 'Assign Manager',
                        sortKey: 'manager',
                        filterWidget: UserColumnFilter(
                          columnKey: 'manager',
                          columnName: 'Manager',
                        ),
                        isCenter: true,
                      ),
                    ),
                    DataColumn2(
                      fixedWidth: 75,
                      label: const UserTableHeaderCell(
                        title: 'Actions',
                        isCenter: true,
                      ),
                    ),
                  ],
                  rows: displayedUsers
                      .map(
                        (user) => UserDataRow(
                          user: user,
                          controller: controller,
                          isDirector: isDirector,
                          canManageSubscription: canManageSubscription,
                        ),
                      )
                      .toList(),
                ),
              ),
            if (totalCount > 0 || displayedUsers.isNotEmpty)
              TablePagination(
                totalPages: totalPages,
                tableController: tableController,
              ),
          ],
        ),
      );
    });
  }
}
