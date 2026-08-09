import 'package:get/get.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';

class UsersTableController extends GetxController {
  final UserManagementController _userManagementController =
      Get.find<UserManagementController>();

  RxInt get currentPage => _userManagementController.currentPage;
  RxInt get itemsPerPage => _userManagementController.pageSize;

  void nextPage(int totalPages) {
    if (currentPage.value < totalPages) {
      _userManagementController.fetchUsers(page: currentPage.value + 1);
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      _userManagementController.fetchUsers(page: currentPage.value - 1);
    }
  }

  void goToPage(int page) {
    _userManagementController.fetchUsers(page: page);
  }
}
