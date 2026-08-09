import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/plan_purchase.controller.dart';
import '../../core/models/subscription_history.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_styles.dart';
import '../../core/utils/responsive.dart';
import 'widgets/subscription_card.dart';
import '../../services/snackbar.service.dart';

class SubscriptionHistoryController extends GetxController {
  final planController = Get.put(PlanPurchaseController());

  final RxString selectedFilter = 'Latest'.obs;

  final RxList<SubscriptionHistory> segments = <SubscriptionHistory>[].obs;
  final RxList<SubscriptionHistory> filteredSegments = <SubscriptionHistory>[].obs;
  final RxList<Map<String, dynamic>> segmentsRaw = <Map<String, dynamic>>[].obs;

  final RxBool isSegmentLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

  final RxInt segmentPage = 1.obs;
  final RxBool hasMoreSegments = true.obs;
  final int pageSize = 20;
  
  DateTime? _lastRefreshTime;
  static const Duration _refreshThreshold = Duration(seconds: 60);

  @override
  void onInit() {
    super.onInit();
    // Default to Segment view
    // loadRegistrationHistory(); 
    loadSegmentHistory();
    ever(selectedFilter, (_) => _applyFilter());
  }

  Future<void> refreshData() async {
     await loadSegmentHistory();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> loadSegmentHistory({
    int? page,
    int? pageSize,
    bool loadMore = false,
    bool force = false,
  }) async {
    final now = DateTime.now();
    if (!force && !loadMore && _lastRefreshTime != null && 
        now.difference(_lastRefreshTime!) < _refreshThreshold && 
        segments.isNotEmpty) {
      debugPrint('SubscriptionHistoryController: Skipping refresh, data fresh.');
      return;
    }

    debugPrint('DEBUG: loadSegmentHistory called with loadMore: $loadMore');
    if (loadMore) {
      if (!hasMoreSegments.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    } else {
      isSegmentLoading.value = true;
      _lastRefreshTime = now;
      segmentPage.value = 1;
      hasMoreSegments.value = true;
    }

    try {
      final uid = await planController.userId;
      debugPrint('DEBUG: User ID: $uid');
      if (uid == null) {
        SnackbarService.showError('User not logged in');
        return;
      }

      final currentPage = page ?? segmentPage.value;
      final currentPageSize = pageSize ?? this.pageSize;
      debugPrint(
        'DEBUG: Fetching page $currentPage with size $currentPageSize',
      );

      final data = await planController.fetchUserSubscriptionHistoryApi(
        userId: uid,
        page: currentPage,
        pageSize: currentPageSize,
        type: 'plan',
      );

      final List items = data['userSubcriptionHistory'] ?? [];
      
      if (items.isEmpty || items.length < currentPageSize) {
        hasMoreSegments.value = false;
      }

      final List<SubscriptionHistory> loaded = items
          .map((e) => SubscriptionHistory.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (loadMore) {
        segmentsRaw.addAll(items.cast<Map<String, dynamic>>());
        segments.addAll(loaded);
        segmentPage.value++;
      } else {
        segmentsRaw.value = items.cast<Map<String, dynamic>>();
        segments.value = loaded;
      }
      
      _applyFilter();
    } catch (e) {
      debugPrint('DEBUG: Error in loadSegmentHistory: $e');
      SnackbarService.showError('Failed to load segment history');
    } finally {
      if (loadMore) {
        isLoadingMore.value = false;
      } else {
        isSegmentLoading.value = false;
      }
    }
  }

  void _applyFilter() {
    // Filter Segments
    List<SubscriptionHistory> filteredSegs = List.from(segments);
    
    switch (selectedFilter.value) {
      case 'Latest':
        filteredSegs.sort((a, b) {
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
        filteredSegs.sort((a, b) {
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
        filteredSegs = filteredSegs
            .where((s) => s.headerStatus == SubscriptionStatus.active)
            .toList();
            
        filteredSegs.sort((a, b) {
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
        filteredSegs = filteredSegs
            .where((s) => s.headerStatus == SubscriptionStatus.expired)
            .toList();
            
        filteredSegs.sort((a, b) {
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
    filteredSegments.value = filteredSegs;
  }

  void changeFilter(String? newFilter) {
    if (newFilter != null) {
      selectedFilter.value = newFilter;
    }
  }
}

class SubscriptionHistoryScreen extends StatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  State<SubscriptionHistoryScreen> createState() => _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends State<SubscriptionHistoryScreen> {
  late final SubscriptionHistoryController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SubscriptionHistoryController());
    controller.refreshData();
  }


  void _showInstallmentHistoryDialog(BuildContext context, List<dynamic> installments) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Payment History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            if (installments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text("No installments found")),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: installments.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final inst = installments[index];
                    final date = DateTime.tryParse(inst['transactionDate'] ?? '');
                    final status = inst['status'] ?? 'PENDING';
                    
                    final base = inst['baseAmount'] ?? (double.tryParse(inst['amountPaid'].toString()) ?? 0.0) / 1.18;
                    final gst = inst['gstAmount'] ?? (double.tryParse(inst['amountPaid'].toString()) ?? 0.0) - base;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("₹${base.toStringAsFixed(2)} + ₹${gst.toStringAsFixed(2)}", 
                                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                if (date != null)
                                  Text(DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()), 
                                       style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'APPROVED' ? Colors.green[50] : 
                                     status == 'REJECTED' ? Colors.red[50] : Colors.orange[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: status == 'APPROVED' ? Colors.green : 
                                       status == 'REJECTED' ? Colors.red : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    // controller is initialized in initState

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlueDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Active Plans',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlueDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderGrey, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(
              () => DropdownButton<String>(
                value: controller.selectedFilter.value,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.textGrey,
                  size: 20,
                ),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textBlack,
                ),
                items: ['Latest', 'Oldest', 'Active', 'Expired'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: controller.changeFilter,
              ),
            ),
          ),
        ],
        bottom: null,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Obx(
                    () => Text(
                      'Filter: ${controller.selectedFilter.value}',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.search,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(
              () => controller.isSegmentLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.segments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: responsive.sp(64),
                            color: AppTheme.infoBorder,
                          ),
                          SizedBox(height: responsive.hp(2)),
                          Text(
                            'No segment history',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: responsive.sp(16),
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => controller.loadSegmentHistory(),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!controller.isLoadingMore.value &&
                              controller.hasMoreSegments.value &&
                              scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent -
                                      200) {
                            controller.loadSegmentHistory(loadMore: true);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              controller.filteredSegments.length +
                              (controller.isLoadingMore.value ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == controller.filteredSegments.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final segment = controller.filteredSegments[index];
                                
                            // Directly use model properties
                            final isPartial = segment.isPartial;
                            final paymentIntentId = segment.paymentIntentId;
                                
                            final isActive = segment.headerStatus == SubscriptionStatus.active;
                            final isPending = segment.headerStatus == SubscriptionStatus.pending || segment.headerStatus.toString().toLowerCase().contains('pending');
                            // Allow if partial, and status is active (continuing) or pending
                            final shouldShowPayButton = isPartial && (isActive || isPending);

                            return SubscriptionCard(
                              planName: segment.planName,
                              startDate: segment.paymentDate,
                              remainingAmount: segment.remainingAmount,
                              amountPaid: segment.totalAmountStr,
                              validityDays: segment.validityDays,
                              perDayCost: segment.perDayCost,
                              headerStatus: segment.headerStatus,
                              footerStatus: segment.footerStatus,
                              isPartial: isPartial,
                              onViewInstallments: isPartial ? () => _showInstallmentHistoryDialog(context, segment.partialPaymentsHistory) : null,
                              onPayInstallment: shouldShowPayButton
                                ? () {
                                    if (paymentIntentId == null) {
                                        SnackbarService.showError("Payment Intent ID not found");
                                        return;
                                    }
                                        
                                    Get.toNamed('/bank-transfer-upload', arguments: {
                                      'paymentId': paymentIntentId,
                                      'isPartial': true,
                                      'planName': segment.planName,
                                      'totalToPay': segment.partialTotalTarget,
                                    });
                                  }
                                : null,
                              onTap: null, // Invoice will now only be accessible from Billing History

                            );
                          },
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ));
  }
}
