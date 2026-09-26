import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:spresearch_web/services/user.service.dart';
import 'package:spresearch_web/services/segment.service.dart';
import 'package:spresearch_web/services/acquisition.service.dart';
import 'package:spresearch_web/services/auth.service.dart';
import 'package:spresearch_web/services/subscription.service.dart';
import '../../models/user.model.dart';
import '../auth/auth.controller.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class QrmpScheduleInfo {
  final String quarterName; // 'Q1', 'Q2', 'Q3', 'Q4'
  final String quarterMonths; // 'Apr - Jun', 'Jul - Sep', 'Oct - Dec', 'Jan - Mar'
  final String financialYear; // 'FY 2026-27'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime gstr1DueDate; // 13th of month following quarter
  final DateTime gstr3bDueDate; // 22nd of month following quarter (MP / Cat 1)
  final String gstr1DueText;
  final String gstr3bDueText;
  final bool isOverdue;
  final int daysLeftGstr1;
  final int daysLeftGstr3b;

  const QrmpScheduleInfo({
    required this.quarterName,
    required this.quarterMonths,
    required this.financialYear,
    required this.startDate,
    required this.endDate,
    required this.gstr1DueDate,
    required this.gstr3bDueDate,
    required this.gstr1DueText,
    required this.gstr3bDueText,
    required this.isOverdue,
    required this.daysLeftGstr1,
    required this.daysLeftGstr3b,
  });
}

class PendingBankTransfersController extends GetxController {
  late final SegmentService _segmentService;
  late final UserService _userService;
  late final AcquisitionService _acquisitionService;
  late final AuthService _authService;
  late final SubscriptionService _subscriptionService;

