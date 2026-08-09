import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/ui/screens/users/details/user_details.screen.dart';
import 'package:spresearch_web/ui/screens/users/edit_profile.screen.dart';
import 'package:spresearch_web/ui/screens/users/manage_subscription.screen.dart';
import 'package:spresearch_web/ui/screens/subscription/pending_bank_transfers.screen.dart';
import 'package:spresearch_web/ui/screens/users/create_user.screen.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';

class UsersNavigationController extends GetxController {
  var navigationStack = <Widget>[].obs;

  Widget? get currentScreen =>
      navigationStack.isEmpty ? null : navigationStack.last;

  void showUserDetails(String userId) {
    Get.toNamed('/users/$userId');
  }

  void showEditProfile(String userId) {
    Get.toNamed('/edit-user/$userId');
  }

  void showManageSubscription(String userId) {
    Get.toNamed('/manage-user/$userId');
  }

  void showCreateUser() {
    navigationStack.add(const CreateUserScreen());
  }

  void showPendingBankTransfers() {
    navigationStack.add(const PendingBankTransfersScreen());
  }

  void goBack() {
    if (navigationStack.isNotEmpty) {
      navigationStack.removeLast();
      if (navigationStack.isEmpty) {
        if (Get.isRegistered<UserManagementController>()) {
          Get.find<UserManagementController>().fetchUsers();
        }
      }
    } else {
      Get.back();
    }
  }
}
