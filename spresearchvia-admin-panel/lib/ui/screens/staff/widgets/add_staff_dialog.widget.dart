import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'dart:ui';

class AddStaffDialog extends StatelessWidget {
  final StaffController controller;

  const AddStaffDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 750,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(
                              () => Text(
                                controller.isEditing.value
                                    ? 'Update Staff Member'
                                    : 'Add New Staff Member',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Obx(
                              () => Text(
                                controller.isEditing.value
                                    ? 'Update staff information, role, and status.'
                                    : 'Create a new staff profile, assign role, and generate login credentials.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C757D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 24),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Full Name
                  _buildLabel('Full Name', required: true),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: controller.nameController,
                    hint: 'Enter full name',
                  ),
                  const SizedBox(height: 14),
                  // Mobile Number
                  _buildLabel('Mobile Number', required: true),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: controller.mobileController,
                    hint: 'Enter 10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                  ),
                  const SizedBox(height: 14),
                  // Email Address
                  _buildLabel('Email Address'),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: controller.emailController,
                    hint: 'Enter official email address',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  // MPIN field
                  Obx(() {
                    if (controller.selectedDepartment.value.toLowerCase() == 'manager') {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(
                          'MPIN',
                          required: !controller.isEditing.value,
                        ),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: controller.mpinController,
                          hint: 'Enter 4-digit MPIN',
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: false,
                        ),
                        const SizedBox(height: 14),
                      ],
                    );
                  }),
                  // Department / Role
                  _buildLabel('Role', required: true),
                  const SizedBox(height: 6),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: controller.isDirectorLoggedIn
                          ? Colors.grey[200]
                          : Colors.white,
                      border: Border.all(color: const Color(0xFFDEE2E6)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: Obx(() {
                        final departments = controller.availableDepartments
                            .toSet()
                            .toList();
                        final currentValue =
                            controller.selectedDepartment.value.isEmpty
                            ? null
                            : controller.selectedDepartment.value;
                        // Safety: if current value isn't in the list, treat as null (show hint)
                        final safeValue =
                            (currentValue != null &&
                                departments.contains(currentValue))
                            ? currentValue
                            : null;
                        return DropdownButton<String>(
                          value: safeValue,
                          isExpanded: true,
                          hint: const Text(
                            'Select Role',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFADB5BD),
                            ),
                          ),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: controller.isDirectorLoggedIn
                                ? Colors.transparent
                                : const Color(0xFF6C757D),
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: controller.isDirectorLoggedIn
                                ? const Color(0xFF6C757D)
                                : const Color(0xFF212529),
                          ),
                          items: departments
                              .map(
                                (e) => DropdownMenuItem<String>(
                                  value: e,
                                  child: Text(
                                    e,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: controller.isDirectorLoggedIn
                                          ? const Color(0xFF6C757D)
                                          : const Color(0xFF212529),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: controller.isDirectorLoggedIn
                              ? null
                              : (v) {
                                  if (v != null) {
                                    controller.updateDepartment(v);
                                  }
                                },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // View Only Toggle (Only for Researcher)
                  Obx(() {
                    if (controller.selectedDepartment.value != 'Researcher') {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'View Only Mode',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF212529),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: controller.isViewOnly.value,
                              onChanged: (v) => controller.isViewOnly.value = v,
                              activeColor: const Color(0xFF0D6EFD),
                            ),
                          ],
                        ),
                        const Text(
                          'Restricts researcher to view-only access (no editing/publishing).',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    );
                  }),
                  // Assigned Director (Only for Manager)
                  Obx(() {
                    if (controller.selectedDepartment.value != 'Manager') {
                      return const SizedBox.shrink();
                    }

                    if (controller.isDirectorLoggedIn) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Assigned Director', required: true),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              border: Border.all(
                                color: const Color(0xFFDEE2E6),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              controller.currentDirectorName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6C757D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      );
                    } else {
                      // Admin select
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Assigned Director', required: true),
                          const SizedBox(height: 6),
                          Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFDEE2E6),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: Obx(
                                () => DropdownButton<StaffModel>(
                                  value: controller.assignedDirector.value,
                                  isExpanded: true,
                                  hint: const Text(
                                    'Select Director',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFADB5BD),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: Color(0xFF6C757D),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF212529),
                                  ),
                                  items: controller.availableDirectors
                                      .map(
                                        (e) => DropdownMenuItem<StaffModel>(
                                          value: e,
                                          child: Text(
                                            e.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF212529),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      controller.assignedDirector.value = v;
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      );
                    }
                  }),
                  // Additional Profile Information
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Date of Birth'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: controller.dobController,
                              readOnly: true,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
                                  firstDate: DateTime(1930),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  controller.dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                }
                              },
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'YYYY-MM-DD',
                                hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                suffixIcon: const Icon(Icons.calendar_today, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Gender'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: controller.genderController,
                              hint: 'Male / Female / Other',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Experience (Years)'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: controller.experienceController,
                              hint: 'e.g. 3',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Previous Employer'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: controller.previousCompanyController,
                              hint: 'Company name',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Last CTC'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: controller.lastCtcController,
                              hint: 'e.g. 500000',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Address'),
                            const SizedBox(height: 6),
                            _buildTextField(
                              controller: controller.localAddressController,
                              hint: 'Street, City, State',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Onboarding Documents Section (Only when editing)
                  Obx(() {
                    if (!controller.isEditing.value) {
                      return const SizedBox.shrink();
                    }
                    final staff = controller.staffList.firstWhereOrNull((s) => s.id == controller.editingStaffId.value);
                    if (staff == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 32),
                        const Text(
                          'Onboarding Documents & Video',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDocUploadRow(context, 'PAN Card', 'pan', staff),
                        const SizedBox(height: 12),
                        _buildDocUploadRow(context, 'Aadhaar Card', 'aadhaar', staff),
                        const SizedBox(height: 12),
                        _buildDocUploadRow(context, 'NISM Certificate', 'nism', staff),
                        const SizedBox(height: 12),
                        _buildDocUploadRow(context, 'Highest Education Certificate', 'education', staff),
                        const SizedBox(height: 12),
                        _buildDocUploadRow(context, 'KYC Verification Video', 'video', staff),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: controller.resetForm,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF212529),
                          side: const BorderSide(color: Color(0xFFDEE2E6)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF212529),
                          side: const BorderSide(color: Color(0xFFDEE2E6)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          minimumSize: const Size(0, 36),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.saveStaff,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28A745),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFADB5BD),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                            minimumSize: const Size(0, 36),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  controller.isEditing.value
                                      ? 'Update Staff'
                                      : 'Save Staff',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF212529),
        ),
        children: required
            ? [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Color(0xFFDC3545)),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Color(0xFFDEE2E6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Color(0xFFDEE2E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Color(0xFF0D6EFD)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        counterText: '',
        isDense: true,
      ),
    );
  }

  Widget _buildDocUploadRow(BuildContext context, String title, String type, StaffModel staff) {
    String? fileUrl;
    if (type == 'pan') fileUrl = staff.panUrl;
    else if (type == 'aadhaar') fileUrl = staff.aadhaarUrl;
    else if (type == 'nism') fileUrl = staff.nismUrl;
    else if (type == 'education') fileUrl = staff.highestEducationUrl;
    else if (type == 'video') fileUrl = staff.kycVideoUrl;

    final isUploaded = fileUrl != null && fileUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFDEE2E6)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            type == 'video' ? Icons.video_library : Icons.description,
            color: isUploaded ? Colors.green : const Color(0xFF6C757D),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (isUploaded)
                  Text(
                    'File: $fileUrl',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const Text(
                    'No document uploaded',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6C757D)),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => controller.pickAndUploadDoc(staff.id, type),
            icon: const Icon(Icons.upload, size: 14),
            label: Text(isUploaded ? 'Re-upload' : 'Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isUploaded ? const Color(0xFF6C757D) : const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
