import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/routes/app_routes.dart';
import '../controllers/user.controller.dart';
import 'auth.controller.dart';

class DashboardController extends GetxController {
  final RxBool showReminder = false.obs;
  final RxInt reminderDays = 0.obs;

  int? _computeDaysRemaining() {
    if (!Get.isRegistered<UserController>()) return null;
    final user = Get.find<UserController>().currentUser.value;
    if (user == null) return null;

    if (user.subscriptionExpiryDate != null) {
      final now = DateTime.now();
      final diff = user.subscriptionExpiryDate!.difference(now);
      return diff.inDays;
    }

    return user.daysRemaining;
  }

  @override
  void onInit() {
    super.onInit();
    // fetchResearchHours(); // Moved to Screen logic
    
    // Initial check (give it a moment for local data to load if needed)
    Future.delayed(const Duration(seconds: 1), _checkReminder);

    // Reactive check whenever user data updates from backend
    if (Get.isRegistered<UserController>()) {
      ever(Get.find<UserController>().currentUser, (_) => _checkReminder());
    }
  }

  void _checkReminder() {
    final days = _computeDaysRemaining();
    final shouldShow = days != null && days <= 7 && days >= 0;
    
    // Only update if changed to avoid unnecessary rebuilds or popups appearing repeatedly if logic complex
    if (showReminder.value != shouldShow) {
       showReminder.value = shouldShow;
    }
    reminderDays.value = (days ?? 0).clamp(0, 9999);
  }

  void closeReminder() {
    showReminder.value = false;
  }

  void renewNow(BuildContext context) {
    if (!Get.isRegistered<UserController>()) return;
    final user = Get.find<UserController>().currentUser.value;
    
    // Block suspended users
    if (user?.userStatus == 'SUSPENDED') {
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().showSuspensionDialog();
      }
      return;
    }

    Get.toNamed(AppRoutes.quickRenewal);
  }
}
