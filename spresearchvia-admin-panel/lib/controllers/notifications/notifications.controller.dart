import 'package:get/get.dart';

class NotificationsController extends GetxController {
  var selectedTab = 0.obs;
  var sendNow = true.obs;

  void changeTab(int index) {
    selectedTab.value = index;
  }

  void toggleSendNow(bool value) {
    sendNow.value = value;
  }
}
