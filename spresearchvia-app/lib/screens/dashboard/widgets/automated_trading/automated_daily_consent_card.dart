import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/automated_trading.controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/snackbar.service.dart';

class AutomatedDailyConsentCard extends StatefulWidget {
  final VoidCallback onEditConfigRequested;

  const AutomatedDailyConsentCard({
    super.key,
    required this.onEditConfigRequested,
  });

  @override
  State<AutomatedDailyConsentCard> createState() => _AutomatedDailyConsentCardState();
}

class _AutomatedDailyConsentCardState extends State<AutomatedDailyConsentCard> {
  final controller = Get.find<AutomatedTradingController>();
  bool _isAgreementChecked = true;
  bool _isGranting = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isConsentActive = controller.isDailyConsentActive;

      if (isConsentActive) {
        return _buildActiveConsentCard(context);
      }

      return _buildPendingConsentCard(context);
    });
  }

  Widget _buildActiveConsentCard(BuildContext context) {
    final stratData = controller.currentStrategyData.value?['strategy'];
    final stratType = stratData?['strategyType'] ?? controller.selectedStrategy.value;
    final currentMult = stratData?['currentMultiplier'] ?? 1;
    final broker = controller.linkedBrokers.isNotEmpty
        ? controller.linkedBrokers.firstWhere(
            (b) => b['isSessionActive'] == true,
            orElse: () => controller.linkedBrokers.first,
          )
        : null;
    final margin = double.tryParse(broker?['availableMargin']?.toString() ?? '0') ?? 0.0;
    final date = controller.consentsDate.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0D2847), Color(0xff1E4A7C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0D2847).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Daily Consent Active',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.4)),
                ),
                child: const Text(
                  'LIVE READY',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'Your broker account is authorized to receive and execute automated signals for today’s trading session.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Details grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Strategy',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stratType == 'LOSS_MULTIPLIER_2X'
                          ? '2× Loss (${currentMult}×)'
                          : 'Fixed 1×',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Available Margin',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${margin.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Authorized on: $date',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmAdjustConfiguration(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Adjust Lots / Strategy',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _revokeConsent(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Revoke Consent',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingConsentCard(BuildContext context) {
    final stratData = controller.currentStrategyData.value?['strategy'];
    final stratType = stratData?['strategyType'] ?? controller.selectedStrategy.value;
    final broker = controller.linkedBrokers.isNotEmpty
        ? controller.linkedBrokers.firstWhere(
            (b) => b['isSessionActive'] == true,
            orElse: () => controller.linkedBrokers.first,
          )
        : null;
    final margin = double.tryParse(broker?['availableMargin']?.toString() ?? '0') ?? 0.0;
    final baseLot = controller.userSegments.isNotEmpty ? (controller.userSegments.first['baseLot'] ?? 1) : 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.06),
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
                child: const Icon(Icons.gpp_maybe_rounded, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Daily Trading Consent',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff11416B),
                      ),
                    ),
                    Text(
                      'Grant today’s digital execution authorization',
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

          // Configuration Summary Pill
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Broker', '${broker?['brokerCode'] ?? 'Linked'} (Margin: ₹${margin.toStringAsFixed(0)})'),
                const SizedBox(height: 6),
                _buildSummaryRow('Base Lot Size', '$baseLot Lot${baseLot > 1 ? 's' : ''}'),
                const SizedBox(height: 6),
                _buildSummaryRow('Strategy', stratType == 'LOSS_MULTIPLIER_2X' ? '2× Loss Multiplier (1× cycle)' : 'Fixed 1× Base Lot'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Agreement Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: _isAgreementChecked,
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) => setState(() => _isAgreementChecked = val ?? true),
              ),
              Expanded(
                child: Text(
                  'I authorize SP ResearchVia to execute automated signals on my linked broker account according to the active strategy for today.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Grant Consent Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAgreementChecked && !_isGranting
                  ? () => _grantDailyConsent(broker?['brokerCode'] ?? 'ANGEL_ONE')
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isGranting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Sign & Grant Daily Consent',
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

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xff11416B),
          ),
        ),
      ],
    );
  }

  void _confirmAdjustConfiguration(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Modify Sizing & Strategy?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Important Rule: Updating your trading lots or strategy will invalidate today’s active daily consent. You will need to grant a new daily consent to resume automated trading.\n\nDo you want to proceed?',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.consentsStatus.value = 'NOT_GRANTED';
              widget.onEditConfigRequested();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Proceed to Edit', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _grantDailyConsent(String brokerCode) async {
    setState(() => _isGranting = true);
    try {
      final success = await controller.grantConsent(brokerCode);
      if (success) {
        SnackbarService.showSuccess('Daily trading consent granted! Algo trading live.');
      }
    } finally {
      setState(() => _isGranting = false);
    }
  }

  Future<void> _revokeConsent() async {
    final success = await controller.revokeConsent();
    if (success) {
      SnackbarService.showSuccess('Trading consent revoked. Automated order routing paused.');
    }
  }
}
