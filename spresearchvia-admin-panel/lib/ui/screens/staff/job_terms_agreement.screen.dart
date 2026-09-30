import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/services/auth.service.dart';

class JobTermsAgreementScreen extends StatefulWidget {
  const JobTermsAgreementScreen({super.key});

  @override
  State<JobTermsAgreementScreen> createState() => _JobTermsAgreementScreenState();
}

class _JobTermsAgreementScreenState extends State<JobTermsAgreementScreen> {
  final AuthService _authService = Get.find<AuthService>();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController _signatureController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final user = _authController.user.value;
    if (user != null && user.fullName.isNotEmpty) {
      _signatureController.text = user.fullName;
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submitAgreement() async {
    setState(() => _errorMessage = '');

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please check the box to confirm that you have read and accepted the agreement terms.');
      return;
    }

    final signature = _signatureController.text.trim();
    if (signature.isEmpty || signature.length < 3) {
      setState(() => _errorMessage = 'Please enter your full legal name as your digital signature.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _authService.signJobAgreement(signature: signature, version: '1.0');
      if (result.success && result.user != null) {
        Get.snackbar(
          'Agreement Signed',
          'Welcome to the ResearchVia team! Your workspace is now activated.',
          backgroundColor: AppTheme.successGreen.withValues(alpha: 0.15),
          colorText: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
        );
        _authController.onAgreementSigned(result.user!);
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = result.error ?? 'Failed to submit agreement. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'An unexpected error occurred: $e';
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

    return Scaffold(
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
                        'Digital Signature & Confirmation',
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

                      // Digital signature text input
                      const Text(
                        'Digital Signature (Type your Full Legal Name)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _signatureController,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. ${user?.fullName ?? "Your Full Name"}',
                          prefixIcon: const Icon(Icons.draw_outlined, color: AppTheme.primaryBlue),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'By typing your legal name and clicking "Sign & Accept Agreement", you execute a legally binding electronic agreement under the Information Technology Act, 2000. Your IP address, device details, and timestamp will be permanently logged.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                      ),

                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
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
                      ],

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitAgreement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Sign & Accept Agreement',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
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
}
