import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/subscription.service.dart';
import 'package:spresearch_web/services/user_details.service.dart';
import 'package:spresearch_web/services/user.service.dart';
import 'package:spresearch_web/models/user_details.model.dart';
import 'package:spresearch_web/models/subscription_plan.model.dart';
import 'package:spresearch_web/models/segment.model.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'package:spresearch_web/services/acquisition.service.dart';
import 'package:spresearch_web/services/segment.service.dart';
import 'package:spresearch_web/services/auth.service.dart';

class ManageSubscriptionController extends GetxController {
  late final SubscriptionService _subscriptionService;
  late final UserDetailsService _userDetailsService;
  late final UserService _userService;
  late final StaffService _staffService;
  late final AcquisitionService _acquisitionService;
  late final SegmentService _segmentService;
  late final AuthService _authService;

  var isLoading = false.obs;
  var userSubscriptions = <Map<String, dynamic>>[].obs;
  var currentUserId = ''.obs;
  var userDetails = Rxn<UserDetailsModel>();
  String? _lastFetchedUserId;

  // Maps to store editing state for dates
  var startDateControllers = <String, TextEditingController>{}.obs;
  var endDateControllers = <String, TextEditingController>{}.obs;

  // For CustomPlans accordion
  var expandedPlanIndex = (-1).obs;

  void togglePlanExpansion(int index) {
    if (expandedPlanIndex.value == index) {
      expandedPlanIndex.value = -1;
    } else {
      expandedPlanIndex.value = index;
    }
  }

  var availablePlans = <SubscriptionPlanModel>[].obs;
  var segments = <SegmentModel>[].obs;
  var staffList = <StaffModel>[].obs;

  // Correction Engine Observables
  var correctionSegments = <Map<String, dynamic>>[].obs;
  var plansForSelectedSegment = <Map<String, dynamic>>[].obs;
  var isFetchingPlans = false.obs;
  var currentUser = Rxn<dynamic>();

  bool get isAdmin => currentUser.value?.isAdmin ?? false;

  @override
  void onInit() {
    _subscriptionService = Get.find<SubscriptionService>();
    _userDetailsService = Get.find<UserDetailsService>();
    _userService = Get.find<UserService>();
    _staffService = Get.find<StaffService>();
    _acquisitionService = Get.find<AcquisitionService>();
    _segmentService = Get.find<SegmentService>();
    _authService = Get.find<AuthService>();
    super.onInit();
    _loadCurrentUser();
    fetchAvailablePlans();
    fetchSegments();
    fetchStaffList();
    loadCorrectionSegments();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getUser();
    currentUser.value = user;
  }

  Future<void> loadCorrectionSegments() async {
    final list = await _segmentService.getSegmentDropdownList();
    correctionSegments.assignAll(list);
  }

  Future<void> loadCorrectionPlansForSegment(String segmentId) async {
    isFetchingPlans.value = true;
    final list = await _segmentService.getPlansBySegment(segmentId);
    // Filter out Custom/HNI plans as per Gap 17
    plansForSelectedSegment.assignAll(
      list.where((p) => p['isHni'] != true).toList(),
    );
    isFetchingPlans.value = false;
  }

  Future<void> fetchStaffList() async {
    try {
      final list = await _staffService.getStaffList();
      staffList.value = list;
    } catch (e) {
      debugPrint('Error fetching staff for manage subscription: $e');
    }
  }

  Future<void> fetchSegments() async {
    final result = await _subscriptionService.getSegments();
    segments.value = result;
  }

  Future<void> fetchAvailablePlans() async {
    final result = await _subscriptionService.getSubscriptionPlans(
      pageSize: 100,
    );
    availablePlans.value = result.plans;
  }

  Future<void> fetchUserSubscriptions(String userId) async {
    if (_lastFetchedUserId == userId &&
        (isLoading.value || userSubscriptions.isNotEmpty))
      return;
    _lastFetchedUserId = userId;

    isLoading.value = true;
    currentUserId.value = userId;
    try {
      final user = await _userDetailsService.getUserDetails(userId);
      userDetails.value = user;

      final subs = await _subscriptionService.getUserSubscriptions(userId);
      userSubscriptions.value = subs;

      // Initialize controllers for dates
      for (var sub in subs) {
        final id = sub['_id'];
        final name = sub['packageName']?.toString().toLowerCase() ?? '';

        String? startStr = sub['startDate'];
        String? endStr = sub['endDate'] ?? sub['expiryDate'];

        if (name.contains('registration') &&
            (endStr == null || endStr.isEmpty)) {
          // Check user details as fallback if sub history doesn't have it
          endStr = user?.registrationExpiry;
        }

        startDateControllers[id] = TextEditingController(
          text: _formatDate(startStr),
        );
        endDateControllers[id] = TextEditingController(
          text: _formatDate(endStr),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(dateStr));
    } catch (e) {
      return '';
    }
  }

  Future<void> pickDate(
    BuildContext context,
    String planId,
    bool isStartDate,
  ) async {
    final initialDate =
        DateTime.tryParse(
          isStartDate
              ? startDateControllers[planId]?.text ?? ''
              : endDateControllers[planId]?.text ?? '',
        ) ??
        DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      if (isStartDate) {
        startDateControllers[planId]?.text = formatted;
      } else {
        endDateControllers[planId]?.text = formatted;
      }
      // Trigger update immediately or show save button?
      // User asked for "two calender fields", implying direct interaction.
      // I'll auto-save on change for convenience or provide a specific update button per row.
      // Let's provide an explicit "Update" icon/button next to dates or row to confirm.
      await updateDates(planId);
    }
  }

