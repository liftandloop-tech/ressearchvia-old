import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/config/app.config.dart';
import 'controllers/auth.controller.dart';
import 'controllers/user.controller.dart';
import 'controllers/kyc.controller.dart';
import 'controllers/plan_purchase.controller.dart';
import 'controllers/report.controller.dart';
import 'services/secure_storage.service.dart';
import 'services/payment.service.dart';
import 'services/notification.service.dart';
import 'services/cache.service.dart';

Future<void> startup() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('DEBUG: AppConfig.baseUrl = ${AppConfig.baseUrl}');

  await SecureStorageService.init();

  Get.put(SecureStorageService(), permanent: true);
  Get.put(CacheService(), permanent: true);
  Get.put(PaymentService(), permanent: true);
  
  // Initialize Notifications
  final notificationService = Get.put(NotificationService(), permanent: true);
  await notificationService.init();

  Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  Get.lazyPut<UserController>(() => UserController(), fenix: true);
  Get.lazyPut<KycController>(() => KycController(), fenix: true);
  Get.lazyPut<PlanPurchaseController>(
    () => PlanPurchaseController(),
    fenix: true,
  );
  Get.lazyPut<ReportController>(() => ReportController(), fenix: true);
}
