import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/services/refund.service.dart';

class RefundDialog extends StatefulWidget {
  final Map<String, dynamic>? payment;
  final List<Map<String, dynamic>>? availableSubscriptions;
  final String userId;
  final String userName;
  final VoidCallback? onRefundSuccess;

  const RefundDialog({
    super.key,
    this.payment,
    this.availableSubscriptions,
    required this.userId,
    required this.userName,
    this.onRefundSuccess,
  });

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _planNameController;
  late TextEditingController _originalAmountController;
  late TextEditingController _refundAmountController;
  late TextEditingController _deductionController;
  late TextEditingController _reasonController;
  late TextEditingController _adminNotesController;

  String _reasonCategory = 'SERVICE_DISSATISFACTION';
  String _refundType = 'PRORATED'; // PRORATED, FULL, CUSTOM
  String _subscriptionAction = 'REVOKE_IMMEDIATELY'; // REVOKE_IMMEDIATELY, NONE

  bool _isCalculating = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _previewData;

  double _originalAmount = 0.0;

  List<Map<String, dynamic>> _selectablePlans = [];
  Map<String, dynamic>? _selectedPlan;
  String? _selectedPlanKey;

  final List<Map<String, String>> _categories = [
    {'value': 'COOLING_PERIOD_CANCELLATION', 'label': 'Cooling-Off Period (< 7 Days)'},
    {'value': 'SERVICE_DISSATISFACTION', 'label': 'Service Dissatisfaction / Early Termination'},
    {'value': 'DUPLICATE_PAYMENT', 'label': 'Duplicate / Double Payment'},
    {'value': 'TECHNICAL_ISSUE', 'label': 'Technical / Signal Delivery Issue'},
    {'value': 'ACCOUNT_TERMINATION', 'label': 'Mutual Agreement Account Termination'},
    {'value': 'OTHER', 'label': 'Other (Specified in compliance notes)'},
  ];

  @override
  void initState() {
    super.initState();

    // Prepare selectable plans
    final rawList = widget.availableSubscriptions ?? [];
    if (rawList.isNotEmpty) {
      _selectablePlans = List<Map<String, dynamic>>.from(rawList);
    } else if (widget.payment != null) {
      _selectablePlans = [Map<String, dynamic>.from(widget.payment!)];
    }

    // Determine initial plan
    if (widget.payment != null && (widget.payment!['planId'] != null || widget.payment!['_id'] != null)) {
      final pId = widget.payment!['planId'] ?? widget.payment!['_id'];
      _selectedPlan = _selectablePlans.firstWhereOrNull(
        (p) => (p['planId'] ?? p['_id']) == pId,
      );
    }

    _selectedPlan ??= _selectablePlans.firstWhereOrNull(
      (p) => (p['status'] ?? '').toString().toLowerCase() == 'active',
    ) ?? (_selectablePlans.isNotEmpty ? _selectablePlans.first : null);

    _selectedPlanKey = _getPlanKey(_selectedPlan);

    final initialPlanData = _selectedPlan ?? widget.payment ?? {};
    final rawAmount = initialPlanData['amountPaid'] ??
        initialPlanData['price'] ??
        initialPlanData['totalAmount'] ??
        initialPlanData['amount'] ??
        '0';
    final cleanAmountStr = rawAmount.toString().replaceAll('₹', '').replaceAll(',', '').trim();
    _originalAmount = double.tryParse(cleanAmountStr) ?? 0.0;

    final plan = initialPlanData['packageName'] ?? initialPlanData['planName'] ?? 'Subscription Plan';

    _planNameController = TextEditingController(text: plan.toString());
    _originalAmountController = TextEditingController(text: _originalAmount.toStringAsFixed(2));
    _refundAmountController = TextEditingController(text: _originalAmount.toStringAsFixed(2));
    _deductionController = TextEditingController(text: '0');
    _reasonController = TextEditingController();
    _adminNotesController = TextEditingController();

    _fetchCalculationPreview();
  }

