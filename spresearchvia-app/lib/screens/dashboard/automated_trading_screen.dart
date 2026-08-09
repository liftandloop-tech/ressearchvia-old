import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/automated_trading.controller.dart';
import '../../controllers/segment_plan.controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../services/snackbar.service.dart';
import './broker_auth_webview_screen.dart';

class AutomatedTradingScreen extends StatefulWidget {
  const AutomatedTradingScreen({super.key});

  @override
  State<AutomatedTradingScreen> createState() => _AutomatedTradingScreenState();
}

class _DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DashboardStatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomatedTradingScreenState extends State<AutomatedTradingScreen> {
  final controller = Get.put(AutomatedTradingController());

  String selectedBrokerCode = 'ANGEL_ONE';
  final _zebuClientIdController = TextEditingController();
  final _zebuApiKeyController = TextEditingController();
  final _zebuVendorCodeController = TextEditingController();
  final _zebuPasswordController = TextEditingController();
  final _zebuTotpKeyController = TextEditingController();

  @override
  void dispose() {
    _zebuClientIdController.dispose();
    _zebuApiKeyController.dispose();
    _zebuVendorCodeController.dispose();
    _zebuPasswordController.dispose();
    _zebuTotpKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Automated Trading',
          style: TextStyle(
            color: Color(0xff11416B),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xff11416B)),
            onPressed: () => controller.refreshData(),
          )
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.isInitializing.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PNL Summary Card
                _buildPnlSummarySection(),
                const SizedBox(height: 24),

                // Broker Status & Connection
                _buildBrokerSection(context),
                const SizedBox(height: 24),

                // Segment Configurations & Sizing
                _buildSegmentsSection(context),
                const SizedBox(height: 24),

                // Live Portfolio
                _buildLivePortfolioSection(),
                const SizedBox(height: 24),

                // Live Books (Orders/Trades)
                _buildLiveBooksSection(),
                const SizedBox(height: 24),

                // Trade History Logs
                _buildTradeHistorySection(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPnlSummarySection() {
    final summary = controller.pnlSummary.value;
    final realized = double.tryParse(summary?['realizedPnl']?.toString() ?? '0') ?? 0.0;
    final unrealized = double.tryParse(summary?['unrealizedPnl']?.toString() ?? '0') ?? 0.0;
    final winRate = double.tryParse(summary?['winRate']?.toString() ?? '0') ?? 0.0;
    final totalTrades = summary?['totalTrades'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Summary',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xff11416B),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _DashboardStatCard(
              label: 'Realized P&L',
              value: '₹${realized.toStringAsFixed(2)}',
              valueColor: realized >= 0 ? AppTheme.primaryGreen : Colors.red,
            ),
            _DashboardStatCard(
              label: 'Unrealized P&L',
              value: '₹${unrealized.toStringAsFixed(2)}',
              valueColor: unrealized >= 0 ? AppTheme.primaryGreen : Colors.red,
            ),
            _DashboardStatCard(
              label: 'Win Rate',
              value: '${winRate.toStringAsFixed(1)}%',
              valueColor: const Color(0xff11416B),
            ),
            _DashboardStatCard(
              label: 'Total Trades',
              value: totalTrades.toString(),
              valueColor: const Color(0xff11416B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrokerSection(BuildContext context) {
    if (controller.linkedBrokers.isEmpty) {
      return _buildLinkBrokerCard();
    }

    final broker = controller.linkedBrokers.first;
    final isActive = broker['isSessionActive'] == true;
    final margin = double.tryParse(broker['availableMargin']?.toString() ?? '0') ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Broker: ${broker['brokerCode']}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Get.defaultDialog(
                        title: 'Disconnect Broker',
                        middleText: 'Are you sure you want to disconnect and log out from your broker account?',
                        textConfirm: 'Yes, Disconnect',
                        textCancel: 'Cancel',
                        confirmTextColor: Colors.white,
                        onConfirm: () async {
                          Get.back();
                          await controller.unlinkBroker(broker['brokerCode']);
                        },
                      );
                    },
                    child: const Text(
                      'Disconnect Account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.1) : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'Active Daily Session' : 'Auth Required',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green.shade700 : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Client ID: ${broker['brokerClientId']}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          if (isActive && broker['profile'] != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileRow('Name', broker['profile']['name'] ?? ''),
                  _buildProfileRow('Email', broker['profile']['email'] ?? ''),
                  _buildProfileRow('Mobile', broker['profile']['mobileno'] ?? ''),
                  _buildProfileRow('Exchanges', (broker['profile']['exchanges'] as List?)?.join(', ') ?? ''),
                  _buildProfileRow('Products', (broker['profile']['products'] as List?)?.join(', ') ?? ''),
                  _buildProfileRow('Last Login', broker['profile']['lastlogintime'] ?? ''),
                  _buildProfileRow('Status', broker['profile']['activeStatus'] ?? ''),
                ],
              ),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 12),
            Text(
              'Available Margin: ₹${margin.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E4A7C),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            _buildAuthorizeForm(broker['brokerCode']),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkBrokerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connect Trading Broker',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xff11416B),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: selectedBrokerCode,
            items: const [
              DropdownMenuItem(value: 'ANGEL_ONE', child: Text('Angel One')),
              DropdownMenuItem(value: 'ZEBU', child: Text('Zebu')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedBrokerCode = val;
                });
              }
            },
            decoration: InputDecoration(
              labelText: 'Select Broker',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedBrokerCode == 'ZEBU') ...[
            TextFormField(
              controller: _zebuClientIdController,
              decoration: InputDecoration(
                labelText: 'Client ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _zebuApiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key (App Key)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _zebuVendorCodeController,
              decoration: InputDecoration(
                labelText: 'Vendor Code',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (selectedBrokerCode == 'ZEBU') {
                  final clientId = _zebuClientIdController.text.trim();
                  final apiKey = _zebuApiKeyController.text.trim();
                  final vendorCode = _zebuVendorCodeController.text.trim();

                  if (clientId.isEmpty || apiKey.isEmpty || vendorCode.isEmpty) {
                    Get.snackbar(
                      'Required Fields',
                      'Please fill in all Zebu details.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  final success = await controller.linkBroker(
                    'ZEBU',
                    clientId,
                    apiKey: apiKey,
                    vendorCode: vendorCode,
                  );
                  if (success) {
                    _zebuClientIdController.clear();
                    _zebuApiKeyController.clear();
                    _zebuVendorCodeController.clear();
                  }
                } else {
                  final authUrl = await controller.getAuthUrl(selectedBrokerCode);
                  if (authUrl != null) {
                    final success = await Get.to<bool>(
                      () => BrokerAuthWebviewScreen(authUrl: authUrl),
                    );
                    if (success == true) {
                      controller.refreshData();
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Connect Account', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorizeForm(String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        const Text(
          'Activate Daily Session',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xff11416B),
          ),
        ),
        const SizedBox(height: 16),
        if (code == 'ZEBU') ...[
          TextFormField(
            controller: _zebuPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _zebuTotpKeyController,
            decoration: InputDecoration(
              labelText: 'TOTP Key (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (code == 'ZEBU') {
                final password = _zebuPasswordController.text.trim();
                final totpKey = _zebuTotpKeyController.text.trim();

                if (password.isEmpty) {
                  Get.snackbar(
                    'Required Fields',
                    'Please enter your Zebu password.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                final success = await controller.authorizeBroker(
                  'ZEBU',
                  password,
                  totpKey,
                );
                if (success) {
                  _zebuPasswordController.clear();
                  _zebuTotpKeyController.clear();
                }
              } else {
                final authUrl = await controller.getAuthUrl(code);
                if (authUrl != null) {
                  final success = await Get.to<bool>(
                    () => BrokerAuthWebviewScreen(authUrl: authUrl),
                  );
                  if (success == true) {
                    controller.refreshData();
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1E4A7C),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Authorize daily session', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ),
      ],
    );
  }

  Widget _buildTradeHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Automated Trades',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xff11416B),
          ),
        ),
        const SizedBox(height: 12),
        if (controller.tradeHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No automated trades logged for today.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.tradeHistory.length,
            itemBuilder: (context, index) {
              final trade = controller.tradeHistory[index];
              final pnl = double.tryParse(trade['pnl']?.toString() ?? '0') ?? 0.0;
              final qty = trade['quantity'] ?? 0;
              final status = trade['status'] ?? 'OPEN';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qty: $qty | Multiplier: x${trade['multiplier'] ?? 1}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: Color(0xff11416B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      pnl >= 0 ? '+₹${pnl.toStringAsFixed(2)}' : '-₹${pnl.abs().toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: pnl >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSegmentsSection(BuildContext context) {
    if (!Get.isRegistered<SegmentPlanController>()) {
      Get.put(SegmentPlanController());
    }
    final segmentPlanCtrl = Get.find<SegmentPlanController>();

    final activeNames = segmentPlanCtrl.activeSegments.map((s) {
      final segObj = s['segmentId'];
      if (segObj is Map) {
        return segObj['segmentName']?.toString().toUpperCase();
      }
      return null;
    }).whereType<String>().toSet();

    final filteredSegments = controller.masterSegments.where((master) {
      final name = master['name']?.toString().toUpperCase() ?? '';
      return activeNames.contains(name);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trading Segments & Lot Allocation',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xff11416B),
          ),
        ),
        const SizedBox(height: 12),
        if (filteredSegments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Text(
                'No segments available. Please configure them.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSegments.length,
            itemBuilder: (context, index) {
              final master = filteredSegments[index];
              final userConfig = controller.userSegments.firstWhereOrNull(
                (us) => us['segmentId'] == master['id'],
              );
              final isConfigured = userConfig != null;
              final isActive = isConfigured && userConfig['status'] == 'ACTIVE';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          master['name'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1E4A7C),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : isConfigured
                                    ? Colors.amber.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive
                                ? 'ACTIVE'
                                : isConfigured
                                    ? 'PAUSED'
                                    : 'NOT CONFIGURED',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.green.shade700
                                  : isConfigured
                                      ? Colors.amber.shade800
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      master['description'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (isConfigured) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            master['sizingType'] == 'AMOUNT'
                                ? 'Trading Capital per Trade: '
                                : 'Base Lot Size: ',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff11416B),
                            ),
                          ),
                          Text(
                            master['sizingType'] == 'AMOUNT'
                                ? NumberFormat.currency(
                                    locale: 'en_IN',
                                    symbol: '₹',
                                    decimalDigits: 0,
                                  ).format(double.tryParse(userConfig['baseLot']?.toString() ?? '0') ?? 0)
                                : '${userConfig['baseLot']}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1E4A7C),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showConfigureSegmentSheet(context, master, userConfig),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Color(0xff1E4A7C)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              isConfigured ? 'Edit Configuration' : 'Configure Segment',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1E4A7C),
                              ),
                            ),
                          ),
                        ),
                        if (isConfigured) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            icon: Icon(
                              isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                              color: isActive ? Colors.amber.shade700 : AppTheme.primaryGreen,
                              size: 28,
                            ),
                            onPressed: () {
                              if (isActive) {
                                controller.pauseSegment(master['id']);
                              } else {
                                controller.activateSegment(
                                  segmentId: master['id'],
                                  capital: double.tryParse(userConfig['capital']?.toString() ?? '0') ?? 0.0,
                                  backupCapital: double.tryParse(userConfig['backupCapital']?.toString() ?? '0') ?? 0.0,
                                  baseLot: int.tryParse(userConfig['baseLot']?.toString() ?? '1') ?? 1,
                                  maxMultiplier: int.tryParse(userConfig['maxMultiplier']?.toString() ?? '1') ?? 1,
                                  dailyLossLimit: double.tryParse(userConfig['dailyLossLimit']?.toString() ?? '0') ?? 0.0,
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDetailCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xff11416B),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xff11416B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfigureSegmentSheet(BuildContext context, dynamic master, dynamic userConfig) {
    final capCtrl = TextEditingController(text: userConfig?['capital']?.toString() ?? '');
    final backupCtrl = TextEditingController(text: userConfig?['backupCapital']?.toString() ?? '');
    final lotCtrl = TextEditingController(text: userConfig?['baseLot']?.toString() ?? '1');
    final multCtrl = TextEditingController(text: userConfig?['maxMultiplier']?.toString() ?? '4');
    final lossCtrl = TextEditingController(text: userConfig?['dailyLossLimit']?.toString() ?? '');
    String strategy = (userConfig?['maxMultiplier']?.toString() == '1') ? 'Fixed' : 'Martingale';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Configure ${master['name']}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff11416B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set risk and allocation sizing constraints below for automated trade signals.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: lotCtrl,
                      keyboardType: master['sizingType'] == 'AMOUNT'
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.number,
                      decoration: InputDecoration(
                        labelText: master['sizingType'] == 'AMOUNT'
                            ? 'Trading Capital per Trade (₹)'
                            : 'Base Lot Size',
                        hintText: master['sizingType'] == 'AMOUNT'
                            ? 'e.g. 10000'
                            : 'e.g. 1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final isEquityCash = master['sizingType'] == 'AMOUNT';
                          final lotDouble = double.tryParse(lotCtrl.text) ?? 0.0;
                          final lot = isEquityCash ? lotDouble.round() : lotDouble.toInt();

                          if (lotDouble <= 0) {
                            SnackbarService.showError(isEquityCash
                                ? 'Please enter a valid capital amount per trade.'
                                : 'Please enter a valid base lot size.');
                            return;
                          }

                          final success = await controller.activateSegment(
                            segmentId: master['id'],
                            capital: 99999999.0,
                            backupCapital: 0.0,
                            baseLot: lot,
                            maxMultiplier: 1,
                            dailyLossLimit: 99999999.0,
                          );

                          if (success) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E4A7C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Save Configuration',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLivePortfolioSection() {
    final hasActiveSession = controller.linkedBrokers.any((b) => b['isSessionActive'] == true);
    if (!hasActiveSession) return const SizedBox.shrink();

    return Obx(() {
      if (controller.isLivePortfolioLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Color(0xff11416B)),
          ),
        );
      }

      if (controller.livePositions.isEmpty && controller.liveHoldings.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Positions Section
          if (controller.livePositions.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Broker Positions',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.livePositions.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final pos = controller.livePositions[index];
                      final pnl = double.tryParse(pos['unrealizedPnl']?.toString() ?? '0') ?? 0.0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pos['symbol'] ?? 'UNKNOWN',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Qty: ${pos['quantity']} | Avg: ₹${pos['avgPrice']} | LTP: ₹${pos['currentPrice']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${pnl >= 0 ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: pnl >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Live Holdings Section
          if (controller.liveHoldings.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Broker Holdings',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.liveHoldings.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final hld = controller.liveHoldings[index];
                      final pnl = double.tryParse(hld['unrealizedPnl']?.toString() ?? '0') ?? 0.0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hld['symbol'] ?? 'UNKNOWN',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Qty: ${hld['quantity']} | Avg: ₹${hld['avgPrice']} | LTP: ₹${hld['currentPrice']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${pnl >= 0 ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: pnl >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      );
    });
  }

  Widget _buildLiveBooksSection() {
    final hasActiveSession = controller.linkedBrokers.any((b) => b['isSessionActive'] == true);
    if (!hasActiveSession) return const SizedBox.shrink();

    return Obx(() {
      if (controller.isLivePortfolioLoading.value) return const SizedBox.shrink();

      if (controller.liveOrders.isEmpty && controller.liveTrades.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Orders Section
          if (controller.liveOrders.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Broker Orders (Today)',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.liveOrders.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final order = controller.liveOrders[index];
                      final side = order['side']?.toString().toUpperCase() ?? 'BUY';
                      final status = order['status']?.toString().toUpperCase() ?? 'PENDING';
                      final isComplete = status == 'COMPLETE' || status == 'EXECUTED';
                      final isRejected = status.contains('REJECT') || status == 'FAILED' || status == 'CANCELED';
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['symbol'] ?? 'UNKNOWN',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${side} ${order['quantity']} qty @ ₹${order['price']}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: side == 'BUY' ? Colors.green : Colors.orange,
                                  ),
                                ),
                                if (order['rejreason'] != null && order['rejreason'].toString().isNotEmpty)
                                  Text(
                                    'Reason: ${order['rejreason']}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isComplete
                                  ? Colors.green.withOpacity(0.1)
                                  : isRejected
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isComplete
                                    ? Colors.green
                                    : isRejected
                                        ? Colors.red
                                        : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Live Trades Section
          if (controller.liveTrades.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Broker Trade Book',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.liveTrades.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final trade = controller.liveTrades[index];
                      final side = trade['side']?.toString().toUpperCase() ?? 'BUY';
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trade['symbol'] ?? 'UNKNOWN',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Trade ID: ${trade['brokerOrderId']}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${side} ${trade['quantity']} qty',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: side == 'BUY' ? Colors.green : Colors.orange,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '₹${trade['price']}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      );
    });
  }
}
