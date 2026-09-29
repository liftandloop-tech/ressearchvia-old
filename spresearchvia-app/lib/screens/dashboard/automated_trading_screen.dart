import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/automated_trading.controller.dart';
import '../../core/theme/app_theme.dart';
import '../../services/snackbar.service.dart';
import './widgets/automated_trading/automated_stepper_header.dart';
import './widgets/automated_trading/automated_onboarding_view.dart';
import './widgets/automated_trading/automated_proxy_purchase_card.dart';
import './widgets/automated_trading/automated_broker_config_card.dart';
import './widgets/automated_trading/automated_strategy_lots_card.dart';
import './widgets/automated_trading/automated_daily_consent_card.dart';

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
  int? _overrideStep;

  int _calculateCurrentStep() {
    if (!controller.hasSignedAgreement.value) {
      return 0; // Stage 1: Explainer & Master Agreement
    }
    if (!controller.hasActiveProxy) {
      return 1; // Stage 2: Purchase Static IP
    }
    if (!controller.isBrokerConfigured || !controller.isBrokerSessionActive) {
      return 2; // Stage 3: Broker Configuration & Daily Session Auth
    }
    if (!controller.isLotConfigured || !controller.isStrategyConfigured) {
      return 3; // Stage 4: Lot & Strategy Configuration Gate
    }
    return 4; // Stage 5: Live Session & Daily Consent
  }

  int get _effectiveStep {
    final current = _calculateCurrentStep();
    if (_overrideStep != null) {
      if (_overrideStep! <= current) {
        return _overrideStep!;
      }
    }
    return current;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
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
            onPressed: () {
              setState(() {
                _overrideStep = null;
              });
              controller.refreshData();
            },
          )
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isInitializing.value) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
        }

        final currentStep = _calculateCurrentStep();
        final displayStep = _effectiveStep;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _overrideStep = null;
            });
            await controller.refreshData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Progress Stepper
                AutomatedStepperHeader(
                  currentStep: displayStep,
                  onStepTapped: (index) {
                    if (index <= currentStep) {
                      setState(() {
                        _overrideStep = index;
                      });
                    } else {
                      SnackbarService.showInfo(
                        'Please complete Step ${currentStep + 1} before proceeding to this step.',
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Return banner if reviewing earlier steps
                if (_overrideStep != null && _overrideStep != currentStep) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Browsing prior step settings.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppTheme.primaryBlue),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _overrideStep = null),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: const Text(
                            'Return to Active Step',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Dynamic Step Content
                _buildStepContent(context, displayStep),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(BuildContext context, int step) {
    switch (step) {
      case 0:
        return AutomatedOnboardingView(
          onAgreementSigned: () {
            setState(() {
              _overrideStep = null;
            });
            controller.refreshData();
          },
        );
      case 1:
        return AutomatedProxyPurchaseCard(
          onProxyAssigned: () {
            setState(() {
              _overrideStep = null;
            });
            controller.refreshData();
          },
        );
      case 2:
        return AutomatedBrokerConfigCard(
          onSessionAuthorized: () {
            setState(() {
              _overrideStep = null;
            });
            controller.refreshData();
          },
        );
      case 3:
        return AutomatedStrategyLotsCard(
          onConfigured: () {
            setState(() {
              _overrideStep = null;
            });
            controller.refreshData();
          },
        );
      case 4:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Consent Card (authorise trading session & summary)
            AutomatedDailyConsentCard(
              onEditConfigRequested: () {
                setState(() {
                  _overrideStep = 3;
                });
              },
            ),
            const SizedBox(height: 24),

            // Performance Summary
            _buildPnlSummarySection(),
            const SizedBox(height: 24),

            // Live Portfolio (Positions & Holdings)
            _buildLivePortfolioSection(),
            const SizedBox(height: 24),

            // Live Books (Orders & Trades)
            _buildLiveBooksSection(),
            const SizedBox(height: 24),

            // Recent Automated Trades
            _buildTradeHistorySection(),
          ],
        );
    }
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
                                  '$side ${order['quantity']} qty @ ₹${order['price']}',
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
                                '$side ${trade['quantity']} qty',
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
}
