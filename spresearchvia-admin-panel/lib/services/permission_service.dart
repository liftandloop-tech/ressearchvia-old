import 'package:get/get.dart';
import '../controllers/auth/auth.controller.dart';

class PermissionService extends GetxService {
  static PermissionService get to => Get.find<PermissionService>();

  /// Evaluates whether the currently authenticated user possesses the canonical permission key.
  bool has(String permissionKey) {
    if (!Get.isRegistered<AuthController>()) return false;
    final authController = Get.find<AuthController>();
    final user = authController.user.value;
    if (user == null) return false;
    return user.has(permissionKey);
  }

  /// Triggers a refresh of the current user profile & permissions from the server.
  Future<void> refreshPermissions() async {
    if (!Get.isRegistered<AuthController>()) return;
    final authController = Get.find<AuthController>();
    await authController.checkAuth();
  }
}
