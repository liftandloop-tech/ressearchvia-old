import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/automated_trading.controller.dart';
import '../../core/theme/app_theme.dart';
import '../../services/snackbar.service.dart';
import 'strategy_settings_screen.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AutomatedTradingController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trading Consent & Strategy',
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
        if (controller.isInitializing.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasConsent = controller.consentsStatus.value == 'ACTIVE';
        final stratData = controller.currentStrategyData.value?['strategy'];
        final currentStratType = stratData?['strategyType'] ?? controller.selectedStrategy.value;
        final currentMult = stratData?['currentMultiplier'] ?? 1;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: hasConsent
                        ? [const Color(0xff1E4A7C), const Color(0xff0D2847)]
                        : [Colors.grey.shade800, Colors.grey.shade900],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (hasConsent ? const Color(0xff1E4A7C) : Colors.black)
                          .withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasConsent ? Icons.verified_user : Icons.gpp_maybe,
                          color: hasConsent ? AppTheme.primaryGreen : Colors.amber,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasConsent ? 'Daily Consent Active' : 'Consent Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasConsent
                          ? 'You have authorized the platform to place trades on your linked broker account for today using your active strategy.'
                          : 'You must select your trading strategy and grant execution consent daily to enable automated trading signals to reach your broker account.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.4,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (hasConsent && controller.consentsDate.value.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Authorized on: ${controller.consentsDate.value}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentStratType == 'LOSS_MULTIPLIER_2X' ? '2× Loss (${currentMult}×)' : 'Fixed 1×',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Strategy Selection Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Position Sizing Strategy',
                    style: TextStyle(
                      color: Color(0xff11416B),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (hasConsent)
                    TextButton.icon(
                      onPressed: () => Get.to(() => const StrategySettingsScreen()),
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text('Manage'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how order lot sizing escalates following trade outcomes:',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 14),

              // Option 1: Fixed 1x
              _buildStrategyCard(
                title: 'Fixed 1× Base Quantity',
                subtitle: 'Every trade uses your base quantity. No multiplier progression after losses. Recommended for conservative risk tolerance.',
                strategyKey: 'FIXED_1X',
                isSelected: controller.selectedStrategy.value == 'FIXED_1X',
                icon: Icons.shield_outlined,
                onTap: hasConsent ? null : () => controller.selectedStrategy.value = 'FIXED_1X',
              ),

              const SizedBox(height: 12),

              // Option 2: 2x Loss Multiplier
              _buildStrategyCard(
                title: '2× Loss Multiplier',
                subtitle: 'Initial trade = 1×. On loss → 2× → 4× → 8× → 16× (capped). On profit → resets to 1×. Recovers drawdown quickly with disciplined stops.',
                strategyKey: 'LOSS_MULTIPLIER_2X',
                isSelected: controller.selectedStrategy.value == 'LOSS_MULTIPLIER_2X',
                icon: Icons.trending_up,
                onTap: hasConsent ? null : () => controller.selectedStrategy.value = 'LOSS_MULTIPLIER_2X',
              ),

              const SizedBox(height: 24),

              // Regulatory Disclosures
              const Text(
                'Regulatory Disclosures',
                style: TextStyle(
                  color: Color(0xff11416B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              _buildDisclosureItem(
                Icons.check_circle_outline,
                'One-Day Validity',
                'Trading consents are strictly valid for a single trading session and expire automatically at the end of the day.',
              ),
              _buildDisclosureItem(
                Icons.security_outlined,
                'Client Controlled',
                'You retain absolute control. You can revoke this consent or change your strategy anytime. Admins cannot alter your strategy without your consent.',
              ),
              _buildDisclosureItem(
                Icons.info_outline,
                'Execution & Multiplier Risk',
                'Automated trading involves execution and market risks. The 2× strategy increases order lot sizes after losses up to a maximum safety ceiling (16×).',
              ),

              const SizedBox(height: 20),

              // Agreement Checkbox (if not consented yet)
              if (!hasConsent) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: controller.isAgreementAccepted.value,
                      onChanged: (val) => controller.isAgreementAccepted.value = val ?? true,
                      activeColor: AppTheme.primaryGreen,
                    ),
                    Expanded(
                      child: Text(
                        'I accept the Automated Trading Agreement (v1.0) and authorize orders according to the selected strategy.',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 12,
                          height: 1.3,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons
              if (hasConsent)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.revokeConsent(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Revoke Consent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isAgreementAccepted.value
                        ? () {
                            if (controller.linkedBrokers.isEmpty) {
                              SnackbarService.showError(
                                  'Please link a broker first before granting trading consent.');
                              return;
                            }
                            final bCode = controller.linkedBrokers.first['brokerCode'];
                            controller.grantConsent(bCode);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign & Grant Daily Consent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStrategyCard({
    required String title,
    required String subtitle,
    required String strategyKey,
    required bool isSelected,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1E4A7C).withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xff1E4A7C) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xff1E4A7C) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? const Color(0xff1E4A7C) : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Radio<String>(
                        value: strategyKey,
                        groupValue: isSelected ? strategyKey : '',
                        onChanged: onTap != null ? (_) => onTap() : null,
                        activeColor: const Color(0xff1E4A7C),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      height: 1.4,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclosureItem(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff1E4A7C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff11416B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11.5,
                    height: 1.35,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
