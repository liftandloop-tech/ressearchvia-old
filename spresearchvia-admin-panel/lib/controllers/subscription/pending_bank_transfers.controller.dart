import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:spresearch_web/services/user.service.dart';
import 'package:spresearch_web/services/segment.service.dart';
import 'package:spresearch_web/services/acquisition.service.dart';
import 'package:spresearch_web/services/auth.service.dart';
import 'package:spresearch_web/services/subscription.service.dart';
import '../../models/user.model.dart';
import 'package:file_picker/file_picker.dart';

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

  bool get isAdmin => currentUser.value?.isAdmin ?? false;

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
    // Filter out Custom/HNI plans as per Gap 17
    plansForSelectedSegment.assignAll(
      list.where((p) => p['isHni'] != true).toList(),
    );
    isFetchingPlans.value = false;
  }

  void showSubscriptionCorrectionDialog(Map<String, dynamic> payment) {
    // 0. Preliminary Checks
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
    loadSegments();
    if (currentSegmentId.isNotEmpty) loadPlansForSegment(currentSegmentId);

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
                  // Info Box
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

                  // Segment Selection
                  Text(
                    'Segment',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value:
                          segments.any(
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
                  ),
                  SizedBox(height: 16),

                  // Plan Selection
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

                  // Date Selectors
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
                                icon: Icon(Icons.event_busy, size: 16),
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
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.grey[700]),
                        SizedBox(width: 8),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                if (selectedSegmentId.value.isEmpty ||
                    selectedPlanId.value.isEmpty) {
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
                          newSegmentId: selectedSegmentId.value,
                          newPlanId: selectedPlanId.value,
                          newStartDate: startDate.value?.toIso8601String(),
                          newExpiryDate: expiryDate.value?.toIso8601String(),
                          clientVersion: currentCorrectionVersion,
                        );

                    if (success) {
                      Get.back(); // Close dialog
                      Get.snackbar(
                        "Success",
                        "Subscription metadata corrected successfully.",
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                      fetchPendingTransfers();
                    } else {
                      Get.snackbar(
                        "Update Failed",
                        "Error saving changes. Check concurrency or plan availability.",
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  },
                  loadingWidget: Center(child: CircularProgressIndicator()),
                );
              },
              child: Text(
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

  void showCorrectionDialog(Map<String, dynamic> payment) {
    final paymentIntentId = payment['_id'] ?? '';
    final currentAmount = (payment['amountPaid'] ?? payment['amount'] ?? 0)
        .toDouble();
    final isApproved =
        payment['status'] == 'PAID' ||
        payment['status'] == 'APPROVED' ||
        payment['status'] == 'PARTIAL-PAID';

    // Always reset preview state when opening a new dialog
    correctionPreview.value = {};
    isCalculating.value = false;

    final TextEditingController amountController = TextEditingController(
      text: currentAmount.toString(),
    );
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController utrController = TextEditingController(
      text: payment['utrNumber']?.toString() ?? '',
    );
    final originallyPartial = payment['isPartial'] == true;
    final isPartialMode = originallyPartial.obs;
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
                            "This payment is already APPROVED. Changing the amount will re-value the user's entitlements.",
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
                  'Correct Payment Amount',
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

                if (originallyPartial) ...[
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
                  'Update UTR / Ref ID (Optional)',
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
                  'Update Payment Screenshots (Optional)',
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
  var pendingPayments = <Map<String, dynamic>>[].obs;
  var filteredPayments = <Map<String, dynamic>>[].obs;
  var totalPaymentsCount = 0.obs;

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

      final result = await _segmentService.getPendingBankTransfers(
        page: currentPage.value,
        pageSize: pageSize.value,
        search: searchQuery.value,
        status: statusFilter.value,
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

      totalPaymentsCount.value = result['totalCount'] ?? 0;
      hasMorePages.value = pendingPayments.length < totalPaymentsCount.value;

      // Since filtering is primarily done on backend now, we just pass the filtered list
      // Local applyFilters can still be run for any extra UI-side sync needs
      applyFilters();

      debugPrint(
        '[PendingTransfers] Updated observable with ${pendingPayments.length} payments',
      );
    } catch (e) {
      debugPrint('[PendingTransfers] Error: $e');
      if (isLoadMore) currentPage.value--; // Revert page increment on error
    } finally {
      isLoading.value = false;
    }
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

  Future<bool> rejectPartialInstallment(
    String intentId,
    String historyId,
  ) async {
    try {
      isLoading.value = true;
      final success = await _acquisitionService.rejectPartialPayment(
        paymentIntentId: intentId,
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
        final status = user.kycStatus?.toUpperCase() ?? 'NOT_STARTED';

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
}
