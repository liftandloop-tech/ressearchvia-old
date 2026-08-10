import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../config/theme.config.dart';
import '../../../services/lead.service.dart';
import '../../layouts/dashboard_layout.widget.dart';

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
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
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
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade800);
      } else {
        Get.snackbar('Error', res.body?['message'] ?? 'Failed to save settings',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), backgroundColor: Colors.red.withOpacity(0.1));
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
        padding: const EdgeInsets.all(32),
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
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Get.back(),
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lead Distribution',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: Text(
                        'Control how many leads staff members can pull and hold at one time.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Config Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppTheme.gray200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fresh Leads section
                            _sectionHeader(Icons.bolt_rounded, 'Fresh Leads', AppTheme.primaryBlue),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _numberField(
                                    label: 'Maximum per Staff',
                                    hint: '100',
                                    controller: _freshMaxCtrl,
                                    helpText: 'Max fresh leads a staff member can hold at once',
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _numberField(
                                    label: 'Pull Amount',
                                    hint: '20',
                                    controller: _freshPullCtrl,
                                    helpText: 'How many leads to grab per pull action',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: hint,
            helperText: helpText,
            helperMaxLines: 2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
