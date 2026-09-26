import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/staff/staff_details.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';
import '../../../config/app.config.dart';
import 'widgets/staff_digital_id_dialog.widget.dart';
import '../../../models/staff.model.dart';

class StaffDetailsScreen extends StatelessWidget {
  const StaffDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffDetailsController());

    return DashboardLayout(
      child: Container(
        color: const Color(0xFFF8FAFC),
        width: double.infinity,
        height: double.infinity,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final staff = controller.staff.value;
          if (staff == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined, size: 54, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'Staff member not found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, size: 15),
                    label: const Text('Back to Staff Directory', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Navigation & Action Row
                    _buildHeader(context, staff),
                    const SizedBox(height: 18),

                    // Minimal Hero Header Card
                    _buildHeroCard(context, staff),
                    const SizedBox(height: 20),

                    // Sleek Segmented Tab Selector
                    _buildTabBar(controller),
                    const SizedBox(height: 20),

                    // Tab View Contents
                    Obx(() {
                      switch (controller.selectedTabIndex.value) {
                        case 0:
                          return _buildOverviewTab(staff);
                        case 1:
                          return _buildWalkInTab(staff);
                        case 2:
                          return _buildCareerTab(staff);
                        case 3:
                          return _buildDocumentsTab(context, staff);
                        default:
                          return _buildOverviewTab(staff);
                      }
                    }),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header Area
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, StaffModel staff) {
    return Row(
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
        Text(
          staff.name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlue,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => StaffDigitalIdDialog(staff: staff),
            );
          },
          icon: const Icon(Icons.badge_outlined, size: 15),
          label: const Text('Digital ID Card', style: TextStyle(fontSize: 12.5)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1E293B),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => Get.toNamed('/staff/edit/${staff.id}'),
          icon: const Icon(Icons.edit_outlined, size: 15),
          label: const Text('Edit Staff', style: TextStyle(fontSize: 12.5)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Minimal Hero Card
  // ---------------------------------------------------------------------------
  Widget _buildHeroCard(BuildContext context, StaffModel staff) {
    final bool isActive = staff.status == 'Active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                child: ClipOval(
                  child: staff.photoUrl != null && staff.photoUrl!.isNotEmpty
                      ? Image.network(
                          AppConfig.buildImageUrl(staff.photoUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(staff.name),
                        )
                      : _buildAvatarFallback(staff.name),
                ),
              ),
              const SizedBox(width: 16),
              // Name and Primary Identifiers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          staff.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Staff ID Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            staff.staffId.isNotEmpty ? staff.staffId : 'ID Pending',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isActive ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                staff.status,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${staff.department.isNotEmpty ? staff.department : staff.role} • ${staff.email}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          // Subtle Metric Bar
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildMiniMetric(Icons.phone_outlined, 'Phone', staff.mobile),
              _buildMiniMetric(Icons.event_outlined, 'Joining Date', staff.joiningDate != null ? "${staff.joiningDate!.day}/${staff.joiningDate!.month}/${staff.joiningDate!.year}" : 'Not set'),
              _buildMiniMetric(Icons.timeline_outlined, 'Experience', staff.experienceYears != null ? '${staff.experienceYears} Years' : (staff.walkInForm?.totalExperience.isNotEmpty == true ? staff.walkInForm!.totalExperience : 'Fresher')),
              _buildMiniMetric(Icons.supervisor_account_outlined, 'Supervisor', staff.assignedDirectorName ?? 'Unassigned / Direct'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase()
        : 'S';
    return Container(
      color: const Color(0xFFEFF6FF),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sleek Segmented Tab Selector
  // ---------------------------------------------------------------------------
  Widget _buildTabBar(StaffDetailsController controller) {
    final tabs = [
      {'title': 'Overview & Profile', 'icon': Icons.badge_outlined},
      {'title': 'Walk-In Application', 'icon': Icons.description_outlined},
      {'title': 'Education & Career', 'icon': Icons.school_outlined},
      {'title': 'KYC & Documents', 'icon': Icons.folder_shared_outlined},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Obx(
        () => Row(
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = controller.selectedTabIndex.value == index;

            return Expanded(
              child: InkWell(
                onTap: () => controller.selectedTabIndex.value = index,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 15,
                        color: isSelected ? AppTheme.primaryBlue : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        tab['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppTheme.primaryBlue : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Overview & Profile
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(StaffModel staff) {
    final w = staff.walkInForm;

    return Column(
      children: [
        _buildSectionCard(
          title: 'Personal Details & Identity',
          subtitle: 'Core demographic, contact, and identification information.',
          child: Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildDataTile('Full Name', staff.name),
              _buildDataTile('Position Applied', (w?.appliedPosition.isNotEmpty == true) ? w!.appliedPosition : staff.role),
              _buildDataTile('Date of Birth', staff.dob ?? (w?.dob.isNotEmpty == true ? w!.dob : 'N/A')),
              _buildDataTile('Gender', staff.gender ?? (w?.gender.isNotEmpty == true ? w!.gender : 'N/A')),
              _buildDataTile('Native Place (Hometown)', (w?.nativePlace.isNotEmpty == true) ? w!.nativePlace : 'N/A'),
              _buildDataTile('Marital Status', (w?.maritalStatus.isNotEmpty == true) ? w!.maritalStatus : 'N/A'),
              _buildDataTile('Current Location', (w?.currentLocation.isNotEmpty == true) ? w!.currentLocation : 'N/A'),
              _buildDataTile('Skype / LinkedIn Handle', (w?.skypeAddress.isNotEmpty == true) ? w!.skypeAddress : 'N/A'),
              _buildDataTile('Mobile Number', staff.mobile),
              _buildDataTile('Email Address', staff.email),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Residential Addresses',
          subtitle: 'Current local address and permanent domicile address.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddressItem('Current / Residential Address', staff.localAddress ?? 'Not specified'),
              const SizedBox(height: 12),
              _buildAddressItem('Permanent Address', staff.permanentAddress ?? 'Same as current address'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (staff.emergencyContact != null)
          _buildSectionCard(
            title: 'Emergency Contact Information',
            subtitle: 'Immediate contact for workplace health, safety, and urgent family alerts.',
            child: Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _buildDataTile('Emergency Contact Person', staff.emergencyContact!.name.isNotEmpty ? staff.emergencyContact!.name : 'N/A'),
                _buildDataTile('Relationship', staff.emergencyContact!.relation.isNotEmpty ? staff.emergencyContact!.relation : 'N/A'),
                _buildDataTile('Emergency Contact Phone', staff.emergencyContact!.phone.isNotEmpty ? staff.emergencyContact!.phone : 'N/A'),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Walk-In Application (Declarations & Screening)
  // ---------------------------------------------------------------------------
  Widget _buildWalkInTab(StaffModel staff) {
    final w = staff.walkInForm;

    if (w == null) {
      return _buildEmptyTabMessage(
        icon: Icons.assignment_outlined,
        title: 'Walk-In Interview Form Not Attached',
        subtitle: 'No walk-in application form data was recorded for this staff member.',
      );
    }

    return Column(
      children: [
        _buildSectionCard(
          title: 'Walk-In Screening & Lifestyle Declarations',
          subtitle: 'Declarations signed during the walk-in recruitment and screening process.',
          child: Column(
            children: [
              _buildDeclarationTile(
                'Interviewed by company in last six months',
                w.interviewedBefore,
                w.interviewedBeforeDetails,
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDeclarationTile(
                'Tobacco / Smoking consumption',
                w.smoke,
                null,
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDeclarationTile(
                'Alcohol consumption',
                w.alcohol,
                null,
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDeclarationTile(
                'Differently abled candidate',
                w.differentlyAbled,
                w.differentlyAbledDetails,
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDeclarationTile(
                'Past police records or legal proceedings',
                w.policeRecord,
                w.policeRecordDetails,
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              _buildDeclarationTile(
                'History of major illness or medical treatment',
                w.majorIllness,
                w.majorIllnessDetails,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Candidate Sourcing & Referral Details',
          subtitle: 'Information about how the candidate discovered the job vacancy.',
          child: Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildDataTile('Application Date', w.applicationDate.isNotEmpty ? w.applicationDate : 'N/A'),
              _buildDataTile('Vacancy Source Channel', w.source.isNotEmpty ? w.source : 'Not declared'),
              _buildDataTile('Referrer / Source Details', w.sourceDetails.isNotEmpty ? w.sourceDetails : 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Education & Career
  // ---------------------------------------------------------------------------
  Widget _buildCareerTab(StaffModel staff) {
    final w = staff.walkInForm;

    return Column(
      children: [
        // Education Table Card
        _buildSectionCard(
          title: 'Educational Qualifications',
          subtitle: 'Academic background recorded in the walk-in application form.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (w?.educationList.isNotEmpty == true)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingTextStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      dataTextStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(label: Text('Class / Level')),
                        DataColumn(label: Text('Degree / Stream')),
                        DataColumn(label: Text('School / College')),
                        DataColumn(label: Text('Board / Univ')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Year')),
                        DataColumn(label: Text('Attempts')),
                        DataColumn(label: Text('% / CGPA')),
                      ],
                      rows: w!.educationList.map((e) => DataRow(
                        cells: [
                          DataCell(Text(e.standard.isNotEmpty ? e.standard : '-')),
                          DataCell(Text(e.degree.isNotEmpty ? e.degree : '-')),
                          DataCell(Text(e.schoolCollege.isNotEmpty ? e.schoolCollege : '-')),
                          DataCell(Text(e.boardUniversity.isNotEmpty ? e.boardUniversity : '-')),
                          DataCell(Text(e.courseType.isNotEmpty ? e.courseType : '-')),
                          DataCell(Text(e.passingYear.isNotEmpty ? e.passingYear : '-')),
                          DataCell(Text(e.attempts.isNotEmpty ? e.attempts : '1')),
                          DataCell(Text(e.percentage.isNotEmpty ? '${e.percentage}%' : '-')),
                        ],
                      )).toList(),
                    ),
                  ),
                )
              else
                Text('No educational records logged.', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                children: [
                  _buildDataTile('Academic Gap', (w?.academicGap == true) ? 'Yes (${w?.academicGapDetails})' : 'No gap reported'),
                  _buildDataTile('Backlogs / ATKTs', (w?.backlogsCount.isNotEmpty == true) ? w!.backlogsCount : 'Nil'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Compensation & Reporting Structure
        _buildSectionCard(
          title: 'Current / Last Employment & Compensation',
          subtitle: 'Prior organization, designation, reporting hierarchy, and remuneration breakdown.',
          child: Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _buildDataTile('Current / Last Employer', (w?.currentOrganisation.isNotEmpty == true) ? w!.currentOrganisation : (staff.previousCompany ?? 'N/A')),
              _buildDataTile('Current Designation', (w?.currentDesignation.isNotEmpty == true) ? w!.currentDesignation : 'N/A'),
              _buildDataTile('Reporting Manager Name', (w?.reportingManagerName.isNotEmpty == true) ? w!.reportingManagerName : 'N/A'),
              _buildDataTile('Reporting Manager Designation', (w?.reportingManagerDesignation.isNotEmpty == true) ? w!.reportingManagerDesignation : 'N/A'),
              _buildDataTile('Direct Reportees', (w?.reporteesCount.isNotEmpty == true) ? w!.reporteesCount : '0'),
              _buildDataTile('Total Experience', (w?.totalExperience.isNotEmpty == true) ? w!.totalExperience : (staff.experienceYears != null ? '${staff.experienceYears} Years' : 'N/A')),
              _buildDataTile('Fixed Salary (CTC)', (w?.fixedSalary.isNotEmpty == true) ? '₹${w!.fixedSalary}' : 'N/A'),
              _buildDataTile('Bonus / Incentive', (w?.bonusIncentive.isNotEmpty == true) ? '₹${w!.bonusIncentive}' : 'N/A'),
              _buildDataTile('Total Salary (CTC)', (w?.totalSalary.isNotEmpty == true) ? '₹${w!.totalSalary}' : (staff.lastCtc != null ? '₹${staff.lastCtc}' : 'N/A')),
              _buildDataTile('Expected CTC', (w?.expectedSalary.isNotEmpty == true) ? '₹${w!.expectedSalary}' : 'N/A'),
              _buildDataTile('Notice Period', (w?.noticePeriod.isNotEmpty == true) ? w!.noticePeriod : 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Employment History Table
        _buildSectionCard(
          title: 'Previous Employment History',
          subtitle: 'Chronological timeline of past employers and reasons for transitions.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (w?.employmentList.isNotEmpty == true)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      headingTextStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      dataTextStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: const [
                        DataColumn(label: Text('From')),
                        DataColumn(label: Text('To')),
                        DataColumn(label: Text('Organisation')),
                        DataColumn(label: Text('Designation')),
                        DataColumn(label: Text('Reason for Leaving')),
                      ],
                      rows: w!.employmentList.map((emp) => DataRow(
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
                )
              else
                Text('No previous employment history recorded.', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
              const SizedBox(height: 12),
              _buildDataTile('Career Gap Details', (w?.careerGap.isNotEmpty == true) ? w!.careerGap : 'No career gaps specified'),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 4: KYC & Documents
  // ---------------------------------------------------------------------------
  Widget _buildDocumentsTab(BuildContext context, StaffModel staff) {
    return _buildSectionCard(
      title: 'Uploaded Compliance & Verification Media',
      subtitle: 'Mandatory KYC documentation, identity proofs, and education verification files.',
      child: Column(
        children: [
          _buildCompactDocTile(context, 'Resume / CV', staff.resumeUrl, Icons.description_outlined),
          const SizedBox(height: 8),
          _buildCompactDocTile(context, 'PAN Card', staff.panUrl, Icons.credit_card_outlined),
          const SizedBox(height: 8),
          _buildCompactDocTile(context, 'Aadhaar Card', staff.aadhaarUrl, Icons.badge_outlined),
          const SizedBox(height: 8),
          _buildCompactDocTile(context, 'NISM Certification', staff.nismUrl, Icons.verified_user_outlined),
          const SizedBox(height: 8),
          _buildCompactDocTile(context, 'Highest Education Degree', staff.highestEducationUrl, Icons.school_outlined),
          const SizedBox(height: 8),
          _buildCompactDocTile(context, 'KYC Verification Video', staff.kycVideoUrl, Icons.videocam_outlined, isVideo: true),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable Micro-Components for Clean, Non-Congested Layout
  // ---------------------------------------------------------------------------
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDataTile(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem(String title, String address) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
          Text(
            address,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclarationTile(String question, bool isYes, String? details) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                question,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
              ),
              if (isYes && details != null && details.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Details: $details',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB)),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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

  Widget _buildCompactDocTile(BuildContext context, String title, String? fileUrl, IconData icon, {bool isVideo = false}) {
    final bool hasFile = fileUrl != null && fileUrl.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasFile ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: hasFile ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: hasFile ? AppTheme.primaryBlue : const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasFile ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  hasFile ? (isVideo ? 'Video Uploaded & Available' : 'Document Uploaded') : 'Not uploaded yet',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: hasFile ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
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
              icon: const Icon(Icons.visibility_outlined, size: 13),
              label: const Text('View', style: TextStyle(fontSize: 11.5)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
