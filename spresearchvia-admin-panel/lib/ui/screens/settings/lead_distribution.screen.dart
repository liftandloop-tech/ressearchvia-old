import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../config/theme.config.dart';
import '../../../services/lead.service.dart';
import '../../layouts/dashboard_layout.widget.dart';
import '../leads/lead_management.screen.dart';

class LeadDistributionScreen extends StatefulWidget {
  const LeadDistributionScreen({super.key});

  @override
  State<LeadDistributionScreen> createState() => _LeadDistributionScreenState();
}

class _LeadDistributionScreenState extends State<LeadDistributionScreen> {
  final LeadService _leadService = Get.find<LeadService>();

  bool _isLoading = true;
  bool _isSaving = false;

  final _freshMaxCtrl = TextEditingController(text: '100');
  final _freshPullCtrl = TextEditingController(text: '20');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await _leadService.getLeadDistributionSettings();
      if (!res.status.hasError && res.body != null) {
        final data = res.body['data'] as Map<String, dynamic>? ?? {};
        setState(() {
          _freshMaxCtrl.text = (data['freshMaxPerStaff'] ?? 100).toString();
          _freshPullCtrl.text = (data['freshPullSize'] ?? 20).toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading distribution settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final freshMax = int.tryParse(_freshMaxCtrl.text.trim());
    final freshPull = int.tryParse(_freshPullCtrl.text.trim());

    if (freshMax == null || freshPull == null || freshMax <= 0 || freshPull <= 0) {
      Get.snackbar('Validation Error', 'All values must be positive numbers',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await _leadService.saveLeadDistributionSettings({
        'freshMaxPerStaff': freshMax,
        'freshPullSize': freshPull,
      });
      if (!res.status.hasError) {
        Get.snackbar('Saved', 'Lead distribution settings updated',
            backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green.shade800);
      } else {
        Get.snackbar('Error', res.body?['message'] ?? 'Failed to save settings',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red.withValues(alpha: 0.1));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _freshMaxCtrl.dispose();
    _freshPullCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () => Get.back(),
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lead Distribution',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Control capacity limits and pull quotas for default fresh leads distribution',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Lead Pools Navigation Banner
                    Container(
                      width: 580,
                      constraints: const BoxConstraints(maxWidth: 580, minWidth: 320),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Distribution rules are now customizable per Lead Pool. To configure team-specific pools or adjust custom quotas, visit Lead Pools.',
                              style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, height: 1.4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => Get.to(() => const LeadManagementScreen()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryBlue,
                              side: BorderSide(color: AppTheme.primaryBlue),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Lead Pools', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Config Card
                    Container(
                      width: 580,
                      constraints: const BoxConstraints(maxWidth: 580, minWidth: 320),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gray200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fresh Leads section
                          _sectionHeader(Icons.bolt_rounded, 'Fresh Leads (Default Fallback)', AppTheme.primaryBlue),
                          const SizedBox(height: 8),
                          Text(
                            'These settings apply to the default global Fresh Leads pool when staff pull new leads.',
                            style: TextStyle(fontSize: 12.5, color: AppTheme.gray500, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _numberField(
                                  label: 'Maximum per Staff',
                                  hint: '100',
                                  controller: _freshMaxCtrl,
                                  helpText: 'Max leads a staff member can hold at once',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _numberField(
                                  label: 'Pull Amount',
                                  hint: '20',
                                  controller: _freshPullCtrl,
                                  helpText: 'Batch size grabbed per pull action',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: _isSaving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 16, height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _numberField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppTheme.gray400),
            helperText: helpText,
            helperStyle: TextStyle(fontSize: 11, color: AppTheme.gray500),
            helperMaxLines: 2,
            filled: true,
            fillColor: AppTheme.gray50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.gray300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.gray200)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryBlue),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }
}
