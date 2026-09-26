import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/controllers/subscription/pending_bank_transfers.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/utils/invoice_pdf_generator.dart';
import 'package:spresearch_web/ui/widgets/skeleton_loader.widget.dart';
import '../../../models/user.model.dart';

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
        ? _buildPaymentsTab(context, controller)
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
                        Tab(text: "Registered Clients"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPaymentsTab(context, controller),
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
                Expanded(
                  child: Text(
                    specificTab == 1
                        ? "Registered Clients"
                        : specificTab == 0
                        ? "Pending Payments Approvals"
                        : "Pending Approvals",
                    style: TextStyle(
                      fontSize: context.width < 600 ? 20 : 24,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
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

  Widget _buildPaymentsTab(
    BuildContext context,
    PendingBankTransfersController controller,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Compact GST & Revenue Section (with integrated toolbar)
          _buildGstSummaryCards(context, controller),

          const SizedBox(height: 12),
          // 2. Data Section (By Customer Table)
          Obx(() {
            final listEmpty = controller.consolidatedUsers.isEmpty;

            if (controller.isLoading.value && listEmpty) {
              return const TableSkeleton(rowCount: 7, columnCount: 6);
            }

            if (listEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("No pending transfers found."),
                ),
              );
            }

            return _buildConsolidatedUsersTable(controller);
          }),
        ],
      ),
    );
  }

  Widget _buildGstSummaryCards(
    BuildContext context,
    PendingBankTransfersController controller,
  ) {
    return Obx(() {
      final selectedPeriod = controller.selectedGstPeriod.value;
      final customStart = controller.customGstStartDate.value;
      final customEnd = controller.customGstEndDate.value;
      final isExporting = controller.isExportingGst.value;

      final gross = controller.gstGrossTurnover.value;
      final taxable = controller.gstTaxableTurnover.value;
      final totalTax = controller.gstTotalTax.value;
      final cgst = controller.gstCgst.value;
      final sgst = controller.gstSgst.value;
      final igst = controller.gstIgst.value;
      final b2bCount = controller.gstB2bCount.value;
      final b2cCount = controller.gstB2cCount.value;
      final b2bAmt = controller.gstB2bAmount.value;
      final b2cAmt = controller.gstB2cAmount.value;

      String customDateText = "Select Dates";
      if (customStart != null && customEnd != null) {
        customDateText =
            "${DateFormat('dd MMM').format(customStart)} - ${DateFormat('dd MMM').format(customEnd)}";
      }

      String formatInr(double amount) {
        try {
          return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
        } catch (_) {
          return '₹${amount.toStringAsFixed(0)}';
        }
      }

      final cards = [
        _buildGstCard(
          title: "Gross Turnover",
          value: formatInr(gross),
          subtitle: "Incl. 18% GST",
          icon: Icons.currency_rupee,
          accentColor: const Color(0xFF1E40AF),
          bgColor: const Color(0xFFEFF6FF),
        ),
        _buildGstCard(
          title: "Taxable Base",
          value: formatInr(taxable),
          subtitle: "Net (÷1.18)",
          icon: Icons.trending_up,
          accentColor: const Color(0xFF0F766E),
          bgColor: const Color(0xFFF0FDFA),
        ),
        _buildGstCard(
          title: "GST Liability",
          value: formatInr(totalTax),
          subtitle: "MP ₹${(cgst + sgst).toStringAsFixed(0)} | IGST ₹${igst.toStringAsFixed(0)}",
          icon: Icons.account_balance_outlined,
          accentColor: const Color(0xFFB45309),
          bgColor: const Color(0xFFFFFBEB),
        ),
        _buildGstCard(
          title: "GSTR-1 Split",
          value: "$b2bCount B2B • $b2cCount B2C",
          subtitle: "B2B ₹${(b2bAmt / 1000).toStringAsFixed(1)}k | B2C ₹${(b2cAmt / 1000).toStringAsFixed(1)}k",
          icon: Icons.pie_chart_outline_rounded,
          accentColor: const Color(0xFF6B21A8),
          bgColor: const Color(0xFFFAF5FF),
        ),
      ];

      final periodSelector = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.primaryBlue),
            const SizedBox(width: 4),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: [
                  'All Time',
                  'This Month',
                  'Last Month',
                  'This Quarter (QRMP)',
                  'Last Quarter (QRMP)',
                  'Q1: Apr - Jun (Due 13 Jul)',
                  'Q2: Jul - Sep (Due 13 Oct)',
                  'Q3: Oct - Dec (Due 13 Jan)',
                  'Q4: Jan - Mar (Due 13 Apr)',
                  'Custom',
                ].contains(selectedPeriod)
                    ? selectedPeriod
                    : (selectedPeriod == 'This Quarter'
                        ? 'This Quarter (QRMP)'
                        : (selectedPeriod == 'Last Quarter'
                            ? 'Last Quarter (QRMP)'
                            : 'All Time')),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                items: const [
                  DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                  DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                  DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
                  DropdownMenuItem(value: 'This Quarter (QRMP)', child: Text('This Quarter (QRMP)')),
                  DropdownMenuItem(value: 'Last Quarter (QRMP)', child: Text('Last Quarter (QRMP)')),
                  DropdownMenuItem(value: 'Q1: Apr - Jun (Due 13 Jul)', child: Text('Q1: Apr - Jun (Due 13 Jul)')),
                  DropdownMenuItem(value: 'Q2: Jul - Sep (Due 13 Oct)', child: Text('Q2: Jul - Sep (Due 13 Oct)')),
                  DropdownMenuItem(value: 'Q3: Oct - Dec (Due 13 Jan)', child: Text('Q3: Oct - Dec (Due 13 Jan)')),
                  DropdownMenuItem(value: 'Q4: Jan - Mar (Due 13 Apr)', child: Text('Q4: Jan - Mar (Due 13 Apr)')),
                  DropdownMenuItem(value: 'Custom', child: Text('Custom Range...')),
                ],
                onChanged: (val) async {
                  if (val == null) return;
                  if (val == 'Custom') {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: (customStart != null && customEnd != null)
                          ? DateTimeRange(start: customStart, end: customEnd)
                          : DateTimeRange(
                              start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                              end: DateTime.now(),
                            ),
                    );
                    if (picked != null) {
                      controller.setGstPeriod('Custom', start: picked.start, end: picked.end);
                    }
                  } else {
                    controller.setGstPeriod(val);
                  }
                },
              ),
            ),
          ],
        ),
      );

      final customDateBtn = (selectedPeriod == 'Custom')
          ? OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppTheme.primaryBlue,
                side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: (customStart != null && customEnd != null)
                      ? DateTimeRange(start: customStart, end: customEnd)
                      : DateTimeRange(
                          start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                          end: DateTime.now(),
                        ),
                );
                if (picked != null) {
                  controller.setGstPeriod('Custom', start: picked.start, end: picked.end);
                }
              },
              icon: const Icon(Icons.date_range, size: 12),
              label: Text(
                customDateText,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            )
          : null;

      final canExport = (Get.find<AuthController>().user.value?.isAdmin == true) ||
          (Get.find<AuthController>().user.value?.has('payments.export') ?? false);

      final exportBtn = canExport
          ? ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                backgroundColor: const Color(0xFF107C41),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: isExporting ? null : () => controller.exportGstReport(),
              icon: isExporting
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.file_download_outlined, size: 14),
              label: Text(
                isExporting ? "Generating..." : "Export CA GST (CSV)",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : null;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact Header & Toolbar
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 880;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 15, color: AppTheme.primaryBlue),
                          const SizedBox(width: 6),
                          const Text(
                            "GST & Revenue",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text("SAC 998371", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text("MP (23)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green[800])),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          periodSelector,
                          if (customDateBtn != null) customDateBtn,
                          if (exportBtn != null) exportBtn,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 15, color: AppTheme.primaryBlue),
                    const SizedBox(width: 6),
                    const Text(
                      "GST & Revenue",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("SAC 998371", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text("MP (23)", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green[800])),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: "SAC 998371 (Market Research Services - 18% GST). Intra-state MP clients: 9% CGST + 9% SGST. Inter-state clients: 18% IGST. Export file matches GSTR-1.",
                      child: Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        periodSelector,
                        if (customDateBtn != null) customDateBtn,
                        if (exportBtn != null) exportBtn,
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            // Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                } else if (constraints.maxWidth >= 500) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[1]),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: cards[2]),
                          const SizedBox(width: 8),
                          Expanded(child: cards[3]),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        cards[i],
                      ],
                    ],
                  );
                }
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildGstCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, size: 14, color: accentColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsolidatedUsersTable(
    PendingBankTransfersController controller,
  ) {
    return Obx(() {
      if (controller.filteredConsolidatedUsers.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Text("No customer payments match the selected filters."),
          ),
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
                    dataRowHeight: 85,
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    headingRowColor: MaterialStateProperty.all(AppTheme.gray50),
                    columns: const [
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Total Paid (LTV)')),
                      DataColumn(label: Text('State (SGST Filing)')),
                      DataColumn(label: Text('Latest Activity')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: controller.filteredConsolidatedUsers.map((userGroup) {
                      final user = userGroup['user'] is Map
                          ? Map<String, dynamic>.from(userGroup['user'])
                          : <String, dynamic>{};
                      final double totalPaid = (userGroup['totalPaid'] is num)
                          ? (userGroup['totalPaid'] as num).toDouble()
                          : (double.tryParse(userGroup['totalPaid']?.toString() ?? '0') ?? 0);
                      final double remaining = (userGroup['remainingBalance'] is num)
                          ? (userGroup['remainingBalance'] as num).toDouble()
                          : (double.tryParse(userGroup['remainingBalance']?.toString() ?? '0') ?? 0);
                      final int pendingCount = userGroup['pendingCount'] is int
                          ? userGroup['pendingCount'] as int
                          : (int.tryParse(userGroup['pendingCount']?.toString() ?? '0') ?? 0);
                      final bool hasPending = userGroup['hasPending'] == true || pendingCount > 0;

                      DateTime? latestDate;
                      if (userGroup['latestActivity'] != null) {
                        latestDate = DateTime.tryParse(userGroup['latestActivity'].toString());
                      }
                      final isNew = hasPending &&
                          latestDate != null &&
                          DateTime.now().difference(latestDate).inHours < 48;

                      final double basePaid = totalPaid / 1.18;
                      final double gstPaid = totalPaid - basePaid;

                      return DataRow(
                        color: hasPending
                            ? MaterialStateProperty.all(Colors.amber[50])
                            : null,
                        cells: [
                          // Customer
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                                    child: Text(
                                      (user['fullName']?.toString().isNotEmpty == true)
                                          ? user['fullName'].toString().substring(0, 1).toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
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
                                            fontSize: 13,
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
                                ],
                              ),
                            ),
                          ),
                          // Total Paid (LTV)
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '₹${basePaid.toStringAsFixed(0)} + ₹${gstPaid.toStringAsFixed(0)} GST',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Total Paid: ₹${totalPaid.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                                if (remaining > 0)
                                  Text(
                                    'Balance Due: ₹${remaining.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[800],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // State (SGST Filing)
                          DataCell(
                            Builder(
                              builder: (context) {
                                final payments = userGroup['payments'] as List? ?? [];
                                final fallbackGstin = payments.isNotEmpty ? payments.first['gstin']?.toString() : null;
                                final stateInfo = PendingBankTransfersController.resolveStateInfo(user, fallbackGstin: fallbackGstin);
                                final isKnown = stateInfo.name != 'Unspecified';

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Tooltip(
                                      message: stateInfo.code != '--'
                                          ? 'State: ${stateInfo.name}\nGST Code: ${stateInfo.code}\nPAN Code: ${stateInfo.panCode}'
                                          : 'State: Unspecified',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: stateInfo.isIntraState
                                                ? Colors.green[800]
                                                : (isKnown ? Colors.blue[800] : Colors.grey[600]),
                                          ),
                                          const SizedBox(width: 4),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 160),
                                            child: Text(
                                              stateInfo.code != '--' ? '${stateInfo.name} (${stateInfo.code})' : stateInfo.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: stateInfo.isIntraState
                                                    ? Colors.green[900]
                                                    : (isKnown ? AppTheme.textPrimary : Colors.grey[700]),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: stateInfo.isIntraState
                                            ? Colors.green[50]
                                            : (isKnown ? Colors.blue[50] : Colors.grey[100]),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: stateInfo.isIntraState
                                              ? Colors.green[300]!
                                              : (isKnown ? Colors.blue[200]! : Colors.grey[300]!),
                                        ),
                                      ),
                                      child: Text(
                                        stateInfo.isIntraState
                                            ? "Intra: SGST + CGST (9%+9%)"
                                            : (isKnown ? "Inter: IGST (18%)" : "Unspecified POS"),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: stateInfo.isIntraState
                                              ? Colors.green[800]
                                              : (isKnown ? Colors.blue[800] : Colors.grey[700]),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          // Latest Activity
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(latestDate != null ? _getRelativeDate(latestDate) : '-'),
                                if (isNew) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                          // Actions
                          DataCell(
                            Button(
                              title: "Details",
                              buttonType: hasPending ? ButtonType.blue : ButtonType.grey,
                              size: ButtonSize.small,
                              icon: Icons.folder_open_outlined,
                              onTap: () => _showUserPaymentDossierDialog(userGroup, controller),
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
            "Showing ${controller.filteredConsolidatedUsers.length} of ${controller.totalPaymentsCount.value} customers",
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (controller.hasMorePages.value) ...[
            const SizedBox(height: 16),
            Center(
              child: Button(
                title: controller.isLoading.value ? "Loading..." : "Load More Customers",
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

  static Future<void> showUserDossierDialogByUserId(
    String userId, {
    UserModel? userModel,
  }) async {
    final controller = Get.isRegistered<PendingBankTransfersController>()
        ? Get.find<PendingBankTransfersController>()
        : Get.put(PendingBankTransfersController());

    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      ),
      barrierDismissible: false,
    );

    final userGroup = await controller.fetchUserPaymentDossier(userId, userModel);

    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    const PendingBankTransfersScreen()._showUserPaymentDossierDialog(userGroup, controller);
  }

  void _showUserPaymentDossierDialog(
    Map<String, dynamic> initialUserGroup,
    PendingBankTransfersController controller,
  ) {
    final RxMap<String, dynamic> liveUserGroup =
        Map<String, dynamic>.from(initialUserGroup).obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 1150,
          constraints: BoxConstraints(maxHeight: Get.height * 0.9),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Obx(() {
            final user = liveUserGroup['user'] is Map
                ? Map<String, dynamic>.from(liveUserGroup['user'])
                : <String, dynamic>{};
            final List payments = liveUserGroup['payments'] is List
                ? liveUserGroup['payments'] as List
                : [];
            final String userId = user['_id']?.toString() ?? '';

            // Compute summary stats dynamically
            double totalPaid = 0;
            double remainingTotal = 0;
            int pendingCount = 0;
            double pendingAmount = 0;
            int activePlansCount = 0;

            for (var p in payments) {
              final double pPaid = (p['amountPaid'] is num)
                  ? (p['amountPaid'] as num).toDouble()
                  : (double.tryParse(p['amountPaid']?.toString() ?? '0') ?? 0);
              final double pTarget = (p['amount'] is num)
                  ? (p['amount'] as num).toDouble()
                  : (double.tryParse(p['amount']?.toString() ?? '0') ?? 0);
              final double pDiscount = (p['discount'] is num)
                  ? (p['discount'] as num).toDouble()
                  : (double.tryParse(p['discount']?.toString() ?? '0') ?? 0);
              final double rem = (pTarget - pDiscount - pPaid) > 0
                  ? (pTarget - pDiscount - pPaid)
                  : 0;

              totalPaid += pPaid;
              remainingTotal += rem;

              final isPending = p['status'] == 'PENDING' ||
                  p['status'] == 'PENDING_BANK_TRANSFER' ||
                  p['status'] == 'VERIFICATION_PENDING';
              final history = p['partialPaymentsHistory'] as List? ?? [];
              final pendingInst =
                  history.where((h) => h['status'] == 'PENDING').toList();

              if (isPending) {
                pendingCount++;
                pendingAmount += pPaid > 0 ? pPaid : pTarget;
              } else if (pendingInst.isNotEmpty) {
                pendingCount += pendingInst.length;
                for (var inst in pendingInst) {
                  pendingAmount += (inst['amountPaid'] is num)
                      ? (inst['amountPaid'] as num).toDouble()
                      : (double.tryParse(inst['amountPaid']?.toString() ?? '0') ?? 0);
                }
              }

              if (p['status'] == 'PAID' ||
                  p['status'] == 'APPROVED' ||
                  p['status'] == 'PARTIAL-PAID') {
                activePlansCount++;
              }
            }

            final regType =
                (user['registrationType'] ?? '').toString().toUpperCase();
            String regBadge = 'Standard';
            if (regType.contains('LIFETIME')) {
              regBadge = 'Gold (Lifetime)';
            } else if (regType.contains('YEARLY')) {
              regBadge = 'Silver (Yearly)';
            } else if (regType.isNotEmpty) {
              regBadge = user['registrationType'].toString();
            }

            return Column(
              children: [
                // Modal Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: AppTheme.primaryBlue,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white24,
                        child: Text(
                          (user['fullName']?.toString().isNotEmpty == true)
                              ? user['fullName']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user['fullName'] ??
                                      'Customer Payments Dossier',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    regBadge,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (user['kycStatus'] == 'VERIFIED' ||
                                            user['kycStatus'] == 'APPROVED')
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.orange.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "KYC: ${user['kycStatus'] ?? 'PENDING'}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Phone: ${user['phone'] ?? '-'}  •  Email: ${user['email'] ?? '-'}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      if (userId.isNotEmpty) ...[
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white12,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.person, size: 16),
                          label: const Text("User Profile",
                              style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Get.toNamed('/users/$userId');
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: "Close",
                      ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Summary KPI Cards
                        Row(
                          children: [
                            _buildStatCard(
                              "Customer Lifetime (Paid)",
                              "₹${totalPaid.toStringAsFixed(0)}",
                              Icons.account_balance_wallet_outlined,
                              Colors.green[700]!,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              "Active Subscriptions",
                              "$activePlansCount / ${payments.length} Plans",
                              Icons.verified_outlined,
                              AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              "Pending Reviews",
                              pendingCount > 0
                                  ? "$pendingCount Slips (₹${pendingAmount.toStringAsFixed(0)})"
                                  : "None Pending",
                              Icons.pending_actions_outlined,
                              pendingCount > 0
                                  ? Colors.orange[800]!
                                  : Colors.grey[700]!,
                            ),
                            const SizedBox(width: 16),
                            _buildStatCard(
                              "Remaining Balance",
                              "₹${remainingTotal.toStringAsFixed(0)}",
                              Icons.timelapse_outlined,
                              remainingTotal > 0
                                  ? Colors.purple[700]!
                                  : Colors.grey[700]!,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Section Heading
                        Row(
                          children: [
                            const Icon(Icons.receipt_long,
                                size: 20, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              "All Purchases & Subscriptions (${payments.length})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "Sorted by newest activity",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Render Plan Cards
                        ...payments.asMap().entries.map((entry) {
                          final int idx = entry.key;
                          final payment = entry.value is Map
                              ? Map<String, dynamic>.from(entry.value)
                              : <String, dynamic>{};
                          return _buildDossierPaymentCard(
                            payment: payment,
                            controller: controller,
                            index: idx,
                            onPaymentUpdated: (updatedPayment) {
                              final List updatedList =
                                  List.from(liveUserGroup['payments'] ?? []);
                              final int pIdx = updatedList.indexWhere(
                                (p) =>
                                    p['_id']?.toString() ==
                                    updatedPayment['_id']?.toString(),
                              );
                              if (pIdx != -1) {
                                updatedList[pIdx] = updatedPayment;
                              } else {
                                updatedList.add(updatedPayment);
                              }
                              liveUserGroup['payments'] = updatedList;
                              liveUserGroup.refresh();
                              controller.fetchPendingTransfers();
                            },
                          );
                        }).toList(),
                      ],
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

  Widget _buildCorrectFinancialsButton({
    required VoidCallback onTap,
    bool isSmall = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: isSmall
              ? AppTheme.buttonHeightSmall
              : AppTheme.buttonHeightDefault,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 14),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange[300]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note,
                  size: isSmall ? 16 : 18, color: Colors.orange[900]),
              const SizedBox(width: 4),
              Text(
                "Correct Financials",
                style: TextStyle(
                  fontSize: isSmall ? 11 : 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDossierPaymentCard({
    required Map<String, dynamic> payment,
    required PendingBankTransfersController controller,
    required int index,
    required Function(Map<String, dynamic> updatedPayment) onPaymentUpdated,
  }) {
    final String intentId = payment['_id']?.toString() ?? '';
    final String purchaseType = payment['purchaseType']?.toString() ?? 'PLAN';
    final bool isRegistration = purchaseType == 'REGISTRATION';
    final bool isPartial = payment['isPartial'] == true;
    final String status = payment['status']?.toString() ?? 'PENDING';
    final bool canAct = controller.canTakePaymentActions;

    final Map<String, dynamic> plan = (payment['segmentPlanId'] is Map)
        ? Map<String, dynamic>.from(payment['segmentPlanId'])
        : {};
    final String planName = isRegistration
        ? (payment['amount'] == 10000 || payment['baseAmount'] == 10000
            ? 'Gold Registration (Lifetime)'
            : 'Silver Registration (Yearly)')
        : (plan['segmentsName'] != null &&
                plan['segmentsName'].toString().isNotEmpty &&
                plan['segmentsName'] != 'Platform'
            ? "${plan['planName'] ?? 'Custom Plan'} (${plan['segmentsName']})"
            : (plan['planName'] ?? 'Custom Plan'));

    final double planAmount = (payment['amount'] is num)
        ? (payment['amount'] as num).toDouble()
        : (double.tryParse(payment['amount']?.toString() ?? '0') ?? 0);
    final double discount = (payment['discount'] is num)
        ? (payment['discount'] as num).toDouble()
        : (double.tryParse(payment['discount']?.toString() ?? '0') ?? 0);
    final double amountPaid = (payment['amountPaid'] is num)
        ? (payment['amountPaid'] as num).toDouble()
        : (double.tryParse(payment['amountPaid']?.toString() ?? '0') ?? 0);
    final double target = planAmount - discount;
    final double remaining =
        (target - amountPaid) > 0 ? (target - amountPaid) : 0;

    final double basePaid = amountPaid / 1.18;
    final double gstPaid = amountPaid - basePaid;

    final date = DateTime.tryParse(payment['createdAt'] ?? '');
    final history = payment['partialPaymentsHistory'] as List? ?? [];
    final proofUrl = payment['paymentProof'] ?? payment['paymentScreenshot'];
    final List<String> paymentProofs =
        (payment['paymentProofs'] != null &&
                (payment['paymentProofs'] as List).isNotEmpty)
            ? (payment['paymentProofs'] as List)
                .map((e) => AppConfig.buildImageUrl(e.toString()))
                .toList()
            : (proofUrl != null
                ? [AppConfig.buildImageUrl(proofUrl.toString())]
                : []);

    // Date Logic
    final String? startStr = payment['serviceStartDate']?.toString();
    DateTime? startDate = (startStr != null && startStr.isNotEmpty)
        ? DateTime.tryParse(startStr)
        : null;

    if (startDate == null) {
      for (var inst in history) {
        if (inst['status'] == 'APPROVED' ||
            inst['status'] == 'PARTIAL-PAID' ||
            inst['status'] == 'PAID') {
          final dtStr = inst['transactionDate']?.toString() ??
              inst['updatedAt']?.toString() ??
              inst['createdAt']?.toString();
          if (dtStr != null) {
            startDate = DateTime.tryParse(dtStr);
            break;
          }
        }
      }
      if (status == 'PAID' || status == 'APPROVED') {
        startDate ??= date;
      }
    }

    final String sDateDisplay = startDate != null
        ? _formatToIST(startDate, 'dd MMM yyyy')
        : 'Yet to be activated';

    final String? expiryStr = payment['currentExpiryDate']?.toString();
    DateTime? expiryDate = (expiryStr != null && expiryStr.isNotEmpty)
        ? DateTime.tryParse(expiryStr)
        : null;

    final int originalDuration = (payment['originalDuration'] is num)
        ? (payment['originalDuration'] as num).toInt()
        : (isRegistration ? 3650 : 365);

    if (expiryDate == null && startDate != null && !isPartial) {
      expiryDate = startDate.add(Duration(days: originalDuration));
    }

    final String eDateDisplay =
        expiryDate != null ? _formatToIST(expiryDate, 'dd MMM yyyy') : 'N/A';

    final bool hasPendingInstallment =
        history.any((h) => h['status'] == 'PENDING');
    final bool needsAttention = status == 'PENDING' ||
        status == 'PENDING_BANK_TRANSFER' ||
        status == 'VERIFICATION_PENDING' ||
        hasPendingInstallment;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: needsAttention ? Colors.orange[300]! : AppTheme.gray200,
          width: needsAttention ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Top Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: needsAttention
                  ? Colors.orange[50]?.withOpacity(0.5)
                  : AppTheme.gray50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppTheme.gray200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isRegistration ? Colors.amber : AppTheme.primaryBlue)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isRegistration ? Icons.badge_outlined : Icons.layers_outlined,
                    size: 20,
                    color:
                        isRegistration ? Colors.amber[900] : AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            planName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: "Change Plan",
                            child: InkWell(
                              onTap: () => controller.showSubscriptionCorrectionDialog(
                                payment,
                                onUpdated: onPaymentUpdated,
                              ),
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.change_circle_outlined,
                                    size: 16,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isRegistration)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'REGISTRATION FEE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[900],
                                ),
                              ),
                            )
                          else if (isPartial)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.purple[200]!),
                              ),
                              child: Text(
                                'PARTIAL PLAN',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[900],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Created: ${date != null ? _formatToIST(date, 'dd MMM yyyy, hh:mm a') : '-'}  •  Order ID: ${payment['razorpayOrderId'] ?? '-'}",
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status,
                    remaining: remaining, installmentCount: history.length),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.receipt_long,
                      color: AppTheme.primaryBlue),
                  tooltip: 'View / Download Invoice',
                  onPressed: () => _showInvoiceDialog(payment),
                ),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Snapshot Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.gray200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          "Total Plan Target",
                          "₹${target.toStringAsFixed(0)}",
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          "Amount Paid (Base + GST)",
                          "₹${basePaid.toStringAsFixed(0)} + ₹${gstPaid.toStringAsFixed(0)}",
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          "Balance Due",
                          remaining > 0
                              ? "₹${remaining.toStringAsFixed(0)}"
                              : "₹0 (Cleared)",
                        ),
                      ),
                      if (discount > 0)
                        Expanded(
                          child: InkWell(
                            onTap: canAct
                                ? () => controller.showDiscountDialog(
                                      payment,
                                      onUpdated: onPaymentUpdated,
                                    )
                                : null,
                            borderRadius: BorderRadius.circular(4),
                            child: _buildInfoItem(
                              "Discount Applied",
                              "₹${discount.toStringAsFixed(0)}",
                            ),
                          ),
                        ),
                      Expanded(
                        child: _buildInfoItem(
                          "Service Validity",
                          "$sDateDisplay ➔ $eDateDisplay",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // If Partial Plan: Render Installment Timeline
                if (isPartial) ...[
                  Row(
                    children: [
                      const Icon(Icons.timeline, size: 18, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text(
                        "Partial Installments History",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${history.length} Installment${history.length == 1 ? '' : 's'} recorded",
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "No installments uploaded yet",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Table(
                      columnWidths: canAct
                          ? const {
                              0: FlexColumnWidth(1.5),
                              1: FlexColumnWidth(2.2),
                              2: FlexColumnWidth(1.8),
                              3: FlexColumnWidth(0.8),
                              4: FlexColumnWidth(1.2),
                              5: FlexColumnWidth(3.4),
                            }
                          : const {
                              0: FlexColumnWidth(1.6),
                              1: FlexColumnWidth(2.2),
                              2: FlexColumnWidth(2.0),
                              3: FlexColumnWidth(1.0),
                              4: FlexColumnWidth(1.2),
                            },
                      border:
                          TableBorder.all(color: Colors.grey[200]!, width: 0.5),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[100]),
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Date',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Amount (Base+GST)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('UTR',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Proof',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                            ),
                            if (canAct)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Actions',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ),
                          ],
                        ),
                        ...history.reversed.map((inst) {
                          final instDate = DateTime.tryParse(
                              inst['transactionDate'] ?? '');
                          final instProof = inst['proofImage'];
                          final List instProofs = (inst['proofImages'] is List &&
                                  (inst['proofImages'] as List).isNotEmpty)
                              ? (inst['proofImages'] as List)
                                  .map((e) =>
                                      AppConfig.buildImageUrl(e.toString()))
                                  .toList()
                              : (instProof != null
                                  ? [
                                      AppConfig.buildImageUrl(
                                          instProof.toString())
                                    ]
                                  : []);
                          final double instAmt = (inst['amountPaid'] is num)
                              ? (inst['amountPaid'] as num).toDouble()
                              : (double.tryParse(
                                      inst['amountPaid']?.toString() ?? '0') ??
                                  0);
                          final isInstPending = inst['status'] == 'PENDING';
                          final isInstApproved = inst['status'] == 'APPROVED';
                          final isInstRejected = inst['status'] == 'REJECTED';

                          return TableRow(
                            decoration: BoxDecoration(
                              color: isInstPending ? Colors.amber[50] : null,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  instDate != null
                                      ? _formatToIST(instDate, 'dd MMM yyyy')
                                      : '-',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '₹${(instAmt / 1.18).toStringAsFixed(0)} + ₹${(instAmt - (instAmt / 1.18)).toStringAsFixed(0)} = ₹${instAmt.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  inst['utrNumber'] ?? '-',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: instProofs.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.image_outlined,
                                            size: 18,
                                            color: AppTheme.primaryBlue),
                                        onPressed: () => _showImageDialog(
                                            instProofs.cast<String>()),
                                        tooltip: "View Slip",
                                      )
                                    : const Icon(Icons.image_not_supported,
                                        size: 16, color: Colors.grey),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildStatusChip(
                                    inst['status'] ?? 'PENDING'),
                              ),
                              if (canAct)
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _buildCorrectFinancialsButton(
                                        onTap: () => controller.showCorrectionDialog(
                                          payment,
                                          installment: inst,
                                          onPaymentUpdated: onPaymentUpdated,
                                        ),
                                      ),
                                      if (isInstPending) ...[
                                        Button(
                                          title: "Approve",
                                          buttonType: ButtonType.green,
                                          size: ButtonSize.small,
                                          onTap: () {
                                            _showRemarkPopup(
                                              intentId: intentId,
                                              historyId:
                                                  inst['_id']?.toString(),
                                              isFullPayment: false,
                                              controller: controller,
                                              discount: discount,
                                              payment: payment,
                                            );
                                          },
                                        ),
                                        Button(
                                          title: "Reject",
                                          buttonType: ButtonType.red,
                                          size: ButtonSize.small,
                                          onTap: () {
                                            _showRevertConfirmation(
                                              title: "Reject Installment?",
                                              message:
                                                  "Are you sure you want to reject this installment?",
                                              onConfirm: (remark) async {
                                                final success = await controller
                                                    .rejectPartialInstallment(
                                                  intentId,
                                                  inst['_id']?.toString() ?? '',
                                                );
                                                if (success) {
                                                  inst['status'] = 'REJECTED';
                                                  onPaymentUpdated(payment);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ] else if (isInstApproved) ...[
                                        Button(
                                          title: "Revert",
                                          buttonType: ButtonType.red,
                                          size: ButtonSize.small,
                                          onTap: () {
                                            _showRevertConfirmation(
                                              title: "Revert Approval?",
                                              message:
                                                  "This will REJECT this installment and REVERT associated data.",
                                              onConfirm: (reason) async {
                                                final success = await controller
                                                    .revertApprovalAction(
                                                  intentId,
                                                  historyId:
                                                      inst['_id']?.toString(),
                                                  reason: reason,
                                                );
                                                if (success) {
                                                  inst['status'] = 'REJECTED';
                                                  onPaymentUpdated(payment);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ] else if (isInstRejected) ...[
                                        Button(
                                          title: "Restore",
                                          buttonType: ButtonType.green,
                                          size: ButtonSize.small,
                                          onTap: () {
                                            _showRevertConfirmation(
                                              title: "Restore Installment?",
                                              message:
                                                  "This will restore this installment to APPROVED state.",
                                              confirmColor: Colors.green,
                                              onConfirm: (reason) async {
                                                final success = await controller
                                                    .revertRejectionAction(
                                                  intentId,
                                                  historyId:
                                                      inst['_id']?.toString(),
                                                  reason: reason,
                                                );
                                                if (success) {
                                                  inst['status'] = 'APPROVED';
                                                  onPaymentUpdated(payment);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ] else ...[
                                        const Icon(Icons.check,
                                            size: 16, color: Colors.green),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                ] else ...[
                  // Full Payment Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // UTR and Proof preview
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Payment Slip & UTR",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: paymentProofs.isNotEmpty
                                        ? () => _showImageDialog(paymentProofs)
                                        : null,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        color: Colors.grey[100],
                                      ),
                                      child: paymentProofs.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.network(
                                                paymentProofs.first,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                        Icons.broken_image,
                                                        size: 20),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image_not_supported,
                                              size: 24,
                                              color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "UTR: ${payment['utrNumber'] ?? 'N/A'}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Method: ${payment['paymentMethod'] ?? 'BANK_TRANSFER'}",
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.grey),
                                        ),
                                        if (paymentProofs.length > 1)
                                          Text(
                                            "+${paymentProofs.length - 1} additional slip(s)",
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.primaryBlue,
                                                fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Actions
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Actions",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (status != 'PAID' &&
                                status != 'APPROVED' &&
                                status != 'REJECTED') ...[
                              if (canAct)
                                Row(
                                  children: [
                                    _buildCorrectFinancialsButton(
                                      isSmall: false,
                                      onTap: () => controller.showCorrectionDialog(
                                        payment,
                                        onPaymentUpdated: onPaymentUpdated,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Button(
                                        title: "Approve & Activate",
                                        buttonType: ButtonType.green,
                                        size: ButtonSize.medium,
                                        onTap: () {
                                          _showRemarkPopup(
                                            intentId: intentId,
                                            controller: controller,
                                            isFullPayment: true,
                                            payment: payment,
                                            discount: discount,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Button(
                                        title: "Reject",
                                        buttonType: ButtonType.red,
                                        size: ButtonSize.medium,
                                        onTap: () {
                                          controller.rejectTransfer(payment);
                                        },
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: Colors.amber[300]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hourglass_empty,
                                          size: 16,
                                          color: Colors.amber[800]),
                                      const SizedBox(width: 6),
                                      Text(
                                        "PENDING APPROVAL",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber[900]),
                                      ),
                                    ],
                                  ),
                                ),
                            ] else ...[
                              Row(
                                children: [
                                  if (canAct) ...[
                                    _buildCorrectFinancialsButton(
                                      isSmall: true,
                                      onTap: () => controller.showCorrectionDialog(
                                        payment,
                                        onPaymentUpdated: onPaymentUpdated,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (status == 'PAID' ||
                                              status == 'APPROVED')
                                          ? Colors.green[50]
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: (status == 'PAID' ||
                                                status == 'APPROVED')
                                            ? Colors.green[300]!
                                            : Colors.red[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          (status == 'PAID' ||
                                                  status == 'APPROVED')
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 16,
                                          color: (status == 'PAID' ||
                                                  status == 'APPROVED')
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          (status == 'PAID' ||
                                                  status == 'APPROVED')
                                              ? "APPROVED"
                                              : "REJECTED",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: (status == 'PAID' ||
                                                    status == 'APPROVED')
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (canAct) ...[
                                    const SizedBox(width: 12),
                                    if (status == 'PAID' ||
                                        status == 'APPROVED')
                                      Button(
                                        title: "REVERT APPROVAL",
                                        buttonType: ButtonType.red,
                                        size: ButtonSize.small,
                                        onTap: () {
                                          _showRevertConfirmation(
                                            title: "Revert Approval?",
                                            message:
                                                "This will REJECT the payment and DELETE all created entitlements, invoices, and plan purchases.",
                                            onConfirm: (reason) {
                                              controller.revertApprovalAction(
                                                  intentId,
                                                  reason: reason);
                                            },
                                          );
                                        },
                                      )
                                    else if (status == 'REJECTED')
                                      Button(
                                        title: "RESTORE & APPROVE",
                                        buttonType: ButtonType.green,
                                        size: ButtonSize.small,
                                        onTap: () {
                                          _showRevertConfirmation(
                                            title: "Restore & Approve?",
                                            message:
                                                "This will RESTORE the payment to Approved state and RECREATE all entitlements and invoices.",
                                            confirmColor: Colors.green,
                                            onConfirm: (reason) {
                                              controller.revertRejectionAction(
                                                  intentId,
                                                  historyId: null,
                                                  reason: reason);
                                            },
                                          );
                                        },
                                      ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Admin Correction Buttons footer for this payment
                if (canAct) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month,
                            size: 14, color: AppTheme.primaryBlue),
                        label: const Text("Edit Plan/Dates",
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.primaryBlue)),
                        onPressed: () => controller.showSubscriptionCorrectionDialog(
                          payment,
                          onUpdated: onPaymentUpdated,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.discount_outlined,
                            size: 15, color: Colors.teal),
                        label: const Text(
                          "Discount",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal),
                        ),
                        onPressed: () => controller.showDiscountDialog(
                          payment,
                          onUpdated: onPaymentUpdated,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildInfoItem(String label, String value, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing,
            ],
          ],
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
              return const SizedBox(
                height: 450,
                child: TableSkeleton(rowCount: 7, columnCount: 6),
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
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
