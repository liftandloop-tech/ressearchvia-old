import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/proxy.controller.dart';
import '../../core/theme/app_theme.dart';

class ProxyPurchaseScreen extends StatefulWidget {
  const ProxyPurchaseScreen({super.key});

  @override
  State<ProxyPurchaseScreen> createState() => _ProxyPurchaseScreenState();
}

class _ProxyPurchaseScreenState extends State<ProxyPurchaseScreen> {
  final controller = Get.put(ProxyController());
  double validityMonths = 3.0; // Default 3 months minimum
  String selectedBrokerCode = 'angel';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Static Proxy IP Settings',
          style: TextStyle(
            color: AppTheme.primaryBlue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final proxy = controller.proxyData.value ?? {
          'brokerCode': 'angel',
          'brokerName': 'Angel One',
          'hasProxy': false,
        };

        final hasProxy = proxy['hasProxy'] == true;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBrokerCard(proxy),
              const SizedBox(height: 24),
              if (hasProxy) _buildActiveProxyDetails(proxy) else _buildPurchaseFlow(proxy),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBrokerCard(Map<String, dynamic> proxy) {
    final brokerName = proxy['brokerName'] ?? 'Broker Account';
    final hasProxy = proxy['hasProxy'] == true;
    final isExpired = proxy['status'] == 'expired';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hub_outlined, color: AppTheme.primaryBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brokerName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasProxy
                      ? (isExpired ? 'Proxy Expired' : 'Proxy Active')
                      : 'No Proxy Configured (Select broker below)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasProxy
                        ? (isExpired ? Colors.red : AppTheme.primaryGreen)
                        : AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProxyDetails(Map<String, dynamic> proxy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Static Proxy IP',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Column(
            children: [
              _buildDetailRow('IP Address', proxy['ip'] ?? 'N/A', isBold: true),
              _buildDetailRow('Status', proxy['status']?.toString().toUpperCase() ?? 'N/A'),
              _buildDetailRow(
                'Expiry Date',
                proxy['expiry'] != null
                    ? proxy['expiry'].toString().split('T')[0]
                    : 'N/A',
              ),
              const Divider(height: 24),
              _buildDetailRow('Port', proxy['port']?.toString() ?? 'N/A'),
              _buildDetailRow('Hostname', proxy['hostname'] ?? 'N/A'),
              _buildDetailRow('IP Username', proxy['ipUserid'] ?? 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Renew Your Proxy',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        _buildSliderAndButton(isRenewal: true),
      ],
    );
  }

  Widget _buildPurchaseFlow(Map<String, dynamic> proxy) {
    final availableBrokers = (proxy['availableBrokers'] as List<dynamic>?) ?? [
      {'code': 'angel', 'name': 'Angel One'},
      {'code': 'zebu', 'name': 'Mynt by Zebu'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Target Broker Platform',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedBrokerCode,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryBlue),
              items: availableBrokers.map((b) {
                final code = b['code'].toString();
                final name = b['name'].toString();
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedBrokerCode = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Proxy Allocation Options',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        _buildSliderAndButton(isRenewal: false),
      ],
    );
  }

  Widget _buildSliderAndButton({required bool isRenewal}) {
    const int minMonth = 3;
    const double baseRatePerMonth = 1.0; // Testing rate
    const double gstRate = 0.18; // 18% GST

    if (validityMonths < minMonth) {
      validityMonths = minMonth.toDouble();
    }

    final double baseTotal = baseRatePerMonth * validityMonths;
    final double gstTotal = baseTotal * gstRate;
    final double grandTotal = baseTotal + gstTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration:', style: TextStyle(fontFamily: 'Poppins')),
              Text(
                '${validityMonths.round()} Month${validityMonths.round() > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          Slider(
            value: validityMonths,
            min: minMonth.toDouble(),
            max: 12.0,
            divisions: 9,
            activeColor: AppTheme.primaryBlue,
            inactiveColor: AppTheme.borderGrey,
            onChanged: (val) {
              setState(() {
                validityMonths = val;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Base Price', '₹1 / month'),
          _buildDetailRow('GST (18%)', '₹0.18 / month'),
          _buildDetailRow('Subtotal (${validityMonths.round()} mo)', '₹${baseTotal.toStringAsFixed(2)}'),
          _buildDetailRow('GST Amount', '₹${gstTotal.toStringAsFixed(2)}'),
          const Divider(height: 16),
          _buildDetailRow('Total Payable', '₹${grandTotal.toStringAsFixed(2)}', isBold: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Important Note: This is a non-refundable fee used to purchase the static IP for automated trading. Subscribers cannot demand a refund once purchased.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.startProxyPurchaseFlow(
                  validityMonths.round(),
                  isRenewal: isRenewal,
                  brokerCode: selectedBrokerCode,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isRenewal
                    ? 'Renew Proxy (Pay ₹${grandTotal.toStringAsFixed(2)})'
                    : 'Pay ₹${grandTotal.toStringAsFixed(2)} via Razorpay',
                style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', color: AppTheme.textGrey)),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: isBold ? AppTheme.primaryGreen : AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
