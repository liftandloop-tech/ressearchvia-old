import 'package:get/get.dart';

class DatePickerController extends GetxController {
  late Rx<DateTime> selectedDate;
  late Rx<DateTime> displayMonth;

  void initialize(DateTime? initialDate) {
    final date = initialDate ?? DateTime.now();
    selectedDate = date.obs;
    displayMonth = DateTime(date.year, date.month).obs;
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
  }

  void previousMonth() {
    displayMonth.value = DateTime(
      displayMonth.value.year,
      displayMonth.value.month - 1,
    );
  }

  void nextMonth() {
    displayMonth.value = DateTime(
      displayMonth.value.year,
      displayMonth.value.month + 1,
    );
  }
}
