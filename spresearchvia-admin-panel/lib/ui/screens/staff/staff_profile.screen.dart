import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.config.dart';
import '../../../controllers/staff/staff_profile.controller.dart';
import '../../../models/staff.model.dart';
import '../../layouts/dashboard_layout.widget.dart';
import 'widgets/staff_digital_id_dialog.widget.dart';

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffProfileController());

    return DashboardLayout(
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final staff = controller.profile.value;
          if (staff == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined, size: 64, color: AppTheme.gray400),
                  const SizedBox(height: 16),
                  const Text(
                    'Profile details unavailable',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => controller.fetchProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Page Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Get.back(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'View and manage your personal details and login credentials',
                          style: TextStyle(fontSize: 13, color: AppTheme.gray500),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => StaffDigitalIdDialog(staff: staff),
                        );
                      },
                      icon: const Icon(Icons.badge_outlined, size: 18),
                      label: const Text('View Digital ID Badge'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Profile',
                      onPressed: () => controller.fetchProfile(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hero Profile Card
                _buildHeroCard(context, staff),
                const SizedBox(height: 24),

                // Main Content Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 950;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildPersonalInfoCard(context, controller),
                                const SizedBox(height: 24),
                                _buildWalkInFormCard(context, staff),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildMpinSecurityCard(context, controller),
                                const SizedBox(height: 24),
                                _buildOrganizationInfoCard(context, staff),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildPersonalInfoCard(context, controller),
                          const SizedBox(height: 24),
                          _buildWalkInFormCard(context, staff),
                          const SizedBox(height: 24),
                          _buildMpinSecurityCard(context, controller),
                          const SizedBox(height: 24),
                          _buildOrganizationInfoCard(context, staff),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, dynamic staff) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
            backgroundImage: staff.photoUrl != null && staff.photoUrl!.isNotEmpty
                ? NetworkImage(staff.photoUrl!)
                : null,
            child: (staff.photoUrl == null || staff.photoUrl!.isEmpty)
                ? Text(
                    staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      staff.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        staff.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        staff.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _buildIconLabel(Icons.badge_outlined, staff.staffId.isNotEmpty ? staff.staffId : 'STAFF'),
                    if (staff.department.isNotEmpty)
                      _buildIconLabel(Icons.apartment_outlined, staff.department),
                    _buildIconLabel(Icons.email_outlined, staff.email),
                    _buildIconLabel(Icons.phone_outlined, staff.mobile),
                    if (staff.joiningDate != null)
                      _buildIconLabel(
                        Icons.calendar_today_outlined,
                        'Joined: ${DateFormat('dd MMM yyyy').format(staff.joiningDate!)}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.gray500),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(fontSize: 13, color: AppTheme.gray600),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, StaffProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Personal & Contact Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your personal information, address, and emergency contact up to date.',
            style: TextStyle(fontSize: 13, color: AppTheme.gray500),
          ),
          const SizedBox(height: 20),

          // Name and Email
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: controller.emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mobile and Gender
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(() {
                  return DropdownButtonFormField<String>(
                    value: controller.gender.value.isNotEmpty ? controller.gender.value : null,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.transgender_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (val) => controller.gender.value = val ?? '',
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Addresses
          TextField(
            controller: controller.localAddressController,
            decoration: const InputDecoration(
              labelText: 'Current / Local Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home_outlined, size: 20),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.permanentAddressController,
            decoration: const InputDecoration(
              labelText: 'Permanent Address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city_outlined, size: 20),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Emergency Contact Sub-section
          const Row(
            children: [
              Icon(Icons.contact_emergency_outlined, size: 18, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Emergency Contact Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller.emergencyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller.emergencyRelationController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship (e.g. Spouse, Parent)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controller.emergencyPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Button
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() {
              return ElevatedButton.icon(
                onPressed: controller.isUpdating.value ? null : () => controller.saveProfile(),
                icon: controller.isUpdating.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(controller.isUpdating.value ? 'Saving Changes...' : 'Save Profile Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMpinSecurityCard(BuildContext context, StaffProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_reset_outlined, size: 20, color: AppTheme.warningOrange),
              SizedBox(width: 8),
              Text(
                'Change Login MPIN',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Set or change your 4 to 6-digit staff login PIN.',
            style: TextStyle(fontSize: 13, color: AppTheme.gray500),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.oldMpinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Current MPIN',
              hintText: 'Leave blank if first time setting PIN',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline, size: 18),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.newMpinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'New MPIN (4-6 digits)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.password_outlined, size: 18),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.confirmMpinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Confirm New MPIN',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.check_circle_outline, size: 18),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Obx(() {
              return ElevatedButton(
                onPressed: controller.isChangingMpin.value ? null : () => controller.changeMpin(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(controller.isChangingMpin.value ? 'Updating MPIN...' : 'Update Login MPIN'),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationInfoCard(BuildContext context, dynamic staff) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.corporate_fare_outlined, size: 20, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Employment & Team Info',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Official organizational hierarchy and onboarding records.',
            style: TextStyle(fontSize: 13, color: AppTheme.gray500),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Employee ID', staff.staffId.isNotEmpty ? staff.staffId : 'STAFF-001'),
          const Divider(height: 16, color: AppTheme.gray200),
          _buildInfoRow('Department', staff.department.isNotEmpty ? staff.department : 'General Staff'),
          const Divider(height: 16, color: AppTheme.gray200),
          _buildInfoRow('Role Designation', staff.role.isNotEmpty ? staff.role : 'Staff'),
          const Divider(height: 16, color: AppTheme.gray200),
          _buildInfoRow('Direct Supervisor', staff.assignedDirectorName ?? 'Director / Management'),
          const Divider(height: 16, color: AppTheme.gray200),
          _buildInfoRow('Onboarding Stage', staff.stage.toUpperCase()),
          const Divider(height: 16, color: AppTheme.gray200),
          _buildInfoRow('Account Verification', staff.onboardingStatus.toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppTheme.gray600, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildWalkInFormCard(BuildContext context, dynamic staff) {
    final WalkInFormModel? w = staff is StaffModel ? staff.walkInForm : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, size: 20, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Walk-In Interview & Application Details',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Declarations, qualifications, and employment history submitted during recruitment.',
            style: TextStyle(fontSize: 13, color: AppTheme.gray500),
          ),
          const SizedBox(height: 20),
          if (w == null)
            Text(
              'No walk-in application form on file.',
              style: TextStyle(fontSize: 13, color: AppTheme.gray500, fontStyle: FontStyle.italic),
            )
          else ...[
            _buildProfileSectionHeader('Application & Personal Details'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildProfileDetailItem('Position Applied', w.appliedPosition.isNotEmpty ? w.appliedPosition : (staff.role ?? 'N/A')),
                _buildProfileDetailItem('Application Date', w.applicationDate.isNotEmpty ? w.applicationDate : 'N/A'),
                _buildProfileDetailItem('Native Place', w.nativePlace.isNotEmpty ? w.nativePlace : 'N/A'),
                _buildProfileDetailItem('Marital Status', w.maritalStatus.isNotEmpty ? w.maritalStatus : 'N/A'),
                _buildProfileDetailItem('Current Location', w.currentLocation.isNotEmpty ? w.currentLocation : 'N/A'),
                _buildProfileDetailItem('Skype / LinkedIn', w.skypeAddress.isNotEmpty ? w.skypeAddress : 'N/A'),
              ],
            ),
            const Divider(height: 28, color: AppTheme.gray200),
            _buildProfileSectionHeader('Screening Declarations'),
            const SizedBox(height: 10),
            _buildProfileDeclarationRow('Interviewed by company in last 6 months', w.interviewedBefore, w.interviewedBeforeDetails),
            const SizedBox(height: 6),
            _buildProfileDeclarationRow('Tobacco / Smoking', w.smoke, null),
            const SizedBox(height: 6),
            _buildProfileDeclarationRow('Alcohol consumption', w.alcohol, null),
            const SizedBox(height: 6),
            _buildProfileDeclarationRow('Differently abled', w.differentlyAbled, w.differentlyAbledDetails),
            const SizedBox(height: 6),
            _buildProfileDeclarationRow('Police record / Legal case', w.policeRecord, w.policeRecordDetails),
            const SizedBox(height: 6),
            _buildProfileDeclarationRow('History of major illness', w.majorIllness, w.majorIllnessDetails),
            const SizedBox(height: 6),
            _buildProfileDetailItem('Source of vacancy', w.source.isNotEmpty ? '${w.source} (${w.sourceDetails})' : 'N/A'),

            if (w.educationList.isNotEmpty) ...[
              const Divider(height: 28, color: AppTheme.gray200),
              _buildProfileSectionHeader('Educational Qualifications'),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  dataTextStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
                  columnSpacing: 14,
                  horizontalMargin: 8,
                  columns: const [
                    DataColumn(label: Text('Class')),
                    DataColumn(label: Text('Degree')),
                    DataColumn(label: Text('School/College')),
                    DataColumn(label: Text('Board/Univ')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Year')),
                    DataColumn(label: Text('%/CGPA')),
                  ],
                  rows: w.educationList.map((e) => DataRow(
                    cells: [
                      DataCell(Text(e.standard.isNotEmpty ? e.standard : '-')),
                      DataCell(Text(e.degree.isNotEmpty ? e.degree : '-')),
                      DataCell(Text(e.schoolCollege.isNotEmpty ? e.schoolCollege : '-')),
                      DataCell(Text(e.boardUniversity.isNotEmpty ? e.boardUniversity : '-')),
                      DataCell(Text(e.courseType.isNotEmpty ? e.courseType : '-')),
                      DataCell(Text(e.passingYear.isNotEmpty ? e.passingYear : '-')),
                      DataCell(Text(e.percentage.isNotEmpty ? '${e.percentage}%' : '-')),
                    ],
                  )).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _buildProfileDetailItem('Academic Gap', w.academicGap ? 'Yes (${w.academicGapDetails})' : 'No gap'),
                  _buildProfileDetailItem('Backlogs / ATKTs', w.backlogsCount.isNotEmpty ? w.backlogsCount : 'Nil'),
                ],
              ),
            ],

            const Divider(height: 28, color: AppTheme.gray200),
            _buildProfileSectionHeader('Work Experience & Compensation History'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildProfileDetailItem('Current / Last Org', w.currentOrganisation.isNotEmpty ? w.currentOrganisation : (staff.previousCompany ?? 'N/A')),
                _buildProfileDetailItem('Designation', w.currentDesignation.isNotEmpty ? w.currentDesignation : 'N/A'),
                _buildProfileDetailItem('Reporting Manager', w.reportingManagerName.isNotEmpty ? '${w.reportingManagerName} (${w.reportingManagerDesignation})' : 'N/A'),
                _buildProfileDetailItem('Direct Reportees', w.reporteesCount.isNotEmpty ? w.reporteesCount : '0'),
                _buildProfileDetailItem('Total Experience', w.totalExperience.isNotEmpty ? w.totalExperience : (staff.experienceYears != null ? '${staff.experienceYears} Years' : 'N/A')),
                _buildProfileDetailItem('Fixed Salary', w.fixedSalary.isNotEmpty ? '₹${w.fixedSalary}' : 'N/A'),
                _buildProfileDetailItem('Bonus / Incentive', w.bonusIncentive.isNotEmpty ? '₹${w.bonusIncentive}' : 'N/A'),
                _buildProfileDetailItem('Total CTC', w.totalSalary.isNotEmpty ? '₹${w.totalSalary}' : (staff.lastCtc != null ? '₹${staff.lastCtc}' : 'N/A')),
                _buildProfileDetailItem('Expected CTC', w.expectedSalary.isNotEmpty ? '₹${w.expectedSalary}' : 'N/A'),
                _buildProfileDetailItem('Notice Period', w.noticePeriod.isNotEmpty ? w.noticePeriod : 'N/A'),
              ],
            ),
            if (w.employmentList.isNotEmpty) ...[
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  dataTextStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
                  columnSpacing: 14,
                  horizontalMargin: 8,
                  columns: const [
                    DataColumn(label: Text('From')),
                    DataColumn(label: Text('To')),
                    DataColumn(label: Text('Organisation')),
                    DataColumn(label: Text('Designation')),
                    DataColumn(label: Text('Reason for Leaving')),
                  ],
                  rows: w.employmentList.map((emp) => DataRow(
                    cells: [
                      DataCell(Text(emp.fromPeriod.isNotEmpty ? emp.fromPeriod : '-')),
                      DataCell(Text(emp.toPeriod.isNotEmpty ? emp.toPeriod : '-')),
                      DataCell(Text(emp.organisation.isNotEmpty ? emp.organisation : '-')),
                      DataCell(Text(emp.designation.isNotEmpty ? emp.designation : '-')),
                      DataCell(Text(emp.reasonForLeaving.isNotEmpty ? emp.reasonForLeaving : '-')),
                    ],
                  )).toList(),
                ),
              ),
              const SizedBox(height: 8),
              _buildProfileDetailItem('Career Gap', w.careerGap.isNotEmpty ? w.careerGap : 'No gaps reported'),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildProfileSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildProfileDetailItem(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDeclarationRow(String question, bool isYes, String? details) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question, style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B))),
              if (isYes && details != null && details.trim().isNotEmpty)
                Text('Details: $details', style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isYes ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: isYes ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
          ),
          child: Text(
            isYes ? 'Yes' : 'No',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isYes ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
            ),
          ),
        ),
      ],
    );
  }
}
