import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/theme.config.dart';
import '../../../config/app.config.dart';
import '../../../controllers/settings/settings.controller.dart';
import '../../layouts/dashboard_layout.widget.dart';
import '../../widgets/button.widget.dart';
import '../leads/lead_management.screen.dart';
import '../../../models/staff.model.dart';

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
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                            iconSize: 20,
                          ),
                          const SizedBox(width: 8),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'General Settings',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Configure company bank accounts, default staff assignments, permissions, and lead flow policies.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildBankDetailsCard(controller),
                          _buildDefaultRMCard(controller),
                          _buildRolesPermissionsCard(),
                          _buildLeadDistributionCard(),
                        ],
                      ),
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
            // Header row with title + Edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Bank Transfer Details',
                      style: TextStyle(
                        fontSize: 16,
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
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

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

  Widget _buildDefaultRMCard(SettingsController controller) {
    return Obx(() {
      final editing = controller.isEditingRM.value;
      return Container(
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
            // Header row with title + Edit / Save buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Default Relationship Manager (RM)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'App Dashboard & Contact RM Fallback',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!editing)
                  OutlinedButton.icon(
                    onPressed: controller.startEditingRM,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit RM', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      TextButton(
                        onPressed: controller.cancelEditRM,
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: AppTheme.gray500, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: controller.isSavingRM.value
                            ? null
                            : controller.updateDefaultRM,
                        icon: controller.isSavingRM.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, size: 15),
                        label: const Text('Save RM', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'When a mobile app client does not have an individually assigned relationship manager, this default RM is shown on their mobile app dashboard and "Contact RM" screen.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.gray500, height: 1.4),
            ),
            const SizedBox(height: 20),

            if (editing) ...[
              // Quick Select Staff Member Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Link to Staff Member (Optional Quick-Fill)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<StaffModel?>(
                    initialValue: controller.selectedStaff.value,
                    isExpanded: true,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.gray50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
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
                    hint: const Text('Select a staff member or enter manually below', style: TextStyle(fontSize: 13)),
                    items: [
                      const DropdownMenuItem<StaffModel?>(
                        value: null,
                        child: Text('Custom / Manual Entry', style: TextStyle(fontSize: 13)),
                      ),
                      ...controller.staffList.map(
                        (staff) => DropdownMenuItem<StaffModel?>(
                          value: staff,
                          child: Text(
                            '${staff.name} (${staff.staffId}) • ${staff.department.isNotEmpty ? staff.department : staff.role}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: controller.onSelectStaff,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(
                label: 'RM Full Name *',
                controller: controller.rmNameController,
                hint: 'e.g. Jaya Verma',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                label: 'Mobile / WhatsApp Number *',
                controller: controller.rmPhoneController,
                hint: 'e.g. +91 9755016839',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                label: 'Email Address',
                controller: controller.rmEmailController,
                hint: 'e.g. info@researchvia.in',
              ),
              const SizedBox(height: 14),
              _buildTextField(
                label: 'Department / Designation',
                controller: controller.rmDepartmentController,
                hint: 'e.g. Relationship Manager',
              ),
            ] else ...[
              // Read-only Card View
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        controller.rmNameController.text.isNotEmpty
                            ? controller.rmNameController.text[0].toUpperCase()
                            : 'R',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                controller.rmNameController.text.isNotEmpty
                                    ? controller.rmNameController.text
                                    : 'Not Configured',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (controller.rmStaffId.value.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    controller.rmStaffId.value,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade700,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            controller.rmDepartmentController.text.isNotEmpty
                                ? controller.rmDepartmentController.text
                                : 'Relationship Manager',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Active on Dashboard',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _buildViewRow(
                'Full Name',
                controller.rmNameController.text,
              ),
              _buildViewRow(
                'Mobile Number',
                controller.rmPhoneController.text,
              ),
              _buildViewRow(
                'Email Address',
                controller.rmEmailController.text.isEmpty
                    ? '—'
                    : controller.rmEmailController.text,
              ),
              _buildViewRow(
                'Designation',
                controller.rmDepartmentController.text.isEmpty
                    ? '—'
                    : controller.rmDepartmentController.text,
              ),
              _buildViewRow(
                'Linked Staff ID',
                controller.rmStaffId.value.isEmpty
                    ? 'Custom / None'
                    : controller.rmStaffId.value,
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Read-only label + value row
  Widget _buildViewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppTheme.gray400),
            filled: true,
            fillColor: AppTheme.gray50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
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
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
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
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.4),
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
                                          size: 28,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cannot load image',
                                          style: TextStyle(
                                            fontSize: 11,
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
                              color: Colors.black.withValues(alpha: 0.45),
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
                    width: 140,
                    height: 140,
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
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cannot load image',
                                style: TextStyle(
                                  fontSize: 11,
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
                      size: 15,
                    ),
                    label: const Text(
                      'Remove',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            );
          }

          // No QR yet
          if (!editing) {
            return Text(
              'No QR Code uploaded',
              style: TextStyle(fontSize: 13, color: AppTheme.gray400),
            );
          }

          return InkWell(
            onTap: controller.pickAndUploadQR,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 140,
              height: 140,
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
                    size: 32,
                    color: AppTheme.gray500,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upload QR Code',
                    style: TextStyle(color: AppTheme.gray500, fontSize: 12),
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
        final dialogSize = (screenSize.width / 3).clamp(280.0, 480.0);

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
                      color: Colors.black.withValues(alpha: 0.2),
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
                            size: 40,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cannot load QR image',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
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
                          color: Colors.black.withValues(alpha: 0.15),
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

  Widget _buildRolesPermissionsCard() {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security_outlined,
                  color: AppTheme.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Roles & Dynamic Permissions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Configure dynamic user roles, customize permission groups, and assign granular feature access (Create, Read, Update, Delete) to staff members.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.gray500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Get.toNamed('/settings/roles-permissions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Manage Roles & Permissions', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadDistributionCard() {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.primaryBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lead Pools & Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Lead distribution rules (batch pull size, staff capacity caps, and team visibility) are now unified directly per Lead Pool. Navigate to Lead Pools to manage or adjust quotas.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.gray500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Manage Lead Pools & Distribution', style: TextStyle(fontSize: 13)),
            onPressed: () => Get.to(() => const LeadManagementScreen()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
