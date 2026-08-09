import 'package:get/get.dart';
// Force refresh
import 'dashboard_management.controller.dart';

class DashboardController extends GetxController {
  final DashboardManagementController _dashboardManagementController =
      Get.find<DashboardManagementController>();

  var selectedRenewalStatus = 'All'.obs;
  var selectedDateFilter = 'All Time'.obs;
  var selectedManagerFilter = 'All Managers'.obs;
  var searchQuery = ''.obs;

  List<Map<String, dynamic>> get renewalsList =>
      _dashboardManagementController.renewalsList;

  List<String> get managerFilterItems {
    final managers = _dashboardManagementController.staffList
        .map((e) => e.name)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    managers.sort();
    return ['All Managers', ...managers];
  }

  List<Map<String, dynamic>> get filteredRenewalsList {
    var list = List<Map<String, dynamic>>.from(renewalsList);

    if (searchQuery.value.isNotEmpty) {
      list = list.where((item) {
        final name = item['name'].toString().toLowerCase();
        final phone = item['phone'].toString().toLowerCase();
        final query = searchQuery.value.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();
    }

    if (selectedRenewalStatus.value != 'All') {
      final filterStatus = selectedRenewalStatus.value.toLowerCase();
      list = list.where((item) {
        return item['kycStatus'].toString().toLowerCase() == filterStatus;
      }).toList();
    }

    if (selectedDateFilter.value != 'All Time') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      list = list.where((item) {
        final dateStr = item['rawCreatedAt'];
        if (dateStr == null || dateStr == '-') return false;

        DateTime? date;
        try {
          date = DateTime.tryParse(dateStr.toString());
        } catch (e) {
          return false;
        }

        if (date == null) return false;

        // Normalize date to midnight (local time)
        date = date.toLocal();
        date = DateTime(date.year, date.month, date.day);

        if (selectedDateFilter.value == 'Today') {
          return date.isAtSameMomentAs(today);
        } else if (selectedDateFilter.value == 'This Week') {
          // Calculate start of week (Monday)
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          // or simple "Next 7 days" logic if preferred, effectively "This Week" usually means current week Mon-Sun
          // But often simpler is "Last 7 days" or "Coming 7 days"?
          // Let's assume standard calendar week or simply [today, today+7]
          // The previous logic was `!date.isBefore(today) && date.isBefore(nextWeek)` which means "Future 7 days".
          // usually "This Week" implies current week. CreatedAt is past.
          // So "This Week" should filter created dates in valid current week range.
          // However, if we look at previous logic: `if (selectedDateFilter.value == 'This Week')`
          // it checked items created within next 7 days? Wait, created date is past.
          // If we want users created "This Week":
          final start = today.subtract(Duration(days: today.weekday - 1));
          final end = start.add(const Duration(days: 7));
          return !date.isBefore(start) && date.isBefore(end);
        } else if (selectedDateFilter.value == 'This Month') {
          return date.year == today.year && date.month == today.month;
        } else {
          // Custom Date "D/M/YYYY"
          try {
            final parts = selectedDateFilter.value.split('/');
            if (parts.length == 3) {
              final d = int.parse(parts[0]);
              final m = int.parse(parts[1]);
              final y = int.parse(parts[2]);
              final selected = DateTime(y, m, d);
              return date.isAtSameMomentAs(selected);
            }
          } catch (e) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    if (selectedManagerFilter.value != 'All Managers') {
      list = list
          .where((item) => item['manager'] == selectedManagerFilter.value)
          .toList();
    }

    return list;
  }

  Map<String, dynamic> get dashboardStats =>
      _dashboardManagementController.dashboardStats;
  List<Map<String, dynamic>> get recentPayments =>
      _dashboardManagementController.recentPayments;
  bool get isLoading => _dashboardManagementController.isLoading.value;

  void applyFilters() {
    update();
  }

  void resetFilters() {
    selectedRenewalStatus.value = 'All';
    selectedDateFilter.value = 'All Time';
    selectedManagerFilter.value = 'All Managers';
    searchQuery.value = '';
  }
}
