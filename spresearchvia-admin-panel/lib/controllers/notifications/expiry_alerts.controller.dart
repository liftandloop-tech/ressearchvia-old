import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api.service.dart';

class ExpiryAlert {
  int days;
  bool enabled;
  String? title;
  String? message;

  ExpiryAlert({
    required this.days,
    this.enabled = true,
    this.title,
    this.message,
  });

  Map<String, dynamic> toJson() => {
    'days': days,
    'enabled': enabled,
    'title': title,
    'body': message, // Backend uses 'body'
  };

  factory ExpiryAlert.fromJson(Map<String, dynamic> json) => ExpiryAlert(
    days: json['days'] as int,
    enabled: json['enabled'] as bool? ?? true,
    title: json['title'] as String?,
    message: json['body'] as String?,
  );
}

class ExpiryAlertsController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final autoAlerts = true.obs;
  final alerts = <ExpiryAlert>[].obs;
  final selectedAlertIndex = 0.obs;

  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final newAlertDayController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchSettings();

    // Periodically update preview if needed, or use listeners
    selectedAlertIndex.listen((index) {
      if (index >= 0 && index < alerts.length) {
        titleController.text =
            alerts[index].title ?? "Subscription Expiring Soon!";
        messageController.text =
            alerts[index].message ??
            "Your {{planName}} plan expires in {{days}} days. Renew now to continue services.";
      }
    });
  }

  Future<void> fetchSettings() async {
    try {
      final res = await _apiService.get('/expiry/settings');
      if (res.statusCode == 200 && res.body['data'] != null) {
        final data = res.body['data'];
        autoAlerts.value = data['isAutomatedAlertsEnabled'] ?? true;

        if (data['alerts'] != null) {
          final List<dynamic> alertsList = data['alerts'];
          alerts.assignAll(
            alertsList.map((e) => ExpiryAlert.fromJson(e)).toList(),
          );

          if (alerts.isNotEmpty) {
            selectedAlertIndex.value = 0;
            titleController.text =
                alerts[0].title ?? "Subscription Expiring Soon!";
            messageController.text =
                alerts[0].message ??
                "Your {{planName}} plan expires in {{days}} days. Renew now to continue services.";
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching expiry settings: $e');
    }
  }

  Future<void> updateSettings() async {
    try {
      // Sync current controllers to the selected alert
      if (alerts.isNotEmpty && selectedAlertIndex.value < alerts.length) {
        alerts[selectedAlertIndex.value].title = titleController.text;
        alerts[selectedAlertIndex.value].message = messageController.text;
      }

      final body = {
        'isAutomatedAlertsEnabled': autoAlerts.value,
        'alerts': alerts.map((e) => e.toJson()).toList(),
      };

      await _apiService.post('/expiry/settings', body);
      Get.snackbar(
        'Success',
        'Settings saved successfully',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      Get.snackbar(
        'Error',
        'Failed to save settings',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void toggleAutoAlerts(bool value) {
    autoAlerts.value = value;
    updateSettings();
  }

  void toggleAlert(int index, bool? value) {
    if (value != null) {
      alerts[index].enabled = value;
      alerts.refresh();
      updateSettings();
    }
  }

  void addAlert() {
    final text = newAlertDayController.text.trim();
    if (text.isEmpty) return;

    final days = int.tryParse(text);
    if (days == null || days <= 0) {
      Get.snackbar('Error', 'Please enter a valid number of days');
      return;
    }

    if (alerts.any((element) => element.days == days)) {
      Get.snackbar('Error', 'Alert for $days days already exists');
      return;
    }

    final newAlert = ExpiryAlert(
      days: days,
      enabled: true,
      title: "Subscription Expiring Soon!",
      message:
          "Your {{planName}} plan expires in {{days}} days. Renew now to continue services.",
    );

    alerts.add(newAlert);
    alerts.sort((a, b) => b.days.compareTo(a.days));

    // Select the newly added one? Or find it
    selectedAlertIndex.value = alerts.indexOf(newAlert);

    newAlertDayController.clear();
    updateSettings();
  }

  void removeAlert(int index) {
    alerts.removeAt(index);
    if (selectedAlertIndex.value >= alerts.length) {
      selectedAlertIndex.value = alerts.length - 1;
    }
    updateSettings();
  }

  void selectAlert(int index) {
    // Before switching, save current edits to the previous alert
    if (alerts.isNotEmpty && selectedAlertIndex.value < alerts.length) {
      alerts[selectedAlertIndex.value].title = titleController.text;
      alerts[selectedAlertIndex.value].message = messageController.text;
    }
    selectedAlertIndex.value = index;
  }
}
