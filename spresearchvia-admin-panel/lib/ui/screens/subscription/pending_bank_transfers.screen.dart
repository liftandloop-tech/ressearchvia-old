import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/controllers/subscription/pending_bank_transfers.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/utils/invoice_pdf_generator.dart';

class PendingBankTransfersScreen extends StatelessWidget {
  final int? specificTab;
  const PendingBankTransfersScreen({super.key, this.specificTab});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PendingBankTransfersController>()
        ? Get.find<PendingBankTransfersController>()
        : Get.put(PendingBankTransfersController());

    final content = specificTab == 1
        ? _buildKycTab(controller)
        : specificTab == 0
        ? _buildPaymentsTab(controller)
        : DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.gray200)),
                  ),
                  child: const Material(
                    type: MaterialType.transparency,
                    child: TabBar(
                      isScrollable: true,
                      labelColor: AppTheme.primaryBlue,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryBlue,
                      tabs: [
                        Tab(text: "Payments approvals"),
                        Tab(text: "User KYC"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPaymentsTab(controller),
                      _buildKycTab(controller),
                    ],
                  ),
                ),
              ],
            ),
          );

    return Container(
      color: AppTheme.gray50,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.getResponsivePadding(context),
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  specificTab == 1
                      ? "User KYC Approvals"
                      : specificTab == 0
                      ? "Pending Payments Approvals"
                      : "Pending Approvals",
                  style: TextStyle(
                    fontSize: context.width < 600 ? 20 : 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    controller.fetchPendingTransfers();
                    controller.fetchPendingKyc();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab(PendingBankTransfersController controller) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: (value) {
                          controller.onSearchChanged(value);
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search by name, phone, registration, plan, or UTR',
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppTheme.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppTheme.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppTheme.primaryBlue),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Filter
                    Expanded(
                      child: Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: controller.statusFilter.value,
                              isExpanded: true,
                              items:
                                  [
                                    'All',
                                    'Pending',
                                    'Approved',
                                    'Rejected',
                                    'Partial',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  controller.statusFilter.value = newValue;
                                  controller.fetchPendingTransfers();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Reset Button
                    Button(
                      title: 'Reset',
                      buttonType: ButtonType.grey,
                      icon: Icons.refresh,
                      size: ButtonSize.small,
                      onTap: controller.resetFilters,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Data Section
          Obx(() {
            if (controller.isLoading.value &&
                controller.pendingPayments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (controller.pendingPayments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("No pending transfers found."),
                ),
              );
            }

            return _buildPaymentsTable(controller);
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentsTable(PendingBankTransfersController controller) {
    return Obx(() {
      if (controller.filteredPayments.isEmpty) {
        return const Center(
          child: Text("No payments match the selected filters."),
        );
      }

      final tableCard = Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.gray200),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scrollController = ScrollController();
            return Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    dataRowHeight: 80,
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    headingRowColor: MaterialStateProperty.all(AppTheme.gray50),
                    columns: [
                      const DataColumn(label: Text('Date')),
                      const DataColumn(label: Text('Customer')),
                      const DataColumn(label: Text('Registration')),
                      const DataColumn(label: Text('Plan')),
                      const DataColumn(label: Text('Paid Amount + GST')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Invoice')),
                      if (Get.find<AuthController>().user.value?.has('payments.bypass') ?? false)
                        const DataColumn(label: Text('Actions')),
                    ],
                    rows: controller.filteredPayments.map((payment) {
                      final user = payment['userId'] ?? {};
                      final planData = payment['segmentPlanId'];
                      final Map<String, dynamic> plan = (planData is Map)
                          ? Map<String, dynamic>.from(planData)
                          : {};
                      final isRegistration =
                          payment['purchaseType'] == 'REGISTRATION';

                      final amountPaid = (payment['amountPaid'] is num)
                          ? (payment['amountPaid'] as num).toDouble()
                          : (double.tryParse(
                                  payment['amountPaid']?.toString() ?? '0',
                                ) ??
                                0);
                      final totalAmount = (payment['amount'] is num)
                          ? (payment['amount'] as num).toDouble()
                          : (double.tryParse(
                                  payment['amount']?.toString() ?? '0',
                                ) ??
                                0);
                      final discount = (payment['discount'] is num)
                          ? (payment['discount'] as num).toDouble()
                          : (double.tryParse(
                                  payment['discount']?.toString() ?? '0',
                                ) ??
                                0);
                      final remaining = totalAmount - discount - amountPaid;

                      // Use createdAt for main table (when payment was initiated)
                      final date = DateTime.tryParse(
                        payment['createdAt'] ?? '',
                      );

                      final history =
                          payment['partialPaymentsHistory'] as List? ?? [];

                      final proofUrl =
                          payment['paymentProof'] ??
                          payment['paymentScreenshot'];

                      // Effectively Partial only if balance remains
                      final isPartialIntent = payment['isPartial'] == true;
                      final isEffectivelyPartial =
                          isPartialIntent && remaining > 0;

                      // Row needs highlight if: main status is PENDING, or
                      // any installment inside is still waiting for approval.
                      final rowStatus = payment['status'] ?? 'PENDING';
                      final hasPendingInstallment = history.any(
                        (inst) => inst['status'] == 'PENDING',
                      );
                      final needsAttention =
                          rowStatus == 'PENDING' || hasPendingInstallment;

                      // "NEW" tag: only on rows that still need attention
                      // AND were submitted within the last 48 hours.
                      final isNew = needsAttention &&
                          date != null &&
                          DateTime.now().difference(date).inHours < 48;

                      return DataRow(
                        color: needsAttention
                            ? MaterialStateProperty.all(
                                Colors.amber[50],
                              )
                            : null,
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    date != null ? _getRelativeDate(date) : '-'),
                                if (isNew) ...
                                  [
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green[600],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'NEW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                              ],
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    user['fullName'] ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    user['email'] ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    user['phone'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              isRegistration
                                  ? (user['registrationType']
                                                ?.toString()
                                                .toUpperCase() ==
                                            'LIFETIME'
                                        ? 'Gold'
                                        : (user['registrationType']
                                                      ?.toString()
                                                      .toUpperCase() ==
                                                  'YEARLY'
                                              ? 'Silver'
                                              : user['registrationType'] ??
                                                    '-'))
                                  : '-',
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: Text(
                                isRegistration
                                    ? '-'
                                    : (plan['segmentsName'] != null &&
                                              plan['segmentsName']
                                                  .toString()
                                                  .isNotEmpty
                                          ? "${plan['planName']} (${plan['segmentsName']})"
                                          : (plan['planName'] ?? '-')),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Builder(
                              builder: (context) {
                                final double basePaid = amountPaid / 1.18;
                                final double gstPaid = amountPaid - basePaid;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '₹${basePaid.toStringAsFixed(0)} + ₹${gstPaid.toStringAsFixed(0)} GST',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          DataCell(
                            _buildStatusChip(
                              payment['status'] ?? 'PENDING',
                              remaining: remaining,
                              installmentCount: history.length,
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.receipt_long,
                                color: AppTheme.primaryBlue,
                              ),
                              tooltip: 'View Invoice',
                              onPressed: () => _showInvoiceDialog(payment),
                            ),
                          ),
                          if (Get.find<AuthController>().user.value?.has('payments.bypass') ?? false)
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Button(
                                    title: "Details",
                                    buttonType: ButtonType.blue,
                                    size: ButtonSize.small,
                                    onTap: () =>
                                        _showDetailsDialog(payment, controller),
                                  ),
                                  if (controller.isAdmin) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          controller.showCorrectionDialog(payment),
                                      tooltip: "Correct Amount / Mode",
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tableCard,
          const SizedBox(height: 16),
          Text(
            "Showing ${controller.filteredPayments.length} of ${controller.totalPaymentsCount.value} records",
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (controller.hasMorePages.value) ...[
            const SizedBox(height: 16),
            Center(
              child: Button(
                title: controller.isLoading.value ? "Loading..." : "Load More",
                buttonType: ButtonType.blue,
                size: ButtonSize.small,
                onTap: controller.isLoading.value
                    ? null
                    : () => controller.fetchPendingTransfers(isLoadMore: true),
              ),
            ),
          ],
        ],
      );
    });
  }

  void _showImageDialog(List<String> urls) {
    if (urls.isEmpty) return;

    final currentPage = 0.obs;
    final pageController = PageController(initialPage: 0);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: Get.width * 0.8,
                maxHeight: Get.height * 0.8,
              ),
              color: Colors.black,
              child: PageView.builder(
                controller: pageController,
                itemCount: urls.length,
                onPageChanged: (index) => currentPage.value = index,
                itemBuilder: (context, index) {
                  return Image.network(
                    AppConfig.buildImageUrl(urls[index]),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        "Failed to load image",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (urls.length > 1) ...[
              // Left Arrow
              Obx(
                () => currentPage.value > 0
                    ? Positioned(
                      left: 20,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
              ),
              // Right Arrow
              Obx(
                () => currentPage.value < urls.length - 1
                    ? Positioned(
                      right: 20,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
              ),
              Positioned(
                bottom: 20,
                child: Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${currentPage.value + 1} / ${urls.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) => pageController.dispose());
  }

  void _showInstallmentsDialog(
    Map<String, dynamic> initialPayment,
    PendingBankTransfersController controller,
  ) {
    final RxMap<String, dynamic> livePayment =
        Map<String, dynamic>.from(initialPayment).obs;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final double initialDiscount = (livePayment['discount'] is num)
        ? (livePayment['discount'] as num).toDouble()
        : (double.tryParse(livePayment['discount']?.toString() ?? '0') ?? 0);
    final discountController = TextEditingController(
      text: initialDiscount > 0 ? initialDiscount.toStringAsFixed(0) : '',
    );
    final isDiscountApplied = RxBool(initialDiscount > 0);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: 1050,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Obx(() {
            final payment = livePayment;
            final List installments = payment['partialPaymentsHistory'] ?? [];
            final String intentId = payment['_id']?.toString() ?? '';
            final double planAmount = (payment['amount'] is num)
                ? (payment['amount'] as num).toDouble()
                : (double.tryParse(payment['amount']?.toString() ?? '0') ?? 0);
            final double discount = (payment['discount'] is num)
                ? (payment['discount'] as num).toDouble()
                : (double.tryParse(payment['discount']?.toString() ?? '0') ?? 0);

            // TARGET = The final amount to be paid (Original - Discount)
            final double target = planAmount - discount;
            final int originalDuration = (payment['originalDuration'] is num)
                ? (payment['originalDuration'] as num).toInt()
                : 365;

            // Logic extraction for header stats
            double totalApproved = 0;
            double currentPending = 0;
            for (var inst in installments) {
              final amt = (inst['amountPaid'] is num)
                  ? (inst['amountPaid'] as num).toDouble()
                  : (double.tryParse(inst['amountPaid']?.toString() ?? '0') ?? 0);
              if (inst['status'] == 'APPROVED') {
                totalApproved += amt;
              } else if (inst['status'] == 'PENDING' && currentPending == 0) {
                currentPending = amt;
              }
            }

            // For internal math (Days/1.5x math), we consider what HAS been paid + what IS pending
            final prospectiveTotal = totalApproved + currentPending;
            final isFullPaid =
                prospectiveTotal >= (target - 1); // Full paid check against Target

            final totalPaidDisplay = totalApproved;
            final remainingAmount = target - totalApproved;
            final wallet = (payment['walletBalance'] ?? 0);
            final applied = currentPending > 0 ? currentPending : totalApproved;

            // Check if the payment fully covers the remaining target amount in a single installment context
            // This removes the 1.5 penalty to match the backend logic for full payments.
            final double multiplier = isFullPaid ? 1.0 : 1.5;

            // Per Day Charge calculation based on the TARGET amount
            // Formula: (Target * multiplier) / originalDuration
            var perDayRaw =
                (target * multiplier) / (originalDuration > 0 ? originalDuration : 365);

            final double perDay = perDayRaw > 0 ? perDayRaw : 1.0;

            // Max days and granted days
            final granted = isFullPaid ? originalDuration : (applied / perDay).ceil();
            final max = isFullPaid ? originalDuration : (target / perDay).round();

            // Metadata extraction
            final Map<String, dynamic> user = (payment['userId'] is Map)
                ? payment['userId'] as Map<String, dynamic>
                : {};
            final Map<String, dynamic> plan = (payment['segmentPlanId'] is Map)
                ? payment['segmentPlanId'] as Map<String, dynamic>
                : {};
            final String pName = plan['planName']?.toString() ?? 'N/A';
            final String sName = plan['segmentsName']?.toString() ?? 'N/A';

            // User Level mapping (Robust check)
            final String regType = (user['registrationType'] ?? '')
                .toString()
                .toUpperCase();
            String level = 'Standard';
            if (regType.contains('LIFETIME'))
              level = 'Gold';
            else if (regType.contains('YEARLY'))
              level = 'Silver';

            final String? startStr = payment['serviceStartDate']?.toString();
            DateTime? startDate = (startStr != null && startStr.isNotEmpty)
                ? DateTime.tryParse(startStr)
                : null;

            if (startDate == null) {
              for (var inst in installments) {
                if (inst['status'] == 'APPROVED' ||
                    inst['status'] == 'PARTIAL-PAID' ||
                    inst['status'] == 'PAID') {
                  final dtStr =
                      inst['transactionDate']?.toString() ??
                      inst['updatedAt']?.toString() ??
                      inst['createdAt']?.toString();
                  if (dtStr != null) {
                    startDate = DateTime.tryParse(dtStr);
                    break;
                  }
                }
              }
              // For pending payments, default to today's date if no approved installments found
              startDate ??= DateTime.now();
            }

            final String sDateDisplay = startDate != null
                ? _formatToIST(startDate, 'dd MMM yyyy')
                : 'Yet to be activated';

            final String? expiryStr = payment['currentExpiryDate']?.toString();
            DateTime? expiryDate = (expiryStr != null && expiryStr.isNotEmpty)
                ? DateTime.tryParse(expiryStr)
                : null;

            if (expiryDate == null && startDate != null) {
              expiryDate = startDate.add(Duration(days: granted.toInt()));
            }

            final String eDateDisplay = expiryDate != null
                ? _formatToIST(expiryDate, 'dd MMM yyyy')
                : 'N/A';

            DateTime? date;
            if (installments.isNotEmpty) {
              final histDtStr = installments.last['transactionDate']?.toString();
              if (histDtStr != null) date = DateTime.tryParse(histDtStr);
            }
            if (date == null) {
              final dtStr = payment['transactionDate']?.toString();
              if (dtStr != null) date = DateTime.tryParse(dtStr);
            }
            if (date == null) {
              date = DateTime.tryParse(payment['createdAt'] ?? '');
            }
            final String tDateDisplay = date != null
                ? _formatToIST(date, 'dd MMM yyyy')
                : '-';

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  color: AppTheme.primaryBlue,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Manage Installments",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Stats Section
                          Row(
                            children: [
                              _buildStatCard(
                                "Total Paid",
                                "₹${totalPaidDisplay.toStringAsFixed(0)}",
                                Icons.payments_outlined,
                                Colors.green,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                "Remaining Amount",
                                "₹${remainingAmount < 0 ? 0 : remainingAmount.toStringAsFixed(0)}",
                                Icons.assignment_turned_in_outlined,
                                AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 16),
                              _buildStatCard(
                                "Advance Wallet",
                                "₹$wallet",
                                Icons.account_balance_wallet_outlined,
                                Colors.orange,
                              ),
                              if (!(payment['purchaseType'] == 'REGISTRATION' ||
                                  pName.toLowerCase().contains(
                                    'registration',
                                  ))) ...[
                                const SizedBox(width: 16),
                                _buildStatCard(
                                  "Progress",
                                  "$granted / $max Days",
                                  Icons.timer_outlined,
                                  Colors.purple,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 32),

                          // User Details Section
                          const Text(
                            "User Details",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50]?.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Full Name",
                                        user['fullName'] ?? '-',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Phone No.",
                                        user['phone'] ?? '-',
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Email ID",
                                        user['email'] ?? '-',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Subscription Details",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              if (payment['purchaseType'] != 'REGISTRATION' && controller.isAdmin)
                                TextButton.icon(
                                  icon: Icon(Icons.edit, size: 14, color: Colors.blue),
                                  label: Text("Edit Plan/Dates", style: TextStyle(fontSize: 12, color: Colors.blue)),
                                  onPressed: () {
                                    Get.back();
                                    controller.showSubscriptionCorrectionDialog(payment);
                                  },
                                ),

                            ],
                          ),

                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50]?.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem("Plan Name", pName),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem("Segment", sName),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem("User Level", level),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Transaction Date",
                                        tDateDisplay,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Service Start Date",
                                        sDateDisplay,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Current Expiry Date",
                                        eDateDisplay,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Detailed Info Grid
                          const Text(
                            "Plan Configuration",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        payment['purchaseType'] == 'REGISTRATION'
                                            ? "Registration Amount (X)"
                                            : "Plan Amount (X)",
                                        "₹${(planAmount / 1.18).toStringAsFixed(2)}",
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Total Target",
                                        "₹${target.toStringAsFixed(0)}",
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Per Day Charge",
                                        "₹${perDay.toStringAsFixed(2)}",
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 32),
                                const Text(
                                  "Price Breakdown (Formula: Total / 1.18 for Base, then 9% CGST & SGST)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        "Taxable Amount",
                                        "₹${(target / 1.18).toStringAsFixed(2)}",
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        "CGST (9%)",
                                        "₹${((target - (target / 1.18)) / 2).toStringAsFixed(2)}",
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        "SGST (9%)",
                                        "₹${((target - (target / 1.18)) / 2).toStringAsFixed(2)}",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Verification Settings
                          const Text(
                            "Verification Settings",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Form(
                            key: formKey,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50]?.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[100]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "Manage discounts below. Remarks will be collected in a separate popup during approval.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 250,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: discountController,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  "Additional Discount (₹)",
                                              hintText: "Amount in Rs",
                                              border: OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          height: 40,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final double disc =
                                                  double.tryParse(
                                                    discountController.text,
                                                  ) ??
                                                  0;
                                              final success = await controller
                                                  .updateDiscount(
                                                    payment['_id']
                                                            ?.toString() ??
                                                        '',
                                                    disc,
                                                  );
                                              if (success) {
                                                isDiscountApplied.value =
                                                    disc > 0;
                                                livePayment['discount'] = disc;
                                                livePayment.refresh();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  isDiscountApplied.value
                                                  ? Colors.blue
                                                  : Colors.green,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                            ),
                                            child: Text(
                                              isDiscountApplied.value
                                                  ? "EDIT"
                                                  : "ADD",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // History Table Header
                          const Text(
                            "Installment History",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                width: constraints.maxWidth,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LayoutBuilder(
                                    builder: (context, tableConstraints) {
                                      final installmentScrollController = ScrollController();
                                      return Scrollbar(
                                        controller: installmentScrollController,
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          controller: installmentScrollController,
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: tableConstraints.maxWidth,
                                            ),
                                            child: DataTable(
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                              Colors.grey[100],
                                            ),
                                        columnSpacing: 12,
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              'Date',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Amount',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'UTR',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Proof',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Remark',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Status',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Action',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: installments.reversed.toList().map((inst) {
                                          final isPending =
                                              inst['status'] == 'PENDING';
                                          final date = DateTime.tryParse(
                                            inst['transactionDate'] ?? '',
                                          );
                                          final proof = inst['proofImage'];

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  date != null
                                                      ? _formatToIST(
                                                          date,
                                                          'dd MMM yyyy',
                                                        )
                                                      : '-',
                                                ),
                                              ),
                                              DataCell(
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '₹${(inst['amountPaid'] / 1.18).toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      'GST: ₹${(inst['amountPaid'] - (inst['amountPaid'] / 1.18)).toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Total: ₹${inst['amountPaid']}',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    inst['utrNumber'] ?? '-',
                                                    style: const TextStyle(fontSize: 12),
                                                    softWrap: true,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                (inst['proofImages'] != null &&
                                                            (inst['proofImages']
                                                                    as List)
                                                                .isNotEmpty) ||
                                                        proof != null
                                                    ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.image,
                                                              size: 20,
                                                              color: AppTheme
                                                                  .primaryBlue,
                                                            ),
                                                            onPressed: () {
                                                              List<String> urls =
                                                                  [];
                                                              if (inst['proofImages'] != null && (inst['proofImages'] as List).isNotEmpty) {
                                                                urls = (inst['proofImages'] as List).map((e) {
                                                                  final raw = e.toString();
                                                                  final parsed = AppConfig.buildImageUrl(raw);
                                                                  return parsed;
                                                                }).toList();
                                                              } else if (proof != null) {
                                                                final raw = proof.toString();
                                                                final parsed = AppConfig.buildImageUrl(raw);
                                                                urls = [parsed];
                                                              }
                                                              _showImageDialog(
                                                                urls,
                                                              );
                                                            },
                                                          ),
                                                          if (inst['proofImages'] !=
                                                                  null &&
                                                              (inst['proofImages']
                                                                          as List)
                                                                      .length >
                                                                  1)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    4,
                                                                  ),
                                                              decoration:
                                                                  BoxDecoration(
                                                                    color: AppTheme
                                                                        .primaryBlue,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                              child: Text(
                                                                "${(inst['proofImages'] as List).length}",
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      )
                                                    : const Text('-'),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 100,
                                                  child: Text(
                                                    inst['note'] ?? '-',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                _buildStatusChip(inst['status']),
                                              ),
                                              DataCell(
                                                isPending
                                                    ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Button(
                                                            title: "Approve",
                                                            buttonType:
                                                                ButtonType.green,
                                                            size:
                                                                ButtonSize.small,
                                                            onTap: () {
                                                              _showRemarkPopup(
                                                                intentId:
                                                                    intentId,
                                                                historyId:
                                                                    inst['_id']
                                                                        ?.toString(),
                                                                controller:
                                                                    controller,
                                                                payment: livePayment,
                                                              );
                                                            },
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Button(
                                                            title: controller.isLoading.value ? "..." : "Reject",
                                                            buttonType:
                                                                ButtonType.red,
                                                            size:
                                                                ButtonSize.small,
                                                            onTap: controller.isLoading.value ? () {} : () {
                                                              _showRevertConfirmation(
                                                                title: "Reject Installment?",
                                                                message: "Are you sure you want to reject this installment?",
                                                                onConfirm: (remark) async {
                                                                  final success = await controller.rejectPartialInstallment(
                                                                    intentId,
                                                                    inst['_id']?.toString() ?? '',
                                                                  );
                                                                  if (success) {
                                                                    final List history = List.from(livePayment['partialPaymentsHistory'] ?? []);
                                                                    final int idx = history.indexWhere((h) => h['_id']?.toString() == inst['_id']?.toString());
                                                                    if (idx != -1) {
                                                                      history[idx]['status'] = 'REJECTED';
                                                                      livePayment['partialPaymentsHistory'] = history;
                                                                      livePayment.refresh();
                                                                    }
                                                                  }
                                                                },
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      )
                                                    : Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            inst['status'] ==
                                                                    'APPROVED'
                                                                ? Icons
                                                                    .check_circle
                                                                : Icons.cancel,
                                                            color: inst['status'] ==
                                                                    'APPROVED'
                                                                ? Colors.green
                                                                : Colors.red,
                                                            size: 20,
                                                          ),
                                                          if (controller.isAdmin) ...[
                                                            const SizedBox(
                                                                width: 8),
                                                            if (inst['status'] ==
                                                                'APPROVED')
                                                              Button(
                                                                title: controller.isLoading.value ? "..." : "REVERT",
                                                                buttonType:
                                                                    ButtonType
                                                                        .red,
                                                                size: ButtonSize
                                                                    .small,
                                                                onTap: controller.isLoading.value ? () {} : () {
                                                                  _showRevertConfirmation(
                                                                    title:
                                                                        "Revert Approval?",
                                                                    message:
                                                                        "This will REJECT this installment and REVERT associated data.",
                                                                    onConfirm:
                                                                        (reason) async {
                                                                      Get.back();
                                                                      final success = await controller
                                                                          .revertApprovalAction(
                                                                              intentId,
                                                                              historyId: inst['_id']?.toString(),
                                                                              reason: reason);
                                                                      if (success) {
                                                                        final List history = List.from(livePayment['partialPaymentsHistory'] ?? []);
                                                                        final int idx = history.indexWhere((h) => h['_id']?.toString() == inst['_id']?.toString());
                                                                        if (idx != -1) {
                                                                          history[idx]['status'] = 'REJECTED';
                                                                          livePayment['partialPaymentsHistory'] = history;
                                                                          livePayment.refresh();
                                                                        }
                                                                      }
                                                                    },
                                                                  );
                                                                },
                                                              ),
                                                            if (inst['status'] ==
                                                                'REJECTED')
                                                              Button(
                                                                title: controller.isLoading.value ? "..." : "RESTORE",
                                                                buttonType:
                                                                    ButtonType
                                                                        .green,
                                                                size: ButtonSize
                                                                    .small,
                                                                onTap: controller.isLoading.value ? () {} : () {
                                                                  _showRevertConfirmation(
                                                                    title:
                                                                        "Restore Installment?",
                                                                    message:
                                                                        "This will restore this installment to APPROVED state.",
                                                                    onConfirm:
                                                                        (reason) async {
                                                                      Get.back();
                                                                      final success = await controller
                                                                          .revertRejectionAction(
                                                                              intentId,
                                                                              historyId: inst['_id']
                                                                                  ?.toString(),
                                                                              reason: reason);
                                                                      if (success) {
                                                                        final List history = List.from(livePayment['partialPaymentsHistory'] ?? []);
                                                                        final int idx = history.indexWhere((h) => h['_id']?.toString() == inst['_id']?.toString());
                                                                        if (idx != -1) {
                                                                          history[idx]['status'] = 'APPROVED';
                                                                          livePayment['partialPaymentsHistory'] = history;
                                                                          livePayment.refresh();
                                                                        }
                                                                      }
                                                                    },
                                                                    confirmColor:
                                                                        Colors
                                                                            .green,
                                                                  );
                                                                },
                                                              ),
                                                          ],
                                                        ],
                                                      ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                          if (installments.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  "No installments uploaded yet",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text("CORRECT FINANCIALS"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange[800],
                                side: BorderSide(color: Colors.orange[800]!),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: () {
                                Get.back();
                                controller.showCorrectionDialog(payment);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showRemarkPopup({
    required String intentId,
    String? historyId,
    bool isFullPayment = false,
    required PendingBankTransfersController controller,
    double? discount,
    required Map<String, dynamic> payment,
  }) {
    final TextEditingController remarkController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Approval Confirmation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please enter a mandatory remark for this approval:",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarkController,
              decoration: const InputDecoration(
                hintText: "Reason for approval...",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (remarkController.text.trim().isEmpty) {
                Get.snackbar("Error", "Remark is mandatory");
                return;
              }
              Get.back(); // close remark popup

              if (isFullPayment) {
                Get.back(); // close main details dialog
                controller.approveTransfer(
                  payment,
                  remark: remarkController.text.trim(),
                  discount: discount,
                );
              } else {
                final success = await controller.approvePartialInstallment(
                  intentId,
                  historyId!,
                  remark: remarkController.text.trim(),
                  discount: discount,
                );
                if (success) {
                  final List history = List.from(payment['partialPaymentsHistory'] ?? []);
                  final int idx = history.indexWhere((h) => h['_id']?.toString() == historyId);
                  if (idx != -1) {
                    history[idx]['status'] = 'APPROVED';
                    payment['partialPaymentsHistory'] = history;
                    if (payment is RxMap) {
                      (payment as dynamic).refresh();
                    }
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Approve Now"),
          ),
        ],
      ),
    );
  }

  void _showRevertConfirmation({
    required String title,
    required String message,
    required Function(String reason) onConfirm,
    Color confirmColor = Colors.red,
  }) {
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Text(
              "Reason for revert (Internal audit):",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Enter reason...",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar("Error", "Reason is mandatory for internal audit");
                return;
              }
              final reason = reasonController.text.trim();
              Get.back();
              onConfirm(reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusChip(
    String status, {
    double? remaining,
    int? installmentCount,
  }) {
    Color color;
    String label = status;

    // A single installment that clears the balance (including discount) is a FULL Activation (365 days).
    // Multiple installments that clear the balance is still a PARTIAL Activation process.
    bool isFullyPaidSingle =
        remaining != null && remaining <= 0 && (installmentCount ?? 0) <= 1;
    bool isFullyPaidMulti =
        remaining != null && remaining <= 0 && (installmentCount ?? 0) > 1;

    switch (status.toUpperCase()) {
      case 'PAID':
      case 'APPROVED':
        color = Colors.green;
        label = 'Completed';
        break;
      case 'PARTIAL-PAID':
      case 'PARTIAL':
        if (isFullyPaidSingle) {
          color = Colors.green;
          label = 'Completed';
        } else if (isFullyPaidMulti) {
          color = Colors.purple;
          label = 'Partial (Paid)';
        } else {
          color = Colors.purple;
          label = 'Partial';
        }
        break;
      case 'VERIFICATION_PENDING':
      case 'PENDING':
        color = Colors.orange;
        label = 'Pending Approval';
        break;
      case 'REJECTED':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getRelativeDate(DateTime date) {
    // Ensure we are working with IST (UTC + 5:30)
    final dateIst = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateIst);
  }

  String _formatToIST(DateTime? date, String pattern) {
    if (date == null) return '-';
    final istDate = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat(pattern).format(istDate);
  }

  void _showDetailsDialog(
    Map<String, dynamic> payment,
    PendingBankTransfersController controller,
  ) {
    if (payment['isPartial'] == true) {
      _showInstallmentsDialog(payment, controller);
      return;
    }

    final proofUrl = payment['paymentProof'] ?? payment['paymentScreenshot'];
    final List<String> paymentProofs =
        (payment['paymentProofs'] != null &&
            (payment['paymentProofs'] as List).isNotEmpty)
        ? (payment['paymentProofs'] as List).map((e) => AppConfig.buildImageUrl(e.toString())).toList()
        : (proofUrl != null ? [AppConfig.buildImageUrl(proofUrl.toString())] : []);
    final Map<String, dynamic> user = (payment['userId'] is Map)
        ? payment['userId'] as Map<String, dynamic>
        : {};
    final Map<String, dynamic> plan = (payment['segmentPlanId'] is Map)
        ? payment['segmentPlanId'] as Map<String, dynamic>
        : {};
    final String status = payment['status']?.toString() ?? '';
    final String intentId = payment['_id']?.toString() ?? '';

    // Financial Extraction (Consistent with premium partial logic)
    final double planAmount = (payment['amount'] is num)
        ? (payment['amount'] as num).toDouble()
        : (double.tryParse(payment['amount']?.toString() ?? '0') ?? 0);
    final double discount = (payment['discount'] is num)
        ? (payment['discount'] as num).toDouble()
        : (double.tryParse(payment['discount']?.toString() ?? '0') ?? 0);
    final double amountPaid = (payment['amountPaid'] is num)
        ? (payment['amountPaid'] as num).toDouble()
        : (double.tryParse(payment['amountPaid']?.toString() ?? '0') ?? 0);

    // TARGET = The final amount to be paid (Original - Discount)
    final double target = planAmount - discount;
    final int originalDuration = (payment['originalDuration'] is num)
        ? (payment['originalDuration'] as num).toInt()
        : (payment['purchaseType'] == 'REGISTRATION' ? 3650 : 365);

    final double remainingAmount = target - amountPaid;
    final double wallet = (payment['walletBalance'] ?? 0).toDouble();

    // Metadata extraction
    final String pName = plan['planName']?.toString() ?? 'N/A';
    final String sName = plan['segmentsName']?.toString() ?? 'N/A';
    final String regType = (user['registrationType'] ?? '')
        .toString()
        .toUpperCase();
    String level = 'Standard';
    if (regType.contains('LIFETIME'))
      level = 'Gold';
    else if (regType.contains('YEARLY'))
      level = 'Silver';

    // Date Logic
    final String? startStr = payment['serviceStartDate']?.toString();
    DateTime? startDate = (startStr != null && startStr.isNotEmpty)
        ? DateTime.tryParse(startStr)
        : null;

    final history = payment['partialPaymentsHistory'] as List? ?? [];
    if (startDate == null) {
      for (var inst in history) {
        if (inst['status'] == 'APPROVED' ||
            inst['status'] == 'PARTIAL-PAID' ||
            inst['status'] == 'PAID') {
          final dtStr =
              inst['transactionDate']?.toString() ??
              inst['updatedAt']?.toString() ??
              inst['createdAt']?.toString();
          if (dtStr != null) {
            startDate = DateTime.tryParse(dtStr);
            break;
          }
        }
      }
      // For pending payments, default to today's date if no approved installments found
      startDate ??= DateTime.now();
    }

    final String sDateDisplay = startDate != null
        ? _formatToIST(startDate, 'dd MMM yyyy')
        : 'Yet to be activated';

    final String? expiryStr = payment['currentExpiryDate']?.toString();
    DateTime? expiryDate = (expiryStr != null && expiryStr.isNotEmpty)
        ? DateTime.tryParse(expiryStr)
        : null;

    if (expiryDate == null && startDate != null) {
      // For direct/full payments, calculate expiry based on originalDuration
      expiryDate = startDate.add(Duration(days: originalDuration));
    }

    final String eDateDisplay = expiryDate != null
        ? _formatToIST(expiryDate, 'dd MMM yyyy')
        : 'N/A';

    DateTime? date;
    if (history.isNotEmpty) {
      final histDtStr = history.last['transactionDate']?.toString();
      if (histDtStr != null) date = DateTime.tryParse(histDtStr);
    }
    if (date == null) {
      final dtStr = payment['transactionDate']?.toString();
      if (dtStr != null) date = DateTime.tryParse(dtStr);
    }
    if (date == null) {
      date = DateTime.tryParse(payment['createdAt'] ?? '');
    }
    final String tDateDisplay = date != null
        ? _formatToIST(date, 'dd MMM yyyy')
        : '-';

    // Discount Controller setup
    final discountController = TextEditingController(
      text: discount > 0 ? discount.toStringAsFixed(0) : '',
    );
    final isDiscountApplied = RxBool(discount > 0);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: 1050, // Matching partial dialog width for consistency
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                color: AppTheme.primaryBlue,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Payment Verification",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Section (Premium layout)
                        Row(
                          children: [
                            _buildStatCard(
                              "Amount Paid",
                              "₹${amountPaid.toStringAsFixed(0)}",
                              Icons.payments_outlined,
                              Colors.green,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              "Remaining Amount",
                              "₹${remainingAmount < 0 ? 0 : remainingAmount.toStringAsFixed(0)}",
                              Icons.assignment_turned_in_outlined,
                              AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              "Advance Wallet",
                              "₹${wallet.toStringAsFixed(0)}",
                              Icons.account_balance_wallet_outlined,
                              Colors.orange,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // User Details Section
                        const Text(
                          "User Details",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50]?.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Full Name",
                                      user['fullName'] ?? '-',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Phone No.",
                                      user['phone'] ?? '-',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Email ID",
                                      user['email'] ?? '-',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Subscription Details",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            if (payment['purchaseType'] != 'REGISTRATION' && controller.isAdmin)
                              TextButton.icon(
                                icon: Icon(Icons.edit, size: 14, color: Colors.blue),
                                label: Text("Edit Plan/Dates", style: TextStyle(fontSize: 12, color: Colors.blue)),
                                onPressed: () {
                                  Get.back();
                                  controller.showSubscriptionCorrectionDialog(payment);
                                },
                              ),

                          ],
                        ),

                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50]?.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem("Plan Name", pName),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem("Segment", sName),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem("User Level", level),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Transaction Date",
                                      tDateDisplay,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Service Start Date",
                                      sDateDisplay,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Current Expiry Date",
                                      eDateDisplay,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Plan Configuration (Price vs Target)
                        const Text(
                          "Plan Configuration",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      payment['purchaseType'] == 'REGISTRATION'
                                          ? "Registration Amount (X)"
                                          : "Plan Amount (X)",
                                      "₹${(planAmount / 1.18).toStringAsFixed(2)}",
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Target Amount",
                                      "₹${target.toStringAsFixed(0)}",
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const Divider(height: 32),
                              const Text(
                                "Price Breakdown (Formula: Total / 1.18 for Base, then 9% CGST & SGST)",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      "Taxable Amount",
                                      "₹${(target / 1.18).toStringAsFixed(2)}",
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      "CGST (9%)",
                                      "₹${((target - (target / 1.18)) / 2).toStringAsFixed(2)}",
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      "SGST (9%)",
                                      "₹${((target - (target / 1.18)) / 2).toStringAsFixed(2)}",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Verification / Discount Settings
                        const Text(
                          "Verification Settings",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50]?.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[100]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "Manage discounts if any. Remarks will be required during final approval.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 250,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: discountController,
                                        decoration: const InputDecoration(
                                          labelText: "Discount (₹)",
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Obx(
                                      () => SizedBox(
                                        height: 40,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final double disc =
                                                double.tryParse(
                                                  discountController.text,
                                                ) ??
                                                0;
                                            final success = await controller
                                                .updateDiscount(intentId, disc);
                                            if (success) {
                                              isDiscountApplied.value =
                                                  disc > 0;
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                isDiscountApplied.value
                                                ? Colors.blue
                                                : Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text(
                                            isDiscountApplied.value
                                                ? "EDIT"
                                                : "ADD",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // User Details & Proof
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Transaction Info",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _detailRow(
                                          "Full Name",
                                          user['fullName'] ?? '-',
                                        ),
                                        const Divider(),
                                        _detailRow(
                                          "Phone No.",
                                          user['phone'] ?? '-',
                                        ),
                                        const Divider(),
                                        _detailRow(
                                          "Transaction Date",
                                          tDateDisplay,
                                        ),
                                        const Divider(),
                                        _detailRow(
                                          "UTR / Ref ID",
                                          payment['utrNumber'] ?? '-',
                                          isBold: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Payment Proofs",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (paymentProofs.length > 1)
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showImageDialog(paymentProofs),
                                          icon: const Icon(
                                            Icons.collections,
                                            size: 16,
                                          ),
                                          label: Text(
                                            "View All (${paymentProofs.length})",
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () {
                                      if (paymentProofs.isNotEmpty)
                                        _showImageDialog(paymentProofs);
                                    },
                                    child: Container(
                                      height: 160,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        image: paymentProofs.isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                  AppConfig.buildImageUrl(paymentProofs.first),
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: paymentProofs.isEmpty
                                          ? const Center(
                                              child: Icon(
                                                Icons
                                                    .image_not_supported_outlined,
                                                color: Colors.grey,
                                              ),
                                            )
                                          : (paymentProofs.length > 1
                                                ? Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        "+${paymentProofs.length - 1} more",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : null),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Actions
                        if (status != 'PAID' && status != 'REJECTED') ...[
                          Row(
                            children: [
                              Expanded(
                                child: Obx(() => Button(
                                    title: controller.isLoading.value ? "Processing..." : "Approve & Activate",
                                    buttonType: ButtonType.green,
                                    onTap: controller.isLoading.value ? () {} : () {
                                      _showRemarkPopup(
                                        intentId: intentId,
                                        controller: controller,
                                        isFullPayment: true,
                                        payment: payment,
                                        discount:
                                            double.tryParse(
                                              discountController.text,
                                            ) ??
                                            0,
                                      );
                                    },
                                  )),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Obx(() => Button(
                                    title: controller.isLoading.value ? "Processing..." : "Reject Transaction",
                                    buttonType: ButtonType.red,
                                    onTap: controller.isLoading.value ? () {} : () {
                                      Get.back();
                                      controller.rejectTransfer(payment);
                                    },
                                  )),
                              ),
                            ],
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'PAID'
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (status == 'PAID'
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      status == 'PAID'
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: status == 'PAID'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      status == 'PAID'
                                          ? "PAYMENT APPROVED"
                                          : "PAYMENT REJECTED",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: status == 'PAID'
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                                if (payment['notes'] != null &&
                                    payment['notes']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    payment['notes'].toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (controller.isAdmin) ...[
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  if (status == 'PAID')
                                    SizedBox(
                                      width: double.infinity,
                                      child: Obx(() => Button(
                                        title: controller.isLoading.value ? "Processing..." : "REVERT TO REJECTED",
                                        buttonType: ButtonType.red,
                                        onTap: controller.isLoading.value ? () {} : () {
                                          _showRevertConfirmation(
                                            title: "Revert Approval?",
                                            message:
                                                "This will REJECT the payment and DELETE all created entitlements, invoices, and plan purchases. The user will lose access immediately.",
                                            onConfirm: (reason) {
                                              Get.back(); // close dialog
                                              controller.revertApprovalAction(
                                                  intentId,
                                                  reason: reason);
                                            },
                                          );
                                        },
                                      )),
                                    ),
                                  if (status == 'REJECTED')
                                    SizedBox(
                                      width: double.infinity,
                                      child: Obx(() => Button(
                                        title: controller.isLoading.value ? "Processing..." : "REVERT TO APPROVED",
                                        buttonType: ButtonType.green,
                                        onTap: controller.isLoading.value ? () {} : () {
                                          _showRevertConfirmation(
                                            title: "Restore & Approve?",
                                            message:
                                                "This will RESTORE the payment to Approved state and RECREATE all entitlements and invoices.",
                                            onConfirm: (reason) {
                                              Get.back(); // close dialog
                                              controller.revertRejectionAction(
                                                  intentId,
                                                  historyId: null,
                                                  reason: reason);
                                            },
                                            confirmColor: Colors.green,
                                          );
                                        },
                                      )),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("CORRECT FINANCIALS"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[800],
                              side: BorderSide(color: Colors.orange[800]!),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Get.back();
                              controller.showCorrectionDialog(payment);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppTheme.primaryBlue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycTab(PendingBankTransfersController controller) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.gray200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: controller.kycSearchController,
                        onChanged: (value) {
                          controller.kycSearchQuery.value = value;
                          controller.applyKycFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone',
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppTheme.gray300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppTheme.gray300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppTheme.primaryBlue),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Filter
                    Expanded(
                      child: Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.gray300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: controller.kycStatusFilter.value,
                              isExpanded: true,
                              items:
                                  [
                                    'All',
                                    'Verified',
                                    'Rejected',
                                    'Waiting_for_review',
                                    'In_progress',
                                    'Not_started',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  controller.kycStatusFilter.value = newValue;
                                  controller.applyKycFilters();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Reset Button
                    Button(
                      title: 'Reset',
                      buttonType: ButtonType.grey,
                      icon: Icons.refresh,
                      size: ButtonSize.small,
                      onTap: controller.resetKycFilters,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Data Section
          Obx(() {
            if (controller.isLoading.value &&
                controller.pendingKycUsers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (controller.pendingKycUsers.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("No pending KYC approvals found."),
                ),
              );
            }

            return Column(
              children: [
                // Table
                _buildKycTable(controller),
                const SizedBox(height: 16),
                Text(
                  "Showing ${controller.filteredKycUsers.length} of ${controller.totalKycCount.value} records",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKycTable(PendingBankTransfersController controller) {
    return Obx(() {
      if (controller.filteredKycUsers.isEmpty) {
        return const Center(
          child: Text("No users match the selected filters."),
        );
      }

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.gray200),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scrollController = ScrollController();
            return Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    dataRowHeight: 80,
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    headingRowColor: MaterialStateProperty.all(AppTheme.gray50),
                    columns: const [
                      DataColumn(label: Text('Date Joined')),
                      DataColumn(label: Text('User ID')),
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('PAN Card')),
                      DataColumn(label: Text('KYC Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: controller.filteredKycUsers.map((user) {
                      final date = DateTime.tryParse(user.createdAt);
                      final status = user.kycStatus ?? 'PENDING';

                      Color statusColor;
                      Color statusBgColor;

                      switch (status.toUpperCase()) {
                        case 'VERIFIED':
                        case 'APPROVED':
                          statusColor = Colors.green[800]!;
                          statusBgColor = Colors.green[100]!;
                          break;
                        case 'REJECTED':
                          statusColor = Colors.red[800]!;
                          statusBgColor = Colors.red[100]!;
                          break;
                        case 'WAITING_FOR_REVIEW':
                          statusColor = Colors.blue[800]!;
                          statusBgColor = Colors.blue[100]!;
                          break;
                        default:
                          statusColor = Colors.orange[800]!;
                          statusBgColor = Colors.orange[100]!;
                      }

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              date != null
                                  ? _formatToIST(date, 'yyyy-MM-dd')
                                  : '-',
                            ),
                          ),
                          DataCell(Text(user.userId ?? '-')),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(user.formattedPhone)),
                          DataCell(Text(user.panCard ?? '-')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Button(
                                  title: "View Details",
                                  buttonType: ButtonType.blue,
                                  size: ButtonSize.small,
                                  onTap: () => Get.toNamed('/users/${user.id}'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  String _fmt(double val) => "₹${NumberFormat('#,##,###.##').format(val)}";

  void _showInvoiceDialog(Map<String, dynamic> payment) {
    final user = payment['userId'] ?? {};
    final planData = payment['segmentPlanId'];
    final Map<String, dynamic> plan = (planData is Map)
        ? Map<String, dynamic>.from(planData)
        : {};
    final isRegistration = payment['purchaseType'] == 'REGISTRATION';

    final List<dynamic> history = (payment['partialPaymentsHistory'] is List)
        ? (payment['partialPaymentsHistory'] as List<dynamic>)
            .where((e) => e['status'] != 'REJECTED')
            .toList()
        : [];
        
    final double amountPaid = history.isEmpty 
        ? (payment['status'] == 'REJECTED' ? 0.0 : _toDouble(payment['amountPaid']))
        : history.fold(0.0, (sum, item) => sum + _toDouble(item['amountPaid'] ?? item['amount']));

    final double totalAmount = _toDouble(payment['amount']);
    final double discount = _toDouble(payment['discount']);
    final double remaining = totalAmount - discount - amountPaid;
    
    final bool isPartial = payment['isPartial'] == true;

    String planNameDisplay = isRegistration
        ? (user['registrationType']?.toString().toUpperCase() == 'LIFETIME'
              ? 'Gold Registration'
              : 'Silver Registration')
        : (plan['segmentsName'] != null &&
                  plan['segmentsName'].toString().isNotEmpty
              ? "${plan['planName']} (${plan['segmentsName']})"
              : (plan['planName'] ?? 'Subscription'));

    final date =
        DateTime.tryParse(payment['createdAt'] ?? '') ?? DateTime.now();
    final String rawInvoice =
        payment['invoiceNumber']?.toString() ??
        payment['invoiceNo']?.toString() ??
        (payment['_id'] ?? '').toString();
    final invoiceNo = _formatInvoiceNumber(rawInvoice);
    final String paymentModeDisplay = _formatPaymentMode(
      payment['paymentMethod']?.toString() ??
          payment['paymentMode']?.toString() ??
          'BANK_TRANSFER',
    );

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 800,
          constraints: BoxConstraints(maxHeight: Get.height * 0.9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header actions
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Official Invoice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf),
                          tooltip: 'Download / Print PDF',
                          onPressed: () =>
                              InvoicePdfGenerator.printInvoice(payment),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Invoice Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Branding & Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SP RESEARCHVIA',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xff163174),
                                ),
                              ),
                              const Text(
                                'PRIVATE LIMITED',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff163174),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '129 A, Kalani Bagh, AB Road\nDewas, MP - 455001\ninfo@researchvia.in\nwww.researchvia.in',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'GSTIN: 23ABMCS3444G1ZC',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'SEBI REG: INH000015808',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'CIN: U73200MP2023PTC069041',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'BSE Enlistment no. : 6120',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'INVOICE',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _invoiceMetaRow('Invoice No:', invoiceNo),
                              _invoiceMetaRow(
                                'Date:',
                                _formatToIST(date, 'dd MMM yyyy'),
                              ),
                              _invoiceMetaRow(
                                'Status:',
                                payment['status']?.toString().toUpperCase() ==
                                        'REJECTED'
                                    ? 'REJECTED'
                                    : (remaining <= 0 ? 'PAID' : 'PARTIALLY PAID'),
                                valueColor: payment['status']
                                            ?.toString()
                                            .toUpperCase() ==
                                        'REJECTED'
                                    ? Colors.red
                                    : (remaining <= 0
                                        ? Colors.green
                                        : Colors.orange),
                              ),
                              _invoiceMetaRow(
                                'Payment Mode:',
                                paymentModeDisplay,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Client Information
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'BILL TO',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user['fullName'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user['phone'] ?? '-',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  user['email'] ?? '-',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Service Table
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(1.5),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: const Color(0xff163174).withOpacity(0.05),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'DESCRIPTION',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'BREAKDOWN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'AMOUNT',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      planNameDisplay,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isPartial && remaining > 0)
                                      const Text(
                                        '(Partial Payment Plan)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: const Text(
                                  'Subtotal (Base):',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _fmt(totalAmount / 1.18),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              const SizedBox(),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: const Text(
                                  'CGST (9%):',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _fmt(
                                    (totalAmount - (totalAmount / 1.18)) / 2,
                                  ),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              const SizedBox(),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: const Text(
                                  'SGST (9%):',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _fmt(
                                    (totalAmount - (totalAmount / 1.18)) / 2,
                                  ),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          if (discount > 0)
                            TableRow(
                              children: [
                                const SizedBox(),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: const Text(
                                    'Discount:',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    '-${_fmt(discount)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          TableRow(
                            children: [
                              const SizedBox(),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: const Text(
                                  'Total Payable:',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _fmt(totalAmount - discount),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              const SizedBox(),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: const Text(
                                  'Amount Paid:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  _fmt(amountPaid),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (remaining > 0)
                            TableRow(
                              children: [
                                const SizedBox(),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: const Text(
                                    'Balance Due:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    _fmt(remaining),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Installment History (if partial)
                      if (isPartial && history.isNotEmpty) ...[
                        const Text(
                          'INSTALLMENT HISTORY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff163174),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2.5),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(1.5),
                          },
                          border: TableBorder(
                            horizontalInside: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                          ),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color(0xff163174).withOpacity(0.05),
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'DATE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'BREAKDOWN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'AMOUNT',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ...history.asMap().entries.expand((entry) {
                              final idx = entry.key;
                              final inst = entry.value;
                              final instAmount = _toDouble(inst['amountPaid']);
                              final instDate = DateTime.tryParse(
                                    inst['transactionDate'] ?? '',
                                  ) ??
                                  DateTime.now();
                              final String dateStr =
                                  "${idx + 1}. ${_formatToIST(instDate, 'dd MMM yyyy')}";

                              return [
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        dateStr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'Subtotal (Base):',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        _fmt(instAmount / 1.18),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const SizedBox(),
                                    const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'GST:',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        _fmt(
                                          instAmount - (instAmount / 1.18),
                                        ),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const SizedBox(),
                                    const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'Total Paid:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Text(
                                        _fmt(instAmount),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ];
                            }).toList(),
                          ],
                        ),
                        const SizedBox(height: 48),
                      ],
                      // Additional Information
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xffF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ADDITIONAL INFORMATION',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff163174),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Payment Ref ID:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    payment['paymentRefId']?.toString() ??
                                        payment['utrNumber']?.toString() ??
                                        payment['razorpayOrderId']
                                            ?.toString() ??
                                        'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Payment Mode:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  paymentModeDisplay,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Generated By:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  'ResearchVia Admin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Authorized Signatory:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '[Digital Signature]',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xff9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Footer
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'This is a computer-generated invoice. No physical signature required.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Support: support@researchvia.in | SP ResearchVia Pvt. Ltd.',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _invoiceMetaRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xff163174),
            ),
          ),
        ],
      ),
    );
  }

  Widget _invoicePriceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    double fontSize = 12,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatInvoiceNumber(String invoiceNo) {
    if (invoiceNo.isEmpty) return 'N/A';

    // If it's a MongoDB ID (24 hex characters), take first 12 characters
    if (invoiceNo.length >= 24 &&
        RegExp(r'^[a-f0-9]+$').hasMatch(invoiceNo.substring(0, 24))) {
      return invoiceNo.substring(0, 12).toUpperCase();
    }

    // If it's too long, truncate to reasonable length
    if (invoiceNo.length > 20) {
      return invoiceNo.substring(0, 20).toUpperCase();
    }

    return invoiceNo.toUpperCase();
  }

  String _formatPaymentMode(String rawMode) {
    final m = rawMode.trim().toUpperCase();
    if (m.isEmpty ||
        m == 'BANK_TRANSFER' ||
        m == 'OFFLINE' ||
        m == 'MANUAL' ||
        m == 'BANK' ||
        m.contains('TRANSFER')) {
      return 'Bank Transfer';
    }
    // Razorpay / online methods
    if (m == 'UPI' ||
        m == 'NETBANKING' ||
        m == 'CARD' ||
        m == 'EMI' ||
        m == 'ONLINE' ||
        m == 'RAZORPAY') {
      return 'Online';
    }
    // Title-case fallback
    return rawMode
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
