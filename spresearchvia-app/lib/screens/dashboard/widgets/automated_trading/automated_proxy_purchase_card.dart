import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../controllers/automated_trading.controller.dart';
import '../../../../controllers/proxy.controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/snackbar.service.dart';

class AutomatedProxyPurchaseCard extends StatefulWidget {
  final VoidCallback onProxyAssigned;

  const AutomatedProxyPurchaseCard({
    super.key,
    required this.onProxyAssigned,
  });

  @override
  State<AutomatedProxyPurchaseCard> createState() => _AutomatedProxyPurchaseCardState();
}

class _AutomatedProxyPurchaseCardState extends State<AutomatedProxyPurchaseCard> {
  final proxyController = Get.put(ProxyController());
  final tradingController = Get.find<AutomatedTradingController>();

  String selectedBrokerCode = 'angel';
  int selectedMonths = 3;

  @override
  void initState() {
    super.initState();
    final currentProxy = proxyController.proxyData.value ?? tradingController.proxyInfo.value;
    final bCode = currentProxy?['brokerCode']?.toString().toLowerCase();
    if (bCode == 'zebu' || bCode == 'angel') {
      selectedBrokerCode = bCode!;
    }
    _updateMinMonths();
  }

  void _updateMinMonths() {
    final pricing = proxyController.pricingData.value?[selectedBrokerCode]?['ipv4'];
    final defaultMin = selectedBrokerCode == 'angel' ? 3 : 1;
    final minMonth = pricing?['min_month'] ?? defaultMin;
    if (selectedMonths < minMonth) {
      selectedMonths = minMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final proxy = proxyController.proxyData.value ?? tradingController.proxyInfo.value;
      final proxies = (proxy?['proxies'] as Map?)?.cast<String, dynamic>() ?? {};

      // Match selected broker proxy or active overall proxy
      final selectedProxy = proxies[selectedBrokerCode] ??
          (proxy?['brokerCode']?.toString().toLowerCase() == selectedBrokerCode ? proxy : null);

      final hasActiveForSelected = selectedProxy != null &&
          selectedProxy['ip'] != null &&
          selectedProxy['status'] != 'expired';

      if (hasActiveForSelected) {
        return _buildActiveProxyCard(selectedProxy, proxies);
      }

      return _buildPurchaseForm(context, allProxies: proxies);
    });
  }

  Widget _buildActiveProxyCard(Map<String, dynamic> proxy, Map<String, dynamic> allProxies) {
    final ip = proxy['ip']?.toString() ?? 'N/A';
    final expiry = proxy['expiry'] != null ? proxy['expiry'].toString().split('T')[0] : 'Active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
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
                    child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Static IP Assigned',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff11416B),
                    ),
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
                  'ACTIVE',
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
          const SizedBox(height: 14),

          // Broker Toggle Tabs
          Row(
            children: [
              _buildActiveBrokerTab('angel', 'Angel One', allProxies.containsKey('angel')),
              const SizedBox(width: 10),
              _buildActiveBrokerTab('zebu', 'Zebu', allProxies.containsKey('zebu')),
            ],
          ),
          const SizedBox(height: 16),

          // IP display banner
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
                      'Dedicated IP Address',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ip,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff11416B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppTheme.primaryBlue, size: 20),
                  tooltip: 'Copy IP',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: ip));
                    SnackbarService.showSuccess('Static IP copied to clipboard!');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valid until: $expiry',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Broker: ${proxy['brokerName'] ?? selectedBrokerCode.toUpperCase()}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff11416B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onProxyAssigned,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Proceed to Broker Configuration',
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

  Widget _buildPurchaseForm(BuildContext context, {Map<String, dynamic> allProxies = const {}}) {
    final pricing = proxyController.pricingData.value?[selectedBrokerCode]?['ipv4'];
    final defaultMin = selectedBrokerCode == 'angel' ? 3 : 1;
    final minMonth = pricing?['min_month'] ?? defaultMin;
    const double baseRate = 500.0;
    const double gstRate = 0.18;

    final subtotal = baseRate * selectedMonths;
    final gst = subtotal * gstRate;
    final total = subtotal + gst;

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
                  color: const Color(0xff11416B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings_ethernet_rounded, color: Color(0xff11416B), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dedicated Static Proxy IP',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff11416B),
                      ),
                    ),
                    Text(
                      'Mandatory for SEBI & Broker API Whitelisting',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Broker Selector Tabs
          const Text(
            'Select Broker Platform',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff11416B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBrokerOption(
                'angel',
                'Angel One',
                'Min ${proxyController.pricingData.value?['angel']?['ipv4']?['min_month'] ?? 3} Mo',
              ),
              const SizedBox(width: 10),
              _buildBrokerOption(
                'zebu',
                'Zebu',
                'Min ${proxyController.pricingData.value?['zebu']?['ipv4']?['min_month'] ?? 1} Mo',
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Duration Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Validity Duration',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff11416B),
                ),
              ),
              Text(
                'Min $minMonth Month${minMonth > 1 ? 's' : ''}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1, 2, 3, 6, 12].map((m) {
                final isAllowed = m >= minMonth;
                final isSelected = selectedMonths == m;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '$m Mo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: !isAllowed
                            ? Colors.grey.shade400
                            : (isSelected ? Colors.white : const Color(0xff11416B)),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryBlue,
                    backgroundColor: Colors.grey.shade100,
                    disabledColor: Colors.grey.shade50,
                    onSelected: isAllowed
                        ? (selected) {
                            if (selected) {
                              setState(() {
                                selectedMonths = m;
                              });
                            }
                          }
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Price Calculation Breakdown
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildPriceRow('Base Rate', '₹500 / month'),
                const SizedBox(height: 6),
                _buildPriceRow('Subtotal ($selectedMonths month${selectedMonths > 1 ? 's' : ''})', '₹${subtotal.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _buildPriceRow('GST (18%)', '₹${gst.toStringAsFixed(2)}'),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Payable',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff11416B),
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Non-refundable notice
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Static IP fee is non-refundable and strictly dedicated to your demat broker whitelisting.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.amber.shade900,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Purchase CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: proxyController.isLoading.value
                  ? null
                  : () async {
                      await proxyController.startProxyPurchaseFlow(
                        selectedMonths,
                        isRenewal: false,
                        brokerCode: selectedBrokerCode,
                        onPaymentSuccess: () async {
                          await tradingController.fetchProxyInfo();
                          widget.onProxyAssigned();
                        },
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: proxyController.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Purchase Dedicated Static IP (₹${total.toStringAsFixed(2)})',
                      style: const TextStyle(
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

  Widget _buildBrokerOption(String code, String name, String minBadge) {
    final isSelected = selectedBrokerCode == code;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedBrokerCode = code;
            _updateMinMonths();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff11416B).withOpacity(0.08) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xff11416B) : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xff11416B) : Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xff11416B) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  minBadge,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBrokerTab(String code, String name, bool hasIp) {
    final isSelected = selectedBrokerCode == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedBrokerCode = code;
            _updateMinMonths();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff11416B).withOpacity(0.08) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xff11416B) : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasIp ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                size: 14,
                color: hasIp ? AppTheme.primaryGreen : Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? const Color(0xff11416B) : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.grey.shade700,
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
}
