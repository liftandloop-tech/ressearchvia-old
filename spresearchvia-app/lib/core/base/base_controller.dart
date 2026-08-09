import 'package:get/get.dart';

abstract class BaseController extends GetxController {
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  final _errorMessage = Rxn<String>();
  String? get errorMessage => _errorMessage.value;
  set errorMessage(String? value) => _errorMessage.value = value;

  void showLoading() {
    _isLoading.value = true;
    _errorMessage.value = null;
  }

  void hideLoading() {
    _isLoading.value = false;
  }

  void setError(String message) {
    _errorMessage.value = message;
    _isLoading.value = false;
  }

  void clearError() {
    _errorMessage.value = null;
  }

  void handleError(dynamic error) {
    hideLoading();
    final errorMsg = error.toString();
    setError(errorMsg);
  }

  @override
  void onClose() {
    _isLoading.close();
    _errorMessage.close();
    super.onClose();
  }
}
