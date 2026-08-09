import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import '../../../../models/user.model.dart';

class TableActions extends StatelessWidget {
  final UserModel user;

  const TableActions({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Get.find<UsersNavigationController>().showUserDetails(user.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryBlue),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'View',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