  var isLoading = false.obs;
  var currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    _segmentService = Get.find<SegmentService>();
    _userService = Get.find<UserService>();
    _acquisitionService = Get.find<AcquisitionService>();
    _authService = Get.find<AuthService>();
    _subscriptionService = Get.find<SubscriptionService>();
    super.onInit();
    _loadUser();
    fetchPendingTransfers();
    fetchPendingKyc();
  }

  UserModel? get effectiveUser {
    if (Get.isRegistered<AuthController>()) {
      final authUser = Get.find<AuthController>().user.value;
      if (authUser != null) return authUser;
    }
    return currentUser.value;
  }

  bool get isDirector => effectiveUser?.isDirector ?? false;
  bool get isAdmin => !isDirector && (effectiveUser?.isAdmin ?? true);
  bool get canTakePaymentActions => isAdmin && !isDirector;

  // Correction Engine Observables
  var segments = <Map<String, dynamic>>[].obs;
  var plansForSelectedSegment = <Map<String, dynamic>>[].obs;
  var isFetchingPlans = false.obs;

  Future<void> loadSegments() async {
    final list = await _segmentService.getSegmentDropdownList();
    segments.assignAll(list);
  }

  Future<void> loadPlansForSegment(String segmentId) async {
    isFetchingPlans.value = true;
    final list = await _segmentService.getPlansBySegment(segmentId);
    plansForSelectedSegment.assignAll(list);
    isFetchingPlans.value = false;
  }

  void showSubscriptionCorrectionDialog(
    Map<String, dynamic> payment, {
    Function(Map<String, dynamic> updatedPayment)? onUpdated,
  }) {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can edit subscription dates or plans.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
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

    final bool isRegistration = payment['purchaseType'] == 'REGISTRATION';
    final isRegMode = RxBool(isRegistration);
    final regPlanChoice = RxString(
      (payment['amount'] == 10000 ||
              payment['baseAmount'] == 10000 ||
              (payment['packageName'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains('gold'))
          ? 'REG_GOLD'
          : 'REG_SILVER',
    );

    final selectedSegmentId = RxString(currentSegmentId);
    final selectedPlanId = RxString(currentPlanId);
    final startDate = Rxn<DateTime>(currentStartDate);
    final expiryDate = Rxn<DateTime>(currentExpiryDate);

    // Initial load
    loadSegments();
    if (currentSegmentId.isNotEmpty) loadPlansForSegment(currentSegmentId);

    Future.delayed(const Duration(milliseconds: 100), () {
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.change_circle_outlined, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Change Plan / Correct Subscription'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(12),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Changing the plan will recalibrate the price, GST, validity, and update user entitlements.",
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
                  const SizedBox(height: 16),

                  // Mode Toggle (Registration vs Segment Plan)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Plan Category',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Obx(
                        () => Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Segment Plan', style: TextStyle(fontSize: 11)),
                              selected: !isRegMode.value,
                              onSelected: (val) {
                                if (val) isRegMode.value = false;
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Registration', style: TextStyle(fontSize: 11)),
                              selected: isRegMode.value,
                              onSelected: (val) {
                                if (val) isRegMode.value = true;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Obx(() {
                    if (isRegMode.value) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registration Plan Tier',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: regPlanChoice.value,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'REG_SILVER',
                                child: Text('Silver Registration (Yearly - 365 Days)'),
                              ),
                              DropdownMenuItem(
                                value: 'REG_GOLD',
                                child: Text('Gold Registration (Lifetime - 10 Years)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                regPlanChoice.value = val;
                                if (startDate.value != null) {
                                  expiryDate.value = startDate.value!.add(
                                    Duration(days: val == 'REG_GOLD' ? 3652 : 365),
                                  );
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Segment Selection
                        const Text(
                          'Segment',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: segments.any(
                            (s) => parseId(s['_id'] ?? s['id']) == selectedSegmentId.value,
                          )
                              ? selectedSegmentId.value
                              : null,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: segments
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
                              loadPlansForSegment(val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Plan Selection
                        const Text(
                          'Plan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        isFetchingPlans.value
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<String>(
                                value: plansForSelectedSegment.any(
                                  (p) => parseId(p['_id'] ?? p['id']) == selectedPlanId.value,
                                )
                                    ? selectedPlanId.value
                                    : null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
                        const SizedBox(height: 16),
                      ],
                    );
                  }),

                  // Date Selectors
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Service Start Date',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  alignment: Alignment.centerLeft,
                                ),
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: Text(
                                  startDate.value != null
                                      ? _formatDate(
                                          startDate.value!.toIso8601String(),
                                        )
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
                                  if (picked != null) {
                                    startDate.value = picked;
                                    if (isRegMode.value) {
                                      expiryDate.value = picked.add(
                                        Duration(
                                          days: regPlanChoice.value == 'REG_GOLD'
                                              ? 3652
                                              : 365,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Expiry Date',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  alignment: Alignment.centerLeft,
                                ),
                                icon: const Icon(Icons.event_busy, size: 16),
                                label: Text(
                                  expiryDate.value != null
                                      ? _formatDate(
                                          expiryDate.value!.toIso8601String(),
                                        )
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

                  // Correction History Timeline
                  if (payment['correctionHistory'] != null &&
                      (payment['correctionHistory'] as List).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Correction History',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCorrectionTimeline(
                      payment['correctionHistory'] as List,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                final String targetSegId =
                    isRegMode.value ? 'REGISTRATION' : selectedSegmentId.value;
                final String targetPlanId =
                    isRegMode.value ? regPlanChoice.value : selectedPlanId.value;

                if (!isRegMode.value &&
                    (selectedSegmentId.value.isEmpty ||
                        selectedPlanId.value.isEmpty)) {
                  Get.snackbar(
                    "Required",
                    "Please select both Segment and Plan.",
                  );
                  return;
                }

                Get.showOverlay(
                  asyncFunction: () async {
                    final success = await _acquisitionService
                        .updateSubscriptionMetadata(
                          paymentIntentId: paymentIntentId,
                          newSegmentId: targetSegId,
                          newPlanId: targetPlanId,
                          newStartDate: startDate.value?.toIso8601String(),
                          newExpiryDate: expiryDate.value?.toIso8601String(),
                          clientVersion: currentCorrectionVersion,
                        );

                    if (success) {
                      Get.back(); // Close dialog
                      Get.snackbar(
                        "Success",
                        "Subscription plan corrected successfully.",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                      fetchPendingTransfers();
                      if (onUpdated != null) {
                        payment['purchaseType'] = isRegMode.value ? 'REGISTRATION' : 'PLAN';
                        if (isRegMode.value) {
                          payment['packageName'] = regPlanChoice.value == 'REG_GOLD'
                              ? 'Gold Registration (Lifetime)'
                              : 'Silver Registration (Yearly)';
                        }
                        payment['serviceStartDate'] = startDate.value?.toIso8601String();
                        payment['currentExpiryDate'] = expiryDate.value?.toIso8601String();
                        onUpdated(payment);
                      }
                    } else {
                      Get.snackbar(
                        "Update Failed",
                        "Error saving changes. Check concurrency or plan availability.",
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  loadingWidget: const Center(child: CircularProgressIndicator()),
                );
              },
              child: const Text(
                'SAVE CORRECTIONS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Correction Engine Observables
  var correctionPreview = {}.obs;
  var isCalculating = false.obs;
  String? lastPreviewTimestamp;
  Timer? _searchDebounce;

  void showCorrectionDialog(
    Map<String, dynamic> payment, {
    Map<String, dynamic>? installment,
    Function(Map<String, dynamic>)? onPaymentUpdated,
  }) {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can perform financial corrections.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    final paymentIntentId = payment['_id'] ?? '';
    final String? historyId = installment?['_id']?.toString();
    final double currentAmount = installment != null
        ? ((installment['amountPaid'] is num)
            ? (installment['amountPaid'] as num).toDouble()
            : (double.tryParse(installment['amountPaid']?.toString() ?? '0') ?? 0))
        : (payment['amountPaid'] ?? payment['amount'] ?? 0).toDouble();

    final bool isApproved = installment != null
        ? (installment['status'] == 'APPROVED')
        : (payment['status'] == 'PAID' ||
            payment['status'] == 'APPROVED' ||
            payment['status'] == 'PARTIAL-PAID');

    // Always reset preview state when opening a new dialog
    correctionPreview.value = {};
    isCalculating.value = false;

    final TextEditingController amountController = TextEditingController(
      text: currentAmount > 0
          ? (currentAmount % 1 == 0
              ? currentAmount.toInt().toString()
              : currentAmount.toString())
          : '',
    );
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController utrController = TextEditingController(
      text: (installment != null
              ? installment['utrNumber']?.toString()
              : payment['utrNumber']?.toString()) ??
          '',
    );
    final originallyPartial = payment['isPartial'] == true;
    final isPartialMode = (installment != null ? true : originallyPartial).obs;
    final selectedFileNames = <String>[].obs;
    List<PlatformFile> selectedFiles = [];

    Future<void> pickNewScreenshots() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        selectedFiles = result.files;
        selectedFileNames.value = result.files.map((f) => f.name).toList();
      }
    }

    Future<void> fetchPreview() async {
      final amt = double.tryParse(amountController.text) ?? currentAmount;
      correctionPreview.value = {}; // clear stale data before fetching
      isCalculating.value = true;
      final result = await _subscriptionService.adminPreviewCorrection(
        paymentIntentId: paymentIntentId,
        newAmount: amt,
        targetIsPartial: isPartialMode.value,
        historyId: historyId,
      );
      if (result != null) {
        correctionPreview.value = Map<String, dynamic>.from(result);
        lastPreviewTimestamp = DateTime.now().toIso8601String();
      }
      isCalculating.value = false;
    }

    if (isApproved) {
      SchedulerBinding.instance.addPostFrameCallback((_) => fetchPreview());
    }

    Get.dialog(
      AlertDialog(
        title: Text(
          isApproved
              ? (installment != null
                  ? 'Correct Installment Ledger'
                  : 'Financial Ledger Correction')
              : (installment != null
                  ? 'Edit Installment Draft'
                  : 'Edit Payment Draft'),
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
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber[900],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            installment != null
                                ? "This installment is already APPROVED. Correcting its amount will re-value the user's entitlements."
                                : "This payment is already APPROVED. Changing the amount will re-value the user's entitlements.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                Text(
                  installment != null
                      ? 'Correct Installment Amount'
                      : 'Correct Payment Amount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                  ),
                  onChanged: (v) {
                    if (isApproved) fetchPreview();
                  },
                ),
                SizedBox(height: 16),

                if (originallyPartial && installment == null) ...[
                  Row(
                    children: [
                      Text(
                        'Partial Payment Mode',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Spacer(),
                      Obx(
                        () => Switch(
                          value: isPartialMode.value,
                          onChanged: (val) {
                            isPartialMode.value = val;
                            if (isApproved) fetchPreview();
                          },
                          activeColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Enable this if the user is paying in installments.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                ],

                Text(
                  installment != null
                      ? 'Update Installment UTR / Ref ID (Optional)'
                      : 'Update UTR / Ref ID (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: utrController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter new UTR...',
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  installment != null
                      ? 'Update Installment Screenshots (Optional)'
                      : 'Update Payment Screenshots (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Obx(
                  () => OutlinedButton.icon(
                    icon: Icon(Icons.upload_file, size: 18),
                    label: Text(
                      selectedFileNames.isEmpty
                          ? "SELECT NEW SCREENSHOTS"
                          : "${selectedFileNames.length} Files Selected",
                    ),
                    onPressed: pickNewScreenshots,
                  ),
                ),

                if (isApproved) ...[
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.assessment_outlined,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Mathematical Revaluation Preview',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Obx(() {
                    if (isCalculating.value)
                      return Center(child: LinearProgressIndicator());
                    if (correctionPreview.isEmpty)
                      return Text(
                        "Enter amount to see preview",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      );

                    final data = correctionPreview;
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          _buildPreviewRow(
                            "Current Expiry",
                            _formatDate(data['currentExpiry']),
                          ),
                          SizedBox(height: 4),
                          _buildPreviewRow(
                            "New Target Expiry",
                            _formatDate(data['newExpiry']),
                            valueColor: Colors.blue[800],
                            isBold: true,
                          ),
                          Divider(height: 16),
                          _buildPreviewRow(
                            "Effective Validity",
                            "${data['newValidityDays']} Days",
                          ),
                          _buildPreviewRow(
                            "Standard Duration",
                            "${data['standardDuration']} Days",
                          ),
                          _buildPreviewRow(
                            "Frozen Daily Rate",
                            "₹${data['dailyRate']?.toStringAsFixed(2)}",
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                SizedBox(height: 24),
                Text(
                  isApproved
                      ? 'Reason for Correction (Required)'
                      : 'Edit Remarks (Optional)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: isApproved
                        ? 'Explain why you are re-valuing this ledger entry...'
                        : 'Notes for this payment...',
                    border: OutlineInputBorder(),
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
                          color: Colors.blue,
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
          TextButton(onPressed: () => Get.back(), child: Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproved ? Colors.orange[800] : Colors.blue,
            ),
            onPressed: () async {
              final amt = double.tryParse(amountController.text);
              if (amt == null) {
                Get.snackbar(
                  'Invalid Amount',
                  'Please enter a valid numeric amount',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              if (isApproved && reasonController.text.length < 10) {
                Get.snackbar(
                  'Reason Required',
                  'Please provide a descriptive reason (min 10 chars) for this correction.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

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
                    utrNumber: utrController.text.isNotEmpty
                        ? utrController.text
                        : null,
                    historyId: historyId,
                    files: selectedFiles.isNotEmpty ? selectedFiles : null,
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
                    if (installment != null) {
                      installment['amountPaid'] = amt;
                      if (utrController.text.isNotEmpty) {
                        installment['utrNumber'] = utrController.text;
                      }
                      if (onPaymentUpdated != null) {
                        onPaymentUpdated(payment);
                      }
                    }
                    fetchPendingTransfers();
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
          final item = history[history.length - 1 - i]; // Newest first
          final DateTime date =
              DateTime.tryParse(item['correctedAt'] ?? '') ?? DateTime.now();
          final String reason = item['reason'] ?? 'No reason provided';

          final String oldAmt =
              '₹${item['oldAmount'] ?? item['oldPrice'] ?? 0}';
          final String newAmt =
              '₹${item['newAmount'] ?? item['newPrice'] ?? 0}';

          // Enhanced Fields
          final String? oldSeg = item['oldSegmentName'];
          final String? newSeg = item['newSegmentName'];
          final String? oldPlan = item['oldPlanName'];
          final String? newPlan = item['newPlanName'];
          final String? oldStart = item['oldStartDate'];
          final String? newStart = item['newStartDate'];
          final String? oldExp = item['oldExpiry'] ?? item['oldExpiryDate'];
          final String? newExp = item['newExpiry'] ?? item['newExpiryDate'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Level ${history.length - i}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(date.toIso8601String()),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                reason,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 10),

              // Segment Change
              _buildHistoryItemRow(
                icon: Icons.category_outlined,
                label: "Segment",
                content: "${oldSeg ?? 'N/A'} ➜ ${newSeg ?? 'N/A'}",
                isChange: (oldSeg != newSeg && newSeg != null),
              ),

              // Plan Change
              _buildHistoryItemRow(
                icon: Icons.assignment_outlined,
                label: "Plan",
                content: "${oldPlan ?? 'N/A'} ➜ ${newPlan ?? 'N/A'}",
                isChange: (oldPlan != newPlan && newPlan != null),
              ),

              // Start Date Change
              if (newStart != null)
                _buildHistoryItemRow(
                  icon: Icons.calendar_today_outlined,
                  label: "Start Date",
                  content:
                      "${_formatDate(oldStart)} ➜ ${_formatDate(newStart)}",
                  isChange: (oldStart != newStart),
                ),

              // Expiry Date Change
              if (newExp != null)
                _buildHistoryItemRow(
                  icon: Icons.event_busy_outlined,
                  label: "Expiry Date",
                  content: "${_formatDate(oldExp)} ➜ ${_formatDate(newExp)}",
                  isChange: (oldExp != newExp),
                ),

              // Amount Change
              _buildHistoryItemRow(
                icon: Icons.payments_outlined,
                label: "Amount",
                content: "$oldAmt ➜ $newAmt",
                isChange: (item['oldAmount'] != item['newAmount']),
                contentColor: Colors.green[700],
              ),

              // Legacy/Mode Badge
              if (item['oldMode'] != item['newMode'] && item['oldMode'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text(
                      item['newMode'] == true
                          ? 'MODE: FULL ➔ PARTIAL'
                          : 'MODE: PARTIAL ➔ FULL',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryItemRow({
    required IconData icon,
    required String label,
    required String content,
    bool isChange = false,
    Color? contentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: content,
                    style: TextStyle(
                      color:
                          contentColor ??
                          (isChange ? Colors.blue[800] : Colors.grey[800]),
                      fontWeight: isChange
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(
        dateStr,
      ).toUtc().add(const Duration(hours: 5, minutes: 30));
      return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  // Bank Transfers
  var viewMode = 'grouped'.obs; // 'grouped' (by user) or 'flat' (by transaction)
  var consolidatedUsers = <Map<String, dynamic>>[].obs;
  var filteredConsolidatedUsers = <Map<String, dynamic>>[].obs;
  var pendingPayments = <Map<String, dynamic>>[].obs;
  var filteredPayments = <Map<String, dynamic>>[].obs;
  var totalPaymentsCount = 0.obs;
  var summaryStats = <String, dynamic>{}.obs;

  // GST & Compliance Observables
  var selectedGstPeriod = 'All Time'.obs; // 'All Time', 'This Month', 'Last Month', 'This Quarter', 'Custom'
  var customGstStartDate = Rxn<DateTime>();
  var customGstEndDate = Rxn<DateTime>();
  var isExportingGst = false.obs;

  var gstGrossTurnover = 0.0.obs;
  var gstTaxableTurnover = 0.0.obs;
  var gstTotalTax = 0.0.obs;
  var gstCgst = 0.0.obs;
  var gstSgst = 0.0.obs;
  var gstIgst = 0.0.obs;
  var gstB2bCount = 0.obs;
  var gstB2cCount = 0.obs;
  var gstB2bAmount = 0.0.obs;
  var gstB2cAmount = 0.0.obs;

  // KYC Approvals
  var pendingKycUsers = <UserModel>[].obs;
  var totalKycCount = 0.obs;

  var currentPage = 1.obs;
  var pageSize = 50.obs;

  // Filters for Pending Payments
  final searchController = TextEditingController();
  var statusFilter = 'All'.obs; // 'All', 'Approved', 'Partial'
  var searchQuery = ''.obs;

  // Filters for Pending KYC
  final kycSearchController = TextEditingController();
  var kycStatusFilter = 'All'
      .obs; // 'All', 'Verified', 'Rejected', 'Waiting_for_review', 'In_progress', 'Not_started'
  var kycSearchQuery = ''.obs;
  var filteredKycUsers = <UserModel>[].obs;

  Future<void> _loadUser() async {
    currentUser.value = await _authService.getUser();
  }

  var hasMorePages = true.obs;

  void setViewMode(String mode) {
    if (viewMode.value == mode) return;
    viewMode.value = mode;
    fetchPendingTransfers();
  }

  void _buildClientSideConsolidatedUsers() {
    final Map<String, Map<String, dynamic>> userGroups = {};
    for (final p in pendingPayments) {
      final user = p['userId'];
      final uid = (user is Map)
          ? (user['_id']?.toString() ?? 'unknown')
          : (user?.toString() ?? 'unknown');
      if (!userGroups.containsKey(uid)) {
        userGroups[uid] = {
          'user': user is Map
              ? user
              : {'fullName': 'Unknown', 'phone': '-', 'email': '-'},
          'payments': <Map<String, dynamic>>[],
          'totalPaid': 0.0,
          'totalAmount': 0.0,
          'remainingBalance': 0.0,
          'pendingCount': 0,
          'hasPending': false,
          'activePlansCount': 0,
          'latestActivity': p['createdAt'],
        };
      }
      final group = userGroups[uid]!;
      (group['payments'] as List<Map<String, dynamic>>).add(p);
      final amtPaid = (p['amountPaid'] is num)
          ? (p['amountPaid'] as num).toDouble()
          : (double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0);
      final amtTarget = (p['amount'] is num)
          ? (p['amount'] as num).toDouble()
          : (double.tryParse(p['amount']?.toString() ?? '0') ?? 0);
      final discount = (p['discount'] is num)
          ? (p['discount'] as num).toDouble()
          : (double.tryParse(p['discount']?.toString() ?? '0') ?? 0);
      final rem = (amtTarget - discount - amtPaid) > 0
          ? (amtTarget - discount - amtPaid)
          : 0.0;
      group['totalPaid'] = (group['totalPaid'] as double) + amtPaid;
      group['totalAmount'] = (group['totalAmount'] as double) + amtTarget;
      group['remainingBalance'] = (group['remainingBalance'] as double) + rem;

      final isPending = p['status'] == 'PENDING' ||
          p['status'] == 'PENDING_BANK_TRANSFER' ||
          p['status'] == 'VERIFICATION_PENDING';
      final history = p['partialPaymentsHistory'] as List? ?? [];
      final hasPendingInst = history.any((h) => h['status'] == 'PENDING');
      if (isPending || hasPendingInst) {
        group['pendingCount'] = (group['pendingCount'] as int) + 1;
        group['hasPending'] = true;
      }
      if (p['status'] == 'PAID' ||
          p['status'] == 'APPROVED' ||
          p['status'] == 'PARTIAL-PAID') {
        group['activePlansCount'] = (group['activePlansCount'] as int) + 1;
      }
    }
    consolidatedUsers.assignAll(userGroups.values.toList());
  }

  Future<void> fetchPendingTransfers({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        if (!hasMorePages.value) return;
        currentPage.value++;
      } else {
        currentPage.value = 1;
        isLoading.value = true;
      }

      // Add timestamp to prevent caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      debugPrint('[PendingTransfers] Fetching with timestamp: $timestamp');

      final (startDateStr, endDateStr) = getActiveDateRange();

      final result = await _segmentService.getPendingBankTransfers(
        page: currentPage.value,
        pageSize: pageSize.value,
        search: searchQuery.value,
        status: statusFilter.value,
        groupBy: viewMode.value == 'grouped' ? 'user' : null,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      final newPayments = List<Map<String, dynamic>>.from(
        result['pendingPayments'] ?? [],
      );

      debugPrint('[PendingTransfers] Received ${newPayments.length} payments');
      debugPrint('[PendingTransfers] Total count: ${result['totalCount']}');

      if (isLoadMore) {
        pendingPayments.addAll(newPayments);
      } else {
        pendingPayments.assignAll(newPayments);
      }

      final rawUsers = result['users'];
      if (rawUsers != null && (rawUsers as List).isNotEmpty) {
        final newUsers = List<Map<String, dynamic>>.from(rawUsers);
        if (isLoadMore) {
          consolidatedUsers.addAll(newUsers);
        } else {
          consolidatedUsers.assignAll(newUsers);
        }
      } else {
        _buildClientSideConsolidatedUsers();
      }

      totalPaymentsCount.value = result['totalCount'] ?? 0;
      if (result['summaryStats'] != null && result['summaryStats'] is Map) {
        final stats = Map<String, dynamic>.from(result['summaryStats']);
        summaryStats.assignAll(stats);
      } else {
        summaryStats.assignAll({
          'totalCustomers': totalPaymentsCount.value,
          'totalVolume': 0.0,
          'grossTurnover': 0.0,
          'taxableTurnover': 0.0,
          'totalTax': 0.0,
          'cgst': 0.0,
          'sgst': 0.0,
          'igst': 0.0,
          'b2bCount': 0,
          'b2cCount': 0,
          'b2bAmount': 0.0,
          'b2cAmount': 0.0,
          'actionRequiredCustomers': 0,
          'totalPayments': totalPaymentsCount.value,
          'pendingPaymentsCount': 0,
        });
      }
      final currentListLength = viewMode.value == 'grouped'
          ? consolidatedUsers.length
          : pendingPayments.length;
      hasMorePages.value = currentListLength < totalPaymentsCount.value;

      applyFilters();
      _calculateGstMetrics();

      debugPrint(
        '[PendingTransfers] Updated observables with ${pendingPayments.length} payments and ${consolidatedUsers.length} users, Gross Turnover: ${gstGrossTurnover.value}',
      );
    } catch (e) {
      debugPrint('[PendingTransfers] Error: $e');
      if (isLoadMore) currentPage.value--; // Revert page increment on error
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> fetchUserPaymentDossier(
    String userId, [
    UserModel? fallbackUser,
  ]) async {
    try {
      final result = await _segmentService.getPendingBankTransfers(
        groupBy: 'user',
        userId: userId,
        pageSize: 100,
      );
      final rawUsers = result['users'];
      if (rawUsers != null && (rawUsers as List).isNotEmpty) {
        final group = Map<String, dynamic>.from(rawUsers.first);
        if (group['user'] == null && fallbackUser != null) {
          group['user'] = {
            '_id': fallbackUser.id,
            'fullName': fallbackUser.fullName,
            'phone': fallbackUser.mobile,
            'email': fallbackUser.email,
            'kycStatus': fallbackUser.kycStatus,
            'registrationType': fallbackUser.subscriptionPlan,
          };
        }
        return group;
      }
    } catch (e) {
      debugPrint('Error fetching user payment dossier: $e');
    }
    return {
      'user': {
        '_id': fallbackUser?.id ?? userId,
        'fullName': fallbackUser?.fullName ?? 'Client',
        'phone': fallbackUser?.mobile ?? '-',
        'email': fallbackUser?.email ?? '-',
        'kycStatus': fallbackUser?.kycStatus ?? 'PENDING',
        'registrationType': fallbackUser?.subscriptionPlan ?? '',
      },
      'payments': <Map<String, dynamic>>[],
      'totalPaid': 0.0,
      'totalAmount': 0.0,
      'remainingBalance': 0.0,
      'pendingCount': 0,
      'hasPending': false,
      'activePlansCount': 0,
    };
  }

  Future<void> fetchPendingKyc() async {
    try {
      // Fetch users with any KYC status
      final result = await _userService.getUsers(
        page: 1,
        pageSize: 100, // Fetch more for approval queue
      );
      pendingKycUsers.assignAll(result.users);
      totalKycCount.value = result.totalCount;

      applyKycFilters();
    } catch (e) {
      debugPrint("Error fetching pending KYC: $e");
    }
  }

  Future<void> approveTransfer(
    Map<String, dynamic> payment, {
    String? remark,
    double? discount,
  }) async {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can approve payments.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    final userId = payment['userId']['_id'];
    final segmentPlanIdData = payment['segmentPlanId'];

    // Handle both REGISTRATION (string) and PLAN (object) types
    String segmentPlanId;
    if (segmentPlanIdData is String) {
      // Registration payment - use the string directly
      segmentPlanId = segmentPlanIdData;
    } else if (segmentPlanIdData is Map) {
      // Plan payment - extract _id from object
      segmentPlanId = segmentPlanIdData['_id'];
    } else {
      Get.snackbar(
        "Error",
        "Invalid payment data",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final amount = (payment['amount'] is num)
        ? (payment['amount'] as num).toDouble()
        : (double.tryParse(payment['amount']?.toString() ?? '0') ?? 0);
    final paymentRefId = payment['razorpayOrderId'] ?? 'MANUAL_APPROVE';

    final success = await _segmentService.adminGrantSegment(
      userId: userId,
      segmentPlanId: segmentPlanId,
      paymentRefId: paymentRefId,
      amount: amount,
      remark: remark,
      discount: discount,
    );

    if (success) {
      Get.snackbar(
        "Success",
        "Plan activated successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchPendingTransfers();
    } else {
      Get.snackbar(
        "Error",
        "Failed to activate plan",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectTransfer(Map<String, dynamic> payment) async {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can reject payments.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    final paymentId = payment['_id'];
    final success = await _segmentService.rejectBankTransfer(paymentId);
    if (success) {
      Get.snackbar(
        "Rejected",
        "Request rejected successfully",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      fetchPendingTransfers();
    } else {
      Get.snackbar(
        "Error",
        "Failed to reject request",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool> approvePartialInstallment(
    String intentId,
    String historyId, {
    String? remark,
    double? discount,
  }) async {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can approve installments.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _acquisitionService.approvePartialPayment(
        paymentIntentId: intentId,
        historyId: historyId,
        remark: remark,
        discount: discount,
      );
      if (success) {
        Get.snackbar(
          "Success",
          "Installment approved",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchPendingTransfers();
        return true;
      } else {
        Get.snackbar(
          "Error",
          "Failed to approve installment",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDiscount(String intentId, double discount) async {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can modify discounts.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _acquisitionService.updatePaymentDiscount(
        paymentIntentId: intentId,
        discount: discount,
      );
      if (success) {
        Get.snackbar(
          "Success",
          "Discount updated",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchPendingTransfers();
        return true;
      } else {
        Get.snackbar(
          "Error",
          "Failed to update discount",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void showDiscountDialog(
    Map<String, dynamic> payment, {
    Function(Map<String, dynamic> updatedPayment)? onUpdated,
  }) {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can apply discounts.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return;
    }

    final String paymentIntentId =
        (payment['_id'] ?? payment['paymentIntentId'] ?? '').toString();
    if (paymentIntentId.isEmpty) {
      Get.snackbar(
        "Error",
        "Invalid payment intent ID",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final double planAmount = (payment['amount'] is num)
        ? (payment['amount'] as num).toDouble()
        : (payment['totalPlanAmount'] is num)
            ? (payment['totalPlanAmount'] as num).toDouble()
            : (double.tryParse(
                    payment['amount']?.toString() ??
                        payment['totalPlanAmount']?.toString() ??
                        '0') ??
                0);

    final double currentDiscount = (payment['discount'] is num)
        ? (payment['discount'] as num).toDouble()
        : (double.tryParse(payment['discount']?.toString() ?? '0') ?? 0);

    final double amountPaid = (payment['amountPaid'] is num)
        ? (payment['amountPaid'] as num).toDouble()
        : (double.tryParse(payment['amountPaid']?.toString() ?? '0') ?? 0);

    final TextEditingController discountInputController =
        TextEditingController(
      text: currentDiscount > 0 ? currentDiscount.toStringAsFixed(0) : '',
    );
    discountInputController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: discountInputController.text.length,
    );

    final isSubmitting = false.obs;
    final previewDiscount = RxDouble(currentDiscount);
    final errorText = RxString('');

    void calculatePreview(String val) {
      errorText.value = '';
      final clean = val.trim();
      if (clean.isEmpty) {
        previewDiscount.value = 0;
        return;
      }
      final parsed = double.tryParse(clean);
      if (parsed == null) {
        errorText.value = 'Please enter a valid numeric value';
        return;
      }
      if (planAmount > 0 && parsed > planAmount) {
        errorText.value =
            'Discount cannot exceed original plan price (₹${planAmount.toStringAsFixed(0)})';
      }
      previewDiscount.value = parsed;
    }

    Future<void> submitDiscount() async {
      final clean = discountInputController.text.trim();
      final double newDiscount =
          clean.isEmpty ? 0 : (double.tryParse(clean) ?? -1);
      if (newDiscount < 0) {
        errorText.value = 'Please enter a valid positive discount';
        return;
      }
      if (planAmount > 0 && newDiscount > planAmount) {
        errorText.value =
            'Discount cannot exceed original plan price (₹${planAmount.toStringAsFixed(0)})';
        return;
      }

      isSubmitting.value = true;
      try {
        final success = await updateDiscount(paymentIntentId, newDiscount);
        if (success) {
          final updatedPayment = Map<String, dynamic>.from(payment);
          updatedPayment['discount'] = newDiscount;
          final double newTarget =
              planAmount > 0 ? (planAmount - newDiscount) : 0;
          updatedPayment['remainingAmount'] =
              (newTarget - amountPaid) > 0 ? (newTarget - amountPaid) : 0;
          if (amountPaid >= (newTarget - 1) && newTarget > 0) {
            updatedPayment['status'] = 'PAID';
          }
          if (onUpdated != null) {
            onUpdated(updatedPayment);
          }
          Get.back(); // close dialog
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.discount_outlined,
                            color: Colors.teal, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Plan Discount",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Original Plan Price",
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF64748B))),
                        Text(
                          "₹${planAmount.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Amount Paid",
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF64748B))),
                        Text(
                          "₹${amountPaid.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green),
                        ),
                      ],
                    ),
                    if (currentDiscount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Current Discount",
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF64748B))),
                          Text(
                            "₹${currentDiscount.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Discount Amount (₹)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: discountInputController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  prefixText: "₹ ",
                  hintText: "Enter total discount (e.g. 5000)",
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: calculatePreview,
                onSubmitted: (_) => submitDiscount(),
              ),
              Obx(() {
                if (errorText.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      errorText.value,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 16),
              // Live calculation preview
              Obx(() {
                final d = previewDiscount.value;
                final newTarget = planAmount > 0
                    ? ((planAmount - d) > 0 ? (planAmount - d) : 0)
                    : 0;
                final newBal =
                    (newTarget - amountPaid) > 0 ? (newTarget - amountPaid) : 0;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text("New Target",
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 3),
                          Text(
                            "₹${newTarget.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: Colors.teal.withOpacity(0.2),
                      ),
                      Column(
                        children: [
                          const Text("Remaining Due",
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 3),
                          Text(
                            newBal > 0
                                ? "₹${newBal.toStringAsFixed(0)}"
                                : "₹0 (Cleared)",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color:
                                  newBal > 0 ? Colors.orange[800] : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 12),
                  Obx(
                    () => ElevatedButton.icon(
                      icon: isSubmitting.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        isSubmitting.value ? "Applying..." : "Apply Discount",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: isSubmitting.value ? null : submitDiscount,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> rejectPartialInstallment(
    String paymentId,
    String historyId,
  ) async {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can reject installments.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _acquisitionService.rejectPartialPayment(
        paymentIntentId: paymentId,
        historyId: historyId,
      );
      if (success) {
        Get.snackbar(
          "Rejected",
          "Installment rejected",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        await fetchPendingTransfers();
        return true;
      } else {
        Get.snackbar(
          "Error",
          "Failed to reject installment",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> revertApprovalAction(
    String paymentId, {
    String? reason,
    String? historyId,
  }) async {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can revert approvals.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _segmentService.revertToRejected(
        paymentId,
        reason: reason,
        historyId: historyId,
      );
      if (success) {
        Get.snackbar(
          "Success",
          "Approval reverted to Rejected",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        await fetchPendingTransfers();
        return true;
      } else {
        Get.snackbar(
          "Error",
          "Failed to revert approval",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> revertRejectionAction(
    String paymentId, {
    String? historyId,
    String? reason,
  }) async {
    if (!canTakePaymentActions) {
      Get.snackbar(
        "Permission Denied",
        "Only administrators can restore rejections.",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _segmentService.revertToApproved(
        paymentId,
        historyId: historyId,
        reason: reason,
      );
      if (success) {
        Get.snackbar(
          "Success",
          "Rejection reverted to Approved",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchPendingTransfers();
        return true;
      } else {
        Get.snackbar(
          "Error",
          "Failed to revert rejection",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveKyc(String userId) async {
    final success = await _userService.updateUser(userId, {
      'kycStatus': 'VERIFIED',
    });
    if (success) {
      Get.snackbar(
        "Success",
        "KYC Approved",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      fetchPendingKyc();
    } else {
      Get.snackbar(
        "Error",
        "Failed to approve KYC",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> rejectKyc(String userId) async {
    final success = await _userService.updateUser(userId, {
      'kycStatus': 'REJECTED',
    });
    if (success) {
      Get.snackbar(
        "Rejected",
        "KYC Rejected",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      fetchPendingKyc();
    } else {
      Get.snackbar(
        "Error",
        "Failed to reject KYC",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void applyFilters() {
    filteredPayments.assignAll(pendingPayments.toList());
    if (consolidatedUsers.isEmpty && pendingPayments.isNotEmpty) {
      _buildClientSideConsolidatedUsers();
    }
    filteredConsolidatedUsers.assignAll(consolidatedUsers.toList());
  }

  void resetFilters() {
    statusFilter.value = 'All';
    searchQuery.value = '';
    searchController.clear();
    fetchPendingTransfers();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;

    // Cancel existing timer
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    // Debounce for 500ms
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchPendingTransfers();
    });
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  void applyKycFilters() {
    var filtered = pendingKycUsers.toList();

    // Apply status filter
    if (kycStatusFilter.value != 'All') {
      filtered = filtered.where((user) {
        final status = user.kycStatus.toUpperCase();

        switch (kycStatusFilter.value) {
          case 'Verified':
            return status == 'VERIFIED' || status == 'APPROVED';
          case 'Rejected':
            return status == 'REJECTED';
          case 'Waiting_for_review':
            return status == 'WAITING_FOR_REVIEW';
          case 'In_progress':
            return status == 'IN_PROGRESS';
          case 'Not_started':
            return status == 'NOT_STARTED' || status == 'PENDING';
          default:
            return false;
        }
      }).toList();
    }

    // Apply search filter
    if (kycSearchQuery.value.isNotEmpty) {
      final query = kycSearchQuery.value.toLowerCase();
      filtered = filtered.where((user) {
        final userName = (user.fullName).toLowerCase();
        final phone = (user.formattedPhone).toLowerCase();

        return userName.contains(query) || phone.contains(query);
      }).toList();
    }

    filteredKycUsers.assignAll(filtered);
  }

  void resetKycFilters() {
    kycStatusFilter.value = 'All';
    kycSearchQuery.value = '';
    kycSearchController.clear();
    applyKycFilters();
  }

  static int getCurrentFyStartYear() {
    final now = DateTime.now();
    return (now.month >= 4) ? now.year : (now.year - 1);
  }

  static int getCurrentQrmpQuarterNumber() {
    final now = DateTime.now();
    if (now.month >= 4 && now.month <= 6) return 1;
    if (now.month >= 7 && now.month <= 9) return 2;
    if (now.month >= 10 && now.month <= 12) return 3;
    return 4;
  }

  static QrmpScheduleInfo getQrmpQuarter(int qNumber, int fyStartYear) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fyString = 'FY $fyStartYear-${(fyStartYear + 1) % 100}';

    DateTime start;
    DateTime end;
    DateTime gstr1Due;
    DateTime gstr3bDue;
    String months;

    switch (qNumber) {
      case 1:
        months = 'Apr - Jun';
        start = DateTime(fyStartYear, 4, 1, 0, 0, 0);
        end = DateTime(fyStartYear, 6, 30, 23, 59, 59, 999);
        gstr1Due = DateTime(fyStartYear, 7, 13);
        gstr3bDue = DateTime(fyStartYear, 7, 22);
        break;
      case 2:
        months = 'Jul - Sep';
        start = DateTime(fyStartYear, 7, 1, 0, 0, 0);
        end = DateTime(fyStartYear, 9, 30, 23, 59, 59, 999);
        gstr1Due = DateTime(fyStartYear, 10, 13);
        gstr3bDue = DateTime(fyStartYear, 10, 22);
        break;
      case 3:
        months = 'Oct - Dec';
        start = DateTime(fyStartYear, 10, 1, 0, 0, 0);
        end = DateTime(fyStartYear, 12, 31, 23, 59, 59, 999);
        gstr1Due = DateTime(fyStartYear + 1, 1, 13);
        gstr3bDue = DateTime(fyStartYear + 1, 1, 22);
        break;
      case 4:
      default:
        months = 'Jan - Mar';
        start = DateTime(fyStartYear + 1, 1, 1, 0, 0, 0);
        end = DateTime(fyStartYear + 1, 3, 31, 23, 59, 59, 999);
        gstr1Due = DateTime(fyStartYear + 1, 4, 13);
        gstr3bDue = DateTime(fyStartYear + 1, 4, 22);
        break;
    }

    final daysLeft1 = gstr1Due.difference(today).inDays;
    final daysLeft3b = gstr3bDue.difference(today).inDays;
    final isOverdue = daysLeft3b < 0;

    return QrmpScheduleInfo(
      quarterName: 'Q$qNumber',
      quarterMonths: months,
      financialYear: fyString,
      startDate: start,
      endDate: end,
      gstr1DueDate: gstr1Due,
      gstr3bDueDate: gstr3bDue,
      gstr1DueText: DateFormat('dd MMM yyyy').format(gstr1Due),
      gstr3bDueText: DateFormat('dd MMM yyyy').format(gstr3bDue),
      isOverdue: isOverdue,
      daysLeftGstr1: daysLeft1,
      daysLeftGstr3b: daysLeft3b,
    );
  }

  QrmpScheduleInfo get currentQrmpInfo {
    final fy = getCurrentFyStartYear();
    final q = getCurrentQrmpQuarterNumber();
    return getQrmpQuarter(q, fy);
  }

  QrmpScheduleInfo get lastQrmpInfo {
    final fy = getCurrentFyStartYear();
    final q = getCurrentQrmpQuarterNumber();
    if (q == 1) {
      return getQrmpQuarter(4, fy - 1);
    } else {
      return getQrmpQuarter(q - 1, fy);
    }
  }

  QrmpScheduleInfo get activeQrmpSchedule {
    final period = selectedGstPeriod.value;
    final fy = getCurrentFyStartYear();
    if (period == 'This Quarter' || period == 'This Quarter (QRMP)') {
      return currentQrmpInfo;
    }
    if (period == 'Last Quarter' || period == 'Last Quarter (QRMP)') {
      return lastQrmpInfo;
    }
    if (period.startsWith('Q1')) {
      return getQrmpQuarter(1, fy);
    }
    if (period.startsWith('Q2')) {
      return getQrmpQuarter(2, fy);
    }
    if (period.startsWith('Q3')) {
      return getQrmpQuarter(3, fy);
    }
    if (period.startsWith('Q4')) {
      return getQrmpQuarter(4, fy);
    }
    return currentQrmpInfo;
  }

  (String?, String?) getActiveDateRange() {
    final now = DateTime.now();
    final fy = getCurrentFyStartYear();

    switch (selectedGstPeriod.value) {
      case 'This Month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        return (start.toIso8601String(), end.toIso8601String());

      case 'Last Month':
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0, 23, 59, 59, 999);
        return (start.toIso8601String(), end.toIso8601String());

      case 'This Quarter':
      case 'This Quarter (QRMP)':
        final info = currentQrmpInfo;
        return (info.startDate.toIso8601String(), info.endDate.toIso8601String());

      case 'Last Quarter':
      case 'Last Quarter (QRMP)':
        final info = lastQrmpInfo;
        return (info.startDate.toIso8601String(), info.endDate.toIso8601String());

      case 'Q1: Apr - Jun (Due 13 Jul)':
      case 'Q1: Apr - Jun':
      case 'Q1 (Apr - Jun)':
        final info = getQrmpQuarter(1, fy);
        return (info.startDate.toIso8601String(), info.endDate.toIso8601String());

      case 'Q2: Jul - Sep (Due 13 Oct)':
      case 'Q2: Jul - Sep':
      case 'Q2 (Jul - Sep)':
        final info = getQrmpQuarter(2, fy);
        return (info.startDate.toIso8601String(), info.endDate.toIso8601String());

      case 'Q3: Oct - Dec (Due 13 Jan)':
      case 'Q3: Oct - Dec':
      case 'Q3 (Oct - Dec)':
        final info = getQrmpQuarter(3, fy);
        return (info.startDate.toIso8601String(), info.endDate.toIso8601String());

      case 'Q4: Jan - Mar (Due 13 Apr)':
      case 'Q4: Jan - Mar':
      case 'Q4 (Jan - Mar)':
        final info = getQrmpQuarter(4, fy);
        return (info.startDate.toIso8601String(), info.endDate.toIso8601String());

      case 'Custom':
        final start = customGstStartDate.value;
        final end = customGstEndDate.value;
        return (start?.toIso8601String(), end?.toIso8601String());

      case 'All Time':
      default:
        return (null, null);
    }
  }

  void setGstPeriod(String period, {DateTime? start, DateTime? end}) {
    selectedGstPeriod.value = period;
    if (period == 'Custom') {
      customGstStartDate.value = start;
      customGstEndDate.value = end;
    }
    fetchPendingTransfers();
  }

  static const Map<String, ({String name, String panCode})> gstMasterStateMap = {
    '01': (name: 'Jammu and Kashmir', panCode: 'JK'),
    '02': (name: 'Himachal Pradesh', panCode: 'HP'),
    '03': (name: 'Punjab', panCode: 'PB'),
    '04': (name: 'Chandigarh', panCode: 'CH'),
    '05': (name: 'Uttarakhand', panCode: 'UA'),
    '06': (name: 'Haryana', panCode: 'HR'),
    '07': (name: 'Delhi', panCode: 'DL'),
    '08': (name: 'Rajasthan', panCode: 'RJ'),
    '09': (name: 'Uttar Pradesh', panCode: 'UP'),
    '10': (name: 'Bihar', panCode: 'BR'),
    '11': (name: 'Sikkim', panCode: 'SK'),
    '12': (name: 'Arunachal Pradesh', panCode: 'AR'),
    '13': (name: 'Nagaland', panCode: 'NL'),
    '14': (name: 'Manipur', panCode: 'MN'),
    '15': (name: 'Mizoram', panCode: 'MZ'),
    '16': (name: 'Tripura', panCode: 'TR'),
    '17': (name: 'Meghalaya', panCode: 'ML'),
    '18': (name: 'Assam', panCode: 'AS'),
    '19': (name: 'West Bengal', panCode: 'WB'),
    '20': (name: 'Jharkhand', panCode: 'JH'),
    '21': (name: 'Odisha', panCode: 'OR'),
    '22': (name: 'Chhattisgarh', panCode: 'CT'),
    '23': (name: 'Madhya Pradesh', panCode: 'MP'),
    '24': (name: 'Gujarat', panCode: 'GJ'),
    '25': (name: 'Dadra and Nagar Haveli and Daman and Diu', panCode: 'DD'),
    '26': (name: 'Dadra and Nagar Haveli and Daman and Diu', panCode: 'DD'),
    '27': (name: 'Maharashtra', panCode: 'MH'),
    '28': (name: 'Andhra Pradesh', panCode: 'AP'),
    '29': (name: 'Karnataka', panCode: 'KA'),
    '30': (name: 'Goa', panCode: 'GA'),
    '31': (name: 'Lakshadweep', panCode: 'LD'),
    '32': (name: 'Kerala', panCode: 'KL'),
    '33': (name: 'Tamil Nadu', panCode: 'TN'),
    '34': (name: 'Puducherry', panCode: 'PY'),
    '35': (name: 'Andaman and Nicobar Islands', panCode: 'AN'),
    '36': (name: 'Telangana', panCode: 'TS'),
    '37': (name: 'Andhra Pradesh', panCode: 'AP'),
    '38': (name: 'Ladakh', panCode: 'LA'),
    '97': (name: 'Other Territory', panCode: 'OT'),
  };

  static ({String name, String code, String panCode, bool isIntraState}) resolveStateInfo(
    Map<dynamic, dynamic> user, {
    String? fallbackGstin,
  }) {
    // Support either user map directly or userGroup map containing 'user'
    final targetUser = (user['user'] is Map) ? user['user'] as Map : user;

    // 1. Check GSTIN first (if B2B, first 2 digits are GST state code)
    final String gstin = (targetUser['gstin'] ?? fallbackGstin ?? '').toString().trim().toUpperCase();
    if (gstin.length >= 2) {
      final code = gstin.substring(0, 2);
      final effectiveCode = (code == '25') ? '26' : (code == '28' ? '37' : code);
      final entry = gstMasterStateMap[effectiveCode];
      if (entry != null) {
        return (
          name: entry.name,
          code: effectiveCode,
          panCode: entry.panCode,
          isIntraState: effectiveCode == '23',
        );
      }
    }

    // 2. Check userObject (APP_COR_STATE, APP_PER_STATE, or state)
    final userObj = targetUser['userObject'] is Map ? targetUser['userObject'] as Map : {};
    final rawVal = userObj['APP_COR_STATE'] ??
        userObj['APP_PER_STATE'] ??
        userObj['state'] ??
        targetUser['state'] ??
        targetUser['address']?['state'];

    if (rawVal != null) {
      final s = rawVal.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null' && s.toLowerCase() != 'undefined') {
        // If string starts with digits (e.g. '003', '03', '3', '011 Sikkim', '027', '028')
        final digitMatch = RegExp(r'^\d+').firstMatch(s);
        if (digitMatch != null) {
          final intVal = int.tryParse(digitMatch.group(0)!);
          if (intVal != null) {
            final codePadded = intVal.toString().padLeft(2, '0');
            final effectiveCode = (codePadded == '25') ? '26' : (codePadded == '28' ? '37' : codePadded);
            final entry = gstMasterStateMap[effectiveCode];
            if (entry != null) {
              return (
                name: entry.name,
                code: effectiveCode,
                panCode: entry.panCode,
                isIntraState: effectiveCode == '23',
              );
            }
          }
        }

        // Match by state name or panCode
        final sLower = s.toLowerCase();
        for (final entry in gstMasterStateMap.entries) {
          final sNameLower = entry.value.name.toLowerCase();
          final panLower = entry.value.panCode.toLowerCase();
          if (sLower == sNameLower ||
              sLower == panLower ||
              (sLower.length >= 3 && sNameLower.contains(sLower)) ||
              (sNameLower.length >= 3 && sLower.contains(sNameLower))) {
            final effectiveCode = (entry.key == '25') ? '26' : (entry.key == '28' ? '37' : entry.key);
            return (
              name: entry.value.name,
              code: effectiveCode,
              panCode: entry.value.panCode,
              isIntraState: effectiveCode == '23',
            );
          }
        }

        // Check common aliases
        if (sLower == 'other' || sLower.contains('other territory')) {
          final entry = gstMasterStateMap['97']!;
          return (
            name: entry.name,
            code: '97',
            panCode: entry.panCode,
            isIntraState: false,
          );
        }
        if (sLower.contains('orissa')) {
          final entry = gstMasterStateMap['21']!;
          return (name: entry.name, code: '21', panCode: entry.panCode, isIntraState: false);
        }
        if (sLower.contains('uttaranchal')) {
          final entry = gstMasterStateMap['05']!;
          return (name: entry.name, code: '05', panCode: entry.panCode, isIntraState: false);
        }
        if (sLower.contains('pondicherry')) {
          final entry = gstMasterStateMap['34']!;
          return (name: entry.name, code: '34', panCode: entry.panCode, isIntraState: false);
        }

        final isMp = sLower.contains('madhya') || sLower == 'mp';
        return (
          name: s,
          code: isMp ? '23' : '--',
          panCode: isMp ? 'MP' : '--',
          isIntraState: isMp,
        );
      }
    }

    return (name: 'Unspecified', code: '--', panCode: '--', isIntraState: false);
  }

  void _calculateGstMetrics() {
    // If backend provided authoritative unpaginated GST metrics, prioritize them
    if (summaryStats.containsKey('grossTurnover') && summaryStats['grossTurnover'] != null) {
      gstGrossTurnover.value = (summaryStats['grossTurnover'] as num?)?.toDouble() ?? 0.0;
      gstTaxableTurnover.value = (summaryStats['taxableTurnover'] as num?)?.toDouble() ?? 0.0;
      gstTotalTax.value = (summaryStats['totalTax'] as num?)?.toDouble() ?? 0.0;
      gstCgst.value = (summaryStats['cgst'] as num?)?.toDouble() ?? 0.0;
      gstSgst.value = (summaryStats['sgst'] as num?)?.toDouble() ?? 0.0;
      gstIgst.value = (summaryStats['igst'] as num?)?.toDouble() ?? 0.0;
      gstB2bCount.value = (summaryStats['b2bCount'] as num?)?.toInt() ?? 0;
      gstB2cCount.value = (summaryStats['b2cCount'] as num?)?.toInt() ?? 0;
      gstB2bAmount.value = (summaryStats['b2bAmount'] as num?)?.toDouble() ?? 0.0;
      gstB2cAmount.value = (summaryStats['b2cAmount'] as num?)?.toDouble() ?? 0.0;
      return;
    }

    double gross = 0.0;
    double taxable = 0.0;
    double totalTax = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;
    int b2b = 0;
    int b2c = 0;
    double b2bAmt = 0.0;
    double b2cAmt = 0.0;

    final allRealizedPayments = <Map<String, dynamic>>[];
    for (var uGroup in consolidatedUsers) {
      final payments = uGroup['payments'] as List? ?? [];
      final user = uGroup['user'] is Map ? uGroup['user'] as Map<String, dynamic> : <String, dynamic>{};
      for (var p in payments) {
        if (p is Map) {
          final pMap = Map<String, dynamic>.from(p);
          pMap['user'] = user;
          allRealizedPayments.add(pMap);
        }
      }
    }

    if (allRealizedPayments.isEmpty) {
      for (var p in pendingPayments) {
        allRealizedPayments.add(p);
      }
    }

    final (startDateStr, endDateStr) = getActiveDateRange();
    final DateTime? filterStart = startDateStr != null ? DateTime.tryParse(startDateStr) : null;
    final DateTime? filterEnd = endDateStr != null ? DateTime.tryParse(endDateStr) : null;

    bool isDateInRange(DateTime d) {
      if (filterStart == null && filterEnd == null) return true;
      if (filterStart != null && d.isBefore(filterStart)) return false;
      if (filterEnd != null && d.isAfter(filterEnd)) return false;
      return true;
    }

    for (var p in allRealizedPayments) {
      final user = p['user'] is Map ? p['user'] as Map : (p['userId'] is Map ? p['userId'] as Map : {});
      final String gstin = (user['gstin'] ?? p['gstin'] ?? '').toString().trim().toUpperCase();
      final bool isB2b = gstin.length == 15;
      final stateInfo = resolveStateInfo(user, fallbackGstin: p['gstin']?.toString());
      final DateTime parentDate = DateTime.tryParse(p['createdAt']?.toString() ?? '') ?? DateTime.now();

      final historyList = p['partialPaymentsHistory'] as List? ?? [];
      bool hasCalculatedInstallment = false;

      if (historyList.isNotEmpty) {
        for (var item in historyList) {
          if (item is! Map) continue;
          final hStatus = item['status']?.toString().toUpperCase() ?? '';
          if (hStatus != 'APPROVED') continue;

          final double instAmount = (item['amountPaid'] is num)
              ? (item['amountPaid'] as num).toDouble()
              : (double.tryParse(item['amountPaid']?.toString() ?? '0') ?? 0);
          if (instAmount <= 0) continue;

          // Prioritize transactionDate (the date client made the transfer)
          final DateTime instDate = DateTime.tryParse(item['transactionDate']?.toString() ?? '') ??
              DateTime.tryParse(item['verifiedAt']?.toString() ?? '') ??
              parentDate;

          if (!isDateInRange(instDate)) continue;

          gross += instAmount;
          final double base = instAmount / 1.18;
          final double tax = instAmount - base;
          taxable += base;
          totalTax += tax;

          if (isB2b) {
            b2b++;
            b2bAmt += instAmount;
          } else {
            b2c++;
            b2cAmt += instAmount;
          }

          if (stateInfo.isIntraState) {
            cgst += (tax / 2);
            sgst += (tax / 2);
          } else {
            igst += tax;
          }
          hasCalculatedInstallment = true;
        }
      }

      if (!hasCalculatedInstallment && historyList.isEmpty) {
        final status = p['status']?.toString().toUpperCase() ?? '';
        final isRealized = status == 'PAID' || status == 'APPROVED' || status == 'PARTIAL-PAID' || status == 'SUCCESS';
        if (!isRealized) continue;

        final double paid = (p['amountPaid'] is num)
            ? (p['amountPaid'] as num).toDouble()
            : (double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0);
        if (paid <= 0) continue;

        // Prioritize transactionDate
        final DateTime paymentDate = DateTime.tryParse(p['transactionDate']?.toString() ?? '') ?? parentDate;
        if (!isDateInRange(paymentDate)) continue;

        gross += paid;
        final double base = paid / 1.18;
        final double tax = paid - base;
        taxable += base;
        totalTax += tax;

        if (isB2b) {
          b2b++;
          b2bAmt += paid;
        } else {
          b2c++;
          b2cAmt += paid;
        }

        if (stateInfo.isIntraState) {
          cgst += (tax / 2);
          sgst += (tax / 2);
        } else {
          igst += tax;
        }
      }
    }

    gstGrossTurnover.value = gross;
    gstTaxableTurnover.value = taxable;
    gstTotalTax.value = totalTax;
    gstCgst.value = cgst;
    gstSgst.value = sgst;
    gstIgst.value = igst;
    gstB2bCount.value = b2b;
    gstB2cCount.value = b2c;
    gstB2bAmount.value = b2bAmt;
    gstB2cAmount.value = b2cAmt;
  }

  Future<void> exportGstReport() async {
    if (isExportingGst.value) return;
    isExportingGst.value = true;
    try {
      final (startDateStr, endDateStr) = getActiveDateRange();
      final DateTime? filterStart = startDateStr != null ? DateTime.tryParse(startDateStr) : null;
      final DateTime? filterEnd = endDateStr != null ? DateTime.tryParse(endDateStr) : null;

      bool isDateInRange(DateTime d) {
        if (filterStart == null && filterEnd == null) return true;
        if (filterStart != null && d.isBefore(filterStart)) return false;
        if (filterEnd != null && d.isAfter(filterEnd)) return false;
        return true;
      }

      final result = await _segmentService.getPendingBankTransfers(
        page: 1,
        pageSize: 5000,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      final rawPayments = List<Map<String, dynamic>>.from(result['pendingPayments'] ?? []);

      final csvBuffer = StringBuffer();
      // UTF-8 BOM so Excel opens with proper Indian currency and headers
      csvBuffer.write('\uFEFF');

      // GSTR-1 & CA Audit standard headers
      csvBuffer.writeln(
        'Invoice Number,Invoice Date,Customer Name,Customer Mobile,Customer GSTIN,Customer PAN,Invoice Type,Place of Supply (POS),Reverse Charge,SAC Code,Taxable Value (INR),GST Rate,CGST (INR),SGST (INR),IGST (INR),Total Invoice Value (INR),Payment Mode,UTR / Transaction Ref,Plan / Service Name,Payment Status',
      );

      int count = 0;
      double grandBaseAmount = 0.0;
      double grandCgst = 0.0;
      double grandSgst = 0.0;
      double grandIgst = 0.0;
      double grandGrossAmount = 0.0;

      final Map<String, Map<String, dynamic>> stateSummaryMap = {};
      final Map<String, Map<String, dynamic>> categorySummaryMap = {
        'B2B Regular': {'count': 0, 'base': 0.0, 'cgst': 0.0, 'sgst': 0.0, 'igst': 0.0, 'gross': 0.0},
        'B2C Small': {'count': 0, 'base': 0.0, 'cgst': 0.0, 'sgst': 0.0, 'igst': 0.0, 'gross': 0.0},
      };
      final Map<String, Map<String, dynamic>> paymentModeSummaryMap = {};

      void recordRow({
        required String stateCode,
        required String stateName,
        required bool isIntraState,
        required bool isB2b,
        required String paymentMode,
        required double baseAmount,
        required double cgst,
        required double sgst,
        required double igst,
        required double totalPaid,
      }) {
        grandBaseAmount += baseAmount;
        grandCgst += cgst;
        grandSgst += sgst;
        grandIgst += igst;
        grandGrossAmount += totalPaid;

        final sKey = stateCode.isNotEmpty ? stateCode : '99';
        final stateEntry = stateSummaryMap.putIfAbsent(sKey, () => {
          'code': sKey,
          'name': stateName.isNotEmpty ? stateName : 'Unspecified',
          'isIntraState': isIntraState,
          'b2bCount': 0,
          'b2cCount': 0,
          'totalCount': 0,
          'baseAmount': 0.0,
          'cgst': 0.0,
          'sgst': 0.0,
          'igst': 0.0,
          'taxTotal': 0.0,
          'grossTotal': 0.0,
        });

        if (isB2b) {
          stateEntry['b2bCount'] = (stateEntry['b2bCount'] as int) + 1;
        } else {
          stateEntry['b2cCount'] = (stateEntry['b2cCount'] as int) + 1;
        }
        stateEntry['totalCount'] = (stateEntry['totalCount'] as int) + 1;
        stateEntry['baseAmount'] = (stateEntry['baseAmount'] as double) + baseAmount;
        stateEntry['cgst'] = (stateEntry['cgst'] as double) + cgst;
        stateEntry['sgst'] = (stateEntry['sgst'] as double) + sgst;
        stateEntry['igst'] = (stateEntry['igst'] as double) + igst;
        stateEntry['taxTotal'] = (stateEntry['taxTotal'] as double) + (cgst + sgst + igst);
        stateEntry['grossTotal'] = (stateEntry['grossTotal'] as double) + totalPaid;

        final catKey = isB2b ? 'B2B Regular' : 'B2C Small';
        final catEntry = categorySummaryMap[catKey]!;
        catEntry['count'] = (catEntry['count'] as int) + 1;
        catEntry['base'] = (catEntry['base'] as double) + baseAmount;
        catEntry['cgst'] = (catEntry['cgst'] as double) + cgst;
        catEntry['sgst'] = (catEntry['sgst'] as double) + sgst;
        catEntry['igst'] = (catEntry['igst'] as double) + igst;
        catEntry['gross'] = (catEntry['gross'] as double) + totalPaid;

        final modeKey = paymentMode.trim().isNotEmpty ? paymentMode.trim().toUpperCase() : 'BANK_TRANSFER';
        final modeEntry = paymentModeSummaryMap.putIfAbsent(modeKey, () => {'count': 0, 'gross': 0.0});
        modeEntry['count'] = (modeEntry['count'] as int) + 1;
        modeEntry['gross'] = (modeEntry['gross'] as double) + totalPaid;
      }

      for (final p in rawPayments) {
        final user = p['userId'] is Map ? p['userId'] as Map : (p['user'] is Map ? p['user'] as Map : {});
        final String fullName = user['fullName']?.toString() ?? 'Customer';
        final String mobile = user['phone']?.toString() ?? '-';
        final String gstin = (user['gstin'] ?? p['gstin'] ?? '').toString().trim().toUpperCase();
        final String pan = (user['panNumber'] ?? '').toString().trim().toUpperCase();
        final bool isB2b = gstin.length == 15;

        final stateInfo = resolveStateInfo(user, fallbackGstin: p['gstin']?.toString());
        final String pos = (stateInfo.code != '--')
            ? '${stateInfo.code}-${stateInfo.name}'
            : '99-Other';

        final plan = p['segmentPlanId'] is Map ? p['segmentPlanId'] as Map : {};
        final isRegistration = p['purchaseType'] == 'REGISTRATION';
        final String basePlanName = isRegistration
            ? 'Registration'
            : (plan['planName']?.toString() ?? 'Subscription');

        final String paymentMode = (p['paymentMethod'] ?? 'BANK_TRANSFER').toString();
        final DateTime parentDate = DateTime.tryParse(p['createdAt']?.toString() ?? '') ?? DateTime.now();

        final String rawInvoice = p['invoiceNumber']?.toString() ?? '';
        final String invoiceNo = rawInvoice.isNotEmpty
            ? rawInvoice
            : 'RV/${parentDate.year}-${(parentDate.year + 1) % 100}/${p['_id'].toString().substring(p['_id'].toString().length >= 6 ? p['_id'].toString().length - 6 : 0).toUpperCase()}';

        // Check for installment history
        final historyList = p['partialPaymentsHistory'] as List? ?? [];
        bool hasExportedInstallment = false;

        if (historyList.isNotEmpty) {
          final approvedList = historyList.where((item) =>
            item is Map &&
            item['status']?.toString().toUpperCase() == 'APPROVED' &&
            ((item['amountPaid'] is num && (item['amountPaid'] as num) > 0) ||
             (double.tryParse(item['amountPaid']?.toString() ?? '0') ?? 0) > 0)
          ).toList();

          final bool hasMultipleInstallments = approvedList.length > 1;

          for (int i = 0; i < historyList.length; i++) {
            final item = historyList[i];
            if (item is! Map) continue;
            final hStatus = item['status']?.toString().toUpperCase() ?? '';
            if (hStatus != 'APPROVED') continue;

            final double instAmount = (item['amountPaid'] is num)
                ? (item['amountPaid'] as num).toDouble()
                : (double.tryParse(item['amountPaid']?.toString() ?? '0') ?? 0);
            if (instAmount <= 0) continue;

            // Prioritize transactionDate (the date client made the transfer)
            final DateTime instDate = DateTime.tryParse(item['transactionDate']?.toString() ?? '') ??
                DateTime.tryParse(item['verifiedAt']?.toString() ?? '') ??
                parentDate;

            if (!isDateInRange(instDate)) continue;

            final double baseAmount = instAmount / 1.18;
            final double gstTotal = instAmount - baseAmount;
            final double cgst = stateInfo.isIntraState ? (gstTotal / 2) : 0.0;
            final double sgst = stateInfo.isIntraState ? (gstTotal / 2) : 0.0;
            final double igst = (!stateInfo.isIntraState) ? gstTotal : 0.0;

            final String formattedDate = DateFormat('dd/MM/yyyy').format(instDate);
            final String utr = (item['utrNumber'] != null && item['utrNumber'].toString().trim().isNotEmpty)
                ? item['utrNumber'].toString().trim()
                : (p['utrNumber'] ?? p['razorpayOrderId'] ?? '-');

            final int instNumber = i + 1;
            // Unique sequential installment invoice number for GSTR-1 compliance
            final String itemInvoiceNo = hasMultipleInstallments
                ? '$invoiceNo-INS$instNumber'
                : invoiceNo;

            final String planLabel = isRegistration
                ? (instAmount >= 10000 ? 'Gold Registration (Installment $instNumber)' : 'Silver Registration (Installment $instNumber)')
                : '$basePlanName (Installment $instNumber)';

            csvBuffer.writeln(
              '"$itemInvoiceNo","$formattedDate","${_cleanCsv(fullName)}","${_cleanCsv(mobile)}","${isB2b ? gstin : 'URP'}","${_cleanCsv(pan)}","${isB2b ? 'B2B Regular' : 'B2C Small'}","$pos","N","998371",${baseAmount.toStringAsFixed(2)},18%,${cgst.toStringAsFixed(2)},${sgst.toStringAsFixed(2)},${igst.toStringAsFixed(2)},${instAmount.toStringAsFixed(2)},"$paymentMode","${_cleanCsv(utr)}","${_cleanCsv(planLabel)}","APPROVED"',
            );
            count++;
            hasExportedInstallment = true;

            recordRow(
              stateCode: stateInfo.code,
              stateName: stateInfo.name,
              isIntraState: stateInfo.isIntraState,
              isB2b: isB2b,
              paymentMode: paymentMode,
              baseAmount: baseAmount,
              cgst: cgst,
              sgst: sgst,
              igst: igst,
              totalPaid: instAmount,
            );
          }
        }

        if (!hasExportedInstallment && historyList.isEmpty) {
          // Standard one-time payment or parent record without installment breakdown
          final status = p['status']?.toString().toUpperCase() ?? '';
          final isRealized = status == 'PAID' || status == 'APPROVED' || status == 'PARTIAL-PAID' || status == 'SUCCESS';
          if (!isRealized) continue;

          final double totalPaid = (p['amountPaid'] is num)
              ? (p['amountPaid'] as num).toDouble()
              : (double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0);
          if (totalPaid <= 0) continue;

          // Prioritize transactionDate
          final DateTime paymentDate = DateTime.tryParse(p['transactionDate']?.toString() ?? '') ?? parentDate;
          if (!isDateInRange(paymentDate)) continue;

          final double baseAmount = totalPaid / 1.18;
          final double gstTotal = totalPaid - baseAmount;
          final double cgst = stateInfo.isIntraState ? (gstTotal / 2) : 0.0;
          final double sgst = stateInfo.isIntraState ? (gstTotal / 2) : 0.0;
          final double igst = (!stateInfo.isIntraState) ? gstTotal : 0.0;

          final String formattedDate = DateFormat('dd/MM/yyyy').format(paymentDate);
          final String utr = p['utrNumber'] ?? p['razorpayOrderId'] ?? '-';
          final String planLabel = isRegistration
              ? (totalPaid >= 10000 ? 'Gold Registration' : 'Silver Registration')
              : basePlanName;

          csvBuffer.writeln(
            '"$invoiceNo","$formattedDate","${_cleanCsv(fullName)}","${_cleanCsv(mobile)}","${isB2b ? gstin : 'URP'}","${_cleanCsv(pan)}","${isB2b ? 'B2B Regular' : 'B2C Small'}","$pos","N","998371",${baseAmount.toStringAsFixed(2)},18%,${cgst.toStringAsFixed(2)},${sgst.toStringAsFixed(2)},${igst.toStringAsFixed(2)},${totalPaid.toStringAsFixed(2)},"$paymentMode","${_cleanCsv(utr)}","${_cleanCsv(planLabel)}","$status"',
          );
          count++;

          recordRow(
            stateCode: stateInfo.code,
            stateName: stateInfo.name,
            isIntraState: stateInfo.isIntraState,
            isB2b: isB2b,
            paymentMode: paymentMode,
            baseAmount: baseAmount,
            cgst: cgst,
            sgst: sgst,
            igst: igst,
            totalPaid: totalPaid,
          );
        }
      }

      // 1. Transaction Table Grand Total Row
      final double grandTotalTax = grandCgst + grandSgst + grandIgst;
      csvBuffer.writeln(
        '"GRAND TOTAL / SUMMARY","","","","","","","","",,"${grandBaseAmount.toStringAsFixed(2)}","18%","${grandCgst.toStringAsFixed(2)}","${grandSgst.toStringAsFixed(2)}","${grandIgst.toStringAsFixed(2)}","${grandGrossAmount.toStringAsFixed(2)}","","","$count Invoices / Vouchers",""',
      );

      // Blank lines for visual separation
      csvBuffer.writeln();
      csvBuffer.writeln();

      // 2. Table 1: State-Wise Place of Supply (POS) GST Breakdown
      csvBuffer.writeln('"=================================================================================================================================================="');
      csvBuffer.writeln('"STATUTORY SUMMARY: STATE-WISE PLACE OF SUPPLY (POS) GST BREAKDOWN (FOR GSTR-1 & GSTR-3B TABLE 3.2)"');
      csvBuffer.writeln('"Report Period: ${selectedGstPeriod.value} | Supplier State: Madhya Pradesh (23) | Applicable Tax: SAC 998371 (18%)"');
      csvBuffer.writeln('"=================================================================================================================================================="');
      csvBuffer.writeln('"POS Code","Place of Supply (State Name)","Supply Nature","B2B Invoices","B2C Invoices","Total Invoices","Taxable Value (INR)","CGST 9% (INR)","SGST 9% (INR)","IGST 18% (INR)","Total Tax Liability (INR)","Total Gross Turnover (INR)"');

      final sortedStates = stateSummaryMap.values.toList()
        ..sort((a, b) {
          if (a['code'] == '23') return -1;
          if (b['code'] == '23') return 1;
          return (b['grossTotal'] as double).compareTo(a['grossTotal'] as double);
        });

      int totalB2bInvoices = 0;
      int totalB2cInvoices = 0;

      for (final s in sortedStates) {
        final b2b = s['b2bCount'] as int;
        final b2c = s['b2cCount'] as int;
        totalB2bInvoices += b2b;
        totalB2cInvoices += b2c;
        final isIntra = s['isIntraState'] == true;
        final supplyType = isIntra ? 'Intra-State (MP)' : 'Inter-State';

        csvBuffer.writeln(
          '"${s['code']}","${_cleanCsv(s['name'].toString())}","$supplyType",$b2b,$b2c,${s['totalCount']},${(s['baseAmount'] as double).toStringAsFixed(2)},${(s['cgst'] as double).toStringAsFixed(2)},${(s['sgst'] as double).toStringAsFixed(2)},${(s['igst'] as double).toStringAsFixed(2)},${(s['taxTotal'] as double).toStringAsFixed(2)},${(s['grossTotal'] as double).toStringAsFixed(2)}',
        );
      }

      csvBuffer.writeln(
        '"TOTAL","All States Combined","-",$totalB2bInvoices,$totalB2cInvoices,$count,${grandBaseAmount.toStringAsFixed(2)},${grandCgst.toStringAsFixed(2)},${grandSgst.toStringAsFixed(2)},${grandIgst.toStringAsFixed(2)},${grandTotalTax.toStringAsFixed(2)},${grandGrossAmount.toStringAsFixed(2)}',
      );

      // Blank lines for visual separation
      csvBuffer.writeln();
      csvBuffer.writeln();

      // 3. Table 2: GSTR-1 Tax Category Summary (B2B vs B2C)
      csvBuffer.writeln('"=================================================================================================================================================="');
      csvBuffer.writeln('"STATUTORY SUMMARY: GSTR-1 TAX CATEGORY BREAKDOWN (B2B TABLE 4A vs B2C TABLE 7)"');
      csvBuffer.writeln('"=================================================================================================================================================="');
      csvBuffer.writeln('"Tax Category","SAC Code","GST Rate","Invoice Count","Taxable Value (INR)","CGST (INR)","SGST (INR)","IGST (INR)","Total GST Liability (INR)","Total Gross Turnover (INR)"');

      for (final entry in categorySummaryMap.entries) {
        final catName = entry.key;
        final data = entry.value;
        final int cCount = data['count'] as int;
        final double base = data['base'] as double;
        final double cgst = data['cgst'] as double;
        final double sgst = data['sgst'] as double;
        final double igst = data['igst'] as double;
        final double tax = cgst + sgst + igst;
        final double gross = data['gross'] as double;

        final String label = catName == 'B2B Regular'
            ? 'B2B Regular (GSTIN Registered Clients)'
            : 'B2C Small (Retail / Unregistered Clients)';

        csvBuffer.writeln(
          '"$label","998371","18%",$cCount,${base.toStringAsFixed(2)},${cgst.toStringAsFixed(2)},${sgst.toStringAsFixed(2)},${igst.toStringAsFixed(2)},${tax.toStringAsFixed(2)},${gross.toStringAsFixed(2)}',
        );
      }

      csvBuffer.writeln(
        '"TOTAL OUTWARD SUPPLIES","998371","18%",$count,${grandBaseAmount.toStringAsFixed(2)},${grandCgst.toStringAsFixed(2)},${grandSgst.toStringAsFixed(2)},${grandIgst.toStringAsFixed(2)},${grandTotalTax.toStringAsFixed(2)},${grandGrossAmount.toStringAsFixed(2)}',
      );

      // Blank lines for visual separation
      csvBuffer.writeln();
      csvBuffer.writeln();

      // 4. Table 3: Payment Mode Collections Summary
      csvBuffer.writeln('"=================================================================================================================================================="');
      csvBuffer.writeln('"COLLECTIONS RECONCILIATION BY PAYMENT METHOD"');
      csvBuffer.writeln('"=================================================================================================================================================="');
      csvBuffer.writeln('"Payment Mode","Transaction Count","Total Realized Collections (INR)","Percentage of Turnover"');

      final sortedModes = paymentModeSummaryMap.entries.toList()
        ..sort((a, b) => (b.value['gross'] as double).compareTo(a.value['gross'] as double));

      for (final m in sortedModes) {
        final mName = m.key;
        final int mCount = m.value['count'] as int;
        final double mGross = m.value['gross'] as double;
        final double pct = grandGrossAmount > 0 ? (mGross / grandGrossAmount) * 100 : 0.0;

        csvBuffer.writeln(
          '"$mName",$mCount,${mGross.toStringAsFixed(2)},"${pct.toStringAsFixed(1)}%"',
        );
      }

      csvBuffer.writeln(
        '"TOTAL COLLECTIONS",$count,${grandGrossAmount.toStringAsFixed(2)},"100.0%"',
      );

      final bytes = utf8.encode(csvBuffer.toString());
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final filename = 'GST_GSTR1_Report_${selectedGstPeriod.value.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';

      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      Get.snackbar(
        "GST Report Exported",
        "Successfully exported $count tax invoice records to $filename",
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint("Error exporting GST report: $e");
      Get.snackbar(
        "Export Failed",
        "Could not generate GST report: $e",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isExportingGst.value = false;
    }
  }

  String _cleanCsv(String val) => val.replaceAll('"', '""');
}
