import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicants_list.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/skeleton_loader.widget.dart';
import '../../widgets/offer_letter_dialog.widget.dart';
import '../../../config/app.config.dart';
import '../../../models/staff.model.dart';
import '../../../controllers/auth/auth.controller.dart';

class ApplicantsListScreen extends StatelessWidget {
  const ApplicantsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ApplicantsListController>()
        ? Get.find<ApplicantsListController>()
        : Get.put(ApplicantsListController(), permanent: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchApplicants();
    });

    final authUser = Get.isRegistered<AuthController>() ? Get.find<AuthController>().user.value : null;
    final canDelete = authUser?.isAdmin == true || (authUser?.canDeleteApplicant ?? false);
    final canAssign = authUser?.isAdmin == true ||
        (authUser?.has('recruitment.assign') ?? false) ||
        (authUser?.has('staff.assignment') ?? false);
    final canPromote = authUser?.isAdmin == true ||
        (authUser?.has('recruitment.promote') ?? false) ||
        (authUser?.has('staff.approve_applicant') ?? false);
    final canReject = authUser?.isAdmin == true ||
        (authUser?.has('recruitment.reject') ?? false);

    return DashboardLayout(
      child: Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recruitment & Job Applicants',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Candidate talent pipeline, screening stages, and walk-in application tracking.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => controller.fetchApplicants(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Controls Bar: Stage Filter Tabs & Search
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Stage Filters
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Obx(() {
                        return Row(
                          children: controller.stageFilters.map((stage) {
                            final isSelected = controller.selectedStage.value == stage['key'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(stage['label']!),
                                selected: isSelected,
                                onSelected: (_) => controller.setStageFilter(stage['key']!),
                                selectedColor: AppTheme.primaryBlue,
                                labelStyle: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                                backgroundColor: const Color(0xFFF1F5F9),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Staff Filter Dropdown
                  Obx(() {
                    final supervisors = controller.availableSupervisors;
                    return Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.selectedStaffFilter.value ?? 'ALL',
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                          onChanged: (val) {
                            controller.selectedStaffFilter.value = val;
                          },
                          items: [
                            const DropdownMenuItem(
                              value: 'ALL',
                              child: Text('All Assigned Staff'),
                            ),
                            const DropdownMenuItem(
                              value: 'UNASSIGNED',
                              child: Text('Unassigned Only'),
                            ),
                            ...supervisors.map((s) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name.isNotEmpty ? s.name : s.email),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 12),

                  // Search Box
                  SizedBox(
                    width: 240,
                    height: 38,
                    child: TextField(
                      onChanged: (val) => controller.searchQuery.value = val,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search candidate...',
                        hintStyle: TextStyle(fontSize: 12.5, color: AppTheme.gray400),
                        prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.gray400),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Table Card
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.filteredApplicants.isEmpty) {
                  return const TableSkeleton(rowCount: 8, columnCount: 7);
                }
                if (controller.filteredApplicants.isEmpty) {
                  return Center(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 54, color: AppTheme.gray400),
                          const SizedBox(height: 12),
                          const Text(
                            'No applicants found.',
                            style: TextStyle(color: Color(0xFF334155), fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try selecting another stage, staff filter, or clearing your search.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DataTable2(
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      minWidth: 1220,
                      dataRowHeight: 68,
                      headingRowHeight: 46,
                      columns: const [
                        DataColumn2(label: Text('Candidate'), size: ColumnSize.L, fixedWidth: 210),
                        DataColumn2(label: Text('Applied Role'), size: ColumnSize.L, fixedWidth: 230),
                        DataColumn2(label: Text('Contact Details'), size: ColumnSize.M, fixedWidth: 200),
                        DataColumn2(label: Text('Status'), fixedWidth: 125),
                        DataColumn2(label: Text('Pipeline Stage'), fixedWidth: 120),
                        DataColumn2(label: Text('Assigned Staff'), size: ColumnSize.M, fixedWidth: 180),
                        DataColumn2(label: Text('Actions'), fixedWidth: 175),
                      ],
                      rows: controller.filteredApplicants.map((applicant) {
                        final raw = applicant.rawJson ?? {};
                        final stage = applicant.stage.toUpperCase();
                        final isPromoted = stage == 'PROMOTED' ||
                            stage == 'OFFER_ACCEPTED' ||
                            stage == 'EMPLOYEE' ||
                            applicant.rawJson?['convertedToStaffId'] != null ||
                            applicant.rawJson?['convertedStaffId'] != null;
                        final isRejected = stage == 'REJECTED';

                        // Calculate Application Form Status: Not Started, Pending, Submitted
                        final isDraft = raw['isDraft'] == true;
                        final currentStep = raw['currentStep'] is int
                            ? raw['currentStep'] as int
                            : (int.tryParse(raw['currentStep']?.toString() ?? '1') ?? 1);

                        final hasFilledStep1 = currentStep >= 2 ||
                            (raw['firstName'] != null && raw['firstName'].toString().trim().isNotEmpty) ||
                            (raw['fatherName'] != null && raw['fatherName'].toString().trim().isNotEmpty) ||
                            (raw['currentLocation'] != null && raw['currentLocation'].toString().trim().isNotEmpty) ||
                            (applicant.name.trim().isNotEmpty &&
                                applicant.name.trim().toLowerCase() != 'candidate' &&
                                applicant.name.trim() != '—');

                        final isFormSubmitted = !isDraft ||
                            raw['isVerified'] == true ||
                            applicant.onboardingStatus == 'COMPLETED' ||
                            applicant.onboardingStatus == 'VERIFIED' ||
                            applicant.onboardingStatus == 'DOCUMENTS_UPLOADED' ||
                            applicant.onboardingStatus == 'SUBMITTED' ||
                            isPromoted ||
                            (stage != 'APPLIED' && stage != 'SCREENING');

                        String formStatusText;
                        Color formStatusBg;
                        Color formStatusBorder;
                        Color formStatusColor;
                        IconData formStatusIcon;

                        if (isFormSubmitted && hasFilledStep1) {
                          formStatusText = 'Submitted';
                          formStatusBg = const Color(0xFFF0FDF4);
                          formStatusBorder = const Color(0xFFBBF7D0);
                          formStatusColor = const Color(0xFF16A34A);
                          formStatusIcon = Icons.check_circle_outline_rounded;
                        } else if (hasFilledStep1) {
                          formStatusText = 'Pending';
                          formStatusBg = const Color(0xFFFFFBEB);
                          formStatusBorder = const Color(0xFFFDE68A);
                          formStatusColor = const Color(0xFFD97706);
                          formStatusIcon = Icons.hourglass_top_rounded;
                        } else {
                          formStatusText = 'Not Started';
                          formStatusBg = const Color(0xFFF1F5F9);
                          formStatusBorder = const Color(0xFFCBD5E1);
                          formStatusColor = const Color(0xFF64748B);
                          formStatusIcon = Icons.radio_button_unchecked_rounded;
                        }

                        Color stageBg = const Color(0xFFEFF6FF);
                        Color stageColor = const Color(0xFF2563EB);
                        String stageDisplay = applicant.stage;

                        if (stage == 'APPLIED') {
                          stageBg = const Color(0xFFEFF6FF);
                          stageColor = const Color(0xFF2563EB);
                          stageDisplay = 'Applied';
                        } else if (stage == 'SCREENING') {
                          stageBg = const Color(0xFFFFFBEB);
                          stageColor = const Color(0xFFD97706);
                          stageDisplay = 'Screening';
                        } else if (stage == 'SHORTLISTED') {
                          stageBg = const Color(0xFFFAF5FF);
                          stageColor = const Color(0xFF9333EA);
                          stageDisplay = 'Shortlisted';
                        } else if (stage == 'INTERVIEW') {
                          stageBg = const Color(0xFFFAF5FF);
                          stageColor = const Color(0xFF7C3AED);
                          stageDisplay = 'Interview';
                        } else if (stage == 'SELECTED') {
                          stageBg = const Color(0xFFF0FDFA);
                          stageColor = const Color(0xFF0D9488);
                          stageDisplay = 'Selected';
                        } else if (stage == 'OFFER_SENT') {
                          stageBg = const Color(0xFFFEF3C7);
                          stageColor = const Color(0xFFB45309);
                          stageDisplay = 'Offer Sent';
                        } else if (stage == 'PROMOTED' || isPromoted) {
                          stageBg = const Color(0xFFF0FDF4);
                          stageColor = const Color(0xFF16A34A);
                          stageDisplay = 'Promoted';
                        } else if (stage == 'REJECTED') {
                          stageBg = const Color(0xFFFEF2F2);
                          stageColor = const Color(0xFFDC2626);
                          stageDisplay = 'Rejected';
                        }

                        return DataRow(
                          cells: [
                            // Candidate Column
                            DataCell(
                              Row(
                                children: [
                                  if (applicant.photoUrl != null && applicant.photoUrl!.isNotEmpty)
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(AppConfig.buildImageUrl(applicant.photoUrl)),
                                      radius: 18,
                                    )
                                  else
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      radius: 18,
                                      child: Text(
                                        applicant.name.isNotEmpty ? applicant.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          applicant.name,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F172A)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          applicant.staffId.isNotEmpty ? applicant.staffId : 'Candidate',
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Role
                            DataCell(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      (() {
                                        if (applicant.role.isNotEmpty && applicant.role.toLowerCase() != 'staff') {
                                          return applicant.role;
                                        }
                                        final rawTarget = raw['targetRole']?.toString() ??
                                            raw['walkInForm']?['appliedPosition']?.toString() ??
                                            raw['walkInForm']?['positionApplied']?.toString() ??
                                            raw['appliedPosition']?.toString();
                                        if (rawTarget != null && rawTarget.trim().isNotEmpty && rawTarget.toLowerCase() != 'staff') {
                                          return rawTarget.trim();
                                        }
                                        return '—';
                                      })(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                        height: 1.25,
                                      ),
                                    ),
                                    if (applicant.department.isNotEmpty || (raw['targetDepartment'] != null && raw['targetDepartment'].toString().trim().isNotEmpty)) ...[
                                      const SizedBox(height: 3),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                                        ),
                                        child: Text(
                                          applicant.department.isNotEmpty
                                              ? applicant.department
                                              : raw['targetDepartment'].toString().trim(),
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF64748B),
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Contact
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    applicant.email,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    applicant.mobile,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),

                            // Application Form Status badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: formStatusBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: formStatusBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(formStatusIcon, size: 13, color: formStatusColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      formStatusText,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: formStatusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Pipeline Stage badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stageBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: stageColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  stageDisplay,
                                  style: TextStyle(
                                    color: stageColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ),

                            // Assigned Staff
                            DataCell(
                              InkWell(
                                onTap: canAssign ? () => _showAssignStaffDialog(context, controller, applicant) : null,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                          ? const Color(0xFFC7D2FE)
                                          : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                            ? Icons.person_rounded
                                            : Icons.person_add_alt_1_outlined,
                                        size: 13,
                                        color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                            ? const Color(0xFF4338CA)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                              ? applicant.assignedStaffName!
                                              : 'Assign Staff',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                                ? const Color(0xFF4338CA)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: 14,
                                        color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                            ? const Color(0xFF4338CA)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Actions
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'View Profile',
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 19, color: Color(0xFF2563EB)),
                                    onPressed: () => Get.toNamed('/applicant/${applicant.id}'),
                                    splashRadius: 18,
                                    padding: const EdgeInsets.all(5),
                                    constraints: const BoxConstraints(),
                                  ),
                                  if (!isPromoted && !isRejected) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      tooltip: 'Offer Letter (Preview & Send)',
                                      icon: const Icon(Icons.mark_email_read_outlined, size: 19, color: Color(0xFF4F46E5)),
                                      onPressed: () => OfferLetterDialog.show(
                                        context,
                                        applicant: applicant,
                                        onSuccess: () => controller.fetchApplicants(),
                                      ),
                                      splashRadius: 18,
                                      padding: const EdgeInsets.all(5),
                                      constraints: const BoxConstraints(),
                                    ),
                                    if (canPromote) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        tooltip: 'Promote to Staff',
                                        icon: const Icon(Icons.how_to_reg_rounded, size: 19, color: Color(0xFF16A34A)),
                                        onPressed: () => _showQuickPromoteDialog(context, controller, applicant),
                                        splashRadius: 18,
                                        padding: const EdgeInsets.all(5),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                    if (canReject) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        tooltip: 'Reject Application',
                                        icon: const Icon(Icons.cancel_outlined, size: 19, color: Color(0xFFEA580C)),
                                        onPressed: () => _showQuickRejectDialog(context, controller, applicant),
                                        splashRadius: 18,
                                        padding: const EdgeInsets.all(5),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ],
                                  if (canDelete) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      tooltip: 'Delete Applicant',
                                      icon: const Icon(Icons.delete_outline_rounded, size: 19, color: Color(0xFFDC2626)),
                                      onPressed: () => _showDeleteConfirmDialog(context, controller, applicant),
                                      splashRadius: 18,
                                      padding: const EdgeInsets.all(5),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickPromoteDialog(BuildContext context, ApplicantsListController controller, StaffModel applicant) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Promote ${applicant.name} to Staff'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to promote this candidate to active Staff member?\n\nRole, Reporting Authority (Supervisor), and Employee MPIN can be configured anytime from the Staff page.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await controller.promoteApplicant(applicant.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Promote'),
          ),
        ],
      ),
    );
  }

  void _showQuickRejectDialog(BuildContext context, ApplicantsListController controller, StaffModel applicant) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Reject ${applicant.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to reject this applicant?',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.of(dialogCtx).pop();
              await controller.rejectApplicant(applicant.id, reason: reason.isNotEmpty ? reason : null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  void _showAssignStaffDialog(BuildContext context, ApplicantsListController controller, StaffModel applicant) {
    String? selectedStaffId = applicant.assignedStaffId ?? applicant.assignedRecruiterId;
    final initialStaff = controller.availableSupervisors.firstWhereOrNull((s) => s.id == selectedStaffId);
    if (initialStaff == null) {
      selectedStaffId = null;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final supervisors = controller.availableSupervisors;
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assign Applicant to Staff',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          applicant.name.isNotEmpty && applicant.name != '—' ? applicant.name : applicant.email,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
                      'Select a team member to assign this candidate for review, interviewing, or onboarding.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedStaffId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Assigned Staff Member',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      hint: const Text('Select staff member'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('— Unassigned —', style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                        ...supervisors.map((s) {
                          final roleText = s.role.isNotEmpty ? ' (${s.role})' : '';
                          return DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(
                              '${s.name.isNotEmpty ? s.name : s.email}$roleText',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5),
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedStaffId = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    String? staffName;
                    if (selectedStaffId != null) {
                      final chosen = supervisors.firstWhereOrNull((s) => s.id == selectedStaffId);
                      staffName = chosen?.name.isNotEmpty == true ? chosen!.name : chosen?.email;
                    }
                    await controller.assignApplicant(
                      applicant.id,
                      staffId: selectedStaffId,
                      staffName: staffName,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Assignment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ApplicantsListController controller, StaffModel applicant) {
    final confirmController = TextEditingController();
    bool isConfirmed = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isMatch = confirmController.text.trim().toUpperCase() == 'DELETE' || isConfirmed;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Confirm Deletion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to permanently delete this applicant record?',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applicant.name.isNotEmpty && applicant.name != '—' ? applicant.name : 'Candidate',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        if (applicant.email.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              applicant.email,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'To confirm, please type "DELETE" below:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    decoration: InputDecoration(
                      hintText: 'Type DELETE to confirm',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                    ),
                    onChanged: (_) {
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        isConfirmed = !isConfirmed;
                        if (isConfirmed && confirmController.text.trim().toUpperCase() != 'DELETE') {
                          confirmController.text = 'DELETE';
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isConfirmed || confirmController.text.trim().toUpperCase() == 'DELETE',
                          activeColor: const Color(0xFFDC2626),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) {
                            setDialogState(() {
                              isConfirmed = val == true;
                              if (isConfirmed && confirmController.text.trim().toUpperCase() != 'DELETE') {
                                confirmController.text = 'DELETE';
                              }
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'I confirm permanent deletion of this applicant and all submitted data.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isMatch
                    ? () async {
                        Navigator.of(dialogCtx).pop();
                        await controller.deleteApplicant(applicant.id);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Delete Permanently'),
              ),
            ],
          );
        },
      ),
    );
  }
}