  String _getPlanKey(Map<String, dynamic>? plan) {
    if (plan == null) return 'none';
    return (plan['_id'] ?? plan['planId'] ?? plan['packageName'] ?? plan['planName'] ?? UniqueKey().toString()).toString();
  }

  void _onSelectPlan(Map<String, dynamic> plan) {
    setState(() {
      _selectedPlan = plan;
      _selectedPlanKey = _getPlanKey(plan);

      final rawAmount = plan['amountPaid'] ??
          plan['price'] ??
          plan['totalAmount'] ??
          plan['amount'] ??
          '0';
      final cleanAmountStr = rawAmount.toString().replaceAll('₹', '').replaceAll(',', '').trim();
      _originalAmount = double.tryParse(cleanAmountStr) ?? 0.0;

      final planTitle = plan['packageName'] ?? plan['planName'] ?? 'Subscription Plan';
      _planNameController.text = planTitle.toString();
      _originalAmountController.text = _originalAmount.toStringAsFixed(2);
      _deductionController.text = '0';
      _refundAmountController.text = _originalAmount.toStringAsFixed(2);
      _refundType = 'PRORATED';
    });

    _fetchCalculationPreview();
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _originalAmountController.dispose();
    _refundAmountController.dispose();
    _deductionController.dispose();
    _reasonController.dispose();
    _adminNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCalculationPreview() async {
    setState(() => _isCalculating = true);
    try {
      final refundService = Get.isRegistered<RefundService>() ? Get.find<RefundService>() : Get.put(RefundService());
      DateTime? startDate;
      DateTime? endDate;

      final planData = _selectedPlan ?? widget.payment ?? {};
      final startVal = planData['startDate'] ?? planData['serviceStartDate'];
      final endVal = planData['endDate'] ?? planData['expiryDate'] ?? planData['currentExpiryDate'];

      if (startVal != null) {
        startDate = DateTime.tryParse(startVal.toString());
      }
      if (endVal != null) {
        endDate = DateTime.tryParse(endVal.toString());
      }

      final result = await refundService.previewRefundCalculation(
        userId: widget.userId,
        planId: planData['planId']?.toString() ?? planData['_id']?.toString(),
        paymentIntentId: planData['paymentIntentId']?.toString(),
        originalAmount: _originalAmount,
        startDate: startDate,
        endDate: endDate,
      );

      if (result != null && mounted) {
        setState(() {
          _previewData = result;
          _applyRefundCalculation(_refundType);
        });
      }
    } catch (e) {
      debugPrint('Error fetching preview: $e');
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  void _applyRefundCalculation(String type) {
    if (type == 'FULL') {
      _deductionController.text = '0.00';
      _refundAmountController.text = _originalAmount.toStringAsFixed(2);
    } else if (type == 'PRORATED' && _previewData != null) {
      final prorated = double.tryParse(_previewData!['suggestedProratedRefund']?.toString() ?? '0') ?? 0;
      final usedFee = _originalAmount - prorated;
      final deduction = usedFee > 0 ? usedFee : 0.0;
      _deductionController.text = deduction.toStringAsFixed(2);
      _refundAmountController.text = prorated.toStringAsFixed(2);
    }
  }

  void _onRefundTypeChanged(String type) {
    setState(() {
      _refundType = type;
      _applyRefundCalculation(type);
    });
  }

  void _onDeductionChanged(String val) {
    final deduction = double.tryParse(val) ?? 0;
    final netRefund = (_originalAmount - deduction).clamp(0.0, _originalAmount);
    _refundAmountController.text = netRefund.toStringAsFixed(2);
  }

  void _onRefundAmountChanged(String val) {
    final refundAmt = double.tryParse(val) ?? 0;
    final deduction = (_originalAmount - refundAmt).clamp(0.0, _originalAmount);
    _deductionController.text = deduction.toStringAsFixed(2);
  }

  Future<void> _submitRefund() async {
    if (!_formKey.currentState!.validate()) return;

    final refundAmount = double.tryParse(_refundAmountController.text.trim()) ?? 0;
    final deductionAmount = double.tryParse(_deductionController.text.trim()) ?? 0;

    if (refundAmount <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Refund amount must be greater than 0',
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    if (refundAmount > _originalAmount) {
      Get.snackbar(
        'Invalid Amount',
        'Refund amount cannot exceed total payment paid (₹${_originalAmount.toStringAsFixed(2)})',
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    final totalDays = _previewData?['totalDays'] ?? 30;
    final daysUsed = _previewData?['daysUsed'] ?? 0;

    // Double confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            const Text('Confirm Refund Policy Execution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issue a refund of ₹${refundAmount.toStringAsFixed(2)} for ${widget.userName}?',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payment Paid:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      Text('₹${_originalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Service Used ($daysUsed / $totalDays days):', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      Text('- ₹${deductionAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Refund Due to Client:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text('₹${refundAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _subscriptionAction == "REVOKE_IMMEDIATELY"
                  ? 'Access to trade signals & entitlements for this plan will be REVOKED immediately.'
                  : 'Subscription access will remain active until expiry.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Process Refund'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final activeData = _selectedPlan ?? widget.payment ?? {};
      final targetPlanId = activeData['planId'] ?? activeData['_id'];
      final targetSegment = activeData['segmentName'] ?? widget.payment?['segmentName'] ?? '-';
      final targetPaymentIntentId = activeData['paymentIntentId'] ?? widget.payment?['paymentIntentId'];
      final targetSegmentsPaymentId = activeData['segmentsPaymentId'] ?? widget.payment?['segmentsPaymentId'] ?? (activeData['source'] == 'segments_payment' ? activeData['_id'] : null);

      final payload = {
        'userId': widget.userId,
        'planId': targetPlanId,
        'planName': _planNameController.text.trim(),
        'segmentName': targetSegment,
        'paymentIntentId': targetPaymentIntentId,
        'segmentsPaymentId': targetSegmentsPaymentId,
        'originalAmount': _originalAmount,
        'refundAmount': refundAmount,
        'deductionAmount': deductionAmount,
        'refundType': _refundType,
        'reason': _reasonController.text.trim(),
        'reasonCategory': _reasonCategory,
        'refundMethod': 'BANK_TRANSFER', // Standard administrative refund
        'subscriptionAction': _subscriptionAction,
        'adminNotes': _adminNotesController.text.trim(),
      };

      final refundService = Get.isRegistered<RefundService>() ? Get.find<RefundService>() : Get.put(RefundService());
      final result = await refundService.processRefund(payload);
      if (result['success'] == true) {
        Get.snackbar(
          'Refund Processed',
          result['message'] ?? 'Refund of ₹${refundAmount.toStringAsFixed(2)} processed successfully.',
          backgroundColor: AppTheme.successGreen,
          colorText: Colors.white,
        );
        widget.onRefundSuccess?.call();
      } else {
        Get.snackbar(
          'Refund Failed',
          result['message'] ?? 'Failed to process refund.',
          backgroundColor: AppTheme.errorRed,
          colorText: Colors.white,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 820,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Target Plan Selection
                      _buildPlanSelectorSection(),
                      const SizedBox(height: 20),

                      // Service Usage & Policy Breakdown Card
                      _buildServiceUsagePolicyCard(),
                      const SizedBox(height: 20),

                      // Section 1: Refund Calculation Breakdown
                      _buildSectionHeader('1. Refund Calculation Policy', Icons.calculate_outlined),
                      const SizedBox(height: 12),
                      _buildRefundTypeSelector(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Total Payment Paid (₹)',
                              controller: _originalAmountController,
                              readOnly: true,
                              prefixIcon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'Used Service Retained (₹)*',
                              controller: _deductionController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.remove_circle_outline,
                              hint: 'Retained for consumed period',
                              onChanged: _onDeductionChanged,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'Net Refund Due (₹)*',
                              controller: _refundAmountController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.check_circle_outline,
                              hint: 'Balance to be refunded',
                              onChanged: _onRefundAmountChanged,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final amt = double.tryParse(v.trim());
                                if (amt == null || amt <= 0) return 'Must be > 0';
                                if (amt > _originalAmount) return 'Exceeds total paid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Reason for Refund
                      _buildSectionHeader('2. Reason for Refund & Compliance Audit*', Icons.announcement_outlined),
                      const SizedBox(height: 12),
                      _buildCategoryDropdown(),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Detailed Refund Reason / Justification*',
                        controller: _reasonController,
                        maxLines: 3,
                        hint: 'Specify details (e.g. client utilized 4 months of 12-month service; retained ₹40,000 for used period and refunding remaining ₹59,000 as per SEBI / refund terms)...',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Refund reason is mandatory for compliance audit' : null,
                      ),
                      const SizedBox(height: 24),

                      // Section 3: Subscription Access & Admin Notes
                      _buildSectionHeader('3. Entitlements & Compliance Notes', Icons.security_outlined),
                      const SizedBox(height: 12),
                      _buildSubscriptionActionSelector(),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Internal Admin Notes (Optional)',
                        controller: _adminNotesController,
                        maxLines: 2,
                        hint: 'Additional notes visible to compliance officers and administrators...',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark slate
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.currency_exchange, color: Color(0xFFF87171), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Process User Refund',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_person, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'ADMIN ONLY',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Issue a financial refund and recalculate service usage policy for ${widget.userName}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectorSection() {
    final hasMultiplePlans = _selectablePlans.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasMultiplePlans ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasMultiplePlans ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
          width: hasMultiplePlans ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasMultiplePlans ? Icons.layers_rounded : Icons.card_membership_rounded,
                size: 20,
                color: hasMultiplePlans ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasMultiplePlans
                      ? 'SELECT TARGET PLAN TO REFUND (${_selectablePlans.length} Subscriptions Found)'
                      : 'TARGET PLAN TO REFUND',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: hasMultiplePlans ? const Color(0xFF0369A1) : const Color(0xFF475569),
                  ),
                ),
              ),
              if (hasMultiplePlans)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'MULTIPLE PLANS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (hasMultiplePlans) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedPlanKey,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                ),
              ),
              items: _selectablePlans.map((plan) {
                final pKey = _getPlanKey(plan);
                final name = plan['packageName'] ?? plan['planName'] ?? 'Unnamed Plan';
                final segment = plan['segmentName'] ?? '-';
                final rawAmt = plan['amountPaid'] ?? plan['price'] ?? plan['totalAmount'] ?? plan['amount'] ?? '0';
                final status = (plan['status'] ?? 'active').toString().toUpperCase();

                return DropdownMenuItem<String>(
                  value: pKey,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'ACTIVE'
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: status == 'ACTIVE'
                                ? const Color(0xFF166534)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$name ($segment)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '₹$rawAmt',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                final matched = _selectablePlans.firstWhereOrNull((p) => _getPlanKey(p) == val);
                if (matched != null) {
                  _onSelectPlan(matched);
                }
              },
            ),
          ] else if (_selectablePlans.length == 1) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (_selectablePlans.first['status'] ?? 'ACTIVE').toString().toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_selectablePlans.first['packageName'] ?? _selectablePlans.first['planName'] ?? 'Active Plan'} (${_selectablePlans.first['segmentName'] ?? '-'})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ),
                  Text(
                    '₹${_originalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildTextField(
              label: 'Plan Name*',
              controller: _planNameController,
              hint: 'Enter subscription / package name to refund',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceUsagePolicyCard() {
    final totalDays = _previewData?['totalDays'] ?? 30;
    final daysUsed = _previewData?['daysUsed'] ?? 0;
    final daysRemaining = _previewData?['daysRemaining'] ?? 0;

    final totalMonths = (totalDays / 30).toStringAsFixed(1);
    final monthsUsed = (daysUsed / 30).toStringAsFixed(1);
    final monthsRemaining = (daysRemaining / 30).toStringAsFixed(1);

    final suggestedProrated = _previewData?['suggestedProratedRefund'] ?? _originalAmount;
    final usedServiceAmount = _previewData?['usedServiceAmount'] ?? (_originalAmount - suggestedProrated);

    final double usagePercent = totalDays > 0 ? (daysUsed / totalDays).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timeline_rounded, size: 18, color: Color(0xFF1E293B)),
                  SizedBox(width: 8),
                  Text(
                    'SERVICE USAGE POLICY & PRORATED BREAKDOWN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (_isCalculating)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usagePercent,
              minHeight: 8,
              backgroundColor: const Color(0xFFDCFCE7),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
          const SizedBox(height: 12),

          // 4 Grid Stat Chips
          Row(
            children: [
              Expanded(
                child: _buildUsageStatPill(
                  title: 'TOTAL PAID',
                  value: '₹${_originalAmount.toStringAsFixed(2)}',
                  subtitle: '$totalDays Days (~$totalMonths Mo)',
                  color: const Color(0xFF0F172A),
                  bgColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildUsageStatPill(
                  title: 'SERVICE USED',
                  value: '$daysUsed Days (~$monthsUsed Mo)',
                  subtitle: 'Retained: ₹$usedServiceAmount',
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildUsageStatPill(
                  title: 'REMAINING PERIOD',
                  value: '$daysRemaining Days (~$monthsRemaining Mo)',
                  subtitle: 'Unutilized service',
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildUsageStatPill(
                  title: 'REFUND DUE',
                  value: '₹$suggestedProrated',
                  subtitle: 'Remaining balance',
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Policy Rule: If total payment is ₹${_originalAmount.toStringAsFixed(0)} for $totalMonths months and client consumed $monthsUsed months ($daysUsed days), ₹$usedServiceAmount is retained for service rendered and the remaining ₹$suggestedProrated is refunded.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStatPill({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E3A5F)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A5F),
          ),
        ),
      ],
    );
  }

  Widget _buildRefundTypeSelector() {
    return Row(
      children: [
        _buildRadioOption('PRORATED', 'Prorated by Service Used', 'Deduct used period fee'),
        const SizedBox(width: 12),
        _buildRadioOption('FULL', 'Full Refund (100%)', 'Refund full original amount'),
        const SizedBox(width: 12),
        _buildRadioOption('CUSTOM', 'Custom Entry', 'Manually adjust deduction'),
      ],
    );
  }

  Widget _buildRadioOption(String value, String title, String subtitle) {
    final isSelected = _refundType == value;
    return Expanded(
      child: InkWell(
        onTap: () => _onRefundTypeChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                    width: isSelected ? 4 : 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _reasonCategory,
      decoration: InputDecoration(
        labelText: 'Refund Reason Category*',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: _categories.map((c) {
        return DropdownMenuItem<String>(
          value: c['value'],
          child: Text(c['label']!, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _reasonCategory = v);
      },
    );
  }

  Widget _buildSubscriptionActionSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _subscriptionAction == 'REVOKE_IMMEDIATELY',
            activeColor: const Color(0xFFD97706),
            onChanged: (v) {
              setState(() {
                _subscriptionAction = (v == true) ? 'REVOKE_IMMEDIATELY' : 'NONE';
              });
            },
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revoke Target Plan & Entitlements Immediately',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                Text(
                  'Terminates trade signals and advisory access for this refunded plan upon completion.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 13,
        color: readOnly ? const Color(0xFF64748B) : const Color(0xFF1E293B),
        fontWeight: readOnly ? FontWeight.bold : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
        filled: readOnly,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: readOnly ? Colors.transparent : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Refund Due: ',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              Text(
                '₹${_refundAmountController.text}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitRefund,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(_isSubmitting ? 'Processing...' : 'Confirm & Issue Refund'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626), // Red primary
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
