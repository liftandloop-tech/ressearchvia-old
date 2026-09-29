import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/dashboard/automated_trading.controller.dart';
import '../../../config/theme.config.dart';
import '../../layouts/dashboard_layout.widget.dart';
import '../../widgets/button.widget.dart';

class StrategyConfigScreen extends StatefulWidget {
  const StrategyConfigScreen({super.key});

  @override
  State<StrategyConfigScreen> createState() => _StrategyConfigScreenState();
}

class _StrategyConfigScreenState extends State<StrategyConfigScreen> {
  final controller = Get.find<AdminAutomatedTradingController>();

  bool _isFixed1xEnabled = true;
  bool _isLossMultiplier2xEnabled = true;
  final TextEditingController _maxMultiplierCtrl = TextEditingController(text: '16');
  final TextEditingController _maxQuantityCtrl = TextEditingController();
  final TextEditingController _maxExposureCtrl = TextEditingController();
  final TextEditingController _maxLossCtrl = TextEditingController();
  final TextEditingController _maxConsecutiveCtrl = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() async {
    await controller.fetchSystemStrategyConfig();
    final cfg = controller.systemConfig;
    if (cfg.isNotEmpty) {
      setState(() {
        _isFixed1xEnabled = cfg['isFixed1xEnabled'] ?? true;
        _isLossMultiplier2xEnabled = cfg['isLossMultiplier2xEnabled'] ?? true;
        _maxMultiplierCtrl.text = (cfg['maxAllowedMultiplier'] ?? 16).toString();
        _maxQuantityCtrl.text = cfg['maxGlobalQuantity'] != null ? cfg['maxGlobalQuantity'].toString() : '';
        _maxExposureCtrl.text = cfg['maxGlobalExposureInr'] != null ? cfg['maxGlobalExposureInr'].toString() : '';
        _maxLossCtrl.text = cfg['maxDailyLossInr'] != null ? cfg['maxDailyLossInr'].toString() : '';
        _maxConsecutiveCtrl.text = (cfg['maxConsecutiveLosses'] ?? 5).toString();
      });
    }
  }

  void _saveConfig() async {
    final maxMult = int.tryParse(_maxMultiplierCtrl.text.trim()) ?? 16;
    final maxQty = int.tryParse(_maxQuantityCtrl.text.trim());
    final maxExp = double.tryParse(_maxExposureCtrl.text.trim());
    final maxLoss = double.tryParse(_maxLossCtrl.text.trim());
    final maxConsec = int.tryParse(_maxConsecutiveCtrl.text.trim()) ?? 5;

    final data = {
      'isFixed1xEnabled': _isFixed1xEnabled,
      'isLossMultiplier2xEnabled': _isLossMultiplier2xEnabled,
      'maxAllowedMultiplier': maxMult,
      'maxGlobalQuantity': maxQty,
      'maxGlobalExposureInr': maxExp,
      'maxDailyLossInr': maxLoss,
      'maxConsecutiveLosses': maxConsec,
    };

    await controller.saveSystemStrategyConfig(data);
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automated Trading Strategy Configuration',
                        style: AppTheme.h1Style.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Configure system-wide guardrails, available strategies, and maximum multiplier caps.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to SRE Dashboard'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Architectural distinction callout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xff1D4ED8), size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'System-Level Limits vs. User Strategy Selection',
                            style: TextStyle(
                              color: Color(0xff1E3A8A),
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'System limits defined below are enforced globally as hard pre-order guardrails before dispatching to broker APIs. The user selects their preferred strategy through legal consent in the mobile app.',
                            style: TextStyle(color: Color(0xff1E40AF), fontSize: 12.5, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Configuration Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.gray200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Strategies',
                      style: AppTheme.h5Style.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enable or disable strategies available to mobile app clients during consent:',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Fixed 1x Checkbox / Toggle
                    CheckboxListTile(
                      value: _isFixed1xEnabled,
                      onChanged: (val) => setState(() => _isFixed1xEnabled = val ?? true),
                      title: const Text(
                        'Fixed 1× Strategy',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'No position multiplier progression. Base lot used consistently on every trade.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      activeColor: AppTheme.primaryBlue,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const Divider(height: 24, color: AppTheme.gray200),

                    // 2x Loss Multiplier Checkbox / Toggle
                    CheckboxListTile(
                      value: _isLossMultiplier2xEnabled,
                      onChanged: (val) => setState(() => _isLossMultiplier2xEnabled = val ?? true),
                      title: const Text(
                        '2× Loss Multiplier Strategy',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Doubles lot size after each consecutive loss (1× → 2× → 4× → 8×). Resets to 1× after profit.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      activeColor: AppTheme.primaryBlue,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 32),
                    const Divider(color: AppTheme.gray200),
                    const SizedBox(height: 24),

                    Text(
                      'Safety Caps & Risk Guardrails',
                      style: AppTheme.h5Style.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enforced synchronously by PositionSizingService before orders are sent to broker APIs:',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    // Fields Grid
                    Wrap(
                      spacing: 24,
                      runSpacing: 20,
                      children: [
                        _buildInputField(
                          label: 'Maximum Multiplier Cap',
                          hint: 'e.g. 16 (default)',
                          controller: _maxMultiplierCtrl,
                          helper: 'Prevents unlimited 2× doubling (1× → 2× → 4× → 8× → 16× → 16×).',
                        ),
                        _buildInputField(
                          label: 'Maximum Quantity per Order',
                          hint: 'e.g. 500 (optional)',
                          controller: _maxQuantityCtrl,
                          helper: 'Absolute ceiling on calculated lots/shares across all clients.',
                        ),
                        _buildInputField(
                          label: 'Maximum Capital Exposure (INR)',
                          hint: 'e.g. 250000 (optional)',
                          controller: _maxExposureCtrl,
                          helper: 'Max allowed position value in rupees per single order execution.',
                        ),
                        _buildInputField(
                          label: 'Maximum Consecutive Losses Limit',
                          hint: 'e.g. 5 (default)',
                          controller: _maxConsecutiveCtrl,
                          helper: 'Circuit breaker triggered if user exceeds this consecutive loss count.',
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Save Action
                    Obx(() {
                      return SizedBox(
                        width: 240,
                        child: Button(
                          title: controller.isConfigSaving.value ? 'Saving...' : 'Save Configuration',
                          icon: Icons.save_outlined,
                          onTap: controller.isConfigSaving.value ? null : _saveConfig,
                          buttonType: ButtonType.blue,
                          showLoading: controller.isConfigSaving.value,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String helper,
  }) {
    return SizedBox(
      width: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xff334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              filled: true,
              fillColor: AppTheme.gray50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.gray300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.gray300),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(color: Colors.grey, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
