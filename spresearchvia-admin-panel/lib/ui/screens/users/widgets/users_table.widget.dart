import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user.controller.dart';
import 'package:spresearch_web/controllers/users/users_table.controller.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import '../../../../models/user.model.dart';
import 'table_pagination.widget.dart';
import 'user_data_row.dart';

class UsersTable extends StatelessWidget {
  const UsersTable({super.key});

  static const TextStyle _headerStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

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

      // With server-side pagination, the users list already contains only the items for the current page.
      // However, UserController might have filtered them further client-side.
      final displayedUsers = users;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            if (displayedUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(48),
                child: Text(
                  'No users found',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              SizedBox(
                height: MediaQuery.of(context).size.height - 50,
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 16,
                  minWidth: 1400,
                  headingRowHeight: 56,
                  dataRowHeight: 60,
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
                      fixedWidth: 50,
                      label: Obx(
                        () => Checkbox(
                          value:
                              displayedUsers.every(
                                (u) => controller.selectedUsers.contains(u.id),
                              ) &&
                              displayedUsers.isNotEmpty,
                          onChanged: (_) => _toggleSelectAllOnPage(
                            controller,
                            displayedUsers,
                          ),
                          activeColor: AppTheme.primary,
                        ),
                      ),
                    ),
                    DataColumn2(
                      size: ColumnSize.M,
                      label: Text('Created At', style: _headerStyle),
                    ),
                    DataColumn2(
                      size: ColumnSize.L,
                      label: Text('Name', style: _headerStyle),
                    ),

                    DataColumn2(
                      size: ColumnSize.M,
                      label: Text('Mobile No.', style: _headerStyle),
                    ),
                    DataColumn2(
                      size: ColumnSize.M,
                      label: Text('PAN Card', style: _headerStyle),
                    ),
                    DataColumn2(
                      size: ColumnSize.S,
                      label: Text('Registration Status', style: _headerStyle),
                    ),
                    DataColumn2(
                      size: ColumnSize.S,
                      label: Text('KYC Status', style: _headerStyle),
                    ),
                    if (!isDirector && canManageSubscription)
                      DataColumn2(
                        size: ColumnSize.M,
                        label: Center(
                          child: Text('Subscription', style: _headerStyle),
                        ),
                      ),
                    DataColumn2(
                      size: ColumnSize.L,
                      label: Center(
                        child: Text('Assign Manager', style: _headerStyle),
                      ),
                    ),
                    DataColumn2(
                      size: ColumnSize.M,
                      label: Center(
                        child: Text('Actions', style: _headerStyle),
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
            if (totalPages > 1)
              TablePagination(
                totalPages: totalPages,
                tableController: tableController,
              ),
          ],
        ),
      );
    });
  }

  void _toggleSelectAllOnPage(
    UserController controller,
    List<UserModel> displayedUsers,
  ) {
    final allSelected = displayedUsers.every(
      (u) => controller.selectedUsers.contains(u.id),
    );
    if (allSelected) {
      for (var user in displayedUsers) {
        controller.selectedUsers.remove(user.id);
      }
    } else {
      for (var user in displayedUsers) {
        if (!controller.selectedUsers.contains(user.id)) {
          controller.selectedUsers.add(user.id);
        }
      }
    }
  }
}
