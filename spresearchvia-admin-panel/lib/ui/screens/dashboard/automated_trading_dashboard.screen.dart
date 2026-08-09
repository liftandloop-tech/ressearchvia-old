import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/dashboard/automated_trading.controller.dart';
import '../../../config/theme.config.dart';
import '../../layouts/dashboard_layout.widget.dart';
import '../../widgets/button.widget.dart';

class AutomatedTradingDashboardScreen extends StatelessWidget {
  const AutomatedTradingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminAutomatedTradingController());
    final reasonController = TextEditingController();

    return Obx(() {
      return DashboardLayout(
        child: Container(
          color: AppTheme.gray50,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SRE Operations & Automated Trading',
                          style: AppTheme.h1Style.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Monitor system health, run trade reconciliation, and toggle emergency lock controls.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                      onPressed: () => controller.refreshAdminData(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // EMERGENCY KILL SWITCH CARD
                _buildEmergencyLockCard(context, controller, reasonController),
                const SizedBox(height: 24),

                // PUBLISH TRADING CALL FORM
                _PublishSignalSection(controller: controller),
                const SizedBox(height: 24),

                // USER LIVE BROKER INSPECTOR
                _buildUserBrokerInspectorSection(controller),
                const SizedBox(height: 24),

                // RECONCILIATION & DISCREPANCIES LIST
                _buildReconciliationSection(controller),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmergencyLockCard(
    BuildContext context,
    AdminAutomatedTradingController controller,
    TextEditingController reasonCtrl,
  ) {
    final isLocked = !controller.isTradingActive.value;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLocked ? Colors.red.shade200 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLocked ? Colors.red.shade50 : Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocked ? Icons.emergency_share : Icons.play_arrow,
              color: isLocked ? Colors.red : Colors.green,
              size: 36,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLocked ? 'Trading Suspended Globally' : 'Trading Core Active',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isLocked ? Colors.red.shade800 : Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLocked
                      ? 'The trading engine has been manually locked. All signal executions to broker APIs are paused.'
                      : 'Trades are executing normally on target user accounts based on analysts signals.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Button(
            title: isLocked ? 'Resume Trading' : 'STOP TRADING',
            buttonType: isLocked ? ButtonType.green : ButtonType.red,
            onTap: () {
              if (!isLocked) {
                // Show stop confirmation dialog
                Get.dialog(
                  AlertDialog(
                    title: const Text('Confirm Emergency Stop'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Please specify a reason for stopping trading globally:'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: reasonCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Host broker APIs experiencing major outages',
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
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Activate Killswitch'),
                      ),
                    ],
                  ),
                );
              } else {
                controller.toggleGlobalTrading(false, '');
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildUserBrokerInspectorSection(AdminAutomatedTradingController controller) {
    final searchCtrl = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Live Broker Portfolio & Book Inspector',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Inspect live broker positions, holdings, order status, and trade book for any client account.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'User ID, Email, or Client ID (e.g. Z67017)',
                    hintText: 'Enter Client ID or User Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_search),
                  ),
                  onSubmitted: (val) {
                    controller.inspectUserBrokerData(val);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Obx(() {
                final isLoading = controller.isUserBrokerLoading.value;
                return Button(
                  title: isLoading ? 'Fetching...' : 'Inspect Broker Account',
                  buttonType: ButtonType.blue,
                  icon: Icons.search,
                  showLoading: isLoading,
                  onTap: isLoading
                      ? null
                      : () {
                          controller.inspectUserBrokerData(searchCtrl.text);
                        },
                );
              }),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() {
            final data = controller.inspectedUserBrokerData.value;
            if (data == null) {
              return const SizedBox.shrink();
            }

            final user = data['user'] ?? {};
            final brokerCode = data['brokerCode'] ?? '';
            final clientCode = data['brokerClientId'] ?? '';
            final isActive = data['isSessionActive'] == true;
            final positions = (data['positions'] as List?) ?? [];
            final holdings = (data['holdings'] as List?) ?? [];
            final orders = (data['orders'] as List?) ?? [];
            final trades = (data['trades'] as List?) ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account: ${user['name'] ?? 'User'} (${user['email'] ?? ''})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Broker: $brokerCode | Client ID: $clientCode',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isActive ? Colors.green.shade200 : Colors.red.shade200),
                      ),
                      child: Text(
                        isActive ? 'Session Active' : 'Session Expired',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Positions Table
                const Text('Live Positions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (positions.isEmpty)
                  const Text('No live positions found.', style: TextStyle(color: Colors.grey, fontSize: 13))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: positions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final pos = positions[idx];
                      final pnl = double.tryParse(pos['unrealizedPnl']?.toString() ?? '0') ?? 0.0;
                      return ListTile(
                        dense: true,
                        title: Text(pos['symbol'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Qty: ${pos['quantity']} | Avg: ₹${pos['avgPrice']} | LTP: ₹${pos['currentPrice']}'),
                        trailing: Text(
                          '${pnl >= 0 ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pnl >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),

                // Holdings Table
                const Text('Live Holdings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (holdings.isEmpty)
                  const Text('No live holdings found.', style: TextStyle(color: Colors.grey, fontSize: 13))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: holdings.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final hld = holdings[idx];
                      final pnl = double.tryParse(hld['unrealizedPnl']?.toString() ?? '0') ?? 0.0;
                      return ListTile(
                        dense: true,
                        title: Text(hld['symbol'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Qty: ${hld['quantity']} | Avg: ₹${hld['avgPrice']} | LTP: ₹${hld['currentPrice']}'),
                        trailing: Text(
                          '${pnl >= 0 ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pnl >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),

                // Orders Table
                const Text('Live Orders (Today)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (orders.isEmpty)
                  const Text('No orders placed today.', style: TextStyle(color: Colors.grey, fontSize: 13))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final ord = orders[idx];
                      return ListTile(
                        dense: true,
                        title: Text(ord['symbol'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${ord['side']} ${ord['quantity']} qty @ ₹${ord['price']} ${ord['rejreason'] != null && ord['rejreason'].toString().isNotEmpty ? "| " + ord['rejreason'].toString() : ""}'),
                        trailing: Text(
                          ord['status'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),

                // Trade Book Table
                const Text('Live Trade Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                if (trades.isEmpty)
                  const Text('No trades executed today.', style: TextStyle(color: Colors.grey, fontSize: 13))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trades.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final trd = trades[idx];
                      return ListTile(
                        dense: true,
                        title: Text(trd['symbol'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Trade ID: ${trd['brokerOrderId']} | ${trd['side']} ${trd['quantity']} qty'),
                        trailing: Text(
                          '₹${trd['price']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReconciliationSection(AdminAutomatedTradingController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reconciliation Discrepancies',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              Button(
                title: 'Run Reconciliation',
                buttonType: ButtonType.blue,
                icon: Icons.sync,
                onTap: () => controller.triggerReconciliation(),
              )
            ],
          ),
          const SizedBox(height: 16),
          if (controller.reconciliationIssues.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('No active reconciliation issues found in the system.', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.reconciliationIssues.length,
              itemBuilder: (context, index) {
                final issue = controller.reconciliationIssues[index];
                return ListTile(
                  title: Text('Discrepancy: ${issue['issueType']}'),
                  subtitle: Text('Details: ${issue['description']} | Severity: ${issue['severity']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        tooltip: 'Resolve',
                        onPressed: () => controller.resolveIssue(issue['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, color: Colors.amber),
                        tooltip: 'Escalate',
                        onPressed: () => controller.escalateIssue(issue['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PublishSignalSection extends StatefulWidget {
  final AdminAutomatedTradingController controller;

  const _PublishSignalSection({super.key, required this.controller});

  @override
  State<_PublishSignalSection> createState() => _PublishSignalSectionState();
}

class _PublishSignalSectionState extends State<_PublishSignalSection> {
  String? selectedSegmentId;
  String selectedSide = 'BUY';
  String selectedSegmentEnum = 'INTRADAY';
  String selectedExchange = 'NSE';
  String selectedOrderType = 'LIMIT';
  bool showAdvancedOptions = false;
  
  final symbolController = TextEditingController();
  final entryPriceController = TextEditingController();
  final targetPriceController = TextEditingController();
  final stopLossController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final formKey = GlobalKey<FormState>();

  void _onSymbolChanged(String val) async {
    final query = val.trim();
    if (query.length < 2) {
      if (_searchResults.isNotEmpty) {
        setState(() {
          _searchResults = [];
        });
      }
      return;
    }
    setState(() {
      _isSearching = true;
    });
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
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectInstrument(Map<String, dynamic> selection) {
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
      } else if (exchSeg == 'MCX' || exchSeg == 'CDS') {
        selectedSegmentEnum = 'INTRADAY';
      } else {
        selectedSegmentEnum = 'INTRADAY';
      }
    });
  }

  @override
  void dispose() {
    symbolController.dispose();
    entryPriceController.dispose();
    targetPriceController.dispose();
    stopLossController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final targetPct = _calcTargetPercent();
    final slPct = _calcStopLossPercent();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Form(
        key: formKey,
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
                      'Publish Trading Call (RA Signal)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Mandatory: Select Segment, Action, Instrument, Entry, Target & Stop Loss.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      showAdvancedOptions = !showAdvancedOptions;
                    });
                  },
                  icon: Icon(
                    showAdvancedOptions ? Icons.expand_less : Icons.tune,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                  label: Text(
                    showAdvancedOptions ? 'Hide Auto-filled Settings' : 'Auto-filled Settings',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ROW 1: MANDATORY TARGET SEGMENT & ACTION SIDE
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Obx(() {
                    final segmentsList = widget.controller.segments;
                    if (segmentsList.isEmpty) {
                      return const Text(
                        'Loading client segments...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      );
                    }

                    if (selectedSegmentId == null && segmentsList.isNotEmpty) {
                      selectedSegmentId = segmentsList.first['id'];
                    }

                    return DropdownButtonFormField<String>(
                      value: selectedSegmentId,
                      items: segmentsList.map<DropdownMenuItem<String>>((seg) {
                        return DropdownMenuItem<String>(
                          value: seg['id'],
                          child: Text(seg['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSegmentId = val;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Target Client Segment *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group, size: 20),
                      ),
                      validator: (val) => val == null ? 'Segment is required' : null,
                    );
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Action Side *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedSide = 'BUY';
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selectedSide == 'BUY' ? Colors.green.shade600 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'BUY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedSide == 'BUY' ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedSide = 'SELL';
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selectedSide == 'SELL' ? Colors.red.shade600 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'SELL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedSide == 'SELL' ? Colors.white : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: symbolController,
              decoration: InputDecoration(
                labelText: 'Trading Symbol * (Search e.g. SBIN, BANKNIFTY)',
                hintText: 'Type 2+ characters to search instrument master...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: _onSymbolChanged,
              validator: (val) => val == null || val.isEmpty ? 'Trading symbol is required' : null,
            ),
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return InkWell(
                      onTap: () => _selectInstrument(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['symbol'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                if (item['name'] != null && item['name'].toString().isNotEmpty)
                                  Text(
                                    item['name'],
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['exch_seg'] ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ROW 3: MANDATORY ENTRY PRICE, TARGET PRICE & STOP LOSS WITH BADGES
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entryPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Entry Price * (₹)',
                      hintText: 'e.g. 810.50',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      if (double.tryParse(val) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: targetPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Target Price * (₹)',
                          hintText: 'e.g. 835.00',
                          border: const OutlineInputBorder(),
                          suffixIcon: targetPct.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      targetPct,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
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
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: stopLossController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Stop Loss * (₹)',
                          hintText: 'e.g. 795.00',
                          border: const OutlineInputBorder(),
                          suffixIcon: slPct.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      slPct,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
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
                    ],
                  ),
                ),
              ],
            ),

            // ROW 4: OPTIONAL AUTO-FILLED SETTINGS (COLLAPSIBLE)
            if (showAdvancedOptions) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Auto-filled System Parameters (Auto-derived from instrument & default execution profile):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedExchange,
                            items: const [
                              DropdownMenuItem(value: 'NSE', child: Text('NSE')),
                              DropdownMenuItem(value: 'BSE', child: Text('BSE')),
                              DropdownMenuItem(value: 'NFO', child: Text('NFO')),
                              DropdownMenuItem(value: 'MCX', child: Text('MCX')),
                              DropdownMenuItem(value: 'CDS', child: Text('CDS')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedExchange = val;
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Exchange',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSegmentEnum,
                            items: const [
                              DropdownMenuItem(value: 'INTRADAY', child: Text('Intraday')),
                              DropdownMenuItem(value: 'DELIVERY', child: Text('Delivery')),
                              DropdownMenuItem(value: 'FO', child: Text('F&O')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedSegmentEnum = val;
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Product Segment',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedOrderType,
                            items: const [
                              DropdownMenuItem(value: 'LIMIT', child: Text('LIMIT')),
                              DropdownMenuItem(value: 'MARKET', child: Text('MARKET')),
                              DropdownMenuItem(value: 'STOPLOSS_LIMIT', child: Text('STOPLOSS_LIMIT')),
                              DropdownMenuItem(value: 'STOPLOSS_MARKET', child: Text('STOPLOSS_MARKET')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedOrderType = val;
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Order Execution Type',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Obx(() {
              final isPub = widget.controller.isPublishing.value;
              return SizedBox(
                width: double.infinity,
                child: Button(
                  title: isPub ? 'Publishing Trading Signal...' : 'Publish Trading Call Now',
                  buttonType: ButtonType.blue,
                  icon: Icons.send,
                  showLoading: isPub,
                  onTap: isPub ? null : _submitForm,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (formKey.currentState?.validate() == true) {
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
        });
      }
    }
  }
}
