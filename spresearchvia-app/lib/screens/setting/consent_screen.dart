import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/automated_trading.controller.dart';
import '../../core/theme/app_theme.dart';
import '../../services/snackbar.service.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AutomatedTradingController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trading Consent',
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
                          ? 'You have authorized the platform to place trades on your linked broker account for today.'
                          : 'You must grant execution consent daily to enable automated trading signals to reach your broker account.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        height: 1.4,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (hasConsent && controller.consentsDate.value.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Authorized on: ${controller.consentsDate.value}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 28),

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
                'You retain absolute control. You can revoke this consent at any time instantly, preventing further automated order placements.',
              ),
              _buildDisclosureItem(
                Icons.info_outline,
                'Execution Risk',
                'Automated trading involves execution and market risks. The platform is not liable for slippages, latency, or connection errors on the broker terminal.',
              ),

              const SizedBox(height: 40),

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
                    onPressed: () {
                      if (controller.linkedBrokers.isEmpty) {
                        SnackbarService.showError(
                            'Please link a broker first before granting trading consent.');
                        return;
                      }
                      // Grant consent using the first linked broker as default
                      final bCode = controller.linkedBrokers.first['brokerCode'];
                      controller.grantConsent(bCode);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Grant Consent for Today',
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

  Widget _buildDisclosureItem(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff1E4A7C), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff11416B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    height: 1.4,
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
