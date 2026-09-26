import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';

class AddStaffScreen extends StatelessWidget {
  const AddStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse existing StaffController or initialize a new one
    final controller = Get.isRegistered<StaffController>()
        ? Get.find<StaffController>()
        : Get.put(StaffController());

    // Deep-link / route parameter handler for edit and create modes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = Get.parameters['id'];
      if (id != null && (!controller.isEditing.value || controller.editingStaffId.value != id)) {
        if (controller.staffList.isEmpty) {
          controller.fetchStaffList().then((_) {
            _findAndPopulate(controller, id);
          });
        } else {
          _findAndPopulate(controller, id);
        }
      } else if (id == null && controller.isEditing.value) {
        controller.resetForm();
      }
    });

    return DashboardLayout(
      child: Container(
        color: const Color(0xFFF8FAFC),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Breadcrumb & Actions Bar
                  _buildHeader(context, controller),
                  const SizedBox(height: 24),

                  // Section 1: Account Credentials & Role Settings
                  _buildAccountSection(context, controller),
                  const SizedBox(height: 20),

                  // Section 2: Walk-In Form - Personal & Identification Details
                  _buildPersonalSection(context, controller),
                  const SizedBox(height: 20),

                  // Section 3: Walk-In Form - Declarations & Screening
                  _buildDeclarationsSection(context, controller),
                  const SizedBox(height: 20),

                  // Section 4: Walk-In Form - Educational Qualifications
                  _buildEducationSection(context, controller),
                  const SizedBox(height: 20),

                  // Section 5: Walk-In Form - Current Compensation & Reporting Structure
                  _buildWorkExpSection(context, controller),
                  const SizedBox(height: 20),

                  // Section 6: Walk-In Form - Employment History
                  _buildEmploymentHistorySection(context, controller),
                  const SizedBox(height: 20),

                  // Section 7: Emergency & Safety Contacts
                  _buildEmergencySection(context, controller),
                  const SizedBox(height: 20),

                  // Section 8: Compliance & KYC Documents (Visible when Editing)
                  Obx(() {
                    if (!controller.isEditing.value) return const SizedBox.shrink();
                    final staff = controller.staffList.firstWhereOrNull(
                      (s) => s.id == controller.editingStaffId.value,
                    );
                    if (staff == null) return const SizedBox.shrink();
                    return _buildDocumentsSection(context, controller, staff);
                  }),

                  const SizedBox(height: 32),

                  // Bottom Action Bar
                  _buildBottomActionBar(controller),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _findAndPopulate(StaffController controller, String id) {
    final staff = controller.staffList.firstWhereOrNull((s) => s.id == id);
    if (staff != null) {
      controller.populateForEdit(staff);
    }
  }

  // ---------------------------------------------------------------------------
  // Top Header Area
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, StaffController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb row
        Row(
          children: [
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new, size: 13, color: AppTheme.gray500),
                    const SizedBox(width: 6),
                    Text(
                      'Staff Directory',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('/', style: TextStyle(fontSize: 13, color: AppTheme.gray400)),
            const SizedBox(width: 8),
            Obx(
              () => Text(
                controller.isEditing.value ? 'Update Profile' : 'New Staff',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Title and Primary Action
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Obx(
                        () => Text(
                          controller.isEditing.value
                              ? 'Update Staff Profile'
                              : 'Add New Staff Member',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Obx(() {
                        if (!controller.isEditing.value) return const SizedBox.shrink();
                        final staffId = controller.autoGeneratedStaffId.value;
                        if (staffId.isEmpty) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            staffId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      Obx(() {
                        if (!controller.isEditing.value) return const SizedBox.shrink();
                        final isActive = controller.isActive.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete employee records including walk-in interview details, qualifications, and role hierarchy.',
                    style: TextStyle(fontSize: 13, color: AppTheme.gray500),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF475569),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 10),
            Obx(
              () => ElevatedButton.icon(
                onPressed: controller.isLoading.value ? null : controller.saveStaff,
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check, size: 16),
                label: Text(
                  controller.isLoading.value
                      ? 'Saving...'
                      : (controller.isEditing.value ? 'Save Changes' : 'Create Staff'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1: Account Credentials & Role Settings
  // ---------------------------------------------------------------------------
  Widget _buildAccountSection(BuildContext context, StaffController controller) {
    return _buildCardWrapper(
      icon: Icons.admin_panel_settings_outlined,
      iconColor: AppTheme.primaryBlue,
      title: 'Account & Role Settings',
      subtitle: 'Credentials, department categorization, reporting hierarchy, and platform permissions.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 650;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Full Legal Name',
                  controller: controller.nameController,
                  hint: 'e.g. John Doe',
                  prefixIcon: Icons.person_outline,
                  required: true,
                ),
                right: _buildInputField(
                  label: 'Official Email Address',
                  controller: controller.emailController,
                  hint: 'name@company.com',
                  prefixIcon: Icons.alternate_email,
                  keyboardType: TextInputType.emailAddress,
                  required: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Mobile Number',
                  controller: controller.mobileController,
                  hint: '10-digit mobile number',
                  prefixIcon: Icons.phone_outlined,
                  prefixText: '+91 ',
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  required: true,
                ),
                right: Obx(() {
                  final roleLower = controller.selectedRole.value.toLowerCase().trim();
                  final deptLower = controller.selectedDepartment.value.toLowerCase().trim();
                  final isManager = roleLower == 'manager' || deptLower == 'manager';
                  return _buildInputField(
                    label: isManager ? '4-Digit MPIN (Optional for Manager)' : '4-Digit Login MPIN',
                    controller: controller.mpinController,
                    hint: 'e.g. 1234',
                    prefixIcon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    required: !isManager,
                  );
                }),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Role', required: true),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Obx(() {
                          final roles = controller.availableRoles;
                          final currentRoleId = controller.selectedRoleId.value;
                          final currentRoleName = controller.selectedRole.value;
                          final match = roles.firstWhereOrNull((r) =>
                              (currentRoleId != null && r.id == currentRoleId) ||
                              r.name.toLowerCase().trim() == currentRoleName.toLowerCase().trim());
                          final safeVal = match?.id;
                          return DropdownButton<String>(
                            value: safeVal,
                            isExpanded: true,
                            hint: const Text('Select Role', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                            items: roles.map((r) {
                              final deptName = r.departmentName;
                              return DropdownMenuItem<String>(
                                value: r.id,
                                child: Row(
                                  children: [
                                    Text(
                                      r.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                    ),
                                    if (deptName != null && deptName.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          deptName,
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: controller.isDirectorLoggedIn
                                ? null
                                : (v) {
                                    if (v != null) controller.updateRole(v);
                                  },
                          );
                        }),
                      ),
                    ),
                    Obx(() {
                      final deptName = controller.selectedDepartment.value;
                      if (deptName.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.apartment_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              'Department: $deptName (Auto-assigned)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                right: Obx(() {
                  final role = controller.selectedRole.value.toLowerCase().trim().isNotEmpty
                      ? controller.selectedRole.value.toLowerCase().trim()
                      : controller.selectedDepartment.value.toLowerCase().trim();
                  if (role == 'director') {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Directors operate with top-level executive authority (no supervisor required).',
                              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.isDirectorLoggedIn) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Assigned Supervisor / Director'),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            controller.currentDirectorName.isNotEmpty ? controller.currentDirectorName : 'Assigned to Director',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    );
                  }

                  final directors = controller.availableDirectors;
                  final selectedValue = controller.assignedDirector.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Assigned Supervisor / Director'),
                      const SizedBox(height: 6),
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<StaffModel?>(
                            value: directors.contains(selectedValue) ? selectedValue : null,
                            isExpanded: true,
                            hint: const Text('Unassigned / Direct', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                            items: [
                              const DropdownMenuItem<StaffModel?>(
                                value: null,
                                child: Text('Unassigned / Direct', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              ),
                              ...directors.map((d) => DropdownMenuItem<StaffModel?>(
                                    value: d,
                                    child: Text('${d.name} (${d.department.isNotEmpty ? d.department : d.role})', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                                  )),
                            ],
                            onChanged: (StaffModel? value) => controller.assignedDirector.value = value,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Status & View-Only Toggles
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  Obx(
                    () => InkWell(
                      onTap: () => controller.isActive.value = !controller.isActive.value,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: controller.isActive.value,
                                onChanged: (v) => controller.isActive.value = v ?? true,
                                activeColor: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Active Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => InkWell(
                      onTap: () => controller.isViewOnly.value = !controller.isViewOnly.value,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: controller.isViewOnly.value,
                                onChanged: (v) => controller.isViewOnly.value = v ?? false,
                                activeColor: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('View-Only Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2: Walk-In Form - Personal & Identification Details
  // ---------------------------------------------------------------------------
  Widget _buildPersonalSection(BuildContext context, StaffController controller) {
    return _buildCardWrapper(
      icon: Icons.person_pin_outlined,
      iconColor: const Color(0xFF0D9488),
      title: 'Walk-In Interview Form: Personal & Identification',
      subtitle: 'Complete personal details, hometown, marital status, and social identifiers.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 650;
          return Column(
            children: [
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Position Applied For',
                  controller: controller.appliedPositionController,
                  hint: 'e.g. Equity Research Analyst / Sales Manager',
                  prefixIcon: Icons.badge_outlined,
                ),
                right: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Date of Application / Walk-in'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller.applicationDateController,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          controller.applicationDateController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: _inputDecoration(hint: 'YYYY-MM-DD', prefixIcon: Icons.event_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Date of Birth'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller.dobController,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 24)),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          controller.dobController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                      style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                      decoration: _inputDecoration(hint: 'YYYY-MM-DD', prefixIcon: Icons.calendar_today_outlined),
                    ),
                  ],
                ),
                right: _buildInputField(
                  label: 'Gender',
                  controller: controller.genderController,
                  hint: 'Male / Female / Other',
                  prefixIcon: Icons.transgender_outlined,
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Native Place (Hometown / State)',
                  controller: controller.nativePlaceController,
                  hint: 'e.g. Indore, Madhya Pradesh',
                  prefixIcon: Icons.location_city_outlined,
                ),
                right: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Marital Status'),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Obx(() {
                          final current = controller.maritalStatus.value;
                          const options = ['Single', 'Married', 'Divorced', 'Widowed'];
                          final val = options.contains(current) ? current : null;
                          return DropdownButton<String>(
                            value: val,
                            isExpanded: true,
                            hint: const Text('Select Marital Status', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))))).toList(),
                            onChanged: (v) => controller.maritalStatus.value = v ?? '',
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Current Location / City',
                  controller: controller.currentLocationController,
                  hint: 'Current residential city',
                  prefixIcon: Icons.pin_drop_outlined,
                ),
                right: _buildInputField(
                  label: 'Skype ID / LinkedIn Handle',
                  controller: controller.skypeController,
                  hint: 'e.g. skype.id or linkedin.com/in/...',
                  prefixIcon: Icons.link_outlined,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Residential / Permanent Address',
                controller: controller.localAddressController,
                hint: 'Street, Landmark, City, State, Pincode',
                prefixIcon: Icons.home_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 3: Walk-In Form - Declarations & Screening
  // ---------------------------------------------------------------------------
  Widget _buildDeclarationsSection(BuildContext context, StaffController controller) {
    return _buildCardWrapper(
      icon: Icons.checklist_rtl_outlined,
      iconColor: const Color(0xFFF59E0B),
      title: 'Walk-In Interview Form: Screening Declarations',
      subtitle: 'Mandatory background, lifestyle, health, and sourcing questionnaire.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeclarationRow(
            label: 'Have you been interviewed by us in the last six months?',
            valueObs: controller.interviewedBefore,
            detailsController: controller.interviewedBeforeDetailsController,
            detailsHint: 'If yes, mention date & role interviewed for',
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildYesNoToggleRow('Do you smoke?', controller.smoke),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildYesNoToggleRow('Do you consume alcohol?', controller.alcohol),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildDeclarationRow(
            label: 'Are you differently abled?',
            valueObs: controller.differentlyAbled,
            detailsController: controller.differentlyAbledDetailsController,
            detailsHint: 'If yes, specify details/requirements',
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildDeclarationRow(
            label: 'Do you have any past police record or pending legal cases?',
            valueObs: controller.policeRecord,
            detailsController: controller.policeRecordDetailsController,
            detailsHint: 'If yes, specify nature of case',
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildDeclarationRow(
            label: 'Do you have a history of any major illness or ongoing treatment?',
            valueObs: controller.majorIllness,
            detailsController: controller.majorIllnessDetailsController,
            detailsHint: 'If yes, specify medical conditions',
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              return _buildResponsiveRow(
                isWide: isWide,
                left: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('How did you learn about the opening?'),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: Obx(() {
                          final current = controller.source.value;
                          const options = [
                            'Newspaper advertisement',
                            'Company website',
                            'Friend or relative',
                            'Job portal',
                            'Social media',
                            'Walk-in',
                            'Other'
                          ];
                          final val = options.contains(current) ? current : null;
                          return DropdownButton<String>(
                            value: val,
                            isExpanded: true,
                            hint: const Text('Select Source', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
                            items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))))).toList(),
                            onChanged: (v) => controller.source.value = v ?? '',
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                right: _buildInputField(
                  label: 'Source Reference / Referral Details',
                  controller: controller.sourceDetailsController,
                  hint: 'Referrer name, portal name, or link',
                  prefixIcon: Icons.campaign_outlined,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoToggleRow(String title, RxBool valueObs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
          ),
        ),
        Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildChoiceChip('No', !valueObs.value, () => valueObs.value = false),
              const SizedBox(width: 8),
              _buildChoiceChip('Yes', valueObs.value, () => valueObs.value = true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeclarationRow({
    required String label,
    required RxBool valueObs,
    required TextEditingController detailsController,
    required String detailsHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYesNoToggleRow(label, valueObs),
        Obx(() {
          if (!valueObs.value) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildInputField(
              label: 'Additional Information',
              controller: detailsController,
              hint: detailsHint,
              prefixIcon: Icons.info_outline,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 4: Walk-In Form - Educational Qualifications
  // ---------------------------------------------------------------------------
  Widget _buildEducationSection(BuildContext context, StaffController controller) {
    return _buildCardWrapper(
      icon: Icons.school_outlined,
      iconColor: const Color(0xFF8B5CF6),
      title: 'Walk-In Interview Form: Educational Qualifications',
      subtitle: 'Complete academic records from 10th standard through graduation and master degree.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Education qualifications table
          Obx(() {
            final entries = controller.educationEntries;
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('Standard / Class')),
                    DataColumn(label: Text('Degree / Stream')),
                    DataColumn(label: Text('School / College')),
                    DataColumn(label: Text('Board / University')),
                    DataColumn(label: Text('Course Type')),
                    DataColumn(label: Text('Passing Year')),
                    DataColumn(label: Text('Attempts')),
                    DataColumn(label: Text('% / CGPA')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              initialValue: item.standard,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'e.g. 10th'),
                              onChanged: (v) => item.standard = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: TextFormField(
                              initialValue: item.degree,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Degree'),
                              onChanged: (v) => item.degree = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: TextFormField(
                              initialValue: item.schoolCollege,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'School/College'),
                              onChanged: (v) => item.schoolCollege = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 130,
                            child: TextFormField(
                              initialValue: item.boardUniversity,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Board/Univ'),
                              onChanged: (v) => item.boardUniversity = v,
                            ),
                          ),
                        ),
                        DataCell(
                          DropdownButton<String>(
                            value: ['Regular', 'Part time'].contains(item.courseType) ? item.courseType : 'Regular',
                            isDense: true,
                            underline: const SizedBox.shrink(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                            items: const [
                              DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                              DropdownMenuItem(value: 'Part time', child: Text('Part time')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                item.courseType = v;
                                controller.educationEntries.refresh();
                              }
                            },
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              initialValue: item.passingYear,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'YYYY'),
                              onChanged: (v) => item.passingYear = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: item.attempts,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: '1'),
                              onChanged: (v) => item.attempts = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 70,
                            child: TextFormField(
                              initialValue: item.percentage,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: '%'),
                              onChanged: (v) => item.percentage = v,
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                            onPressed: () => controller.removeEducationEntry(index),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: controller.addEducationEntry,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Qualification Row', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
            ),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          // Gap in academics check
          _buildDeclarationRow(
            label: 'Was there any gap during your academic career?',
            valueObs: controller.academicGap,
            detailsController: controller.academicGapDetailsController,
            detailsHint: 'Duration and reason for gap',
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: 'Number of Backlogs / ATKTs (if any)',
            controller: controller.backlogsCountController,
            hint: 'e.g. Nil, or 1 in Semester 3',
            prefixIcon: Icons.history_edu_outlined,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 5: Walk-In Form - Current Compensation & Reporting Structure
  // ---------------------------------------------------------------------------
  Widget _buildWorkExpSection(BuildContext context, StaffController controller) {
    return _buildCardWrapper(
      icon: Icons.work_outline,
      iconColor: const Color(0xFF3B82F6),
      title: 'Walk-In Interview Form: Work Experience & Compensation',
      subtitle: 'Current/last organization, designation, reporting hierarchy, and CTC details.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 650;
          return Column(
            children: [
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Current / Last Organisation',
                  controller: controller.currentOrganisationController,
                  hint: 'Company or institution name',
                  prefixIcon: Icons.business_outlined,
                ),
                right: _buildInputField(
                  label: 'Current / Last Designation',
                  controller: controller.currentDesignationController,
                  hint: 'e.g. Relationship Manager / Research Associate',
                  prefixIcon: Icons.work_outline,
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Reporting Manager Name',
                  controller: controller.reportingManagerNameController,
                  hint: 'Manager full name',
                  prefixIcon: Icons.person_outline,
                ),
                right: _buildInputField(
                  label: 'Reporting Manager Designation',
                  controller: controller.reportingManagerDesignationController,
                  hint: 'e.g. Vice President, Head of Research',
                  prefixIcon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Number of Direct Reportees',
                  controller: controller.reporteesCountController,
                  hint: 'Number of people reporting to you (or 0)',
                  prefixIcon: Icons.groups_outlined,
                  keyboardType: TextInputType.number,
                ),
                right: _buildInputField(
                  label: 'Total Experience (Years / Months)',
                  controller: controller.totalExperienceController,
                  hint: 'e.g. 3.5 Years',
                  prefixIcon: Icons.timeline_outlined,
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Current CTC: Fixed Salary (Annual INR)',
                  controller: controller.fixedSalaryController,
                  hint: 'e.g. 5,00,000',
                  prefixIcon: Icons.currency_rupee,
                ),
                right: _buildInputField(
                  label: 'Current CTC: Bonus / Variable / Incentive',
                  controller: controller.bonusIncentiveController,
                  hint: 'e.g. 1,00,000',
                  prefixIcon: Icons.currency_rupee,
                ),
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isWide: isWide,
                left: _buildInputField(
                  label: 'Total Current CTC (Annual INR)',
                  controller: controller.totalSalaryController,
                  hint: 'e.g. 6,00,000',
                  prefixIcon: Icons.currency_rupee,
                ),
                right: _buildInputField(
                  label: 'Expected CTC (Annual INR)',
                  controller: controller.expectedSalaryController,
                  hint: 'e.g. 7,50,000',
                  prefixIcon: Icons.trending_up,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Notice Period (Days)',
                controller: controller.noticePeriodController,
                hint: 'e.g. Immediate, 15 Days, 30 Days',
                prefixIcon: Icons.timer_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 6: Walk-In Form - Employment History
  // ---------------------------------------------------------------------------
  Widget _buildEmploymentHistorySection(BuildContext context, StaffController controller) {
    return _buildCardWrapper(
      icon: Icons.history_outlined,
      iconColor: const Color(0xFF0284C7),
      title: 'Walk-In Interview Form: Employment History',
      subtitle: 'Chronological list of all past organizations and career transitions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final entries = controller.employmentEntries;
            if (entries.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.work_history_outlined, size: 32, color: AppTheme.gray400),
                      const SizedBox(height: 8),
                      Text(
                        'No previous employment entries recorded (Fresher or single company)',
                        style: TextStyle(fontSize: 12, color: AppTheme.gray500),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('From (Month, Year)')),
                    DataColumn(label: Text('To (Month, Year)')),
                    DataColumn(label: Text('Organisation')),
                    DataColumn(label: Text('Designation')),
                    DataColumn(label: Text('Reason for Leaving')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 130,
                            child: TextFormField(
                              initialValue: item.fromPeriod,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'e.g. Jan 2021'),
                              onChanged: (v) => item.fromPeriod = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 130,
                            child: TextFormField(
                              initialValue: item.toPeriod,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'e.g. Mar 2023'),
                              onChanged: (v) => item.toPeriod = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: TextFormField(
                              initialValue: item.organisation,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Company name'),
                              onChanged: (v) => item.organisation = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 160,
                            child: TextFormField(
                              initialValue: item.designation,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Designation'),
                              onChanged: (v) => item.designation = v,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              initialValue: item.reasonForLeaving,
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Better opportunity, etc.'),
                              onChanged: (v) => item.reasonForLeaving = v,
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                            onPressed: () => controller.removeEmploymentEntry(index),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: controller.addEmploymentEntry,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Previous Employer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
            ),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildInputField(
            label: 'Career Gap Details (if any)',
            controller: controller.careerGapController,
            hint: 'Specify duration and reasons for any career gaps',
            prefixIcon: Icons.timelapse_outlined,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 7: Emergency & Safety Contacts
  // ---------------------------------------------------------------------------
  Widget _buildEmergencySection(BuildContext context, StaffController controller) {
    return _buildCardWrapper(
      icon: Icons.emergency_outlined,
      iconColor: const Color(0xFFE11D48),
      title: 'Emergency Contact Information',
      subtitle: 'Designated contact person for workplace health, safety, and urgent notifications.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Emergency Contact Name',
                    controller: controller.emergencyNameController,
                    hint: 'e.g. Priya Sharma',
                    prefixIcon: Icons.person_pin_outlined,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildInputField(
                    label: 'Relationship',
                    controller: controller.emergencyRelationController,
                    hint: 'Spouse / Parent / Sibling',
                    prefixIcon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildInputField(
                    label: 'Emergency Phone',
                    controller: controller.emergencyPhoneController,
                    hint: '10-digit mobile number',
                    prefixIcon: Icons.phone_in_talk_outlined,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                _buildInputField(
                  label: 'Emergency Contact Name',
                  controller: controller.emergencyNameController,
                  hint: 'e.g. Priya Sharma',
                  prefixIcon: Icons.person_pin_outlined,
                ),
                const SizedBox(height: 14),
                _buildInputField(
                  label: 'Relationship',
                  controller: controller.emergencyRelationController,
                  hint: 'Spouse / Parent / Sibling',
                  prefixIcon: Icons.people_outline,
                ),
                const SizedBox(height: 14),
                _buildInputField(
                  label: 'Emergency Phone',
                  controller: controller.emergencyPhoneController,
                  hint: '10-digit mobile number',
                  prefixIcon: Icons.phone_in_talk_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 8: Compliance & KYC Documents (when editing)
  // ---------------------------------------------------------------------------
  Widget _buildDocumentsSection(BuildContext context, StaffController controller, StaffModel staff) {
    return _buildCardWrapper(
      icon: Icons.verified_user_outlined,
      iconColor: const Color(0xFF6366F1),
      title: 'Verification Documents & KYC',
      subtitle: 'Statutory compliance attachments, certifications, and verification media.',
      child: Column(
        children: [
          _buildDocCard(context, controller, 'PAN Card', 'pan', staff.panUrl, staff),
          const SizedBox(height: 10),
          _buildDocCard(context, controller, 'Aadhaar Card', 'aadhaar', staff.aadhaarUrl, staff),
          const SizedBox(height: 10),
          _buildDocCard(context, controller, 'NISM Certificate', 'nism', staff.nismUrl, staff),
          const SizedBox(height: 10),
          _buildDocCard(context, controller, 'Highest Education Degree', 'education', staff.highestEducationUrl, staff),
          const SizedBox(height: 10),
          _buildDocCard(context, controller, 'KYC Verification Video', 'video', staff.kycVideoUrl, staff),
        ],
      ),
    );
  }

  Widget _buildDocCard(
    BuildContext context,
    StaffController controller,
    String title,
    String type,
    String? fileUrl,
    StaffModel staff,
  ) {
    final hasFile = fileUrl != null && fileUrl.trim().isNotEmpty;
    final isVideo = type == 'video';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasFile ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasFile ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasFile ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              isVideo ? Icons.videocam_outlined : Icons.description_outlined,
              size: 20,
              color: hasFile ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
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
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasFile ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasFile ? 'Uploaded' : 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: hasFile ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasFile ? fileUrl : 'No document attached yet.',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (hasFile)
            OutlinedButton.icon(
              onPressed: () {
                final fullUrl = AppConfig.buildImageUrl(fileUrl);
                final ext = isVideo ? '.mp4' : (fileUrl.toLowerCase().endsWith('.pdf') ? '.pdf' : '.png');
                showDialog(
                  context: context,
                  builder: (ctx) => FilePreviewDialog(
                    fileName: '$title$ext',
                    fileUrl: fullUrl,
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined, size: 14),
              label: const Text('Preview', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => controller.pickAndUploadDoc(staff.id, type),
            icon: Icon(hasFile ? Icons.sync : Icons.upload_file, size: 14),
            label: Text(hasFile ? 'Replace' : 'Upload', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasFile ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB),
              foregroundColor: hasFile ? const Color(0xFF334155) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Action Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(StaffController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: controller.resetForm,
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Reset Form', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Obx(
            () => ElevatedButton.icon(
              onPressed: controller.isLoading.value ? null : controller.saveStaff,
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check, size: 16),
              label: Text(
                controller.isLoading.value
                    ? 'Saving...'
                    : (controller.isEditing.value ? 'Update Staff Member' : 'Add Staff Member'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper Component Generators
  // ---------------------------------------------------------------------------
  Widget _buildCardWrapper({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildResponsiveRow({
    required bool isWide,
    required Widget left,
    required Widget right,
  }) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        left,
        const SizedBox(height: 16),
        right,
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
    int? maxLength,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF64748B)) : null,
      prefixText: prefixText,
      prefixStyle: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscureText = false,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, required: required),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          decoration: _inputDecoration(
            hint: hint,
            prefixIcon: prefixIcon,
            prefixText: prefixText,
            maxLength: maxLength,
          ),
        ),
      ],
    );
  }
}
