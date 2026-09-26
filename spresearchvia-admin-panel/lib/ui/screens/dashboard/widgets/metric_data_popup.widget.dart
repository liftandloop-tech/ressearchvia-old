import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/dashboard.controller.dart';

enum MetricCardType {
  totalSales,
  purchases,
  activeStaff,
  avgOrderValue,
  conversionRate,
  topStaff,
}

class MetricDataPopup extends StatefulWidget {
  final MetricCardType type;
  final DashboardController controller;

  const MetricDataPopup({
    super.key,
    required this.type,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required MetricCardType type,
    required DashboardController controller,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => MetricDataPopup(
        type: type,
        controller: controller,
      ),
    );
  }

  @override
  State<MetricDataPopup> createState() => _MetricDataPopupState();
}

class _MetricDataPopupState extends State<MetricDataPopup> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 10;
  String _selectedStatusFilter = 'All';

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.85).clamp(340.0, 1100.0);
    final dialogHeight = (screenSize.height * 0.88).clamp(450.0, 800.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      elevation: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Column(
            children: [
              // 1. Dialog Header
              _buildHeader(),

              const Divider(height: 1, color: AppTheme.gray200),

              // 2. Body Content (Scrollable)
              Expanded(
                child: Container(
                  color: AppTheme.gray50,
                  child: Column(
                    children: [
                      // Summary KPI Strip
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: _buildSummaryMetrics(),
                      ),

                      // Controls Bar (Search & Filter)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                        child: _buildControlsBar(),
                      ),

                      // Data Table Area
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildTableCard(),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: AppTheme.gray200),

              // 3. Dialog Footer
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader() {
    final config = _getHeaderConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, color: config.color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        config.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.gray900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: config.badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: config.badgeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        config.badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: config.badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: AppTheme.gray500,
            tooltip: 'Close Popup',
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // --- Summary Metrics KPI Strip ---
  Widget _buildSummaryMetrics() {
    final cards = _getSummaryCards();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: cards.map((c) {
            final cardWidth = constraints.maxWidth > 700
                ? (constraints.maxWidth - (cards.length - 1) * 12) / cards.length
                : (constraints.maxWidth - 12) / 2;

            return Container(
              width: cardWidth.clamp(140.0, 300.0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gray200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(c.icon, color: c.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.gray600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.value,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gray900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- Controls Bar (Search & Filter) ---
  Widget _buildControlsBar() {
    final isOrderMetric = widget.type == MetricCardType.totalSales ||
        widget.type == MetricCardType.purchases ||
        widget.type == MetricCardType.avgOrderValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                    _currentPage = 1;
                  });
                },
                decoration: InputDecoration(
                  hintText: isOrderMetric
                      ? 'Search by Order ID, Client, Package, Staff...'
                      : 'Search by Staff Name, ID, Department, Email...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.gray400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppTheme.gray500,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          color: AppTheme.gray500,
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.gray50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),

          if (isOrderMetric) ...[
            const SizedBox(width: 12),
            // Quick Status Filter
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatusFilter,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray800,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Orders')),
                    DropdownMenuItem(
                      value: 'Paid',
                      child: Text('Paid / Active Only'),
                    ),
                    DropdownMenuItem(
                      value: 'Pending',
                      child: Text('Pending Only'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatusFilter = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Table Container ---
  Widget _buildTableCard() {
    switch (widget.type) {
      case MetricCardType.totalSales:
      case MetricCardType.purchases:
        return _buildOrdersTable();
      case MetricCardType.avgOrderValue:
        return _buildAovTable();
      case MetricCardType.conversionRate:
        return _buildConversionTable();
      case MetricCardType.activeStaff:
      case MetricCardType.topStaff:
        return _buildStaffLeaderboardTable();
    }
  }

  // --- 1 & 2: Orders Table (Total Sales & Purchases) ---
  Widget _buildOrdersTable() {
    var list = List<Map<String, dynamic>>.from(
      widget.controller.filteredStaffOrders,
    );

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) {
        final orderId = (item['orderId'] ?? '').toString().toLowerCase();
        final client = (item['clientName'] ?? '').toString().toLowerCase();
        final phone = (item['clientPhone'] ?? '').toString().toLowerCase();
        final email = (item['clientEmail'] ?? '').toString().toLowerCase();
        final plan = (item['packageName'] ?? '').toString().toLowerCase();
        final staff = (item['staffName'] ?? '').toString().toLowerCase();
        return orderId.contains(_searchQuery) ||
            client.contains(_searchQuery) ||
            phone.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            plan.contains(_searchQuery) ||
            staff.contains(_searchQuery);
      }).toList();
    }

    // Filter by status dropdown
    if (_selectedStatusFilter != 'All') {
      if (_selectedStatusFilter == 'Paid') {
        list = list.where((item) {
          final s = (item['status'] ?? '').toString().toLowerCase();
          final isPaid = item['isPaid'] == true;
          return isPaid || s == 'active' || s == 'paid';
        }).toList();
      } else if (_selectedStatusFilter == 'Pending') {
        list = list.where((item) {
          final s = (item['status'] ?? '').toString().toLowerCase();
          return s == 'pending';
        }).toList();
      }
    }

    final totalItems = list.length;
    final totalPages = totalItems > 0 ? (totalItems / _pageSize).ceil() : 1;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pageData =
        totalItems > 0 ? list.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

    return _buildTableWrapper(
      totalItems: totalItems,
      totalPages: totalPages,
      startIndex: startIndex,
      endIndex: endIndex,
      headerRow: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                'Order ID',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'Customer Details',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Plan / Package',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Sales Representative',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Transaction Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                'Status',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
          ],
        ),
      ),
      rows: pageData.map((item) {
        final amount = (item['amount'] ?? 0).toDouble();
        final status = (item['status'] ?? 'active').toString();
        final isPaid = status.toLowerCase() == 'active' ||
            status.toLowerCase() == 'paid';

        final Color badgeColor = isPaid
            ? Colors.green
            : (status.toLowerCase() == 'pending' ? Colors.orange : Colors.red);

        String formattedDate = '-';
        if (item['createdAt'] != null) {
          try {
            final dt = DateTime.parse(item['createdAt'].toString()).toLocal();
            formattedDate = DateFormat('dd MMM yyyy').format(dt);
          } catch (_) {
            formattedDate = item['createdAt'].toString();
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.gray200, width: 0.8)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  item['orderId'] ?? 'ORD-000000',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['clientName'] ?? 'Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['clientPhone'] ?? '-'} • ${item['clientEmail'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['packageName'] ?? 'Standard Plan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['staffName'] ?? 'Unassigned',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['department'] ?? 'Sales',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _currencyFormatter.format(amount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 4: Average Order Value (AOV) Comparison Table ---
  Widget _buildAovTable() {
    var list = List<Map<String, dynamic>>.from(
      widget.controller.filteredStaffOrders,
    );
    final aov = widget.controller.avgOrderValue;

    if (_searchQuery.isNotEmpty) {
      list = list.where((item) {
        final orderId = (item['orderId'] ?? '').toString().toLowerCase();
        final client = (item['clientName'] ?? '').toString().toLowerCase();
        final plan = (item['packageName'] ?? '').toString().toLowerCase();
        final staff = (item['staffName'] ?? '').toString().toLowerCase();
        return orderId.contains(_searchQuery) ||
            client.contains(_searchQuery) ||
            plan.contains(_searchQuery) ||
            staff.contains(_searchQuery);
      }).toList();
    }

    if (_selectedStatusFilter != 'All') {
      if (_selectedStatusFilter == 'Paid') {
        list = list.where((item) {
          final s = (item['status'] ?? '').toString().toLowerCase();
          final isPaid = item['isPaid'] == true;
          return isPaid || s == 'active' || s == 'paid';
        }).toList();
      } else if (_selectedStatusFilter == 'Pending') {
        list = list.where((item) {
          final s = (item['status'] ?? '').toString().toLowerCase();
          return s == 'pending';
        }).toList();
      }
    }

    final totalItems = list.length;
    final totalPages = totalItems > 0 ? (totalItems / _pageSize).ceil() : 1;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pageData =
        totalItems > 0 ? list.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

    return _buildTableWrapper(
      totalItems: totalItems,
      totalPages: totalPages,
      startIndex: startIndex,
      endIndex: endIndex,
      headerRow: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                'Order ID',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'Customer & Plan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Representative',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Order Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Variance vs Benchmark',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                'Benchmark AOV',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
          ],
        ),
      ),
      rows: pageData.map((item) {
        final amount = (item['amount'] ?? 0).toDouble();
        final diff = amount - aov;
        final isAbove = diff >= 0;
        final diffColor = isAbove ? Colors.green.shade700 : Colors.deepOrange;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.gray200, width: 0.8)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  item['orderId'] ?? 'ORD-000000',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['clientName'] ?? 'Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['packageName'] ?? 'Standard Plan',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item['staffName'] ?? 'Unassigned',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray800,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _currencyFormatter.format(amount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      isAbove
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: diffColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isAbove ? '+' : ''}${_currencyFormatter.format(diff)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: diffColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 110,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAbove
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAbove
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isAbove ? 'ABOVE AOV' : 'BELOW AOV',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isAbove ? Colors.green.shade800 : Colors.deepOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 5: Sales Conversion Rate Table ---
  Widget _buildConversionTable() {
    var list = List<Map<String, dynamic>>.from(
      widget.controller.filteredStaffPerformance,
    );

    if (_searchQuery.isNotEmpty) {
      list = list.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final dept = (item['department'] ?? '').toString().toLowerCase();
        final id = (item['staffId'] ?? '').toString().toLowerCase();
        final email = (item['email'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) ||
            dept.contains(_searchQuery) ||
            id.contains(_searchQuery) ||
            email.contains(_searchQuery);
      }).toList();
    }

    final totalItems = list.length;
    final totalPages = totalItems > 0 ? (totalItems / _pageSize).ceil() : 1;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pageData =
        totalItems > 0 ? list.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

    return _buildTableWrapper(
      totalItems: totalItems,
      totalPages: totalPages,
      startIndex: startIndex,
      endIndex: endIndex,
      headerRow: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: const Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Staff Representative',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Department',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Assigned Clients',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Converted Orders',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Conversion %',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Generated Revenue',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
          ],
        ),
      ),
      rows: pageData.map((item) {
        final assignedClients = (item['assignedClients'] ?? 0) as int;
        final ordersCount = (item['ordersCount'] ?? 0) as int;
        final totalSales = (item['totalSalesAmount'] ?? 0).toDouble();

        final conversionPercent = assignedClients > 0
            ? ((ordersCount / assignedClients) * 100).round()
            : (ordersCount > 0 ? 100 : 0);

        final Color tierColor = conversionPercent >= 15
            ? Colors.green
            : (conversionPercent >= 5 ? Colors.blue : Colors.orange);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.gray200, width: 0.8)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Staff Member',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${item['staffId'] ?? '-'} • ${item['email'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item['department'] ?? 'Sales',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray800,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$assignedClients Clients',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray800,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$ordersCount Orders',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: tierColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$conversionPercent%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tierColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _currencyFormatter.format(totalSales),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 3 & 6: Staff Leaderboard & Active Staff Table ---
  Widget _buildStaffLeaderboardTable() {
    var list = List<Map<String, dynamic>>.from(
      widget.controller.filteredStaffPerformance,
    );

    if (_searchQuery.isNotEmpty) {
      list = list.where((item) {
        final name = (item['name'] ?? '').toString().toLowerCase();
        final dept = (item['department'] ?? '').toString().toLowerCase();
        final id = (item['staffId'] ?? '').toString().toLowerCase();
        final email = (item['email'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery) ||
            dept.contains(_searchQuery) ||
            id.contains(_searchQuery) ||
            email.contains(_searchQuery);
      }).toList();
    }

    final totalItems = list.length;
    final totalPages = totalItems > 0 ? (totalItems / _pageSize).ceil() : 1;
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pageData =
        totalItems > 0 ? list.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

    return _buildTableWrapper(
      totalItems: totalItems,
      totalPages: totalPages,
      startIndex: startIndex,
      endIndex: endIndex,
      headerRow: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                'Rank',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'Sales Representative',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Department',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Assigned Clients',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Orders Closed',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Total Revenue',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(
                'Tier',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.gray700,
                ),
              ),
            ),
          ],
        ),
      ),
      rows: pageData.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final rank = startIndex + index + 1;
        final totalSales = (item['totalSalesAmount'] ?? 0).toDouble();
        final ordersCount = item['ordersCount'] ?? 0;
        final clientsCount = item['assignedClients'] ?? 0;

        Color badgeColor = Colors.grey;
        String badgeText = 'Inactive';
        if (rank == 1 && totalSales > 0) {
          badgeColor = Colors.amber.shade900;
          badgeText = 'Top Star';
        } else if (totalSales > 100000) {
          badgeColor = Colors.green;
          badgeText = 'Top Seller';
        } else if (totalSales > 0 || ordersCount > 0) {
          badgeColor = Colors.blue;
          badgeText = 'Active';
        } else if (clientsCount > 0) {
          badgeColor = Colors.orange;
          badgeText = 'Assigned';
        }

        String rankLabel = '#$rank';
        if (rank == 1) rankLabel = '🥇 #1';
        if (rank == 2) rankLabel = '🥈 #2';
        if (rank == 3) rankLabel = '🥉 #3';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: rank == 1 && widget.type == MetricCardType.topStaff
                ? Colors.amber.withValues(alpha: 0.04)
                : Colors.transparent,
            border: const Border(
              bottom: BorderSide(color: AppTheme.gray200, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  rankLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: rank <= 3
                        ? AppTheme.primaryBlue
                        : AppTheme.gray600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Staff Member',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${item['staffId'] ?? '-'} • ${item['email'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.gray500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item['department'] ?? 'Sales',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gray800,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$clientsCount Clients',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray800,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$ordersCount Orders',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.gray900,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _currencyFormatter.format(totalSales),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    badgeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- Table Wrapper with Pagination ---
  Widget _buildTableWrapper({
    required int totalItems,
    required int totalPages,
    required int startIndex,
    required int endIndex,
    required Widget headerRow,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table content with horizontal scroll capability
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double minTableWidth = 780;
                final tableWidth = constraints.maxWidth > minTableWidth
                    ? constraints.maxWidth
                    : minTableWidth;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        headerRow,
                        Expanded(
                          child: totalItems == 0
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.search_off_rounded,
                                          size: 40,
                                          color: AppTheme.gray400,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _searchQuery.isEmpty
                                              ? 'No data records found for this metric.'
                                              : 'No records match "$_searchQuery"',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.gray600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(children: rows),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border(
                top: BorderSide(color: AppTheme.gray200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalItems > 0
                      ? 'Showing ${startIndex + 1} to $endIndex of $totalItems entries'
                      : '0 entries',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.gray600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      'Page $_currentPage of $totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gray800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialog Footer ---
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.gray500,
              ),
              const SizedBox(width: 6),
              Text(
                'Data filtered by current dashboard controls',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.gray500,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // --- Header Data Config ---
  _HeaderConfig _getHeaderConfig() {
    final c = widget.controller;
    switch (widget.type) {
      case MetricCardType.totalSales:
        return _HeaderConfig(
          title: 'Total Sales Revenue Breakdown',
          subtitle:
              'Detailed itemized list of all completed orders generating sales revenue volume',
          icon: Icons.payments_rounded,
          color: AppTheme.primaryBlue,
          badge: _currencyFormatter.format(c.totalSalesAmount),
          badgeColor: Colors.green,
        );
      case MetricCardType.purchases:
        return _HeaderConfig(
          title: 'Purchases & Completed Orders',
          subtitle:
              'Full transaction log of completed purchase orders and subscriptions',
          icon: Icons.shopping_bag_rounded,
          color: const Color(0xFF10B981),
          badge: '${c.totalOrders} Orders',
          badgeColor: Colors.teal,
        );
      case MetricCardType.activeStaff:
        return _HeaderConfig(
          title: 'Active Sales Representatives',
          subtitle:
              'Performance and client allocation details for currently active sales staff',
          icon: Icons.groups_rounded,
          color: Colors.purple,
          badge: '${c.activeStaffCount} Active Staff',
          badgeColor: Colors.purple,
        );
      case MetricCardType.avgOrderValue:
        return _HeaderConfig(
          title: 'Average Order Value (AOV) Analysis',
          subtitle:
              'Order-level revenue distribution compared against company AOV benchmark',
          icon: Icons.trending_up_rounded,
          color: Colors.orange,
          badge: 'Benchmark: ${_currencyFormatter.format(c.avgOrderValue)}',
          badgeColor: Colors.orange,
        );
      case MetricCardType.conversionRate:
        return _HeaderConfig(
          title: 'Sales Conversion Rate Analysis',
          subtitle:
              'Staff conversion efficiency measured by converted orders per assigned client',
          icon: Icons.pie_chart_rounded,
          color: Colors.indigo,
          badge: '${c.conversionRate}% Conversion',
          badgeColor: Colors.indigo,
        );
      case MetricCardType.topStaff:
        final topStaff = c.topPerformingStaff;
        final topStaffName =
            topStaff != null ? (topStaff['name'] ?? 'Staff Member') : 'None';
        return _HeaderConfig(
          title: 'Top Performing Sales Staff Spotlight',
          subtitle:
              'Complete leaderboard rankings and individual sales performance metrics',
          icon: Icons.stars_rounded,
          color: Colors.amber.shade800,
          badge: topStaffName,
          badgeColor: Colors.amber.shade900,
        );
    }
  }

  // --- Summary KPI Cards ---
  List<_SummaryCardData> _getSummaryCards() {
    final c = widget.controller;
    switch (widget.type) {
      case MetricCardType.totalSales:
        return [
          _SummaryCardData(
            label: 'Total Sales Revenue',
            value: _currencyFormatter.format(c.totalSalesAmount),
            icon: Icons.currency_rupee_rounded,
            color: AppTheme.primaryBlue,
          ),
          _SummaryCardData(
            label: 'Paid Orders',
            value: '${c.totalOrders} Transactions',
            icon: Icons.receipt_long_rounded,
            color: Colors.green,
          ),
          _SummaryCardData(
            label: 'Average Order',
            value: _currencyFormatter.format(c.avgOrderValue),
            icon: Icons.trending_up_rounded,
            color: Colors.orange,
          ),
        ];

      case MetricCardType.purchases:
        return [
          _SummaryCardData(
            label: 'Total Purchases',
            value: '${c.totalOrders} Transactions',
            icon: Icons.shopping_bag_rounded,
            color: const Color(0xFF10B981),
          ),
          _SummaryCardData(
            label: 'Total Gross Value',
            value: _currencyFormatter.format(c.totalSalesAmount),
            icon: Icons.payments_rounded,
            color: AppTheme.primaryBlue,
          ),
          _SummaryCardData(
            label: 'Average Ticket',
            value: _currencyFormatter.format(c.avgOrderValue),
            icon: Icons.analytics_rounded,
            color: Colors.teal,
          ),
        ];

      case MetricCardType.activeStaff:
        final totalAssignedClients = c.filteredStaffPerformance.fold<int>(
          0,
          (sum, s) => sum + ((s['assignedClients'] ?? 0) as int),
        );
        return [
          _SummaryCardData(
            label: 'Active Sales Team',
            value: '${c.activeStaffCount} Representatives',
            icon: Icons.groups_rounded,
            color: Colors.purple,
          ),
          _SummaryCardData(
            label: 'Assigned Clients',
            value: '$totalAssignedClients Clients Handled',
            icon: Icons.person_pin_rounded,
            color: AppTheme.primaryBlue,
          ),
          _SummaryCardData(
            label: 'Total Orders Generated',
            value: '${c.totalOrders} Orders Closed',
            icon: Icons.verified_rounded,
            color: Colors.green,
          ),
        ];

      case MetricCardType.avgOrderValue:
        final orders = c.filteredStaffOrders;
        final aboveCount = orders.where((o) => (o['amount'] ?? 0) >= c.avgOrderValue).length;
        final belowCount = orders.where((o) => (o['amount'] ?? 0) < c.avgOrderValue).length;
        return [
          _SummaryCardData(
            label: 'Benchmark AOV',
            value: _currencyFormatter.format(c.avgOrderValue),
            icon: Icons.trending_up_rounded,
            color: Colors.orange,
          ),
          _SummaryCardData(
            label: 'Orders Above AOV',
            value: '$aboveCount Orders',
            icon: Icons.arrow_upward_rounded,
            color: Colors.green,
          ),
          _SummaryCardData(
            label: 'Orders Below AOV',
            value: '$belowCount Orders',
            icon: Icons.arrow_downward_rounded,
            color: Colors.deepOrange,
          ),
        ];

      case MetricCardType.conversionRate:
        final totalAssignedClients = c.filteredStaffPerformance.fold<int>(
          0,
          (sum, s) => sum + ((s['assignedClients'] ?? 0) as int),
        );
        return [
          _SummaryCardData(
            label: 'Overall Conversion',
            value: '${c.conversionRate}%',
            icon: Icons.pie_chart_rounded,
            color: Colors.indigo,
          ),
          _SummaryCardData(
            label: 'Total Assigned Clients',
            value: '$totalAssignedClients Accounts',
            icon: Icons.contacts_rounded,
            color: AppTheme.primaryBlue,
          ),
          _SummaryCardData(
            label: 'Converted Orders',
            value: '${c.totalOrders} Closed',
            icon: Icons.task_alt_rounded,
            color: Colors.green,
          ),
        ];

      case MetricCardType.topStaff:
        final topStaff = c.topPerformingStaff;
        final topStaffName =
            topStaff != null ? (topStaff['name'] ?? 'Staff Member') : 'None';
        final topRevenue = topStaff != null
            ? _currencyFormatter.format((topStaff['totalSalesAmount'] ?? 0).toDouble())
            : '₹0';
        return [
          _SummaryCardData(
            label: 'Top Performer',
            value: topStaffName,
            icon: Icons.emoji_events_rounded,
            color: Colors.amber.shade900,
          ),
          _SummaryCardData(
            label: 'Top Revenue Volume',
            value: topRevenue,
            icon: Icons.currency_rupee_rounded,
            color: AppTheme.primaryBlue,
          ),
          _SummaryCardData(
            label: 'Active Staff Pool',
            value: '${c.activeStaffCount} Members',
            icon: Icons.leaderboard_rounded,
            color: Colors.purple,
          ),
        ];
    }
  }
}

class _HeaderConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String badge;
  final Color badgeColor;

  _HeaderConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.badge,
    required this.badgeColor,
  });
}

class _SummaryCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
