import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/dashboard/automated_trading.controller.dart';
import '../../../config/routes.config.dart';
import '../../layouts/dashboard_layout.widget.dart';

class AutomatedTradingDashboardScreen extends StatelessWidget {
  const AutomatedTradingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminAutomatedTradingController());

    return Obx(() {
      final isLocked = !controller.isTradingActive.value;
      final currentTab = controller.selectedTab.value;

      return DashboardLayout(
        child: Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================================
              // HEADER & REAL-TIME ENGINE STATUS
              // ========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Copy Trading Engine',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isLocked ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLocked ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isLocked ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isLocked ? 'Engine Paused' : 'Live Intraday Engine',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isLocked ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Multi-tenant automated intraday order distribution, subscriber risk controls, and broker gateways.',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.strategyConfig),
                        icon: const Icon(Icons.tune_rounded, size: 14),
                        label: const Text('Strategy Rules'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Refresh all engine data',
                        icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF475569)),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: () => controller.refreshAdminData(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ========================================================
              // SLEEK SEGMENTED TAB SWITCHER
              // ========================================================
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton(
                      label: 'Trading Terminal',
                      icon: Icons.bolt_rounded,
                      isActive: currentTab == 0,
                      onTap: () => controller.setTab(0),
                    ),
                    _buildTabButton(
                      label: 'Copy Traders & Risk',
                      icon: Icons.group_outlined,
                      badgeCount: controller.strategyUsers.length,
                      isActive: currentTab == 1,
                      onTap: () => controller.setTab(1),
                    ),
                    _buildTabButton(
                      label: 'Broker Accounts',
                      icon: Icons.account_balance_outlined,
                      isActive: currentTab == 2,
                      onTap: () => controller.setTab(2),
                    ),
                    _buildTabButton(
                      label: 'SRE & Operations',
                      icon: Icons.security_rounded,
                      badgeCount: controller.reconciliationIssues.isNotEmpty
                          ? controller.reconciliationIssues.length
                          : null,
                      badgeColor: const Color(0xFFDC2626),
                      isActive: currentTab == 3,
                      onTap: () => controller.setTab(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ========================================================
              // TAB VIEW CONTENT
              // ========================================================
              Expanded(
                child: SingleChildScrollView(
                  child: _buildActiveTabContent(currentTab, controller, context),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  static Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    int? badgeCount,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: isActive ? Border.all(color: const Color(0xFFE2E8F0)) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor ?? (isActive ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor != null ? Colors.white : (isActive ? Colors.white : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(
    int activeTab,
    AdminAutomatedTradingController controller,
    BuildContext context,
  ) {
    switch (activeTab) {
      case 0:
        return _TradingTerminalTab(controller: controller);
      case 1:
        return _CopyTradersTab(controller: controller);
      case 2:
        return _BrokerAccountsTab(controller: controller);
      case 3:
        return _SreOperationsTab(controller: controller);
      default:
        return _TradingTerminalTab(controller: controller);
    }
  }
}

// ============================================================================
// TAB 0: TRADING TERMINAL WORKSTATION
// ============================================================================
class _TradingTerminalTab extends StatefulWidget {
  final AdminAutomatedTradingController controller;

  const _TradingTerminalTab({required this.controller});

  @override
  State<_TradingTerminalTab> createState() => _TradingTerminalTabState();
}

class _TradingTerminalTabState extends State<_TradingTerminalTab> {
  String? selectedSegmentId;
  String selectedSide = 'BUY';
  String selectedSegmentEnum = 'INTRADAY';
  String selectedExchange = 'NSE';
  String selectedOrderType = 'LIMIT';

  final symbolController = TextEditingController();
  final entryPriceController = TextEditingController();
  final targetPriceController = TextEditingController();
  final stopLossController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  double? _liveLtp;

  @override
  void dispose() {
    symbolController.dispose();
    entryPriceController.dispose();
    targetPriceController.dispose();
    stopLossController.dispose();
    super.dispose();
  }

  void _onSymbolChanged(String val) async {
    final query = val.trim();
    if (query.length < 2) {
      if (_searchResults.isNotEmpty) {
        setState(() => _searchResults = []);
      }
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await widget.controller.searchInstruments(query, '');
      if (mounted) {
        setState(() {
          _searchResults = results.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _selectInstrument(Map<String, dynamic> selection) async {
    final symbol = selection['symbol'] ?? '';
    final exchSeg = selection['exch_seg']?.toString().toUpperCase() ?? 'NSE';

    setState(() {
      symbolController.text = symbol;
      _searchResults = [];
      if (['NSE', 'BSE', 'NFO', 'MCX', 'CDS'].contains(exchSeg)) {
        selectedExchange = exchSeg;
      }
      if (exchSeg == 'NFO') {
        selectedSegmentEnum = 'FO';
      } else {
        selectedSegmentEnum = 'INTRADAY';
      }
    });

    final ltpData = await widget.controller.fetchLtp(
      symbol: symbol,
      exchange: selectedExchange,
      token: selection['token']?.toString(),
    );

    if (mounted) {
      setState(() {
        if (ltpData != null && ltpData['ltp'] != null) {
          _liveLtp = double.tryParse(ltpData['ltp'].toString());
          if (_liveLtp != null && _liveLtp! > 0 && entryPriceController.text.isEmpty) {
            entryPriceController.text = _liveLtp!.toStringAsFixed(2);
          }
        }
      });
    }
  }

  String _calcTargetPercent() {
    final entry = double.tryParse(entryPriceController.text);
    final target = double.tryParse(targetPriceController.text);
    if (entry != null && entry > 0 && target != null) {
      final diffPct = ((target - entry) / entry) * 100;
      final prefix = diffPct >= 0 ? '+' : '';
      return '$prefix${diffPct.toStringAsFixed(1)}%';
    }
    return '';
  }

  String _calcStopLossPercent() {
    final entry = double.tryParse(entryPriceController.text);
    final sl = double.tryParse(stopLossController.text);
    if (entry != null && entry > 0 && sl != null) {
      final diffPct = ((sl - entry) / entry) * 100;
      final prefix = diffPct >= 0 ? '+' : '';
      return '$prefix${diffPct.toStringAsFixed(1)}%';
    }
    return '';
  }

  String _calcRiskReward() {
    final entry = double.tryParse(entryPriceController.text);
    final target = double.tryParse(targetPriceController.text);
    final sl = double.tryParse(stopLossController.text);

    if (entry != null && target != null && sl != null && entry > 0) {
      final reward = (target - entry).abs();
      final risk = (entry - sl).abs();
      if (risk > 0) {
        final ratio = (reward / risk).toStringAsFixed(1);
        return '1 : $ratio';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopTwoCol = screenWidth >= 1100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN: ORDER TICKET
        Expanded(
          flex: isDesktopTwoCol ? 7 : 12,
          child: _buildOrderTicket(context),
        ),

        if (isDesktopTwoCol) ...[
          const SizedBox(width: 20),
          // RIGHT COLUMN: PRE-FLIGHT REACH & RECENT FEED
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _buildPreFlightReachCard(),
                const SizedBox(height: 16),
                _buildRecentSignalsFeedCard(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderTicket(BuildContext context) {
    final targetPct = _calcTargetPercent();
    final slPct = _calcStopLossPercent();
    final rrRatio = _calcRiskReward();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top ticket header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Order Ticket',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Instant copy trade fan-out across subscribed broker accounts.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    '⚡ INTRADAY (MIS)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 18),

            // Segment & Action Side (BUY / SELL)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Segment Dropdown
                Expanded(
                  flex: 3,
                  child: Obx(() {
                    final segmentsList = widget.controller.segments;
                    if (segmentsList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Loading segments...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      );
                    }

                    if (selectedSegmentId == null && segmentsList.isNotEmpty) {
                      selectedSegmentId = segmentsList.first['id'];
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: selectedSegmentId,
                      items: segmentsList.map<DropdownMenuItem<String>>((seg) {
                        return DropdownMenuItem<String>(
                          value: seg['id'],
                          child: Text(
                            seg['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedSegmentId = val),
                      decoration: InputDecoration(
                        labelText: 'Client Segment *',
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        prefixIcon: const Icon(Icons.hub_outlined, size: 16, color: Color(0xFF64748B)),
                      ),
                      validator: (val) => val == null ? 'Segment required' : null,
                    );
                  }),
                ),
                const SizedBox(width: 14),

                // BUY / SELL Segmented Switcher
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => selectedSide = 'BUY'),
                            borderRadius: BorderRadius.circular(6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: selectedSide == 'BUY' ? const Color(0xFF059669) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'BUY / LONG',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: selectedSide == 'BUY' ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => selectedSide = 'SELL'),
                            borderRadius: BorderRadius.circular(6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: selectedSide == 'SELL' ? const Color(0xFFE11D48) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'SELL / SHORT',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: selectedSide == 'SELL' ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Instrument Search Input
            TextFormField(
              controller: symbolController,
              decoration: InputDecoration(
                labelText: 'Instrument Symbol *',
                hintText: 'e.g. SBIN, RELIANCE, NIFTY24OCT...',
                labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : (_liveLtp != null
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: InkWell(
                              onTap: () {
                                if (_liveLtp != null) {
                                  setState(() {
                                    entryPriceController.text = _liveLtp!.toStringAsFixed(2);
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.trending_up, size: 12, color: Color(0xFF059669)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LTP: ₹${_liveLtp!.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF047857),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : null),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: _onSymbolChanged,
              validator: (val) => val == null || val.isEmpty ? 'Symbol is required' : null,
            ),

            // Autocomplete suggestions
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, idx) {
                    final item = _searchResults[idx];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      title: Text(item['symbol'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                      subtitle: Text(item['name'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['exch_seg'] ?? '',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                      onTap: () => _selectInstrument(item),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Pricing Row: Entry, Target, Stop Loss
            Row(
              children: [
                // Entry Price
                Expanded(
                  child: TextFormField(
                    controller: entryPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Entry (₹) *',
                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      hintText: '0.00',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Target Price
                Expanded(
                  child: TextFormField(
                    controller: targetPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Target (₹) *',
                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      hintText: '0.00',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      suffixIcon: targetPct.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(7),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  targetPct,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Stop Loss
                Expanded(
                  child: TextFormField(
                    controller: stopLossController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Stop Loss (₹) *',
                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      hintText: '0.00',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      suffixIcon: slPct.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(7),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  slPct,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Execution Type & Risk-Reward Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Type:',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'LIMIT',
                        isSelected: selectedOrderType == 'LIMIT',
                        onTap: () => setState(() => selectedOrderType = 'LIMIT'),
                      ),
                      const SizedBox(width: 6),
                      _buildChip(
                        label: 'MARKET',
                        isSelected: selectedOrderType == 'MARKET',
                        onTap: () => setState(() => selectedOrderType = 'MARKET'),
                      ),
                      const SizedBox(width: 6),
                      _buildChip(
                        label: 'STOPLOSS',
                        isSelected: selectedOrderType == 'STOPLOSS_LIMIT',
                        onTap: () => setState(() => selectedOrderType = 'STOPLOSS_LIMIT'),
                      ),
                    ],
                  ),

                  if (rrRatio.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        '⚖️ R:R = $rrRatio',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            Obx(() {
              final isPub = widget.controller.isPublishing.value;
              return SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: isPub ? null : _confirmAndPublish,
                  icon: isPub
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 15),
                  label: Text(
                    isPub ? 'Distributing Orders...' : 'Publish Copy Trade Signal',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildPreFlightReachCard() {
    return Obx(() {
      final users = widget.controller.strategyUsers;
      final totalTraders = users.length;
      final activeMultipliers = users.where((u) => u['strategyType'] == 'LOSS_MULTIPLIER_2X').length;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.radar_rounded, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  'Copy Trading Readiness',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildReachMetric('Active Subscribers', '$totalTraders', Icons.people_outline),
                _buildReachMetric('2× Multipliers', '$activeMultipliers', Icons.trending_up_rounded),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF059669)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SEBI Intraday Multi-Tenant Compliance & Broker OAuth active.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildReachMetric(String title, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSignalsFeedCard() {
    return Obx(() {
      final signals = widget.controller.recentSignals;
      final isLoading = widget.controller.isRecentSignalsLoading.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.history_rounded, size: 16, color: Color(0xFF475569)),
                    SizedBox(width: 8),
                    Text(
                      'Recent Published Signals',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 15, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => widget.controller.fetchRecentSignals(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading && signals.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
            else if (signals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No signals published yet today.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: signals.take(4).length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, idx) {
                  final s = signals[idx];
                  final isBuy = s['side'] == 'BUY';
                  final symbol = s['symbol'] ?? '';
                  final entry = s['entryPrice'] ?? '—';
                  final status = s['status'] ?? 'PUBLISHED';
                  final tradesCount = (s['trades'] as List?)?.length ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isBuy ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isBuy ? 'BUY' : 'SELL',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isBuy ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(symbol, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                                Text('Entry: ₹$entry', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                            if (tradesCount > 0)
                              Text('$tradesCount executed', style: const TextStyle(fontSize: 10, color: Color(0xFF059669))),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
    });
  }

  void _confirmAndPublish() {
    if (formKey.currentState?.validate() != true) return;

    final symbol = symbolController.text.trim().toUpperCase();
    final entry = entryPriceController.text.trim();
    final target = targetPriceController.text.trim();
    final sl = stopLossController.text.trim();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: const [
            Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 20),
            SizedBox(width: 8),
            Text('Confirm Signal Fan-Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to execute this order across all subscribers in this segment:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _confirmRow('Action', '$selectedSide $symbol ($selectedExchange)'),
                  _confirmRow('Entry Price', '₹$entry'),
                  _confirmRow('Target Price', '₹$target (${_calcTargetPercent()})'),
                  _confirmRow('Stop Loss', '₹$sl (${_calcStopLossPercent()})'),
                  _confirmRow('Execution', '$selectedOrderType (INTRADAY MIS)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _submitSignal();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Confirm & Publish'),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  void _submitSignal() async {
    final success = await widget.controller.publishSignal(
      segmentId: selectedSegmentId!,
      symbol: symbolController.text.trim().toUpperCase(),
      exchange: selectedExchange,
      segment: selectedSegmentEnum,
      side: selectedSide,
      orderType: selectedOrderType,
      entryPrice: double.parse(entryPriceController.text),
      stopLoss: double.parse(stopLossController.text),
      targetPrice: double.parse(targetPriceController.text),
    );

    if (success) {
      setState(() {
        symbolController.clear();
        entryPriceController.clear();
        targetPriceController.clear();
        stopLossController.clear();
        _searchResults = [];
        _liveLtp = null;
      });
    }
  }
}

// ============================================================================
// TAB 1: COPY TRADERS & MULTIPLIERS
// ============================================================================
class _CopyTradersTab extends StatelessWidget {
  final AdminAutomatedTradingController controller;

  const _CopyTradersTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Active Subscribers & Loss Multipliers',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Real-time overview of subscriber loss streaks, position multipliers, and exposure.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => controller.fetchStrategyDashboardUsers(),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Refresh Multipliers'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Obx(() {
            if (controller.isStrategyUsersLoading.value && controller.strategyUsers.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(strokeWidth: 2)));
            }

            if (controller.strategyUsers.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    'No active copy trading subscribers found with allocated capital.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                  ),
                ),
              );
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: Color(0xFF475569)),
                  dataTextStyle: const TextStyle(fontSize: 12, color: Colors.black87),
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  columns: const [
                    DataColumn(label: Text('CLIENT / USER')),
                    DataColumn(label: Text('BROKER / ID')),
                    DataColumn(label: Text('STRATEGY')),
                    DataColumn(label: Text('MULTIPLIER')),
                    DataColumn(label: Text('LOSS STREAK')),
                    DataColumn(label: Text('NEXT LOT SIZING')),
                    DataColumn(label: Text('ACTIVE EXPOSURE')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: controller.strategyUsers.map((u) {
                    final is2x = u['strategyType'] == 'LOSS_MULTIPLIER_2X';
                    final losses = u['consecutiveLosses'] ?? 0;
                    final exposure = u['exposure'] != null ? '₹${u["exposure"]}' : '—';
                    final mult = u['currentMultiplier'] ?? '1×';
                    final isHighRisk = losses >= 3;

                    return DataRow(cells: [
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(u['name'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(u['mobile'] ?? '', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5)),
                        ],
                      )),
                      DataCell(Text('${u["brokerCode"]} (${u["clientId"]})')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: is2x ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          is2x ? '2× Loss Multiplier' : 'Fixed 1×',
                          style: TextStyle(
                            color: is2x ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isHighRisk ? const Color(0xFFFFF1F2) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mult,
                          style: TextStyle(
                            color: isHighRisk ? const Color(0xFFE11D48) : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      )),
                      DataCell(Row(
                        children: [
                          if (losses > 0)
                            Icon(Icons.warning_amber_rounded, size: 13, color: isHighRisk ? Colors.red : Colors.orange),
                          const SizedBox(width: 4),
                          Text('$losses', style: TextStyle(fontWeight: losses > 0 ? FontWeight.w700 : FontWeight.w500)),
                        ],
                      )),
                      DataCell(Text(u['nextMultiplier'] ?? '1×', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700))),
                      DataCell(Text(exposure, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isHighRisk ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isHighRisk ? 'High Escalation' : 'Healthy',
                          style: TextStyle(
                            color: isHighRisk ? const Color(0xFFE11D48) : const Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                        ),
                      )),
                      DataCell(IconButton(
                        icon: const Icon(Icons.open_in_new, size: 15, color: Color(0xFF2563EB)),
                        onPressed: () => Get.toNamed('/users/${u["userId"]}'),
                        tooltip: 'View Subscriber Details',
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 2: BROKER ACCOUNTS & SESSIONS
// ============================================================================
class _BrokerAccountsTab extends StatelessWidget {
  final AdminAutomatedTradingController controller;

  const _BrokerAccountsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final searchCtrl = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Master Brokers Overview Cards
        Row(
          children: [
            Expanded(
              child: _buildBrokerCard(
                brokerName: 'Angel One SmartAPI',
                brokerCode: 'ANGEL_ONE',
                authType: 'Publisher OAuth 2.0 (PIN + TOTP)',
                redirectUrl: 'https://tradetest.researchvia.in/brokers/ANGEL_ONE/callback',
                status: 'Operational',
                icon: Icons.hub_rounded,
                color: const Color(0xFFFF5722),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildBrokerCard(
                brokerName: 'Zebu (Omnesys)',
                brokerCode: 'ZEBU',
                authType: 'API Session (Password + TOTP)',
                redirectUrl: 'Direct REST Authentication',
                status: 'Operational',
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Live Inspector
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Client Broker Portfolio & Positions Inspector',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 3),
              const Text(
                'Inspect live broker positions, holdings, order status, and trade book for any client account.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        labelText: 'User ID, Email, or Client ID (e.g. Z67017)',
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        prefixIcon: const Icon(Icons.person_search_rounded, size: 16, color: Color(0xFF64748B)),
                      ),
                      onSubmitted: (val) => controller.inspectUserBrokerData(val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(() {
                    final isLoading = controller.isUserBrokerLoading.value;
                    return ElevatedButton.icon(
                      onPressed: isLoading ? null : () => controller.inspectUserBrokerData(searchCtrl.text),
                      icon: isLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.search_rounded, size: 15),
                      label: Text(isLoading ? 'Fetching...' : 'Inspect Live Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Inspected result
              Obx(() {
                final data = controller.inspectedUserBrokerData.value;
                if (data == null) return const SizedBox.shrink();

                final user = data['user'] ?? {};
                final brokerCode = data['brokerCode'] ?? '';
                final clientCode = data['brokerClientId'] ?? '';
                final isActive = data['isSessionActive'] == true;
                final positions = (data['positions'] as List?) ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account: ${user['name'] ?? 'User'} (${user['email'] ?? ''})',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text('Broker: $brokerCode · Client ID: $clientCode', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3)),
                          ),
                          child: Text(
                            isActive ? 'Connected 🟢' : 'Session Expired 🔴',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isActive ? const Color(0xFF047857) : const Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Live Open Positions (${positions.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    if (positions.isEmpty)
                      const Text('No live positions found on broker account.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: positions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, idx) {
                          final pos = positions[idx];
                          final pnl = double.tryParse(pos['unrealizedPnl']?.toString() ?? '0') ?? 0.0;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(pos['symbol'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            subtitle: Text('Qty: ${pos['quantity']} | Avg: ₹${pos['avgPrice']} | LTP: ₹${pos['currentPrice']}', style: const TextStyle(fontSize: 11)),
                            trailing: Text(
                              '${pnl >= 0 ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: pnl >= 0 ? const Color(0xFF059669) : const Color(0xFFE11D48),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrokerCard({
    required String brokerName,
    required String brokerCode,
    required String authType,
    required String redirectUrl,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 9),
                  Text(brokerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Auth Mechanism: $authType', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          Text('Endpoint / Callback: $redirectUrl', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB 3: SRE OPERATIONS & RECONCILIATION
// ============================================================================
class _SreOperationsTab extends StatelessWidget {
  final AdminAutomatedTradingController controller;

  const _SreOperationsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final reasonController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emergency Kill Switch Card
        Obx(() {
          final isLocked = !controller.isTradingActive.value;

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isLocked ? const Color(0xFFFFF1F2) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLocked ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLocked ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLocked ? Icons.lock_rounded : Icons.check_circle_rounded,
                    color: isLocked ? const Color(0xFFE11D48) : const Color(0xFF059669),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLocked ? 'Emergency Trading Lock Active' : 'Global Trading Engine Running',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isLocked ? const Color(0xFF9F1239) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLocked
                            ? 'Trading halted globally. Signal fan-out and broker order placement are suspended.'
                            : 'All copy-trading strategies are executing normally to Angel One and Zebu accounts.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!isLocked) {
                      _showKillswitchDialog(context, controller, reasonController);
                    } else {
                      controller.toggleGlobalTrading(false, '');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLocked ? const Color(0xFF059669) : const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: Text(isLocked ? 'Resume Trading' : 'Activate Kill Switch', style: const TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 18),

        // Reconciliation Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Trade Reconciliation & Discrepancies',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Audit platform trades against broker order books to detect orphaned executions or mismatches.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => controller.triggerReconciliation(),
                    icon: const Icon(Icons.sync_rounded, size: 14),
                    label: const Text('Run Manual Audit', style: TextStyle(fontSize: 12.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Obx(() {
                final issues = controller.reconciliationIssues;
                if (issues.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'Zero reconciliation discrepancies found. All broker trades and platform trades match perfectly.',
                        style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: issues.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, idx) {
                    final item = issues[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item['issueType'] ?? 'Discrepancy', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      subtitle: Text('${item["description"]} · Severity: ${item["severity"]}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(onPressed: () => controller.resolveIssue(item['id']), child: const Text('Resolve', style: TextStyle(fontSize: 11.5))),
                          TextButton(onPressed: () => controller.escalateIssue(item['id']), child: const Text('Escalate', style: TextStyle(color: Colors.orange, fontSize: 11.5))),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _showKillswitchDialog(
    BuildContext context,
    AdminAutomatedTradingController controller,
    TextEditingController reasonCtrl,
  ) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Confirm Emergency Stop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Specify a reason for immediately halting trading engine globally:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Host broker API experiencing major latency/downtime',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.isNotEmpty) {
                controller.toggleGlobalTrading(true, reasonCtrl.text);
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
            child: const Text('Activate Killswitch'),
          ),
        ],
      ),
    );
  }
}
