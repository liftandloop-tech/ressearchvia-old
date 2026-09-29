import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../controllers/automated_trading.controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/snackbar.service.dart';
import '../../broker_auth_webview_screen.dart';

class AutomatedBrokerConfigCard extends StatefulWidget {
  final VoidCallback onSessionAuthorized;

  const AutomatedBrokerConfigCard({
    super.key,
    required this.onSessionAuthorized,
  });

  @override
  State<AutomatedBrokerConfigCard> createState() => _AutomatedBrokerConfigCardState();
}

class _AutomatedBrokerConfigCardState extends State<AutomatedBrokerConfigCard> {
  final controller = Get.find<AutomatedTradingController>();

  String selectedBrokerCode = 'ANGEL_ONE';
  final _clientIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _vendorCodeController = TextEditingController();

  // Daily Auth controllers
  final _mpinController = TextEditingController();
  final _totpController = TextEditingController();
  bool _isAuthorizing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _clientIdController.dispose();
    _apiKeyController.dispose();
    _vendorCodeController.dispose();
    _mpinController.dispose();
    _totpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isConfigured = controller.isBrokerConfigured;

      if (!isConfigured) {
        return _buildAddBrokerSection(context);
      }

      final broker = controller.linkedBrokers.first;
      final isActive = broker['isSessionActive'] == true;

      if (!isActive) {
        return _buildDailyAuthSection(context, broker);
      }

      return _buildSessionActiveCard(context, broker);
    });
  }

  Widget _buildAddBrokerSection(BuildContext context) {
    final staticIp = controller.staticIpAddress.isNotEmpty
        ? controller.staticIpAddress
        : (controller.proxyInfo.value?['ip']?.toString() ?? 'Allocated Static IP');

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
                child: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Configure Broker Account',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff11416B),
                      ),
                    ),
                    Text(
                      'Link your demat broker for automated execution',
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

          // Static IP Copy Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Dedicated Whitelist IP',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      Text(
                        staticIp,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff11416B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: staticIp));
                    SnackbarService.showSuccess('Static IP copied!');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Instructions on How to Configure at Broker's End
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.menu_book_rounded, size: 16, color: Color(0xff11416B)),
                    SizedBox(width: 6),
                    Text(
                      "How to Configure at Broker's End",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff11416B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInstructionStep(
                  '1',
                  'Log in to Developer Portal',
                  'Open your broker developer portal (smartapi.angelbroking.com or zebu portal).',
                ),
                _buildInstructionStep(
                  '2',
                  'Create Trading App & Whitelist IP',
                  'Create an app and paste your dedicated Static IP in the IP Whitelist field.',
                ),
                _buildInstructionStep(
                  '3',
                  'Copy API Keys & Save Below',
                  'Copy your Client ID and API Key, then save your configuration.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Form fields
          DropdownButtonFormField<String>(
            value: selectedBrokerCode,
            items: const [
              DropdownMenuItem(value: 'ANGEL_ONE', child: Text('Angel One')),
              DropdownMenuItem(value: 'ZEBU', child: Text('Zebu')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => selectedBrokerCode = val);
              }
            },
            decoration: InputDecoration(
              labelText: 'Select Broker Platform',
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _clientIdController,
            decoration: InputDecoration(
              labelText: 'Broker Client ID',
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'API Key (App Key)',
              labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (selectedBrokerCode == 'ZEBU') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _vendorCodeController,
              decoration: InputDecoration(
                labelText: 'Vendor Code',
                labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Save Configuration Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _saveBrokerCredentials(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
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
                      'Save Broker Configuration',
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

  Widget _buildInstructionStep(String number, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xff11416B),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff11416B),
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAuthSection(BuildContext context, Map<String, dynamic> broker) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Broker: ${broker['brokerCode']}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
                  ),
                  Text(
                    'Client ID: ${broker['brokerClientId']}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'AUTH REQUIRED',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Authorise Daily Trading Session',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xff11416B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your broker MPIN and live TOTP Authenticator code to unlock trading for today.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _mpinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Broker MPIN / PIN',
              prefixIcon: const Icon(Icons.pin, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _totpController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'TOTP Key / Authenticator Code',
              prefixIcon: const Icon(Icons.password, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAuthorizing ? null : () => _authorizeDailySession(broker['brokerCode']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isAuthorizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Authenticate Session for Today',
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

  Widget _buildSessionActiveCard(BuildContext context, Map<String, dynamic> broker) {
    final margin = double.tryParse(broker['availableMargin']?.toString() ?? '0') ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${broker['brokerCode']} Session Active',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff11416B),
                        ),
                      ),
                      Text(
                        'Client: ${broker['brokerClientId']}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text(
                  'READY',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Available Margin Display
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffF4F7FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Available Margin',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${margin.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Disconnect Broker',
                      middleText: 'Are you sure you want to disconnect your broker account?',
                      textConfirm: 'Disconnect',
                      textCancel: 'Cancel',
                      confirmTextColor: Colors.white,
                      onConfirm: () async {
                        Get.back();
                        await controller.unlinkBroker(broker['brokerCode']);
                      },
                    );
                  },
                  child: const Text(
                    'Disconnect',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBrokerCredentials() async {
    final clientId = _clientIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final vendorCode = _vendorCodeController.text.trim();

    if (clientId.isEmpty || apiKey.isEmpty) {
      SnackbarService.showError('Please fill in Client ID and API Key.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await controller.linkBroker(
        selectedBrokerCode,
        clientId,
        apiKey: apiKey,
        vendorCode: vendorCode.isNotEmpty ? vendorCode : null,
      );

      if (success) {
        _clientIdController.clear();
        _apiKeyController.clear();
        _vendorCodeController.clear();
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _authorizeDailySession(String brokerCode) async {
    final mpin = _mpinController.text.trim();
    final totp = _totpController.text.trim();

    if (mpin.isEmpty || totp.isEmpty) {
      SnackbarService.showError('Please enter both MPIN and TOTP key.');
      return;
    }

    setState(() => _isAuthorizing = true);
    try {
      final success = await controller.authorizeBroker(brokerCode, mpin, totp);
      if (success) {
        _mpinController.clear();
        _totpController.clear();
        widget.onSessionAuthorized();
      }
    } finally {
      setState(() => _isAuthorizing = false);
    }
  }
}
