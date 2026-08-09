import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'widgets/notification_setting_item.dart';
import '../../widgets/button.dart';
import '../../services/snackbar.service.dart';

class NotificationSettingsController extends GetxController {
  final RxBool researchAlert = false.obs;
  final RxBool paymentAlerts = true.obs;
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  void _loadPreferences() {
    final storage = GetStorage();
    researchAlert.value = storage.read('notification_research') ?? false;
    paymentAlerts.value = storage.read('notification_payment') ?? true;
  }

  Future<void> savePreferences() async {
    if (isSaving.value) return;

    try {
      isSaving.value = true;

      final storage = GetStorage();
      await storage.write('notification_research', researchAlert.value);
      await storage.write('notification_payment', paymentAlerts.value);
      await Future.delayed(const Duration(milliseconds: 500));

      SnackbarService.showSuccess('Notification preferences saved');

      Get.back();
    } catch (e) {
      SnackbarService.showError('Failed to save preferences');
    } finally {
      isSaving.value = false;
    }
  }
}

class NotificationSettingScreen extends StatelessWidget {
  const NotificationSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationSettingsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Color(0xff11416B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xff163174),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Stay Informed',
                style: TextStyle(
                  overflow: TextOverflow.clip,
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff163174),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Customize your notifications to stay updated on what\nmatters most to your financial journey.',
                style: TextStyle(
                  overflow: TextOverflow.clip,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Obx(
                () => NotificationSettingItem(
                  value: controller.researchAlert.value,
                  icon: Icons.show_chart_rounded,
                  title: 'Research Updates',
                  description:
                      'Receive market insights and investment research reports',
                  onChanged: (newVal) =>
                      controller.researchAlert.value = newVal,
                ),
              ),
              const SizedBox(height: 5),
              Obx(
                () => NotificationSettingItem(
                  value: controller.paymentAlerts.value,
                  icon: Icons.credit_card,
                  title: 'Payment Alerts',
                  description:
                      'Instant notifications for all transactions and payments',
                  onChanged: (newVal) =>
                      controller.paymentAlerts.value = newVal,
                ),
              ),
              const SizedBox(height: 20),
              Button(
                title: 'Save Preferences',
                buttonType: ButtonType.blue,
                onTap: controller.savePreferences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
