import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/automated_trading.controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/snackbar.service.dart';

class AutomatedStrategyLotsCard extends StatefulWidget {
  final VoidCallback onConfigured;

  const AutomatedStrategyLotsCard({
    super.key,
    required this.onConfigured,
  });

  @override
  State<AutomatedStrategyLotsCard> createState() => _AutomatedStrategyLotsCardState();
}

class _AutomatedStrategyLotsCardState extends State<AutomatedStrategyLotsCard> {
  final controller = Get.find<AutomatedTradingController>();

  int baseLot = 1;
  String selectedStrategy = 'FIXED_1X';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    if (controller.userSegments.isNotEmpty) {
      baseLot = controller.userSegments.first['baseLot'] ?? 1;
    }
    final strat = controller.currentStrategyData.value?['strategy'];
    if (strat != null && strat['strategyType'] != null) {
      selectedStrategy = strat['strategyType'];
    } else {
      selectedStrategy = controller.selectedStrategy.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Strategy & Lot Sizing',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff11416B),
                      ),
                    ),
                    Text(
                      'Configure base quantities and recovery multipliers',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Base Lot Input
          const Text(
            'Base Trading Lots',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff11416B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildLotButton(Icons.remove, () {
                if (baseLot > 1) {
                  setState(() => baseLot--);
                }
              }),
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '$baseLot Lot${baseLot > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff11416B),
                  ),
                ),
              ),
              _buildLotButton(Icons.add, () {
                if (baseLot < 20) {
                  setState(() => baseLot++);
                }
              }),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Starting lot size for signals. Multipliers escalate from this lot.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Strategy Selector
          const Text(
            'Position Sizing Strategy',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff11416B),
            ),
          ),
          const SizedBox(height: 10),

          // Fixed 1x
          _buildStrategyCard(
            title: 'Fixed 1× Base Quantity',
            subtitle: 'Every trade strictly uses your base lot. No multiplier escalation after losses.',
            strategyKey: 'FIXED_1X',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 10),

          // 2x Loss Multiplier
          _buildStrategyCard(
            title: '2× Loss Multiplier (Martingale)',
            subtitle: 'Trade starts at 1×. On loss → 2× → 4× → 8× → 16× cap. On win → resets to 1×.',
            strategyKey: 'LOSS_MULTIPLIER_2X',
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 16),

          // Warning Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rule: Whenever you modify lots or strategy, today’s consent will be reset and you will need to grant a new daily consent before live trades can execute.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.amber.shade900,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _saveStrategyAndLots(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save Sizing & Strategy Configuration',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: const Color(0xff11416B)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildStrategyCard({
    required String title,
    required String subtitle,
    required String strategyKey,
    required IconData icon,
  }) {
    final isSelected = selectedStrategy == strategyKey;

    return GestureDetector(
      onTap: () => setState(() => selectedStrategy = strategyKey),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff11416B).withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xff11416B) : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xff11416B) : Colors.grey.shade500,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xff11416B) : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: strategyKey,
              groupValue: selectedStrategy,
              activeColor: const Color(0xff11416B),
              onChanged: (val) {
                if (val != null) setState(() => selectedStrategy = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveStrategyAndLots() async {
    setState(() => _isSaving = true);
    try {
      // 1. Update segment lots if segment exists
      if (controller.userSegments.isNotEmpty) {
        final segId = controller.userSegments.first['id'] ?? controller.userSegments.first['segmentId'];
        if (segId != null) {
          await controller.activateSegment(
            segmentId: segId.toString(),
            capital: 100000,
            backupCapital: 50000,
            baseLot: baseLot,
            maxMultiplier: 16,
            dailyLossLimit: 25000,
          );
        }
      }

      // 2. Update strategy
      await controller.changeStrategy(selectedStrategy);

      // Invalidate daily consent per specification
      controller.consentsStatus.value = 'NOT_GRANTED';

      SnackbarService.showSuccess(
        'Configuration updated! Please grant today’s daily trading consent.',
      );

      widget.onConfigured();
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
