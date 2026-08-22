import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/permission_service.dart';
import '../../controllers/auth/auth.controller.dart';

/// Reusable widget for capability-based UI gating.
/// Shows child only if currently authenticated user has the specified permission.
class PermissionGate extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget fallback;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.user.value;
      if (user != null && user.has(permission)) {
        return child;
      }
      return fallback;
    });
  }
}
