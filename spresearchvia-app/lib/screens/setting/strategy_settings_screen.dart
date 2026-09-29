import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/automated_trading.controller.dart';
import '../../core/theme/app_theme.dart';

class StrategySettingsScreen extends StatefulWidget {
  const StrategySettingsScreen({super.key});

  @override
  State<StrategySettingsScreen> createState() => _StrategySettingsScreenState();
}

class _StrategySettingsScreenState extends State<StrategySettingsScreen> {
  final controller = Get.find<AutomatedTradingController>();
  String _selectedOption = 'FIXED_1X';

  @override
  void initState() {
    super.initState();
    controller.fetchUserStrategy();
    controller.fetchStrategyHistory();
    _selectedOption = controller.selectedStrategy.value;
  }

  void _confirmStrategyChange(String newStrategy) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text(
              'Confirm Strategy Change',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Switching strategy to ${newStrategy == "LOSS_MULTIPLIER_2X" ? "2× Loss Multiplier" : "Fixed 1×"}:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text(
                'CRITICAL RULE: Your multiplier sequence will reset to 1× base immediately. A new legal strategy version (v1.1+) will be registered.',
                style: TextStyle(color: Colors.brown, fontSize: 12, height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Do you wish to proceed and sign this strategy version update?',
              style: TextStyle(fontSize: 12.5, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await controller.changeStrategy(newStrategy);
              if (success) {
                setState(() {
                  _selectedOption = newStrategy;
                });
                controller.fetchStrategyHistory();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1E4A7C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm & Sign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trading Strategy Settings',
          style: TextStyle(
            color: Color(0xff11416B),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xff11416B)),
      ),
      body: Obx(() {
        if (controller.isStrategyLoading.value && controller.currentStrategyData.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final strat = controller.currentStrategyData.value?['strategy'];
        final currentType = strat?['strategyType'] ?? controller.selectedStrategy.value;
        final currentMult = strat?['currentMultiplier'] ?? 1;
        final nextMult = strat?['nextTradeMultiplier'] ?? 1;
        final losses = strat?['consecutiveLosses'] ?? 0;
        final version = strat?['version'] ?? 1;
        final agreementVer = strat?['agreementVersion'] ?? 'v1.0';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Strategy Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1E4A7C), Color(0xff0D2847)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Active Strategy',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Version $version ($agreementVer)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentType == 'LOSS_MULTIPLIER_2X' ? '2× Loss Multiplier' : 'Fixed 1× Base Quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMetricPill('Current Multiplier', '${currentMult}×'),
                        const SizedBox(width: 12),
                        _buildMetricPill('Loss Streak', '$losses'),
                        const SizedBox(width: 12),
                        _buildMetricPill('Next Trade', '${nextMult}×'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Change Strategy Section
              const Text(
                'Change Trading Strategy',
                style: TextStyle(
                  color: Color(0xff11416B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a new strategy below. Each activation initiates a brand-new cycle starting at 1×:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 14),

              // Fixed 1x
              _buildRadioOption(
                title: 'Fixed 1× Base Quantity',
                description: 'Every trade uses base quantity with no multiplier escalation after losses.',
                value: 'FIXED_1X',
                isSelected: _selectedOption == 'FIXED_1X',
                icon: Icons.shield_outlined,
                onChanged: (val) => setState(() => _selectedOption = val),
              ),

              const SizedBox(height: 12),

              // 2x Loss Multiplier
              _buildRadioOption(
                title: '2× Loss Multiplier',
                description: 'Doubles lot size after each loss (1× → 2× → 4× → 8× → 16×). Resets to 1× upon profit.',
                value: 'LOSS_MULTIPLIER_2X',
                isSelected: _selectedOption == 'LOSS_MULTIPLIER_2X',
                icon: Icons.trending_up,
                onChanged: (val) => setState(() => _selectedOption = val),
              ),

              const SizedBox(height: 20),

              // Apply Change Button
              if (_selectedOption != currentType) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _confirmStrategyChange(_selectedOption),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Apply & Sign ${_selectedOption == "LOSS_MULTIPLIER_2X" ? "2× Loss" : "Fixed 1×"} Strategy',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Strategy History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Strategy Version History',
                    style: TextStyle(
                      color: Color(0xff11416B),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => controller.fetchStrategyHistory(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (controller.strategyHistory.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'No prior strategy changes recorded.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.strategyHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = controller.strategyHistory[index];
                    final prev = item['previousStrategy'] == 'LOSS_MULTIPLIER_2X' ? '2×' : (item['previousStrategy'] == 'FIXED_1X' ? '1×' : '—');
                    final next = item['newStrategy'] == 'LOSS_MULTIPLIER_2X' ? '2× Loss' : 'Fixed 1×';
                    final date = item['createdAt'] != null ? item['createdAt'].toString().substring(0, 10) : '—';
                    final changedBy = item['changedBy'] ?? 'User';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$prev  →  $next',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Changed by $changedBy • $date',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'v${item["newVersion"] ?? 1}',
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMetricPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String description,
    required String value,
    required bool isSelected,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1E4A7C).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xff1E4A7C) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? const Color(0xff1E4A7C) : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xff1E4A7C) : Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5, height: 1.3),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedOption,
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
              activeColor: const Color(0xff1E4A7C),
            ),
          ],
        ),
      ),
    );
  }
}