  Future<void> updateDates(String planId) async {
    final start = startDateControllers[planId]?.text;
    final end = endDateControllers[planId]?.text;

    // basic validation
    if (start == null || end == null) return;

    // Check if dates are already formatted (yyyy-MM-dd)
    try {
      final s = DateFormat('yyyy-MM-dd').parse(start);
      final e = DateFormat('yyyy-MM-dd').parse(end);
      if (e.isBefore(s)) {
        Get.snackbar(
          'Validation Error',
          'End Date cannot be before Start Date',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
    } catch (_) {}

    final reasonController = TextEditingController();
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Update Subscription Dates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a brief reason for this manual date update (Mandatory).',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Edit Reason',
                hintText: 'e.g., Extended due to KYC delay',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().length < 5) {
                Get.snackbar('Error', 'Reason must be at least 5 characters');
                return;
              }
              Get.back(result: true);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _subscriptionService.updateSubscriptionDates(
      planId: planId,
      startDate: start,
      endDate: end,
      editReason: reasonController.text.trim(),
    );

    if (success) {
      Get.snackbar(
        'Success',
        'Subscription dates updated',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Wait a moment and then refresh the UI if possible
      await fetchUserSubscriptions(currentUserId.value);
    } else {
      Get.snackbar(
        'Error',
        'Failed to update dates. Check if it overlaps with another active plan.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> suspendSubscription(String userId, String planId) async {
    final sub = userSubscriptions.firstWhereOrNull((s) => s['_id'] == planId);
    final packageName = sub?['packageName']?.toString().toLowerCase() ?? '';
    final isRegistration = packageName.contains('registration');

    String? reason;
    if (isRegistration) {
      final reasonController = TextEditingController();
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Suspend Registration Plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to suspend this registration plan? This will also suspend the user account.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Suspension Reason',
                  hintText: 'Enter mandatory reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Error',
                    'Reason is mandatory',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }
                Get.back(result: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Suspend'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
      reason = reasonController.text.trim();
    }

    final success = await _subscriptionService.suspendSubscription(
      userId,
      planId: planId,
      reason: reason,
    );
    if (success) {
      Get.snackbar(
        'Success',
        'Subscription suspended',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchUserSubscriptions(userId);
    } else {
      Get.snackbar(
        'Error',
        'Failed to suspend subscription',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> activateSubscription(String userId, String planId) async {
    final success = await _subscriptionService.activateSubscription(
      userId,
      planId: planId,
    );
    if (success) {
      Get.snackbar(
        'Success',
        'Subscription activated',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchUserSubscriptions(userId);
    } else {
      Get.snackbar(
        'Error',
        'Failed to activate subscription',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> revokeSubscription(String userId, String planId) async {
    final success = await _subscriptionService.revokeSubscription(
      userId,
      planId: planId,
    );
    if (success) {
      Get.snackbar(
        'Success',
        'Subscription revoked',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchUserSubscriptions(userId);
    } else {
      Get.snackbar(
        'Error',
        'Failed to revoke subscription',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> revokeCurrentSubscription() async {
    final activePlan = userSubscriptions.firstWhereOrNull(
      (sub) => sub['status'] == 'active',
    );
    if (activePlan != null && currentUserId.value.isNotEmpty) {
      await revokeSubscription(currentUserId.value, activePlan['_id']);
    } else {
      Get.snackbar(
        'Info',
        'No active subscription to revoke',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }

  Future<void> assignRegistration(String regType) async {
    if (currentUserId.value.isEmpty) return;

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirm Registration Assignment'),
        content: Text(
          'Assign $regType registration to user? This will mark user as active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _userService.updateUser(currentUserId.value, {
        'registrationType': regType.toUpperCase(),
        // Backend handles status update logic
      });
      if (success) {
        Get.snackbar(
          'Success',
          'Registration assigned successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchUserSubscriptions(currentUserId.value);
      } else {
        Get.snackbar(
          'Error',
          'Failed to assign registration',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> showAddPlanDialog(BuildContext context, String userId) async {
    // 1. Filter plans: Exclude plans user already has (Active or Suspended)
    debugPrint('--- Filtering Plans ---');

    // Ensure segments are loaded
    if (segments.isEmpty) {
      await fetchSegments();
    }

    final activeSubscriptionNames = userSubscriptions
        .where((s) {
          final status = s['status']?.toString().trim().toLowerCase() ?? '';
          return ['active', 'suspended'].contains(status);
        })
        .map((s) => s['packageName'].toString().trim().toLowerCase())
        .toSet();

    debugPrint('User has active plans: $activeSubscriptionNames');

    final plansToShow = availablePlans.where((p) {
      if (p.planStatus.toLowerCase() != 'active') return false;

      final planNameNormalized = p.planName.trim().toLowerCase();
      final isExcluded = activeSubscriptionNames.contains(planNameNormalized);

      return !isExcluded;
    }).toList();

    DateTime selectedStart = DateTime.now();
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(selectedStart),
    );

    // Registration Status logic
    final currentRegStatus = userDetails.value?.registrationStatus ?? 'PENDING';
    final currentRegType = userDetails.value?.registrationType ?? 'N/A';
    bool isRegActive = currentRegStatus.toUpperCase() == 'ACTIVE';
    String? selectedRegType;
    String? selectedSegmentId;

    // HNI Fields
    final totalAgreementPriceController = TextEditingController();
    final customValidityController = TextEditingController();
    String? selectedRaId;
    var selectedHniSegments = <String>[].obs;

    // Use Get.dialog with Stateful Builder to handle local state update
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: 700,
              height: 800,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assign Entitlements',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Registration Section ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Registration Plan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isRegActive) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'ACTIVE ($currentRegType)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!isRegActive) ...[
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedRegType,
                                  decoration: InputDecoration(
                                    hintText: 'Select Registration Type',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'YEARLY',
                                      child: Text('Silver Registration'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'LIFETIME',
                                      child: Text('Gold Registration'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    setState(() => selectedRegType = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: selectedRegType == null
                                    ? null
                                    : () async {
                                        final confirm = await Get.dialog<bool>(
                                          AlertDialog(
                                            title: Text(
                                              'Confirm Registration Assignment',
                                            ),
                                            content: Text(
                                              'Assign $selectedRegType registration to user? This will mark user as active.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Get.back(result: false),
                                                child: Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Get.back(result: true),
                                                child: Text('Confirm'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          final success = await _userService
                                              .updateUser(userId, {
                                                'registrationType':
                                                    selectedRegType,
                                              });
                                          if (success) {
                                            Get.snackbar(
                                              'Success',
                                              'Registration assigned successfully',
                                              backgroundColor: Colors.green,
                                              colorText: Colors.white,
                                            );
                                            await fetchUserSubscriptions(
                                              userId,
                                            );
                                            Get.back();
                                          } else {
                                            Get.snackbar(
                                              'Error',
                                              'Failed to assign registration',
                                              backgroundColor: Colors.red,
                                              colorText: Colors.white,
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                child: Text('Assign Registration'),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'User already has an active registration plan.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(),
                  const SizedBox(height: 16),

                  // --- Plans Section ---
                  Text(
                    'Segment Subscription Plans',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Segment Dropdown (For Standard Plans)
                  DropdownButtonFormField<String>(
                    value: selectedSegmentId,
                    decoration: InputDecoration(
                      hintText: 'Select Standard Segment',
                      helperText:
                          'Required for standard plans, ignored for HNI plans',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: segments.map((segment) {
                      return DropdownMenuItem(
                        value: segment.id,
                        child: Text(segment.segmentName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedSegmentId = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Picker Row
                  Row(
                    children: [
                      const Text('Start Date for Plan: '),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: selectedStart,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setState(() {
                                selectedStart = d;
                                dateController.text = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(d);
                              });
                            }
                          },
                          child: IgnorePointer(
                            child: TextField(
                              controller: dateController,
                              decoration: InputDecoration(
                                hintText: 'Select Date',
                                suffixIcon: Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // List
                  Expanded(
                    child: plansToShow.isEmpty
                        ? Center(
                            child: Text(
                              'No subscription plans available to assign.',
                            ),
                          )
                        : ListView.builder(
                            itemCount: plansToShow.length,
                            itemBuilder: (ctx, index) {
                              final plan = plansToShow[index];
                              final isHni = plan.isHni;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      plan.planName,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    if (isHni) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .purple
                                                              .shade50,
                                                          border: Border.all(
                                                            color: Colors
                                                                .purple
                                                                .shade200,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'HNI',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .purple
                                                                .shade900,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                if (!isHni)
                                                  Text(
                                                    'Duration: ${plan.duration} ${plan.day}',
                                                  ),
                                                if (!isHni)
                                                  Text(
                                                    'Price: ₹${plan.price}',
                                                    style: TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    'Bespoke HNI Plan',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                (!isHni &&
                                                    selectedSegmentId == null)
                                                ? null
                                                : () async {
                                                    // HNI logic or Standard logic based on isHni
                                                    final standardSegmentName =
                                                        segments
                                                            .firstWhereOrNull(
                                                              (s) =>
                                                                  s.id ==
                                                                  selectedSegmentId,
                                                            )
                                                            ?.segmentName ??
                                                        'Unknown Segment';

                                                    // Dialog Controllers
                                                    final amountController =
                                                        TextEditingController();
                                                    final commentController =
                                                        TextEditingController();
                                                    bool isPartialMode = false;

                                                    // Reset HNI state for this specific assignment click
                                                    if (isHni) {
                                                      totalAgreementPriceController
                                                          .clear();
                                                      customValidityController
                                                          .clear();
                                                      selectedRaId = null;
                                                      selectedHniSegments
                                                          .clear();
                                                    }

                                                    await Get.dialog(
                                                      StatefulBuilder(
                                                        builder: (context, setDialogState) {
                                                          final filteredStaff = staffList
                                                              .where(
                                                                (s) =>
                                                                    s.role
                                                                        .toUpperCase()
                                                                        .contains(
                                                                          'RESEARCH',
                                                                        ) ||
                                                                    s.role
                                                                        .toUpperCase()
                                                                        .contains(
                                                                          'RA',
                                                                        ) ||
                                                                    s.role
                                                                        .toUpperCase()
                                                                        .contains(
                                                                          'ANALYST',
                                                                        ),
                                                              )
                                                              .toList();

                                                          return AlertDialog(
                                                            title: Text(
                                                              isHni
                                                                  ? 'HNI Plan Assignment: ${plan.planName}'
                                                                  : 'Confirm Plan Assignment',
                                                            ),
                                                            content: SingleChildScrollView(
                                                              child: Container(
                                                                width: 500,
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    if (!isHni)
                                                                      Text(
                                                                        'Assign ${plan.planName} ($standardSegmentName) to user starting from ${dateController.text}?',
                                                                      )
                                                                    else
                                                                      Text(
                                                                        'Configure HNI Plan details below for ${plan.planName} starting from ${dateController.text}.',
                                                                        style: TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),

                                                                    const SizedBox(
                                                                      height:
                                                                          20,
                                                                    ),

                                                                    if (isHni) ...[
                                                                      // HNI MULTI-SEGMENT
                                                                      Text(
                                                                        'Select Entitlements (Segments)',
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              13,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Colors.grey[700],
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            8,
                                                                      ),
                                                                      Obx(
                                                                        () => Wrap(
                                                                          spacing:
                                                                              8,
                                                                          runSpacing:
                                                                              8,
                                                                          children: segments.map((
                                                                            seg,
                                                                          ) {
                                                                            final isSelected = selectedHniSegments.contains(
                                                                              seg.id,
                                                                            );
                                                                            return FilterChip(
                                                                              label: Text(
                                                                                seg.segmentName,
                                                                              ),
                                                                              selected: isSelected,
                                                                              onSelected:
                                                                                  (
                                                                                    val,
                                                                                  ) {
                                                                                    if (val)
                                                                                      selectedHniSegments.add(
                                                                                        seg.id,
                                                                                      );
                                                                                    else
                                                                                      selectedHniSegments.remove(
                                                                                        seg.id,
                                                                                      );
                                                                                  },
                                                                              selectedColor: AppTheme.primary.withOpacity(
                                                                                0.2,
                                                                              ),
                                                                              labelStyle: TextStyle(
                                                                                fontSize: 12,
                                                                                color: isSelected
                                                                                    ? AppTheme.primary
                                                                                    : AppTheme.textPrimary,
                                                                              ),
                                                                            );
                                                                          }).toList(),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            16,
                                                                      ),

                                                                      // HNI PRICE & VALIDITY
                                                                      Row(
                                                                        children: [
                                                                          Expanded(
                                                                            child: TextField(
                                                                              controller: totalAgreementPriceController,
                                                                              keyboardType: TextInputType.number,
                                                                              decoration: InputDecoration(
                                                                                labelText: 'Total Agreement Price (₹)',
                                                                                hintText: 'e.g. 50000',
                                                                                border: OutlineInputBorder(),
                                                                                prefixText: '₹ ',
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            width:
                                                                                12,
                                                                          ),
                                                                          Expanded(
                                                                            child: TextField(
                                                                              controller: customValidityController,
                                                                              keyboardType: TextInputType.number,
                                                                              decoration: InputDecoration(
                                                                                labelText: 'Validity (Days)',
                                                                                hintText: 'e.g. 365',
                                                                                border: OutlineInputBorder(),
                                                                                suffixText: 'days',
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            16,
                                                                      ),

                                                                      // RA ASSIGNMENT
                                                                      DropdownButtonFormField<
                                                                        String
                                                                      >(
                                                                        value:
                                                                            selectedRaId,
                                                                        decoration: InputDecoration(
                                                                          labelText:
                                                                              'Assign Research Analyst',
                                                                          border:
                                                                              OutlineInputBorder(),
                                                                        ),
                                                                        items: filteredStaff
                                                                            .map(
                                                                              (
                                                                                s,
                                                                              ) => DropdownMenuItem(
                                                                                value: s.id,
                                                                                child: Text(
                                                                                  s.name,
                                                                                ),
                                                                              ),
                                                                            )
                                                                            .toList(),
                                                                        onChanged:
                                                                            (
                                                                              v,
                                                                            ) =>
                                                                                selectedRaId = v,
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            16,
                                                                      ),
                                                                    ],

                                                                    // Remarks Field (Always Visible)
                                                                    TextField(
                                                                      controller:
                                                                          commentController,
                                                                      decoration: InputDecoration(
                                                                        labelText:
                                                                            'Remarks / Comments',
                                                                        hintText:
                                                                            'Optional notes for this assignment',
                                                                        border:
                                                                            OutlineInputBorder(),
                                                                      ),
                                                                      maxLines:
                                                                          2,
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          16,
                                                                    ),

                                                                    Row(
                                                                      children: [
                                                                        Checkbox(
                                                                          value:
                                                                              isPartialMode,
                                                                          onChanged: (val) {
                                                                            setDialogState(() {
                                                                              isPartialMode =
                                                                                  val ??
                                                                                  false;
                                                                            });
                                                                          },
                                                                        ),
                                                                        const Text(
                                                                          'Partial Payment / Receipt Entered',
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    if (isPartialMode) ...[
                                                                      const SizedBox(
                                                                        height:
                                                                            8,
                                                                      ),
                                                                      TextField(
                                                                        controller:
                                                                            amountController,
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        decoration: InputDecoration(
                                                                          labelText:
                                                                              'Amount Paid (₹)',
                                                                          hintText:
                                                                              'Enter amount paid',
                                                                          border:
                                                                              OutlineInputBorder(),
                                                                          helperText:
                                                                              isHni
                                                                              ? 'Total expected price set above'
                                                                              : 'Standard Price: ₹${plan.price}',
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Get.back(),
                                                                child: Text(
                                                                  'Cancel',
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                                onPressed: () async {
                                                                  // Validation for HNI
                                                                  if (isHni) {
                                                                    if (selectedHniSegments
                                                                        .isEmpty) {
                                                                      Get.snackbar(
                                                                        'Error',
                                                                        'Please select at least one segment',
                                                                        backgroundColor:
                                                                            Colors.red,
                                                                        colorText:
                                                                            Colors.white,
                                                                      );
                                                                      return;
                                                                    }
                                                                    if (totalAgreementPriceController
                                                                        .text
                                                                        .isEmpty) {
                                                                      Get.snackbar(
                                                                        'Error',
                                                                        'Please enter total agreement price',
                                                                        backgroundColor:
                                                                            Colors.red,
                                                                        colorText:
                                                                            Colors.white,
                                                                      );
                                                                      return;
                                                                    }
                                                                    if (customValidityController
                                                                        .text
                                                                        .isEmpty) {
                                                                      Get.snackbar(
                                                                        'Error',
                                                                        'Please enter validity in days',
                                                                        backgroundColor:
                                                                            Colors.red,
                                                                        colorText:
                                                                            Colors.white,
                                                                      );
                                                                      return;
                                                                    }
                                                                  }

                                                                  double?
                                                                  partialAmount;
                                                                  if (isPartialMode) {
                                                                    partialAmount =
                                                                        double.tryParse(
                                                                          amountController
                                                                              .text,
                                                                        );
                                                                    if (partialAmount ==
                                                                            null ||
                                                                        partialAmount <=
                                                                            0) {
                                                                      Get.snackbar(
                                                                        'Error',
                                                                        'Please enter a valid amount',
                                                                        backgroundColor:
                                                                            Colors.red,
                                                                        colorText:
                                                                            Colors.white,
                                                                      );
                                                                      return;
                                                                    }
                                                                  }

                                                                  Get.back(); // Close confirm dialog
                                                                  Get.back(); // Close main list dialog

                                                                  // Calculate validity
                                                                  int validity =
                                                                      30;
                                                                  if (isHni) {
                                                                    validity =
                                                                        int.tryParse(
                                                                          customValidityController
                                                                              .text,
                                                                        ) ??
                                                                        365;
                                                                  } else if (plan
                                                                      .day
                                                                      .toLowerCase()
                                                                      .contains(
                                                                        'day',
                                                                      )) {
                                                                    validity =
                                                                        int.tryParse(
                                                                          plan.duration,
                                                                        ) ??
                                                                        30;
                                                                  } else if (plan
                                                                      .day
                                                                      .toLowerCase()
                                                                      .contains(
                                                                        'month',
                                                                      )) {
                                                                    validity =
                                                                        (int.tryParse(
                                                                              plan.duration,
                                                                            ) ??
                                                                            1) *
                                                                        30;
                                                                  } else if (plan
                                                                      .day
                                                                      .toLowerCase()
                                                                      .contains(
                                                                        'year',
                                                                      )) {
                                                                    validity =
                                                                        (int.tryParse(
                                                                              plan.duration,
                                                                            ) ??
                                                                            1) *
                                                                        365;
                                                                  }

                                                                  // Call API
                                                                  final success = await _subscriptionService.adminCreatePlan(
                                                                    userId:
                                                                        userId,
                                                                    packageName:
                                                                        plan.planName,
                                                                    amount: plan
                                                                        .price
                                                                        .toDouble(),
                                                                    validity:
                                                                        validity,
                                                                    startDate:
                                                                        selectedStart,
                                                                    planId:
                                                                        plan.id,
                                                                    segmentId:
                                                                        isHni
                                                                        ? (selectedHniSegments.isNotEmpty
                                                                              ? selectedHniSegments.first
                                                                              : '')
                                                                        : selectedSegmentId!,
                                                                    segmentIds:
                                                                        isHni
                                                                        ? selectedHniSegments
                                                                              .toList()
                                                                        : null,
                                                                    isPartial:
                                                                        isPartialMode,
                                                                    partialAmountPaid:
                                                                        partialAmount,
                                                                    comment:
                                                                        commentController
                                                                            .text
                                                                            .trim()
                                                                            .isNotEmpty
                                                                        ? commentController
                                                                              .text
                                                                              .trim()
                                                                        : null,
                                                                    totalAgreementPrice:
                                                                        isHni
                                                                        ? double.tryParse(
                                                                            totalAgreementPriceController.text,
                                                                          )
                                                                        : null,
                                                                    raId: isHni
                                                                        ? selectedRaId
                                                                        : null,
                                                                    isHniGrant:
                                                                        isHni,
                                                                  );

                                                                  if (success) {
                                                                    Get.snackbar(
                                                                      'Success',
                                                                      'Plan assigned successfully',
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green,
                                                                      colorText:
                                                                          Colors
                                                                              .white,
                                                                    );
                                                                    fetchUserSubscriptions(
                                                                      userId,
                                                                    );
                                                                  } else {
                                                                    Get.snackbar(
                                                                      'Error',
                                                                      'Failed to assign plan',
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                      colorText:
                                                                          Colors
                                                                              .white,
                                                                    );
                                                                  }
                                                                },
                                                                child: Text(
                                                                  isHni
                                                                      ? 'Assign HNI Plan'
                                                                      : 'Assign',
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isHni
                                                  ? Colors.purple
                                                  : Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: Text('Assign'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- TopUp Partial Plan ---
  void showTopUpDialog(Map<String, dynamic> sub) {
    final userId = sub['userId'] ?? (Get.arguments?['id'] ?? ''); // userId
    // Wait, sub doesn't have userId directly if it's from list.
    // We fetch subcription list for a specific user, so we should have userId in controller state?
    // Not directly stored. We pass it to fetchUserSubscriptions(userId).
    // Let's rely on argument passed or stored.
    // Actually, fetchUserSubscriptions populates userSubscriptions.
    // The userId is passed to showDialog usually.
    // Let's trust we can get it or pass it.
    // The ManageSubscriptionController is instantiated for ONE user? No, it's generic?
    // It seems to be used inside a Dialog triggered from User List.
    // Ah, 'fetchUserSubscriptions(String userId)' is called.

    // We need to know which user this sub belongs to.
    // Let's assume we pass userId to this function.
  }

  Future<void> triggerTopUp(
    String userId,
    String entitlementId,
    String planName,
  ) async {
    final amountController = TextEditingController();
    final commentController = TextEditingController();

    await Get.dialog(
      AlertDialog(
        title: Text('Top Up Partial Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan: $planName',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount to Add (₹)',
                hintText: 'Enter top-up amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Remarks / Comments',
                hintText: 'Reason for top-up',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Get.snackbar(
                  'Error',
                  'Please enter a valid amount',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back(); // Close dialog

              final success = await _subscriptionService.adminTopUpPartialPlan(
                userId: userId,
                entitlementId: entitlementId,
                amount: amount,
                comment: commentController.text,
              );

              if (success) {
                Get.snackbar(
                  'Success',
                  'Top Up Successful',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                fetchUserSubscriptions(userId);
              } else {
                Get.snackbar(
                  'Error',
                  'Top Up Failed',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: Text('Top Up'),
          ),
        ],
      ),
    );
  }

  void showCorrectionDialog(Map<String, dynamic> payment) {
    final paymentIntentId = payment['paymentIntentId'] ?? '';
    if (paymentIntentId.isEmpty) {
      Get.snackbar(
        'Feature Unavailable',
        'Legacy payments without a Payment Intent cannot be corrected via this system.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final currentAmount = (payment['amountPaid'] ?? payment['amount'] ?? 0)
        .toDouble();
    final bool currentIsPartial = payment['isPartial'] == true;
    final String piStatus = payment['paymentIntentStatus'] ?? '';
    final bool isApproved = piStatus == 'PAID' || piStatus == 'APPROVED';

    final amountController = TextEditingController(
      text: currentAmount.toString(),
    );
    final reasonController = TextEditingController();

    var isPartialMode = currentIsPartial.obs;
    var previewResult = Rxn<Map<String, dynamic>>();
    var isPreviewLoading = false.obs;
    String? lastPreviewTimestamp;

    Future<void> fetchPreview() async {
      final amt = double.tryParse(amountController.text);
      if (amt == null) return;

      isPreviewLoading.value = true;
      lastPreviewTimestamp = DateTime.now().toIso8601String();
      final result = await _subscriptionService.adminPreviewCorrection(
        paymentIntentId: paymentIntentId,
        newAmount: amt,
        targetIsPartial: isPartialMode.value,
      );
      previewResult.value = result;
      isPreviewLoading.value = false;
    }

    // Initial preview for approved payments
    if (isApproved) {
      fetchPreview();
    }

    Get.dialog(
      AlertDialog(
        title: Text(
          isApproved ? 'Financial Ledger Correction' : 'Edit Payment Draft',
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isApproved)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber[800],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'CRITICAL: This payment is already approved. Editing it will re-value the user\'s entitlement and overwrite current end dates.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[800],
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This payment is pending. You can edit the amount or toggle partial mode safely before approval.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Text(
                  'Payment Amount (₹)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (isApproved) fetchPreview();
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Obx(
                  () => Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Partial Payment Mode',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isPartialMode.value
                                ? 'Granting reduced validity'
                                : 'Granting full duration',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Switch(
                        value: isPartialMode.value,
                        activeColor: AppTheme.primary,
                        onChanged: (v) {
                          isPartialMode.value = v;
                          if (isApproved) fetchPreview();
                        },
                      ),
                    ],
                  ),
                ),

                if (isApproved) ...[
                  SizedBox(height: 20),
                  Text(
                    'Mathematical Revaluation Preview',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Obx(() {
                    if (isPreviewLoading.value)
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    if (previewResult.value == null)
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Calculate preview by entering valid amount...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );

                    final data = previewResult.value!;
                    final oldExpiry = _formatDate(data['currentExpiry']);
                    final newExpiry = _formatDate(data['newExpiry']);
                    final days = data['newValidityDays'];

                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildPreviewRow(
                            'Current Expiry',
                            oldExpiry,
                            isBold: false,
                          ),
                          SizedBox(height: 8),
                          _buildPreviewRow(
                            'New Expiry',
                            newExpiry,
                            valueColor: Colors.green[700],
                            isBold: true,
                          ),
                          Divider(height: 24),
                          _buildPreviewRow(
                            'Calculated Validity',
                            '$days Days',
                            isBold: true,
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                SizedBox(height: 24),
                Text(
                  isApproved
                      ? 'Reason for Ledger Correction (Audit Log)'
                      : 'Remarks (Internal)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: isApproved
                        ? 'Explain why you are correcting this approved payment...'
                        : 'Add any notes for this update...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),

                if (payment['correctionHistory'] != null &&
                    (payment['correctionHistory'] as List).isNotEmpty) ...[
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.history, size: 16, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text(
                        'Correction Timeline',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Spacer(),
                      Text(
                        'v${payment['correctionVersion'] ?? 0}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildCorrectionTimeline(
                    payment['correctionHistory'] as List,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved
                  ? Colors.orange[800]
                  : AppTheme.primary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final amt = double.tryParse(amountController.text);
              if (amt == null || amt <= 0) {
                Get.snackbar(
                  'Input Error',
                  'Please enter a valid positive amount',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              if (isApproved && reasonController.text.trim().length < 10) {
                Get.snackbar(
                  'Mandatory Field',
                  'Correction reason must be at least 10 characters for audit compliance',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              // Loading indicator
              Get.showOverlay(
                asyncFunction: () async {
                  final success = await _subscriptionService.adminUpdatePayment(
                    paymentIntentId: paymentIntentId,
                    newAmount: amt,
                    targetIsPartial: isPartialMode.value,
                    reason: reasonController.text,
                    previewTimestamp:
                        lastPreviewTimestamp ??
                        DateTime.now().toIso8601String(),
                  );

                  if (success) {
                    Get.back(); // Close dialog
                    Get.snackbar(
                      'Correction Applied',
                      isApproved
                          ? 'Financial record and entitlements successfully re-valued.'
                          : 'Payment draft updated.',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                    fetchUserSubscriptions(currentUserId.value);
                  } else {
                    Get.snackbar(
                      'Error',
                      'Correction failed. Record may have been modified or server error occurred.',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                loadingWidget: Center(child: CircularProgressIndicator()),
              );
            },
            child: Text(
              isApproved ? 'EXECUTE CORRECTION' : 'UPDATE DRAFT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectionTimeline(List history) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (c, i) => Divider(height: 24, thickness: 0.5),
        itemBuilder: (c, i) {
          final item =
              history[history.length - 1 - i]; // Reverse order: Newest first
          final DateTime date =
              DateTime.tryParse(item['correctedAt'] ?? '') ?? DateTime.now();
          final String reason = item['reason'] ?? 'No reason provided';
          final String oldAmt = '₹${item['oldAmount'] ?? 0}';
          final String newAmt = '₹${item['newAmount'] ?? 0}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${history.length - i}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatDate(date.toIso8601String()),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                reason,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    oldAmt,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[300],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Icon(Icons.arrow_right_alt, size: 14, color: Colors.grey),
                  Text(
                    newAmt,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(width: 8),
                  if (item['oldMode'] != item['newMode'])
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['newMode'] == true
                            ? 'FULL ➔ PARTIAL'
                            : 'PARTIAL ➔ FULL',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void onClose() {
    for (var c in startDateControllers.values) {
      c.dispose();
    }
    for (var c in endDateControllers.values) {
      c.dispose();
    }
    super.onClose();
  }

  void showSubscriptionCorrectionDialog(Map<String, dynamic> payment) {
    if (payment['purchaseType'] == 'REGISTRATION') {
      Get.snackbar(
        "Restricted",
        "Registration details cannot be edited.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    String parseId(dynamic id) {
      if (id is Map && id.containsKey('\$oid'))
        return id['\$oid']?.toString() ?? '';
      return id?.toString() ?? '';
    }

    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is DateTime) return date;
      if (date is String) return DateTime.tryParse(date);
      return null;
    }

    final paymentIntentId = parseId(
      payment['paymentIntentId'] ?? payment['_id'],
    );
    final currentSegmentId = parseId(
      payment['segmentId'] is Map
          ? payment['segmentId']['_id']
          : (payment['preferredSegmentId'] ?? payment['segmentId']),
    );
    final currentPlanId = parseId(
      payment['segmentPlanId'] is Map
          ? payment['segmentPlanId']['_id']
          : (payment['planId'] ?? payment['segmentPlanId']),
    );
    final currentStartDate = parseDate(
      payment['startDate'] ?? payment['serviceStartDate'],
    );
    final currentExpiryDate = parseDate(
      payment['endDate'] ??
          payment['expiryDate'] ??
          payment['currentExpiryDate'],
    );
    final currentCorrectionVersion = payment['correctionVersion'] ?? 0;

    final selectedSegmentId = RxString(currentSegmentId);
    final selectedPlanId = RxString(currentPlanId);
    final startDate = Rxn<DateTime>(currentStartDate);
    final expiryDate = Rxn<DateTime>(currentExpiryDate);

    // Initial load
    if (currentSegmentId.isNotEmpty)
      loadCorrectionPlansForSegment(currentSegmentId);

    Future.delayed(Duration(milliseconds: 100), () {
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blue),
              SizedBox(width: 8),
              Text('Correct Subscription Details'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Colors.amber[900],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Changing the plan will reset any existing discounts to ₹0 and recalculate all financial ledgers.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  Text(
                    'Segment',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value:
                          correctionSegments.any(
                            (s) =>
                                parseId(s['_id'] ?? s['id']) ==
                                selectedSegmentId.value,
                          )
                          ? selectedSegmentId.value
                          : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: correctionSegments
                          .map(
                            (s) => DropdownMenuItem(
                              value: parseId(s['_id'] ?? s['id']),
                              child: Text(s['segmentName'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          selectedSegmentId.value = val;
                          selectedPlanId.value = '';
                          loadCorrectionPlansForSegment(val);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 16),

                  Text(
                    'Plan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Obx(
                    () => isFetchingPlans.value
                        ? LinearProgressIndicator()
                        : DropdownButtonFormField<String>(
                            value:
                                plansForSelectedSegment.any(
                                  (p) =>
                                      parseId(p['_id'] ?? p['id']) ==
                                      selectedPlanId.value,
                                )
                                ? selectedPlanId.value
                                : null,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            items: plansForSelectedSegment
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: parseId(p['_id'] ?? p['id']),
                                    child: Text(p['planName'] ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) selectedPlanId.value = val;
                            },
                          ),
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Start Date',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Obx(
                              () => OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  alignment: Alignment.centerLeft,
                                ),
                                icon: Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  startDate.value != null
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(startDate.value!)
                                      : 'Select Date',
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: Get.context!,
                                    initialDate:
                                        startDate.value ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) startDate.value = picked;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Date',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Obx(
                              () => OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 50),
                                  alignment: Alignment.centerLeft,
                                ),
                                icon: Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  expiryDate.value != null
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(expiryDate.value!)
                                      : 'Select Date',
                                ),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: Get.context!,
                                    initialDate:
                                        expiryDate.value ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) expiryDate.value = picked;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (selectedSegmentId.value.isEmpty ||
                    selectedPlanId.value.isEmpty ||
                    startDate.value == null ||
                    expiryDate.value == null) {
                  Get.snackbar(
                    "Required",
                    "All fields must be filled.",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                Get.back(); // Close dialog
                isLoading.value = true;
                try {
                  final success = await _acquisitionService
                      .updateSubscriptionMetadata(
                        paymentIntentId: paymentIntentId,
                        newSegmentId: selectedSegmentId.value,
                        newPlanId: selectedPlanId.value,
                        newStartDate: startDate.value?.toIso8601String(),
                        newExpiryDate: expiryDate.value?.toIso8601String(),
                        clientVersion: currentCorrectionVersion,
                      );
                  if (success) {
                    Get.snackbar(
                      "Success",
                      "Subscription corrected successfully.",
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                    if (currentUserId.value.isNotEmpty)
                      fetchUserSubscriptions(currentUserId.value);
                  } else {
                    Get.snackbar(
                      "Error",
                      "Correction failed. Please check your inputs or try again.",
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                } catch (e) {
                  Get.snackbar(
                    "Error",
                    "Network or server error.",
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                } finally {
                  isLoading.value = false;
                }
              },
              child: Text('Apply Changes'),
            ),
          ],
        ),
      );
    });
  }
}
