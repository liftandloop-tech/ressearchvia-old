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
  double validityMonths = 3.0; // Default validity slider

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

        final proxy = controller.proxyData.value;
        if (proxy == null) {
          return const Center(
            child: Text(
              'No linked broker profile found. Please link a broker first.',
              style: TextStyle(fontFamily: 'Poppins', color: AppTheme.textGrey),
            ),
          );
        }

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
            child: const Icon(Icons.business, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                proxy['brokerName'] ?? 'Broker',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Text(
                'Client ID: ${proxy['brokerCode'] ?? ''}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveProxyDetails(Map<String, dynamic> proxy) {
    final status = proxy['status'] ?? 'expired';
    final isExpired = status == 'expired';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Proxy Status',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isExpired ? AppTheme.errorBackground : AppTheme.backgroundLightBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpired ? AppTheme.errorBorder : AppTheme.borderBlue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    proxy['ip'] ?? 'N/A',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isExpired ? AppTheme.error : AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Expiry Date: ${proxy['expiry']?.toString().split("T")[0] ?? "N/A"}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppTheme.textGrey,
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    final brokerCode = controller.proxyData.value?['brokerCode']?.toString().toLowerCase().replaceAll("_", "") ?? 'angel';
    final pricing = controller.pricingData.value?[brokerCode]?['ipv4'];

    if (pricing == null) {
      return const Text('Loading proxy pricing information...');
    }

    final int minMonth = pricing['min_month'] ?? 3;
    final List<dynamic> tiers = pricing['price_tiers'] ?? [];

    // Make sure validity is at least minimum months
    if (validityMonths < minMonth) {
      validityMonths = minMonth.toDouble();
    }

    // Determine current rate based on slider value
    double currentPrice = 0;
    for (var tier in tiers) {
      final int tierMin = tier['min_month'];
      if (validityMonths >= tierMin) {
        currentPrice = double.tryParse(tier['price'].toString()) ?? 0.0;
      }
    }

    final double totalCost = currentPrice * validityMonths;

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
                '${validityMonths.round()} Months',
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
            divisions: 12 - minMonth,
            activeColor: AppTheme.primaryBlue,
            inactiveColor: AppTheme.borderGrey,
            onChanged: (val) {
              setState(() {
                validityMonths = val;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Per Month Rate', '₹${currentPrice.toStringAsFixed(0)}'),
          _buildDetailRow('Total Cost', '₹${totalCost.toStringAsFixed(0)}', isBold: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showConfirmationDialog(validityMonths.round(), totalCost, isRenewal);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isRenewal ? 'Renew Proxy' : 'Purchase & Generate Static IP',
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

  void _showConfirmationDialog(int months, double amount, bool isRenewal) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Action', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(
          'An amount of ₹${amount.toStringAsFixed(0)} will be deducted from your wallet balance to ${isRenewal ? "renew" : "issue"} the proxy for $months months.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              if (isRenewal) {
                controller.renewProxy(months);
              } else {
                controller.issueProxy(months);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          )
        ],
      ),
    );
  }
}
