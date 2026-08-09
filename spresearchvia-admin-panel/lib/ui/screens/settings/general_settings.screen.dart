import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.config.dart';
import '../../../config/app.config.dart';
import '../../../controllers/settings/settings.controller.dart';
import '../../layouts/dashboard_layout.widget.dart';
import '../../widgets/button.widget.dart';

class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());

    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        child: Obx(
          () => controller.isLoading.value
              ? Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page title with back button
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Get.back(),
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'General Settings',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildBankDetailsCard(controller),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBankDetailsCard(SettingsController controller) {
    return Obx(() {
      final editing = controller.isEditing.value;
      return Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title + Edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Bank Transfer Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (!editing)
                  OutlinedButton.icon(
                    onPressed: controller.startEditing,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'These details will be shown to users when they choose Bank Transfer as payment method in the mobile app.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            // Fields — view-only or editable
            if (editing) ...[
              _buildTextField(
                label: 'Bank Name',
                controller: controller.bankNameController,
                hint: 'e.g. HDFC Bank',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Account Name',
                controller: controller.accountNameController,
                hint: 'e.g. SP ResearchVia Pvt Ltd',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Account Number',
                controller: controller.accountNumberController,
                hint: 'e.g. 50200012345678',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'IFSC Code',
                controller: controller.ifscCodeController,
                hint: 'e.g. HDFC0001234',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'UPI ID',
                controller: controller.upiIdController,
                hint: 'e.g. user@bank',
              ),
              const SizedBox(height: 24),
              _buildQRCodeUpload(controller, editing: true),
              const SizedBox(height: 32),
              // Save + Cancel
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Button(
                        title: controller.isSaving.value
                            ? 'Saving...'
                            : 'Save Changes',
                        buttonType: ButtonType.green,
                        showLoading: controller.isSaving.value,
                        onTap: controller.isSaving.value
                            ? null
                            : () => controller.updateBankDetails(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.cancelEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: AppTheme.gray300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildViewRow('Bank Name', controller.bankNameController.text),
              _buildViewRow(
                'Account Name',
                controller.accountNameController.text,
              ),
              _buildViewRow(
                'Account Number',
                controller.accountNumberController.text,
              ),
              _buildViewRow('IFSC Code', controller.ifscCodeController.text),
              _buildViewRow(
                'UPI ID',
                controller.upiIdController.text.isEmpty
                    ? '—'
                    : controller.upiIdController.text,
              ),
              const SizedBox(height: 16),
              _buildQRCodeUpload(controller, editing: false),
            ],
          ],
        ),
      );
    });
  }

  /// Read-only label + value row
  Widget _buildViewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppTheme.gray50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeUpload(
    SettingsController controller, {
    required bool editing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QR Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: editing ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.isUploadingQR.value) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.qrCodePath.value.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In view mode: tappable thumbnail → opens popup
                if (!editing)
                  GestureDetector(
                    onTap: () =>
                        _showQrDialog(Get.context!, controller.fullQrUrl),
                    child: Stack(
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.4),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              AppConfig.buildImageUrl(controller.fullQrUrl),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image_outlined,
                                          color: AppTheme.gray400,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cannot load image',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.gray400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        // Tap-to-expand hint overlay
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // In edit mode: normal non-tappable image
                if (editing)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.gray300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        AppConfig.buildImageUrl(controller.fullQrUrl),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                color: AppTheme.gray400,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cannot load image',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.gray400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (editing)
                  TextButton.icon(
                    onPressed: controller.removeQR,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    label: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            );
          }

          // No QR yet
          if (!editing) {
            return Text(
              'No QR Code uploaded',
              style: TextStyle(fontSize: 14, color: AppTheme.gray400),
            );
          }

          return InkWell(
            onTap: controller.pickAndUploadQR,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                border: Border.all(
                  color: AppTheme.gray300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: AppTheme.gray500,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload QR Code',
                    style: TextStyle(color: AppTheme.gray500, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showQrDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final screenSize = MediaQuery.of(ctx).size;
        final dialogSize = screenSize.width / 3;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Image container
              Container(
                width: dialogSize,
                height: dialogSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    AppConfig.buildImageUrl(imageUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cannot load QR image',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Close (×) button — top-right
              Positioned(
                top: -14,
                right: -14,
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
