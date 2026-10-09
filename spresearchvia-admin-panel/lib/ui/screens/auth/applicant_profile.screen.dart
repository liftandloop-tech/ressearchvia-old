import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_profile.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';
import '../../../config/app.config.dart';
import '../../../models/staff.model.dart';

class ApplicantProfileScreen extends StatelessWidget {
  const ApplicantProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantProfileController());

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

          final applicant = controller.applicant.value;
          if (applicant == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_search_outlined, size: 54, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 12),
                  const Text(
                    'Applicant record not found or link has expired.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, size: 15),
                    label: const Text('Back to Applicants Directory', style: TextStyle(fontSize: 13)),
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
                    _buildHeader(context, controller, applicant),
                    const SizedBox(height: 18),

                    // Minimal Hero Header Card
                    _buildHeroCard(context, applicant),
                    const SizedBox(height: 20),

                    // Sleek Segmented Tab Selector
                    _buildTabBar(controller),
                    const SizedBox(height: 20),

                    // Tab View Contents
                    Obx(() {
                      switch (controller.selectedTabIndex.value) {
                        case 0:
                          return _buildOverviewTab(applicant);
                        case 1:
                          return _buildWalkInTab(applicant);
                        case 2:
                          return _buildCareerTab(applicant);
                        case 3:
                          return _buildDocumentsTab(context, controller, applicant);
                        default:
                          return _buildOverviewTab(applicant);
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
  Widget _buildHeader(BuildContext context, ApplicantProfileController controller, StaffModel applicant) {
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final currentUser = authController?.user.value;
    final canApproveApplicant = currentUser?.isAdmin == true || (currentUser?.has('staff.approve_applicant') ?? false);

    final isApproved = applicant.stage == 'Employee' ||
        applicant.stage == 'OFFER_ACCEPTED' ||
        applicant.rawJson?['convertedToStaffId'] != null;
    final convertedId = applicant.rawJson?['convertedToStaffId'];

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
                  'Applicants Directory',
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
          applicant.name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlue,
          ),
        ),
        const Spacer(),
        if (isApproved && convertedId != null) ...[
          ElevatedButton.icon(
            onPressed: () => Get.toNamed('/staff/details/$convertedId'),
            icon: const Icon(Icons.badge_outlined, size: 15),
            label: const Text('View Employee Profile', style: TextStyle(fontSize: 12.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ] else if (canApproveApplicant) ...[
          ElevatedButton.icon(
            onPressed: () => _showApproveDialog(context, controller, applicant),
            icon: const Icon(Icons.how_to_reg_rounded, size: 16),
            label: const Text('Promote to Staff', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
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
  Widget _buildHeroCard(BuildContext context, StaffModel applicant) {
    final stage = applicant.stage.isNotEmpty ? applicant.stage : 'Applied';
    final w = applicant.walkInForm;

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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: ClipOval(
                  child: applicant.photoUrl != null && applicant.photoUrl!.isNotEmpty
                      ? Image.network(
                          AppConfig.buildImageUrl(applicant.photoUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(applicant.name),
                        )
                      : _buildAvatarFallback(applicant.name),
                ),
              ),
              const SizedBox(width: 14),
              // Name & Identity Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          applicant.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Stage Pill
                        _buildStagePill(stage),
                        if (applicant.staffId.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              applicant.staffId,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${applicant.role.isNotEmpty ? applicant.role : (w?.appliedPosition.isNotEmpty == true ? w!.appliedPosition : 'Applicant')} • ${applicant.email}',
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
              _buildMiniMetric(Icons.phone_outlined, 'Phone', applicant.mobile),
              _buildMiniMetric(Icons.event_outlined, 'Applied Date', (w?.applicationDate.isNotEmpty == true) ? w!.applicationDate : 'Recent'),
              _buildMiniMetric(Icons.timeline_outlined, 'Experience', applicant.experienceYears != null ? '${applicant.experienceYears} Years' : (w?.totalExperience.isNotEmpty == true ? w!.totalExperience : 'Fresher')),
              _buildMiniMetric(Icons.timer_outlined, 'Notice Period', (w?.noticePeriod.isNotEmpty == true) ? w!.noticePeriod : 'Immediate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join('').toUpperCase()
        : 'A';
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _buildStagePill(String stage) {
    Color bg;
    Color border;
    Color text;

    switch (stage.toUpperCase()) {
      case 'SELECTED':
      case 'OFFER_ACCEPTED':
      case 'EMPLOYEE':
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        text = const Color(0xFF16A34A);
        break;
      case 'INTERVIEW':
      case 'SHORTLISTED':
        bg = const Color(0xFFFAF5FF);
        border = const Color(0xFFE9D5FF);
        text = const Color(0xFF9333EA);
        break;
      case 'SCREENING':
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF2563EB);
        break;
      case 'REJECTED':
      case 'WITHDRAWN':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFECACA);
        text = const Color(0xFFDC2626);
        break;
      default:
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        text = const Color(0xFFD97706);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        stage,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  Widget _buildMiniMetric(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
        ),
        Text(
          value.isNotEmpty ? value : '—',
          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sleek Segmented Tab Selector
  // ---------------------------------------------------------------------------
  Widget _buildTabBar(ApplicantProfileController controller) {
    const tabs = ['Overview', 'Walk-In Form Details', 'Career & History', 'KYC & Compliance Media'];

    return Obx(() {
      final selected = controller.selectedTabIndex.value;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final isSelected = selected == idx;
            return Expanded(
              child: InkWell(
                onTap: () => controller.setTab(idx),
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: isSelected
                        ? const [BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    tabs[idx],
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
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
  // Tab 1: Overview
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(StaffModel applicant) {
    final w = applicant.walkInForm;

    return Column(
      children: [
        _buildSectionCard(
          title: 'Personal & Contact Information',
          subtitle: 'Candidate identity, personal background, and primary communication points.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Full Legal Name', applicant.name),
                _buildDataTile('Email Address', applicant.email),
                _buildDataTile('Mobile Phone', applicant.mobile),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('Date of Birth', applicant.dob ?? (w?.dob.isNotEmpty == true ? w!.dob : 'Not specified')),
                _buildDataTile('Gender', applicant.gender ?? (w?.gender.isNotEmpty == true ? w!.gender : 'Not specified')),
                _buildDataTile('Marital Status', (w?.maritalStatus.isNotEmpty == true) ? w!.maritalStatus : 'Not specified'),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('Native Place / Domicile', (w?.nativePlace.isNotEmpty == true) ? w!.nativePlace : 'Not specified'),
                _buildDataTile('Position Applied For', (w?.appliedPosition.isNotEmpty == true) ? w!.appliedPosition : (applicant.role.isNotEmpty ? applicant.role : 'General')),
                _buildDataTile('Total Experience', applicant.experienceYears != null ? '${applicant.experienceYears} Years' : (w?.totalExperience.isNotEmpty == true ? w!.totalExperience : 'Fresher')),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Emergency & Safety Contact',
          subtitle: 'Primary contact person to notify in case of personal or workplace emergencies.',
          child: _buildRow([
            _buildDataTile('Contact Name', applicant.emergencyContact?.name ?? 'Not recorded'),
            _buildDataTile('Relationship', applicant.emergencyContact?.relation ?? 'Not recorded'),
            _buildDataTile('Primary Mobile', applicant.emergencyContact?.phone ?? 'Not recorded'),
          ]),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Address Information',
          subtitle: 'Current residential address and permanent hometown domicile recorded on application.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Current / Local Address', applicant.localAddress ?? (w?.currentLocation.isNotEmpty == true ? w!.currentLocation : 'Not specified')),
                _buildDataTile('Permanent Address', applicant.permanentAddress ?? (w?.nativePlace.isNotEmpty == true ? w!.nativePlace : 'Same as current / Not specified')),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 2: Walk-In Form Details
  // ---------------------------------------------------------------------------
  Widget _buildWalkInTab(StaffModel applicant) {
    final w = applicant.walkInForm;

    return Column(
      children: [
        _buildSectionCard(
          title: 'Walk-In Screening & Pre-Employment Declarations',
          subtitle: 'Regulatory, integrity, and medical declarations submitted during registration.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Police Record / Inquiries?', (w?.policeRecord == true) ? 'YES (${w?.policeRecordDetails ?? "Unspecified"})' : 'NO'),
                _buildDataTile('Interviewed with Company Before?', (w?.interviewedBefore == true) ? 'YES (${w?.interviewedBeforeDetails ?? "Unspecified"})' : 'NO'),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('Serious Medical Illness or Ailment?', (w?.majorIllness == true) ? 'YES (${w?.majorIllnessDetails ?? "Unspecified"})' : 'NO'),
                _buildDataTile('Differently Abled?', (w?.differentlyAbled == true) ? 'YES (${w?.differentlyAbledDetails ?? "Unspecified"})' : 'NO'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Educational Qualifications',
          subtitle: 'Academic background, university degrees, and passing milestones.',
          child: (w != null && w.educationList.isNotEmpty)
              ? _buildEducationTable(w.educationList)
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No structured education qualifications provided.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Current Compensation & Reporting Structure',
          subtitle: 'Remuneration breakdown, team management scope, and joining timeline.',
          child: Column(
            children: [
              _buildRow([
                _buildDataTile('Fixed Salary (INR)', (w?.fixedSalary.isNotEmpty == true) ? w!.fixedSalary : 'Not stated'),
                _buildDataTile('Bonus / Incentives (INR)', (w?.bonusIncentive.isNotEmpty == true) ? w!.bonusIncentive : '0'),
                _buildDataTile('Total Current CTC', applicant.lastCtc ?? (w?.totalSalary.isNotEmpty == true ? w!.totalSalary : 'Not stated')),
              ]),
              const SizedBox(height: 14),
              _buildRow([
                _buildDataTile('Expected CTC (INR)', (w?.expectedSalary.isNotEmpty == true) ? w!.expectedSalary : 'Negotiable'),
                _buildDataTile('Direct Reportees', (w?.reporteesCount.isNotEmpty == true) ? w!.reporteesCount : '0 (Individual Contributor)'),
                _buildDataTile('Notice Period', (w?.noticePeriod.isNotEmpty == true) ? w!.noticePeriod : 'Immediate'),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Career & History
  // ---------------------------------------------------------------------------
  Widget _buildCareerTab(StaffModel applicant) {
    final w = applicant.walkInForm;

    return Column(
      children: [
        _buildSectionCard(
          title: 'Previous Employment History',
          subtitle: 'Chronological timeline of past corporate positions, responsibilities, and departures.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (w != null && w.employmentList.isNotEmpty)
                _buildEmploymentTable(w.employmentList)
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No previous employment history recorded.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ),
              const SizedBox(height: 16),
              _buildDataTile('Career Gap Details', (w?.careerGap.isNotEmpty == true) ? w!.careerGap : 'No career gaps specified'),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 4: KYC & Compliance Media
  // ---------------------------------------------------------------------------
  Widget _buildDocumentsTab(BuildContext context, ApplicantProfileController controller, StaffModel applicant) {
    return _buildSectionCard(
      title: 'Uploaded Compliance & Verification Media',
      subtitle: 'Mandatory KYC documentation, identity proofs, and education verification files.',
      child: Column(
        children: [
          _buildDocRow(context, controller, 'Resume / CV', 'resume', applicant.resumeUrl, Icons.description_outlined),
          const SizedBox(height: 10),
          _buildDocRow(context, controller, 'PAN Card', 'pan', applicant.panUrl, Icons.credit_card_outlined),
          const SizedBox(height: 10),
          _buildDocRow(context, controller, 'Aadhaar Card', 'aadhaar', applicant.aadhaarUrl, Icons.badge_outlined),
          const SizedBox(height: 10),
          _buildDocRow(context, controller, 'NISM Certification', 'nism', applicant.nismUrl, Icons.verified_user_outlined),
          const SizedBox(height: 10),
          _buildDocRow(context, controller, 'Highest Education Degree', 'education', applicant.highestEducationUrl, Icons.school_outlined),
          const SizedBox(height: 10),
          _buildDocRow(context, controller, 'KYC Verification Video', 'video', applicant.kycVideoUrl, Icons.videocam_outlined, isVideo: true),
        ],
      ),
    );
  }

  Widget _buildDocRow(
    BuildContext context,
    ApplicantProfileController controller,
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

  // ---------------------------------------------------------------------------
  // Reusable Micro-Components
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
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
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

  // ---------------------------------------------------------------------------
  // Approval / Promotion Dialog
  // ---------------------------------------------------------------------------
  void _showApproveDialog(BuildContext context, ApplicantProfileController controller, StaffModel applicant) {
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final currentUser = authController?.user.value;
    final canApproveApplicant = currentUser?.isAdmin == true || (currentUser?.has('staff.approve_applicant') ?? false);
    if (!canApproveApplicant) return;

    controller.resetApproveForm();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Promote ${applicant.name} to Staff',
                        style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Role Selector
                  Obx(() => DropdownButtonFormField<String>(
                        initialValue: controller.selectedRoleId.value,
                        decoration: InputDecoration(
                          labelText: 'Select Role *',
                          border: const OutlineInputBorder(),
                          errorText: controller.roleError.value.isNotEmpty ? controller.roleError.value : null,
                        ),
                        hint: const Text('Select Role'),
                        items: controller.availableRoles
                            .map((r) => DropdownMenuItem(
                                  value: r.id,
                                  child: Text(
                                    r.departmentName != null && r.departmentName!.isNotEmpty
                                        ? '${r.name} (${r.departmentName})'
                                        : r.name,
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) controller.updateRole(val);
                        },
                      )),
                  Obx(() {
                    final dept = controller.selectedDepartment.value;
                    if (dept.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4),
                      child: Text(
                        'Department: $dept (Auto-assigned)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  // Reporting To (Supervisor) Selector
                  Obx(() => DropdownButtonFormField<String>(
                        initialValue: controller.selectedSupervisorId.value,
                        decoration: InputDecoration(
                          labelText: 'Reporting To (Supervisor) *',
                          border: const OutlineInputBorder(),
                          errorText: controller.supervisorError.value.isNotEmpty ? controller.supervisorError.value : null,
                        ),
                        hint: const Text('Select Reporting Supervisor'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'admin',
                            child: Text('Direct to Admin'),
                          ),
                          ...controller.availableSupervisors.map((s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(
                                  s.department.isNotEmpty
                                      ? '${s.name} (${s.department})'
                                      : s.name,
                                ),
                              )),
                        ],
                        onChanged: (val) => controller.updateSupervisor(val),
                      )),
                  const SizedBox(height: 16),
                  // MPIN Input
                  Obx(() => TextField(
                        controller: controller.mpinController,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          if (controller.mpinError.value.isNotEmpty) {
                            controller.mpinError.value = '';
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Set Employee MPIN *',
                          hintText: 'Enter 4-digit numeric code',
                          border: const OutlineInputBorder(),
                          counterText: '',
                          errorText: controller.mpinError.value.isNotEmpty ? controller.mpinError.value : null,
                        ),
                      )),
                  const SizedBox(height: 16),
                  // Joining Date
                  TextField(
                    controller: controller.joiningDateController,
                    decoration: const InputDecoration(labelText: 'Joining Date', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      Obx(() => Button(
                            title: controller.isApproving.value ? 'Approving...' : 'Approve & Create Staff',
                            buttonType: ButtonType.green,
                            onTap: controller.isApproving.value
                                ? null
                                : () async {
                                    final success = await controller.approveApplicant();
                                    if (success) {
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext, rootNavigator: true).pop();
                                      }
                                      Get.snackbar(
                                        'Candidate Hired',
                                        '${applicant.name} has been promoted to Staff and agreement initiated.',
                                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                                      );
                                    }
                                  },
                          )),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
