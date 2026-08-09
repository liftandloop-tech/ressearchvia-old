import 'package:get/get.dart';

class TitleFieldController extends GetxController {
  final RxBool obscure;

  TitleFieldController({required bool isPasswordField})
    : obscure = isPasswordField.obs;

  void toggleObscure() {
    obscure.value = !obscure.value;
  }
}
