import 'package:get/get.dart';
import '../controllers/plan_purchase.controller.dart';
import '../core/models/subscription_history.dart';
import '../services/snackbar.service.dart';

class SubscriptionHistoryController extends GetxController {
  final planController = Get.put(PlanPurchaseController());

  final RxString selectedFilter = 'Latest'.obs;
  final RxString selectedSection = 'Registration'.obs;
  final RxInt selectedTabIndex = 0.obs;

  final RxList<SubscriptionHistory> registrations = <SubscriptionHistory>[].obs;
  final RxList<SubscriptionHistory> allRegistrations =
      <SubscriptionHistory>[].obs;
  final RxList<Map<String, dynamic>> registrationsRaw =
      <Map<String, dynamic>>[].obs;

  final RxList<Map<String, dynamic>> segments = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredSegments = <Map<String, dynamic>>[].obs; // New filtered list

  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;

  final RxInt registrationPage = 1.obs;
  final RxInt segmentPage = 1.obs;
  final RxBool hasMoreRegistrations = true.obs;
  final RxBool hasMoreSegments = true.obs;
  final int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    loadRegistrationHistory();

    ever(selectedFilter, (_) => _applyFilter());
    ever(selectedSection, (_) {
      if (selectedSection.value == 'Registration') {
        loadRegistrationHistory();
      } else {
        loadSegmentHistory();
      }
    });
  }

  Future<void> loadRegistrationHistory({
    int? page,
    int? pageSize,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (!hasMoreRegistrations.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      registrationPage.value = 1;
      hasMoreRegistrations.value = true;
    }

    try {
      final uid = await planController.userId;
      if (uid == null) {
        SnackbarService.showError('User not logged in');
        return;
      }

      final currentPage = page ?? registrationPage.value;
      final currentPageSize = pageSize ?? this.pageSize;

      final data = await planController.fetchUserSubscriptionHistoryApi(
        userId: uid,
        page: currentPage,
        pageSize: currentPageSize,
      );

      final List items = data['userSubcriptionHistory'] ?? [];

      if (items.isEmpty || items.length < currentPageSize) {
        hasMoreRegistrations.value = false;
      }

      final newRaw = items
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final loaded = newRaw.map<SubscriptionHistory>((item) {
        final start = item['startDate'] != null
            ? DateTime.parse(item['startDate']).toString().split(' ')[0]
            : '';
        final end = item['endDate'] != null
            ? DateTime.parse(item['endDate']).toString().split(' ')[0]
            : '';
        final basic = (item['basicAmount'] ?? 0).toString();
        final cgst = (item['cgstAmount'] ?? 0).toString();
        final sgst = (item['sgstAmount'] ?? 0).toString();
        final total =
            double.tryParse(basic.toString()) ??
            0.0 +
                (double.tryParse(cgst.toString()) ?? 0.0) +
                (double.tryParse(sgst.toString()) ?? 0.0);

        // Per Day Cost Calculation
        double costPerDay = 0.0;
        final validityDouble = double.tryParse((item['validity'] ?? 0).toString()) ?? 0.0;
        if (validityDouble > 0) {
          costPerDay = total / validityDouble;
        }

        return SubscriptionHistory(
          id: item['_id'] ?? '',
          planName: 'Registration Plan',
          paymentDate: start,
          amountPaid: '₹${total.toStringAsFixed(2)}',
          perDayCost: costPerDay > 0 ? '₹${costPerDay.toStringAsFixed(2)}' : 'N/A',
          validityDays: '${item['validity'] ?? ''} days',
          expiryDate: end,
          headerStatus:
              (item['status'] ?? '').toString().toLowerCase() == 'active'
              ? SubscriptionStatus.active
              : (item['status'] ?? '').toString().toLowerCase() == 'expired'
              ? SubscriptionStatus.expired
              : SubscriptionStatus.pending,
          footerStatus:
              (item['status'] ?? '').toString().toLowerCase() == 'failed'
              ? SubscriptionStatus.failed
              : SubscriptionStatus.success,
        );
      }).toList();

      if (loadMore) {
        registrationsRaw.addAll(newRaw);
        allRegistrations.addAll(loaded);
        registrationPage.value++;
      } else {
        registrationsRaw.value = newRaw;
        allRegistrations.value = loaded;
      }

      _applyFilter();
    } catch (e) {
      SnackbarService.showError('Failed to load registration history');
    } finally {
      if (loadMore) {
        isLoadingMore.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  Future<void> loadSegmentHistory({
    int? page,
    int? pageSize,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (!hasMoreSegments.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      segmentPage.value = 1;
      hasMoreSegments.value = true;
    }

    try {
      final currentPage = page ?? segmentPage.value;
      final currentPageSize = pageSize ?? this.pageSize;

      final data = await planController.fetchSegmentsListApi(
        page: currentPage,
        pageSize: currentPageSize,
      );

      final List items = data['data'] ?? [];

      if (items.isEmpty || items.length < currentPageSize) {
        hasMoreSegments.value = false;
      }

      final newSegments = items
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (loadMore) {
        segments.addAll(newSegments);
        segmentPage.value++;
      } else {
        segments.value = newSegments;
      }
      
      _applyFilter(); // Apply filter to segments as well
    } catch (e) {
      SnackbarService.showError('Failed to load segment history');
    } finally {
      if (loadMore) {
        isLoadingMore.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }

  void _applyFilter() {
    List<SubscriptionHistory> filtered = List.from(allRegistrations);

    switch (selectedFilter.value) {
      case 'Latest':
        filtered.sort((a, b) {
          try {
            final dateA = DateTime.tryParse(a.paymentDate);
            final dateB = DateTime.tryParse(b.paymentDate);
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Oldest':
        filtered.sort((a, b) {
          try {
            final dateA = DateTime.tryParse(a.paymentDate);
            final dateB = DateTime.tryParse(b.paymentDate);
            if (dateA == null || dateB == null) return 0;
            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Active':
        filtered = filtered
            .where((s) => s.headerStatus == SubscriptionStatus.active)
            .toList();
        filtered.sort((a, b) {
          try {
            final dateA = DateTime.tryParse(a.paymentDate);
            final dateB = DateTime.tryParse(b.paymentDate);
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        break;
      case 'Expired':
        filtered = filtered
            .where((s) => s.headerStatus == SubscriptionStatus.expired)
            .toList();
        filtered.sort((a, b) {
          try {
            final dateA = DateTime.tryParse(a.paymentDate);
            final dateB = DateTime.tryParse(b.paymentDate);
            if (dateA == null || dateB == null) return 0;
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
        break;
    }

    registrations.value = filtered;

    // Filter Segments
    List<Map<String, dynamic>> filteredSegs = List.from(segments);
    
    switch (selectedFilter.value) {
      case 'Latest':
        filteredSegs.sort((a, b) {
             final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
             final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');
             if (dateA == null || dateB == null) return 0;
             return dateB.compareTo(dateA);
        });
        break;
      case 'Oldest':
        filteredSegs.sort((a, b) {
             final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
             final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');
             if (dateA == null || dateB == null) return 0;
             return dateA.compareTo(dateB);
        });
        break;
      case 'Active':
        // Filter where expiry date > now
        filteredSegs = filteredSegs.where((s) {
           final createdAt = DateTime.tryParse(s['createdAt']?.toString() ?? '');
           final segmentInfo = s['segmentId'] is Map ? s['segmentId'] : null;
           final validity = double.tryParse(segmentInfo?['validity']?.toString() ?? '0') ?? 0;
           if (createdAt != null && validity > 0) {
              final expiry = createdAt.add(Duration(days: validity.toInt()));
              return expiry.isAfter(DateTime.now());
           }
           // If lifetime or unknown, assume active? Or define logic. Assuming Active for now if valid.
           // If validity is 0, usually lifetime?
           return true; 
        }).toList();
         filteredSegs.sort((a, b) {
             final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
             final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');
             if (dateA == null || dateB == null) return 0;
             return dateB.compareTo(dateA);
        });
        break;
      case 'Expired':
         filteredSegs = filteredSegs.where((s) {
           final createdAt = DateTime.tryParse(s['createdAt']?.toString() ?? '');
           final segmentInfo = s['segmentId'] is Map ? s['segmentId'] : null;
           final validity = double.tryParse(segmentInfo?['validity']?.toString() ?? '0') ?? 0;
           if (createdAt != null && validity > 0) {
              final expiry = createdAt.add(Duration(days: validity.toInt()));
              return expiry.isBefore(DateTime.now());
           }
           return false; 
        }).toList();
         filteredSegs.sort((a, b) {
             final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
             final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');
             if (dateA == null || dateB == null) return 0;
             return dateB.compareTo(dateA);
        });
        break;
    }
    filteredSegments.value = filteredSegs;
  }

  void changeFilter(String? newFilter) {
    if (newFilter != null) {
      selectedFilter.value = newFilter;
    }
  }
}
