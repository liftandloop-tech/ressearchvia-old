import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
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
                          return _buildPersonalAndContactTab(context, controller, staff);
                        case 1:
                          return _buildEducationAndProfessionalTab(context, controller, staff);
                        case 2:
                          return _buildOccupationalAndKycTab(context, controller, staff);
                        default:
                          return _buildPersonalAndContactTab(context, controller, staff);
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
    final authController = Get.find<AuthController>();
    final currentUser = authController.user.value;
    final canUpdate = currentUser?.isAdmin == true || (currentUser?.has('staff.update') ?? false);
    final canDelete = currentUser?.isAdmin == true || (currentUser?.has('staff.delete') ?? false);

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
        if (canUpdate) ...[
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
        if (canDelete) ...[
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () async {
              final staffCtrl = Get.isRegistered<StaffController>()
                  ? Get.find<StaffController>()
                  : Get.put(StaffController());
              await staffCtrl.deleteStaff(staff.id, staff.name);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 15),
            label: const Text('Delete Staff', style: TextStyle(fontSize: 12.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
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
                        const SizedBox(width: 8),
                        _buildAgreementPill(staff.agreementStatus),
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
  // Step-Flow Segmented Tab Selector (Matching Applicant View)
  // ---------------------------------------------------------------------------
  Widget _buildTabBar(StaffDetailsController controller) {
    final tabs = [
      {'step': 1, 'title': 'Personal & Contact Details'},
      {'step': 2, 'title': 'Education & Professional Details'},
      {'step': 3, 'title': 'Occupational & KYC Details'},
    ];

    return Obx(() {
      final selected = controller.selectedTabIndex.value;
      return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final isSelected = selected == idx;
            final item = tabs[idx];
            return Expanded(
              child: InkWell(
                onTap: () => controller.setTab(idx),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF163174) : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${item['step']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF163174) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Personal & Contact Details Tab
  // ---------------------------------------------------------------------------
  Widget _buildPersonalAndContactTab(
    BuildContext context,
    StaffDetailsController controller,
    StaffModel staff,
  ) {
    final w = staff.walkInForm;
    final raw = staff.rawJson ?? {};

    String cleanDob(String? rawDob) {
      if (rawDob == null || rawDob.isEmpty) return 'Not specified';
      if (rawDob.contains('T')) return rawDob.split('T').first;
      if (rawDob.contains(' ')) return rawDob.split(' ').first;
      return rawDob;
    }

    final dobVal = cleanDob(staff.dob ?? (raw['dob']?.toString() ?? (w?.dob.isNotEmpty == true ? w!.dob : null)));
    final fatherNameVal = staff.fatherName ?? (raw['fatherName']?.toString() ?? 'Not specified');
    final maritalStatusVal = staff.maritalStatus ?? (raw['maritalStatus']?.toString() ?? (w?.maritalStatus.isNotEmpty == true ? w!.maritalStatus : 'Not specified'));
    final genderVal = staff.gender ?? (raw['gender']?.toString() ?? (w?.gender.isNotEmpty == true ? w!.gender : 'Not specified'));
    final currentCityVal = staff.currentLocation ?? (raw['currentLocation']?.toString() ?? (raw['city']?.toString() ?? (w?.currentLocation.isNotEmpty == true ? w!.currentLocation : 'Not specified')));
    final skypeOrLinkedInVal = staff.skypeOrLinkedIn ?? (raw['skypeAddress']?.toString() ?? (raw['skypeOrLinkedIn']?.toString() ?? (w?.skypeAddress.isNotEmpty == true ? w!.skypeAddress : '')));
    final appliedPositionVal = (w?.appliedPosition.isNotEmpty == true) ? w!.appliedPosition : (raw['appliedPosition']?.toString() ?? (staff.role.isNotEmpty ? staff.role : 'General'));
    final aadhaarNumberVal = staff.aadhaarNumber ?? (raw['aadhaarNumber']?.toString() ?? (raw['proofOfAddressNumber']?.toString() ?? 'Not specified'));
    final panNumberVal = staff.panNumber ?? (raw['panNumber']?.toString() ?? '');
    final altEmailVal = staff.alternateEmail ?? (raw['alternateEmail']?.toString() ?? '—');
    final resPhoneVal = raw['telephoneResidence']?.toString() ?? (raw['telephoneResidenceNumber']?.toString() ?? '—');

    // Address Parsing
    final currentAddr = raw['currentAddress'] is Map ? (raw['currentAddress'] as Map) : null;
    final permAddr = raw['permanentAddress'] is Map ? (raw['permanentAddress'] as Map) : null;

    final currLine1 = currentAddr?['line1']?.toString() ?? currentAddr?['street']?.toString() ?? (staff.localAddress ?? (currentCityVal != 'Not specified' ? currentCityVal : 'Not specified'));
    final currLine2 = currentAddr?['line2']?.toString() ?? '';
    final currLine3 = currentAddr?['line3']?.toString() ?? '';
    final currCity = currentAddr?['city']?.toString() ?? currentCityVal;
    final currState = currentAddr?['state']?.toString() ?? (raw['state']?.toString() ?? 'Madhya Pradesh');
    final currCountry = currentAddr?['country']?.toString() ?? (raw['country']?.toString() ?? 'India');
    final currPincode = currentAddr?['pincode']?.toString() ?? (currentAddr?['zip']?.toString() ?? (raw['pincode']?.toString() ?? '—'));

    final sameAsCurrent = raw['sameAsCurrentAddress'] == true || raw['sameAsCurrent'] == true;
    final permLine1 = permAddr?['line1']?.toString() ?? permAddr?['street']?.toString() ?? (staff.permanentAddress ?? (sameAsCurrent ? 'Same as Current Address' : (currLine1 != 'Not specified' ? currLine1 : 'Not specified')));
    final permCity = permAddr?['city']?.toString() ?? (sameAsCurrent ? currCity : '—');
    final permState = permAddr?['state']?.toString() ?? (sameAsCurrent ? currState : '—');
    final permPincode = permAddr?['pincode']?.toString() ?? (sameAsCurrent ? currPincode : '—');

    // Documents
    final photo = staff.photoUrl ?? raw['photoUrl']?.toString();
    final resume = staff.resumeUrl ?? raw['resumeUrl']?.toString();
    final aadhaar = staff.aadhaarUrl ?? raw['aadhaarUrl']?.toString() ?? raw['proofOfAddressUrl']?.toString();
    final aadhaarBack = staff.aadhaarBackUrl ?? raw['aadhaarBackUrl']?.toString();
    final pan = staff.panUrl ?? raw['panUrl']?.toString();

    return Column(
      children: [
        // Uploaded Compliance & Identity Proofs (Step 1)
        _buildSectionCard(
          title: 'Identity & Application Documents',
          subtitle: 'Profile photo, resume, and government identity verification documents.',
          child: Column(
            children: [
              _buildDocRow(context, controller, 'Profile Photo *', 'photo', photo, Icons.account_circle_outlined),
              const SizedBox(height: 10),
              _buildDocRow(context, controller, 'Resume / CV *', 'resume', resume, Icons.description_outlined),
              const SizedBox(height: 10),
              _buildDocRow(context, controller, 'Aadhaar Card (Front) *', 'aadhaarFront', aadhaar, Icons.badge_outlined),
              const SizedBox(height: 10),
              _buildDocRow(context, controller, 'Aadhaar Card (Back) *', 'aadhaarBack', aadhaarBack, Icons.badge_outlined),
              const SizedBox(height: 10),
              _buildDocRow(context, controller, 'PAN Card (Optional)', 'pan', pan, Icons.credit_card_outlined),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Personal & Contact Information
        _buildSectionCard(
          title: 'Personal & Identity Information',
          subtitle: 'Candidate identity, family background, and primary communication coordinates.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Full Legal Name', staff.name),
                _buildDataTile("Father's Name", fatherNameVal),
                _buildDataTile('Date of Birth', dobVal),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('Gender', genderVal),
                _buildDataTile('Marital Status', maritalStatusVal),
                _buildDataTile('Current City', currentCityVal),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('Position Applied For', appliedPositionVal),
                _buildDataTile('Email Address', staff.email),
                _buildDataTile('Alternate Email ID', altEmailVal),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('Mobile Phone', staff.mobile),
                _buildDataTile('Telephone Residence', resPhoneVal),
                _buildDataTile('Aadhaar Number', aadhaarNumberVal),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('PAN Number (Optional)', panNumberVal.isNotEmpty ? panNumberVal : 'Not provided'),
                _buildDataTile(
                  'Login Password',
                  (staff.plainPassword != null && staff.plainPassword!.isNotEmpty && !staff.plainPassword!.startsWith(r'$2a$') && !staff.plainPassword!.startsWith(r'$2b$'))
                      ? staff.plainPassword!
                      : (staff.plainPassword != null ? '[Encrypted / Click Edit to set plain]' : 'Not set'),
                ),
                if (staff.mpin != null && staff.mpin!.isNotEmpty)
                  _buildDataTile('Login MPIN', staff.mpin!)
                else if (skypeOrLinkedInVal.isNotEmpty)
                  _buildDataTile('LinkedIn / Skype ID', skypeOrLinkedInVal)
                else
                  const SizedBox(),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Current Address
        _buildSectionCard(
          title: 'Current Residential Address',
          subtitle: 'Local residence and current physical living coordinates.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Address Line 1', currLine1),
                _buildDataTile('Address Line 2', currLine2.isNotEmpty ? currLine2 : '—'),
                _buildDataTile('Address Line 3 / Landmark', currLine3.isNotEmpty ? currLine3 : '—'),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('City', currCity),
                _buildDataTile('State', currState),
                _buildDataTile('Country / Pincode', '$currCountry - $currPincode'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Permanent Address
        _buildSectionCard(
          title: 'Permanent Address',
          subtitle: 'Permanent hometown domicile recorded on application.',
          child: _buildRow([
            _buildDataTile('Street / Address', permLine1),
            _buildDataTile('City & State', '$permCity, $permState'),
            _buildDataTile('Pincode', permPincode),
          ]),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Education & Professional Details Tab
  // ---------------------------------------------------------------------------
  Widget _buildEducationAndProfessionalTab(
    BuildContext context,
    StaffDetailsController controller,
    StaffModel staff,
  ) {
    final w = staff.walkInForm;
    final raw = staff.rawJson ?? {};

    // Education
    final highestQual = staff.highestQualification ?? (raw['highestQualification']?.toString() ?? (w?.educationList.isNotEmpty == true ? w!.educationList.last.degree : '—'));
    final majorSub = staff.majorSubject ?? (raw['majorSubject']?.toString() ?? '—');
    final univ = staff.instituteUniversity ?? (raw['instituteUniversity']?.toString() ?? (w?.educationList.isNotEmpty == true ? w!.educationList.last.boardUniversity : '—'));
    final String passYear = staff.yearOfPassing != null ? '${staff.yearOfPassing}' : (raw['yearOfPassing']?.toString() ?? (w?.educationList.isNotEmpty == true ? w!.educationList.last.passingYear : '—'));
    final pctGrade = staff.percentageGrade ?? (raw['percentageGrade']?.toString() ?? (w?.educationList.isNotEmpty == true ? w!.educationList.last.percentage : '—'));

    // Professional Certification (NISM)
    final profCert = staff.professionalCertification ?? (raw['professionalCertification']?.toString() ?? (raw['selectedProfessionalCert']?.toString() ?? 'None'));
    final hasNismCert = raw['hasNismCert'] == true || (profCert != 'None' && profCert != '—' && profCert.isNotEmpty);
    final certRegNo = raw['certRegistrationNumber']?.toString() ?? (raw['nismCertificateNumber']?.toString() ?? (raw['licenseMembershipDetails']?.toString() ?? ''));

    // Documents
    final degreeDoc = staff.highestEducationUrl ?? raw['highestEducationUrl']?.toString();
    final certDoc = staff.certDocumentUrl ?? staff.nismUrl ?? raw['certDocumentUrl']?.toString() ?? raw['nismUrl']?.toString();

    return Column(
      children: [
        // Educational Background
        _buildSectionCard(
          title: 'Educational Details',
          subtitle: 'Highest qualification degree, major subject, institute/university, and passing milestones.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Highest Qualification', highestQual),
                _buildDataTile('Major Subject / Stream', majorSub),
                _buildDataTile('Institute / University', univ),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('Year of Passing', passYear),
                _buildDataTile('Percentage / Grade', pctGrade),
                const SizedBox(),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Degree Document
        _buildSectionCard(
          title: 'Highest Qualification Degree / Marksheet',
          subtitle: 'Scanned copy or PDF of final graduation degree or highest marksheet.',
          child: _buildDocRow(context, controller, 'Degree Certificate / Marksheet', 'education', degreeDoc, Icons.school_outlined),
        ),
        const SizedBox(height: 16),

        // Professional Qualifications & NISM
        _buildSectionCard(
          title: 'Professional Qualifications & NISM Certifications',
          subtitle: 'Regulatory certifications and professional accreditation details.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Certification Status', hasNismCert ? 'Yes (Certified)' : 'No / None'),
                if (hasNismCert) ...[
                  _buildDataTile('Selected Certification', profCert),
                  _buildDataTile('Certificate / Registration No.', certRegNo.isNotEmpty ? certRegNo : 'Not specified'),
                ] else ...[
                  const SizedBox(),
                  const SizedBox(),
                ],
              ]),
              if (hasNismCert || (certDoc != null && certDoc.isNotEmpty)) ...[
                const SizedBox(height: 14),
                _buildDocRow(context, controller, 'Certificate Copy', 'certificate', certDoc, Icons.verified_user_outlined),
              ],
            ],
          ),
        ),
        if (w != null && w.educationList.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Structured Qualifications History',
            subtitle: 'Detailed academic background and degree history recorded chronologically.',
            child: _buildEducationTable(w.educationList),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Occupational & KYC Details Tab
  // ---------------------------------------------------------------------------
  Widget _buildOccupationalAndKycTab(
    BuildContext context,
    StaffDetailsController controller,
    StaffModel staff,
  ) {
    final w = staff.walkInForm;
    final raw = staff.rawJson ?? {};

    // Experience / Fresher
    final isFresher = staff.isFresher ?? (raw['isFresher'] == true || raw['isFresher'] == 'true');
    final currentCompany = staff.previousCompany ?? (raw['previousCompany']?.toString() ?? (raw['currentCompany']?.toString() ?? (w?.employmentList.isNotEmpty == true ? w!.employmentList.first.organisation : (w?.currentOrganisation.isNotEmpty == true ? w!.currentOrganisation : '—'))));
    final currentDesignation = staff.currentDesignation ?? (raw['currentDesignation']?.toString() ?? (w?.employmentList.isNotEmpty == true ? w!.employmentList.first.designation : (w?.currentDesignation.isNotEmpty == true ? w!.currentDesignation : '—')));
    final reportingManager = staff.reportingManagerName ?? (raw['reportingManagerName']?.toString() ?? (raw['reportingManager']?.toString() ?? (w?.reportingManagerName.isNotEmpty == true ? w!.reportingManagerName : '—')));
    final reportingManagerDesig = staff.reportingManagerDesignation ?? (raw['reportingManagerDesignation']?.toString() ?? (w?.reportingManagerDesignation.isNotEmpty == true ? w!.reportingManagerDesignation : '—'));
    final String expYears = staff.experienceYears != null ? '${staff.experienceYears} Years' : (raw['totalExperience']?.toString() ?? (w?.totalExperience.isNotEmpty == true ? w!.totalExperience : '—'));
    final String directReportees = staff.reporteesCount != null ? '${staff.reporteesCount}' : (raw['reporteesCount']?.toString() ?? (w?.reporteesCount.isNotEmpty == true ? w!.reporteesCount : '0'));
    final fixedSal = staff.fixedSalary ?? (raw['fixedSalary']?.toString() ?? (w?.fixedSalary.isNotEmpty == true ? w!.fixedSalary : '—'));
    final bonusInc = staff.bonusIncentive ?? (raw['bonusIncentive']?.toString() ?? (w?.bonusIncentive.isNotEmpty == true ? w!.bonusIncentive : '0'));
    final currentCtc = staff.lastCtc ?? (raw['annualCtc']?.toString() ?? (w?.totalSalary.isNotEmpty == true ? w!.totalSalary : '—'));
    final expectedCtc = staff.expectedSalary ?? (raw['expectedSalary']?.toString() ?? (w?.expectedSalary.isNotEmpty == true ? w!.expectedSalary : 'Negotiable'));
    final noticePer = staff.noticePeriod ?? (raw['noticePeriod']?.toString() ?? (w?.noticePeriod.isNotEmpty == true ? w!.noticePeriod : 'Immediate'));
    final careerGapVal = staff.careerGapDetails ?? (raw['careerGap']?.toString() ?? (w?.careerGap.isNotEmpty == true ? w!.careerGap : 'None'));

    // Emergency fields
    final emName = staff.emergencyContact?.name ?? (raw['emergencyContact']?['name']?.toString() ?? 'Not recorded');
    final emRel = staff.emergencyContact?.relation ?? (raw['emergencyContact']?['relation']?.toString() ?? 'Not recorded');
    final emPhone = staff.emergencyContact?.phone ?? (raw['emergencyContact']?['phone']?.toString() ?? 'Not recorded');

    // Documents
    final relieving = staff.relievingLetterUrl ?? raw['relievingLetterUrl']?.toString();
    final kycVideo = staff.kycVideoUrl ?? raw['kycVideoUrl']?.toString();
    final hasVideo = kycVideo != null && kycVideo.isNotEmpty;

    return Column(
      children: [
        // Occupational & Work Experience
        _buildSectionCard(
          title: 'Occupational & Work Experience',
          subtitle: 'Employment status, compensation breakdown, management scope, and notice period.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Employment Status', isFresher ? 'Fresher' : 'Experienced ($expYears)'),
                _buildDataTile('Current / Previous Company', isFresher ? 'N/A (Fresher)' : currentCompany),
                _buildDataTile('Current Designation', isFresher ? 'N/A (Fresher)' : currentDesignation),
              ]),
              if (!isFresher) ...[
                const SizedBox(height: 14),
                _buildRow([
                  _buildDataTile('Reporting Manager', reportingManager != '—' ? '$reportingManager ($reportingManagerDesig)' : '—'),
                  _buildDataTile('Direct Reportees', directReportees),
                  _buildDataTile('Total Experience', expYears),
                ]),
                const SizedBox(height: 14),
                _buildRow([
                  _buildDataTile('Fixed Salary (Monthly)', fixedSal),
                  _buildDataTile('Bonus / Incentive', bonusInc),
                  _buildDataTile('Current Total CTC', currentCtc),
                ]),
                const SizedBox(height: 14),
                _buildRow([
                  _buildDataTile('Expected CTC', expectedCtc),
                  _buildDataTile('Notice Period', noticePer),
                  _buildDataTile('Career Gap Details', careerGapVal),
                ]),
              ] else ...[
                const SizedBox(height: 14),
                _buildRow([
                  _buildDataTile('Expected CTC', expectedCtc),
                  _buildDataTile('Notice Period', noticePer),
                  _buildDataTile('Direct Reportees', directReportees),
                ]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Relieving Letter / Experience Proof
        if (!isFresher || (relieving != null && relieving.isNotEmpty)) ...[
          _buildSectionCard(
            title: 'Experience / Relieving Documentation',
            subtitle: 'Relieving letter or experience certificate from last employer.',
            child: _buildDocRow(context, controller, 'Relieving Letter *', 'relieving', relieving, Icons.work_history_outlined),
          ),
          const SizedBox(height: 16),
        ],

        // Previous Employment Table (if available)
        if (w != null && w.employmentList.isNotEmpty) ...[
          _buildSectionCard(
            title: 'Previous Employment History',
            subtitle: 'Chronological timeline of past corporate positions, responsibilities, and departures.',
            child: _buildEmploymentTable(w.employmentList),
          ),
          const SizedBox(height: 16),
        ],

        // Emergency & Safety Contact
        _buildSectionCard(
          title: 'Emergency Contact Information',
          subtitle: 'Primary contact person to notify in case of personal or workplace emergencies.',
          child: _buildRow([
            _buildDataTile('Contact Name', emName),
            _buildDataTile('Relationship', emRel),
            _buildDataTile('Contact Mobile', emPhone),
          ]),
        ),
        const SizedBox(height: 16),

        // Live Video KYC Verification
        _buildSectionCard(
          title: 'Live Video KYC Verification',
          subtitle: 'Mandatory recorded device video KYC for identity and compliance audit.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: hasVideo ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hasVideo ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasVideo ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 18,
                      color: hasVideo ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasVideo
                            ? 'Video KYC Recording Verified and Stored on Cloud'
                            : 'Video KYC Pending • Candidate must record video verification before approval.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: hasVideo ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildDocRow(context, controller, 'Live KYC Verification Video', 'video', kycVideo, Icons.videocam_outlined, isVideo: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Digio Employment Agreement
        _buildAgreementSection(context, staff, controller),

        // Declarations if available
        if (w != null && (w.policeRecord || w.interviewedBefore || w.differentlyAbled || w.majorIllness)) ...[
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Compliance & Legal Declarations',
            subtitle: 'Mandatory statutory and organizational declarations.',
            child: Column(
              children: [
                if (w.interviewedBefore)
                  _buildDeclarationTile('Interviewed by company in last six months', w.interviewedBefore, w.interviewedBeforeDetails),
                if (w.policeRecord) ...[
                  const SizedBox(height: 10),
                  _buildDeclarationTile('Past police records or legal proceedings', w.policeRecord, w.policeRecordDetails),
                ],
                if (w.differentlyAbled) ...[
                  const SizedBox(height: 10),
                  _buildDeclarationTile('Differently abled candidate', w.differentlyAbled, w.differentlyAbledDetails),
                ],
                if (w.majorIllness) ...[
                  const SizedBox(height: 10),
                  _buildDeclarationTile('History of major illness or medical treatment', w.majorIllness, w.majorIllnessDetails),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocRow(
    BuildContext context,
    StaffDetailsController controller,
    String label,
    String type,
    String? fileUrl,
    IconData icon, {
    bool isVideo = false,
  }) {
    final hasFile = fileUrl != null && fileUrl.isNotEmpty;

    return Obx(() {
      final isUploading = controller.uploadingDocType.value == type;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: hasFile ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: hasFile ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    hasFile ? 'Uploaded and verified' : 'Not uploaded yet',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: hasFile ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (hasFile) ...[
              OutlinedButton.icon(
                onPressed: () {
                  final fullUrl = AppConfig.buildImageUrl(fileUrl);
                  final ext = isVideo ? '.mp4' : (fileUrl.toLowerCase().endsWith('.pdf') ? '.pdf' : '.png');
                  showDialog(
                    context: context,
                    builder: (ctx) => FilePreviewDialog(
                      fileName: '$label$ext',
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
              const SizedBox(width: 8),
            ],
            ElevatedButton.icon(
              onPressed: isUploading ? null : () => (isVideo ? controller.handleVideoKyc(context) : controller.uploadDoc(type)),
              icon: isUploading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    )
                  : Icon(isVideo ? (hasFile ? Icons.videocam : Icons.videocam_outlined) : (hasFile ? Icons.swap_horiz : Icons.file_upload_outlined), size: 13),
              label: Text(
                isUploading ? 'Uploading...' : (isVideo ? (hasFile ? 'Re-record' : 'Record / Upload') : (hasFile ? 'Replace' : 'Upload')),
                style: const TextStyle(fontSize: 11.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasFile ? const Color(0xFFF1F5F9) : AppTheme.primaryBlue,
                foregroundColor: hasFile ? const Color(0xFF334155) : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildEducationTable(List<EducationEntryModel> list) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Table(
          border: TableBorder.symmetric(inside: const BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.0),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.0),
            4: FlexColumnWidth(0.8),
            5: FlexColumnWidth(0.8),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _buildTableHeaderCell('Standard/Degree'),
                _buildTableHeaderCell('Institute/College'),
                _buildTableHeaderCell('Board/University'),
                _buildTableHeaderCell('Course Type'),
                _buildTableHeaderCell('Passing Year'),
                _buildTableHeaderCell('% / CGPA'),
              ],
            ),
            ...list.map((item) {
              return TableRow(
                children: [
                  _buildTableCell(item.degree.isNotEmpty ? item.degree : item.standard),
                  _buildTableCell(item.schoolCollege),
                  _buildTableCell(item.boardUniversity),
                  _buildTableCell(item.courseType),
                  _buildTableCell(item.passingYear),
                  _buildTableCell(item.percentage.isNotEmpty ? '${item.percentage}%' : '—'),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmploymentTable(List<EmploymentEntryModel> list) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Table(
          border: TableBorder.symmetric(inside: const BorderSide(color: Color(0xFFF1F5F9), width: 1)),
          columnWidths: const {
            0: FlexColumnWidth(1.3),
            1: FlexColumnWidth(2.0),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(2.0),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _buildTableHeaderCell('Duration'),
                _buildTableHeaderCell('Organisation'),
                _buildTableHeaderCell('Designation'),
                _buildTableHeaderCell('Reason for Leaving'),
              ],
            ),
            ...list.map((item) {
              return TableRow(
                children: [
                  _buildTableCell('${item.fromPeriod} - ${item.toPeriod}'),
                  _buildTableCell(item.organisation),
                  _buildTableCell(item.designation),
                  _buildTableCell(item.reasonForLeaving),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Text(
        text.isNotEmpty ? text : '—',
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildAgreementSection(BuildContext context, StaffModel staff, StaffDetailsController controller) {
    final status = staff.agreementStatus;
    final isVerified = status == 'VERIFIED';
    final isPendingVerification = status == 'PENDING_ADMIN_VERIFICATION';
    final isRejected = status == 'REJECTED';
    final isPendingSignature = status == 'PENDING_SIGNATURE';

    final agreementUrl = staff.serviceAgreementDocUrl?.isNotEmpty == true
        ? staff.serviceAgreementDocUrl!
        : AppConfig.buildApiUrl('/staff/agreement/document/${staff.id}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPendingVerification
              ? const Color(0xFFC084FC)
              : (isVerified ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
          width: isPendingVerification ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPendingVerification
                      ? const Color(0xFFFAF5FF)
                      : (isVerified ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPendingVerification
                        ? const Color(0xFFE9D5FF)
                        : (isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Icon(
                  isPendingVerification
                      ? Icons.assignment_late_outlined
                      : (isVerified ? Icons.verified_user_outlined : Icons.description_outlined),
                  size: 20,
                  color: isPendingVerification
                      ? const Color(0xFF9333EA)
                      : (isVerified ? const Color(0xFF16A34A) : const Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Employment Service Agreement',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildAgreementPill(status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Official legally-binding Digio e-sign workflow and administrative compliance verification.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Context Alert Banner based on status
          if (isPendingVerification) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF9333EA), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Staff Has Completed Digio E-Signature',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF581C87),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'The employee has signed their employment agreement. Please preview the signed document below and either verify it to grant full dashboard access or reject it with feedback.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF7E22CE), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else if (isVerified) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Agreement verified and active. The legally binding digital contract is on file.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF15803D)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else if (isRejected) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Agreement Rejected by Administrator',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
                      ),
                    ],
                  ),
                  if (staff.agreementRejectionReason?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text(
                        'Reason: "${staff.agreementRejectionReason}"',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFB91C1C)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else if (isPendingSignature) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.hourglass_top, color: Color(0xFFD97706), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Agreement dispatched via Digio. Awaiting candidate / employee electronic signature.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Action Toolbar
          Obx(() {
            final isVerifying = controller.isVerifying.value;
            final isRejecting = controller.isRejecting.value;
            final isInitiating = controller.isInitiatingAgreement.value;

            return Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Preview Button (always accessible if doc exists or signed)
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => FilePreviewDialog(
                        fileName: '${staff.name}_Employment_Agreement.pdf',
                        fileUrl: agreementUrl,
                      ),
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 15),
                  label: const Text('Preview Agreement PDF', style: TextStyle(fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),

                // If Pending Admin Verification -> Show Verify and Reject buttons
                if (isPendingVerification) ...[
                  ElevatedButton.icon(
                    onPressed: (isVerifying || isRejecting)
                        ? null
                        : () => controller.verifyAgreement(),
                    icon: isVerifying
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(
                      isVerifying ? 'Verifying...' : 'Verify & Approve Agreement',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (isVerifying || isRejecting)
                        ? null
                        : () => _showRejectModal(context, controller),
                    icon: isRejecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                          )
                        : const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Reject Agreement',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],

                // If Verified -> Admin can also Reject / Revoke agreement
                if (isVerified) ...[
                  OutlinedButton.icon(
                    onPressed: (isVerifying || isRejecting)
                        ? null
                        : () => _showRejectModal(context, controller),
                    icon: isRejecting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                          )
                        : const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Reject / Revoke Agreement',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],

                // If Not Initiated or Rejected or Pending Signature -> Allow Re-dispatching
                if (!isVerified && !isPendingVerification) ...[
                  ElevatedButton.icon(
                    onPressed: isInitiating ? null : () => controller.initiateAgreement(),
                    icon: isInitiating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 15),
                    label: Text(
                      isInitiating
                          ? 'Dispatching...'
                          : (isPendingSignature ? 'Resend Digio Signing Link' : 'Dispatch Digio Agreement'),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showRejectModal(BuildContext context, StaffDetailsController controller) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              'Reject Employment Agreement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please provide a clear reason for rejecting the agreement. The employee will receive this feedback and will be instructed to revise and re-sign.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'e.g., Aadhaar mismatch, salary terms need revision, signature illegible...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = textController.text.trim();
              if (reason.isEmpty) {
                Get.snackbar('Reason Required', 'Please enter a rejection reason.',
                    backgroundColor: Colors.orange.withValues(alpha: 0.1));
                return;
              }
              Navigator.of(ctx).pop();
              await controller.rejectAgreement(reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementPill(String? status) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    switch (status) {
      case 'VERIFIED':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF16A34A);
        icon = Icons.verified_user_rounded;
        label = 'Agreement Verified';
        break;
      case 'PENDING_ADMIN_VERIFICATION':
        bg = const Color(0xFFFAF5FF);
        border = const Color(0xFFE9D5FF);
        text = const Color(0xFF9333EA);
        icon = Icons.pending_actions_rounded;
        label = 'Agreement Needs Verification';
        break;
      case 'PENDING_SIGNATURE':
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFD97706);
        icon = Icons.draw_rounded;
        label = 'Awaiting Staff Signature';
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined;
        label = 'Agreement Rejected';
        break;
      default:
        bg = const Color(0xFFF8FAFC);
        border = const Color(0xFFE2E8F0);
        text = const Color(0xFF64748B);
        icon = Icons.article_outlined;
        label = 'Agreement Not Initiated';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
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

  Widget _buildRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((c) => Expanded(child: c)).toList(),
    );
  }

  Widget _buildDataTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '—',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
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
}
