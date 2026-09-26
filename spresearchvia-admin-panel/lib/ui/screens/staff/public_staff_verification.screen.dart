import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/services/staff.service.dart';

class PublicStaffVerificationScreen extends StatefulWidget {
  const PublicStaffVerificationScreen({super.key});

  @override
  State<PublicStaffVerificationScreen> createState() => _PublicStaffVerificationScreenState();
}

class _PublicStaffVerificationScreenState extends State<PublicStaffVerificationScreen> {
  final StaffService _service = Get.isRegistered<StaffService>() ? Get.find<StaffService>() : Get.put(StaffService());

  bool _isLoading = true;
  Map<String, dynamic>? _staffData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVerification();
  }

  Future<void> _fetchVerification() async {
    final id = Get.parameters['id'] ?? '';
    if (id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No staff ID provided for verification.';
      });
      return;
    }

    setState(() => _isLoading = true);
    final data = await _service.getPublicStaffVerification(id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (data != null) {
          _staffData = data;
        } else {
          _errorMessage = 'Staff credential could not be verified or record does not exist.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Corporate Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF60A5FA), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'SP RESEARCHVIA PVT. LTD.',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'SEBI REGISTERED RESEARCH ANALYST • INH000015808',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Main Verification Card
                if (_isLoading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2.5),
                        SizedBox(height: 16),
                        Text('Authenticating official record...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                  )
                else if (_errorMessage.isNotEmpty || _staffData == null)
                  _buildErrorCard()
                else
                  _buildSuccessCard(_staffData!),

                const SizedBox(height: 24),
                // Footer
                Text(
                  'SP ResearchVia Pvt. Ltd. • SEBI Reg: INH000015808 • CIN: U73200MP2023PTC069041 • BSE: 6120\nRegistered Office: 129 A, Kalani Bagh, AB Road, Dewas, MP - 455001 • Quick Connect: +91 9755016839',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey[500], height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Icon(Icons.gpp_bad_outlined, size: 48, color: Color(0xFFEF4444)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Verification Failed',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchVerification,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Verification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(Map<String, dynamic> data) {
    final name = (data['name'] ?? 'Staff Member').toString();
    final staffId = (data['staffId'] ?? '').toString();
    final role = (data['role'] ?? data['department'] ?? 'Staff').toString();
    final department = (data['department'] ?? '').toString();
    final status = (data['status'] ?? 'Active').toString();
    final isVerified = data['verified'] == true || status.toLowerCase() == 'active';
    final photoUrl = data['photoUrl']?.toString();
    final joiningDateStr = data['joiningDate'] != null
        ? DateFormat('dd MMMM yyyy').format(DateTime.tryParse(data['joiningDate'].toString()) ?? DateTime.now())
        : 'N/A';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Green Verified Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.verified, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'AUTHENTICATED & ACTIVE EMPLOYEE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Profile Avatar with Ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFFEFF6FF),
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(AppConfig.buildImageUrl(photoUrl))
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                // Name and ID
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'Employee ID: $staffId',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 20),

                // Details List
                _buildVerificationRow('Official Designation', role),
                _buildVerificationRow('Department', department.isNotEmpty ? department : 'Research & Analytics'),
                _buildVerificationRow('Employment Status', isVerified ? 'Active & In Good Standing' : status, isGreen: isVerified),
                _buildVerificationRow('Date of Joining', joiningDateStr),
                _buildVerificationRow('SEBI Registration', 'INH000015808 (Research Analyst)'),
                _buildVerificationRow('Organization', 'SP ResearchVia Pvt. Ltd.'),
                _buildVerificationRow('Corporate CIN', 'U73200MP2023PTC069041'),
                _buildVerificationRow('BSE Enlistment', '6120'),
                _buildVerificationRow('Registered Office', '129 A, Kalani Bagh, AB Road, Dewas, MP - 455001'),
                _buildVerificationRow('Quick Connect', '+91 9755016839'),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                // Security Note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.security, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This real-time credential confirmation validates the authenticity of this representative under SEBI regulations. For compliance inquiries, contact compliance@researchvia.in.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isGreen ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
