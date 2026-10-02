import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/services/auth.service.dart';
import 'package:url_launcher/url_launcher.dart';

class JobTermsAgreementScreen extends StatefulWidget {
  const JobTermsAgreementScreen({super.key});

  @override
  State<JobTermsAgreementScreen> createState() => _JobTermsAgreementScreenState();
}

class _JobTermsAgreementScreenState extends State<JobTermsAgreementScreen> {
  final AuthService _authService = Get.find<AuthService>();
  final AuthController _authController = Get.find<AuthController>();

  bool _agreedToTerms = false;
  bool _isDigioLoading = false;
  bool _isCheckingStatus = false;
  String? _digioSigningUrl;
  bool _digioInitiated = false;
  String _errorMessage = '';
  String? _rejectionReason;
  String? _agreementStatus;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    try {
      final status = await _authService.checkStaffAgreementStatus();
      if (status.success) {
        if ((status.agreementStatus == 'VERIFIED' ||
                status.agreementStatus == 'PENDING_ADMIN_VERIFICATION' ||
                status.agreementStatus == 'PENDING_REVIEW') &&
            status.user != null) {
          _authController.onAgreementSigned(status.user!);
          return;
        }
        setState(() {
          _agreementStatus = status.agreementStatus;
          _rejectionReason = status.agreementRejectionReason;
          if (status.signingUrl != null) {
            _digioSigningUrl = status.signingUrl;
            _digioInitiated = true;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _startDigioEsign() async {
    setState(() => _errorMessage = '');

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please check the box above to confirm that you have read and accepted the agreement terms.');
      return;
    }

    setState(() => _isDigioLoading = true);

    try {
      final result = await _authService.initiateStaffDigioAgreement();
      setState(() => _isDigioLoading = false);

      if (result.success && result.signingUrl != null) {
        setState(() {
          _digioSigningUrl = result.signingUrl;
          _digioInitiated = true;
        });

        final uri = Uri.parse(result.signingUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar(
            'Aadhaar E-Sign Initiated',
            'Your signing link is generated. Check your registered email/phone or open the link below.',
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to initialize Digio Aadhaar e-sign. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isDigioLoading = false;
        _errorMessage = 'Error initiating Digio e-sign: $e';
      });
    }
  }

  Future<void> _checkDigioStatus() async {
    setState(() {
      _errorMessage = '';
      _isCheckingStatus = true;
    });

    try {
      final status = await _authService.checkStaffAgreementStatus();
      setState(() => _isCheckingStatus = false);

      if (status.success && status.hasSignedAgreement && status.user != null) {
        Get.snackbar(
          'Agreement Verified',
          'Aadhaar E-Sign completed! Workspace unlocked.',
          backgroundColor: AppTheme.successGreen.withValues(alpha: 0.15),
          colorText: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
        );
        _authController.onAgreementSigned(status.user!);
      } else {
        Get.snackbar(
          'Pending Signature',
          'Document has not been signed yet on Digio. Please complete Aadhaar OTP signing on Digio and click refresh.',
          backgroundColor: Colors.amber.withValues(alpha: 0.15),
          colorText: Colors.amber.shade900,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      setState(() {
        _isCheckingStatus = false;
        _errorMessage = 'Error checking agreement status: $e';
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final user = _authController.user.value;
    final staffId = user?.rawJson?['staffId'] ?? user?.userId ?? 'STF-PENDING';
    final role = user?.roleData?['name'] ?? user?.subscriptionPlan ?? 'Staff';
    final department = user?.departmentData?['name'] ?? user?.rawJson?['deparment'] ?? 'General';
    final supervisor = user?.rawJson?['assignedDirectorName'] ?? 'Admin Authority';
    final todayStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    return SelectionArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'RESEARCHVIA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Employee Terms & Code of Conduct Agreement',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _authController.logout(),
            icon: const Icon(Icons.logout, size: 18, color: Color(0xFF64748B)),
            label: const Text('Log Out', style: TextStyle(color: Color(0xFF64748B))),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_agreementStatus == 'REJECTED')
                  _buildRejectionBanner(),
                if (_agreementStatus == 'PENDING_ADMIN_VERIFICATION')
                  _buildPendingVerificationBanner(),
                // Top Banner
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF22C55E), width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock_outline, color: Color(0xFF22C55E), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'MANDATORY ONBOARDING GATE',
                                  style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            todayStr,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Employment Agreement & Code of Conduct',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome to the ResearchVia team! Before you can access client management, market research algorithms, and company tools, you must review and digitally sign your terms of employment.',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Employee & Appointment Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: AppTheme.primaryBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Appointment Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      Wrap(
                        spacing: 24,
                        runSpacing: 16,
                        children: [
                          _buildDetailItem('Employee Name', user?.fullName ?? 'N/A'),
                          _buildDetailItem('Staff ID', staffId),
                          _buildDetailItem('Designated Role', role),
                          _buildDetailItem('Department', department),
                          _buildDetailItem('Reporting Supervisor', supervisor.toString()),
                          _buildDetailItem('Effective Date', todayStr),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Terms of Agreement Document Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.description_outlined, color: AppTheme.primaryBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Terms & Conditions of Employment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildClause(
                        number: '1',
                        title: 'Scope of Duties & Performance',
                        content:
                            'The Employee agrees to faithfully and diligently perform all duties assigned under the designated role of $role in the $department department. The Employee shall strictly adhere to company policies, operational procedures, and instructions provided by the assigned reporting authority ($supervisor).',
                      ),
                      _buildClause(
                        number: '2',
                        title: 'Non-Disclosure & Confidentiality (NDA)',
                        content:
                            'The Employee acknowledges that during employment, they will have access to proprietary trading algorithms, financial analytical tools, prospective lead databases, client financial data, and trade secrets. The Employee strictly agrees NOT to disclose, share, duplicate, download, or distribute any company data to any third party. This confidentiality obligation remains legally binding during and indefinitely after the termination of employment.',
                      ),
                      _buildClause(
                        number: '3',
                        title: 'Intellectual Property Rights',
                        content:
                            'All software scripts, research reports, trading strategies, client records, and marketing collaterals created, modified, or contributed to by the Employee in the course of employment shall remain the sole and exclusive intellectual property of ResearchVia.',
                      ),
                      _buildClause(
                        number: '4',
                        title: 'SEBI Compliance & Professional Conduct',
                        content:
                            'The Employee shall strictly comply with all applicable SEBI (Research Analysts) Regulations, 2014 and company compliance guidelines. Under no circumstances shall the Employee promise guaranteed returns to clients, offer unauthorized trading tips outside approved research channels, or solicit personal financial transactions from clients.',
                      ),
                      _buildClause(
                        number: '5',
                        title: 'Information Security & Account Credentials',
                        content:
                            'The Employee is responsible for maintaining the confidentiality of their portal login credentials, MPIN, and attendance sessions. Sharing credentials with unauthorized persons is considered gross misconduct and grounds for immediate termination without notice.',
                      ),
                      _buildClause(
                        number: '6',
                        title: 'Non-Solicitation & Conflict of Interest',
                        content:
                            'During employment and for a period of twelve (12) months following separation, the Employee shall not directly or indirectly solicit any client, vendor, or fellow employee of ResearchVia for competitive business ventures.',
                      ),
                      _buildClause(
                        number: '7',
                        title: 'Termination & Disciplinary Action',
                        content:
                            'Breach of confidentiality, data theft, misrepresentation of research calls, or unapproved absenteeism may result in immediate termination, forfeiture of dues, and legal proceedings under applicable laws of India.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Digital Signature & Acceptance Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Aadhaar E-Sign & Confirmation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Checkbox confirmation
                      InkWell(
                        onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreedToTerms,
                                activeColor: AppTheme.primaryBlue,
                                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'I have carefully read, fully understood, and solemnly accept all the terms, policies, NDA obligations, and code of conduct set forth in this ResearchVia Employment Terms Agreement.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: _agreedToTerms ? const Color(0xFF0F172A) : const Color(0xFF475569),
                                    fontWeight: _agreedToTerms ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (_errorMessage.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Primary Action: Aadhaar E-Sign via Digio
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified, color: Color(0xFF16A34A), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Aadhaar E-Sign via Digio (Recommended)',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Digitally sign all 11 pages of your customized appointment agreement using Aadhaar OTP verification via Digio.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF15803D)),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: (_isDigioLoading || _isCheckingStatus)
                                        ? null
                                        : (_digioInitiated && _digioSigningUrl != null
                                            ? () async {
                                                final uri = Uri.parse(_digioSigningUrl!);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                }
                                              }
                                            : _startDigioEsign),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF16A34A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: _isDigioLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.open_in_new, size: 18),
                                    label: Text(
                                      _digioInitiated ? 'Re-open Digio Signing Page' : 'Proceed to Aadhaar E-Sign',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                if (_digioInitiated) ...[
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: _isCheckingStatus ? null : _checkDigioStatus,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF166534),
                                      side: const BorderSide(color: Color(0xFF16A34A)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: _isCheckingStatus
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF166534)),
                                          )
                                        : const Icon(Icons.refresh, size: 18),
                                    label: const Text('Check Status'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),


                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildClause({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agreement Rejected by Administrator',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF991B1B)),
                ),
                const SizedBox(height: 4),
                Text(
                  _rejectionReason != null && _rejectionReason!.isNotEmpty
                      ? 'Reason: $_rejectionReason'
                      : 'Please verify your details and submit your agreement again.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review the terms below, ensure your name and details are correct, and sign again.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_top_outlined, color: Color(0xFF7C3AED), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agreement E-Signed — Pending Admin Review',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6B21A8)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your electronic signature has been recorded successfully. While your agreement undergoes final administrative verification, you have full access to your assigned role dashboard and features.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7E22CE)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        final user = _authController.user.value;
                        if (user != null) {
                          _authController.navigateToInitialRoute(user);
                        }
                      },
                      icon: const Icon(Icons.dashboard_outlined, size: 16),
                      label: const Text('Proceed to Staff Dashboard', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _checkInitialStatus(),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Check Review Status', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B21A8),
                        side: const BorderSide(color: Color(0xFFD8B4FE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
