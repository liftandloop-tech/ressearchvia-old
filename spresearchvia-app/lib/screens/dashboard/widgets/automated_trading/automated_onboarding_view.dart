import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../controllers/automated_trading.controller.dart';
import '../../../../core/theme/app_theme.dart';

class AutomatedOnboardingView extends StatelessWidget {
  final VoidCallback onAgreementSigned;

  const AutomatedOnboardingView({
    super.key,
    required this.onAgreementSigned,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AutomatedTradingController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Explainer Hero Card
        _buildVideoCard(context),
        const SizedBox(height: 24),

        // Precautionary Tips
        _buildPrecautionaryTips(),
        const SizedBox(height: 24),

        // Do's and Don'ts Section
        _buildDosAndDonts(),
        const SizedBox(height: 32),

        // Bottom CTA Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton(
            onPressed: () => _showAgreementBottomSheet(context, controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Continue to Sign Service Agreement',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openVideoModal(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.play_circle_fill, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Video Guide • 3:45 min',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'How Automated Trading Works',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Watch the step-by-step walkthrough of automated signal routing, lot sizing calculations, and broker terminal security.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrecautionaryTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.shield_outlined, color: Color(0xff11416B), size: 20),
            SizedBox(width: 8),
            Text(
              'Precautionary Tips',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff11416B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTipItem(
          icon: Icons.speed_rounded,
          title: 'Execution & Slippage',
          description:
              'Orders are routed at lightning speed via direct broker APIs. Minor price slippage may occur during heavy market volatility.',
        ),
        const SizedBox(height: 10),
        _buildTipItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Adequate Margin Buffer',
          description:
              'Maintain at least 1.5× the required margin in your broker account to comfortably accommodate position sizing and safety buffers.',
        ),
        const SizedBox(height: 10),
        _buildTipItem(
          icon: Icons.psychology_outlined,
          title: 'Disciplined Automation',
          description:
              'Algorithmic trading removes emotional hesitation. Avoid manual intervention in your broker terminal while strategy signals are live.',
        ),
      ],
    );
  }

  Widget _buildTipItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff11416B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xff11416B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff11416B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosAndDonts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Do's and Don'ts",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xff11416B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // DOs
              Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'DO',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildBulletItem(
                'Complete morning TOTP login before 09:15 AM every trading day.',
                isDo: true,
              ),
              _buildBulletItem(
                'Select a position sizing strategy matching your risk tolerance.',
                isDo: true,
              ),
              _buildBulletItem(
                'Set base lot quantities proportionate to your active capital.',
                isDo: true,
              ),

              const Divider(height: 24),

              // DONTs
              Row(
                children: [
                  Icon(Icons.cancel_rounded, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "DON'T",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildBulletItem(
                'Do not manually square off algorithmic positions in your broker app.',
                isDo: false,
              ),
              _buildBulletItem(
                'Do not change broker MPIN or reset TOTP during live trading hours.',
                isDo: false,
              ),
              _buildBulletItem(
                'Do not trade with unverified or insufficient margin.',
                isDo: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem(String text, {required bool isDo}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 8),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isDo ? AppTheme.primaryGreen : Colors.red.shade500,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openVideoModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Automated Trading Guide',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Video Explainer Player',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final url = Uri.parse('https://researchvia.in');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Open in Browser', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgreementBottomSheet(BuildContext context, AutomatedTradingController controller) {
    final RxBool isAccepted = false.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Activation Agreement',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            // Agreement Text
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Master Terms for Automated Advisory Signal Execution (v1.0)',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAgreementClause(
                      '1. Non-Discretionary Order Routing',
                      'The subscriber authorizes SP ResearchVia to route research advisory signals directly to the linked broker terminal. All trades are non-discretionary and execute strictly according to the published signal parameters.',
                    ),
                    _buildAgreementClause(
                      '2. Client Ownership & Revocation Right',
                      'The client maintains sole control over their broker account. The client may pause segments, alter lots, or revoke automated trading consent at any time without penalty.',
                    ),
                    _buildAgreementClause(
                      '3. Dedicated Static IP Requirement',
                      'As per SEBI and broker security mandates, automated execution requires a dedicated static IP. The subscriber agrees to maintain an active static IP proxy subscription.',
                    ),
                    _buildAgreementClause(
                      '4. Daily Independent Session Authorization',
                      'Daily trading sessions require client authentication with their broker credentials (MPIN + TOTP). The platform does not permanently store trading PINs.',
                    ),
                    _buildAgreementClause(
                      '5. Risk Disclosure & Sizing Multipliers',
                      'The subscriber acknowledges financial risks associated with derivative trading and agrees that chosen position sizing multipliers (e.g. 2× Loss Multiplier) carry capital escalation risks.',
                    ),
                  ],
                ),
              ),
            ),

            // Acceptance Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                children: [
                  Obx(() => Row(
                        children: [
                          Checkbox(
                            value: isAccepted.value,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (val) => isAccepted.value = val ?? false,
                          ),
                          Expanded(
                            child: Text(
                              'I have read, understood, and accept the Automated Trading Service Agreement (v1.0).',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(height: 12),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isAccepted.value && !controller.isSigningAgreement.value
                              ? () async {
                                  final success = await controller.signServiceAgreement();
                                  if (success) {
                                    Navigator.pop(ctx);
                                    onAgreementSigned();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.isSigningAgreement.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Sign & Proceed to Static IP Setup',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementClause(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff11416B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
