import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicants_list.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/skeleton_loader.widget.dart';
import '../../../config/app.config.dart';
import '../../../models/staff.model.dart';
import '../../../controllers/auth/auth.controller.dart';
import 'widgets/applicant_column_filter.widget.dart';

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

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 8,
                    minWidth: 1050,
                    dataRowHeight: 54,
                    headingRowHeight: 44,
                    columns: [
                      DataColumn2(
                        size: ColumnSize.L,
                        label: const ApplicantTableHeaderCell(
                          text: 'Candidate',
                          filterWidget: ApplicantColumnFilter(columnKey: 'candidate', columnName: 'Candidate'),
                        ),
                      ),
                      DataColumn2(
                        size: ColumnSize.L,
                        label: const ApplicantTableHeaderCell(
                          text: 'Applied Role',
                          filterWidget: ApplicantColumnFilter(columnKey: 'role', columnName: 'Applied Role'),
                        ),
                      ),
                      DataColumn2(
                        size: ColumnSize.L,
                        label: const ApplicantTableHeaderCell(
                          text: 'Contact Details',
                          filterWidget: ApplicantColumnFilter(columnKey: 'contact', columnName: 'Contact Details'),
                        ),
                      ),
                      DataColumn2(
                        fixedWidth: 125,
                        label: const ApplicantTableHeaderCell(
                          text: 'Status',
                          filterWidget: ApplicantColumnFilter(columnKey: 'status', columnName: 'Status'),
                        ),
                      ),
                      DataColumn2(
                        fixedWidth: 140,
                        label: const ApplicantTableHeaderCell(
                          text: 'Pipeline Stage',
                          filterWidget: ApplicantColumnFilter(columnKey: 'stage', columnName: 'Pipeline Stage'),
                        ),
                      ),
                      DataColumn2(
                        fixedWidth: 175,
                        label: const ApplicantTableHeaderCell(
                          text: 'Assigned Staff',
                          filterWidget: ApplicantColumnFilter(columnKey: 'staff', columnName: 'Assigned Staff'),
                        ),
                      ),
                      const DataColumn2(
                        fixedWidth: 125,
                        label: Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
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
                                      radius: 16,
                                    )
                                  else
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      radius: 16,
                                      child: Text(
                                        (applicant.name.isNotEmpty && applicant.name != '—' && applicant.name.toLowerCase() != 'candidate')
                                            ? applicant.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: (applicant.name.isNotEmpty &&
                                            applicant.name != '—' &&
                                            applicant.name.toLowerCase() != 'candidate')
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                applicant.name,
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 1),
                                              const Text(
                                                'Candidate',
                                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          )
                                        : const Text(
                                            'Candidate',
                                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF64748B)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                ],
                              ),
                            ),

                            // Role
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (() {
                                      if (applicant.role.isNotEmpty && applicant.role.toLowerCase() != 'staff' && applicant.role.toLowerCase() != 'applicant') {
                                        return applicant.role;
                                      }
                                      final rawTarget = raw['targetRole']?.toString() ??
                                          raw['walkInForm']?['appliedPosition']?.toString() ??
                                          raw['walkInForm']?['positionApplied']?.toString() ??
                                          raw['appliedPosition']?.toString();
                                      if (rawTarget != null && rawTarget.trim().isNotEmpty && rawTarget.toLowerCase() != 'staff' && rawTarget.toLowerCase() != 'applicant') {
                                        return rawTarget.trim();
                                      }
                                      if (applicant.currentDesignation?.isNotEmpty == true && applicant.currentDesignation!.toLowerCase() != 'staff') {
                                        return applicant.currentDesignation!;
                                      }
                                      return 'Business Development executive';
                                    })(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    (() {
                                      if (applicant.department.isNotEmpty && applicant.department.toLowerCase() != 'staff') {
                                        return applicant.department;
                                      }
                                      final rawDept = raw['targetDepartment']?.toString() ??
                                          raw['department']?.toString() ??
                                          raw['walkInForm']?['department']?.toString();
                                      if (rawDept != null && rawDept.trim().isNotEmpty && rawDept.toLowerCase() != 'staff') {
                                        return rawDept.trim();
                                      }
                                      return 'Sales';
                                    })(),
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Contact
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.mail_outline_rounded, size: 12, color: Color(0xFF10B981)),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          applicant.email.isNotEmpty ? applicant.email : '',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.smartphone_rounded, size: 12, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 5),
                                      Text(
                                        (applicant.mobile.isNotEmpty && applicant.mobile != '—')
                                            ? applicant.mobile
                                            : '',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Application Form Status badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: formStatusBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: formStatusBorder, width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(formStatusIcon, size: 12, color: formStatusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      formStatusText,
                                      style: TextStyle(
                                        fontSize: 11,
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: stageBg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  stageDisplay,
                                  style: TextStyle(
                                    color: stageColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
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
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                        ? const Color(0xFFEEF2FF)
                                        : const Color(0xFFFAFAFA),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                          ? const Color(0xFFC7D2FE)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                            ? Icons.person
                                            : Icons.person_add_alt_1_outlined,
                                        size: 12,
                                        color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                            ? const Color(0xFF4338CA)
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                              ? applicant.assignedStaffName!
                                              : 'Assign Staff',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: (applicant.assignedStaffName != null && applicant.assignedStaffName!.isNotEmpty)
                                                ? const Color(0xFF4338CA)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
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
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: Color(0xFF2563EB)),
                                    onPressed: () => Get.toNamed('/applicant/${applicant.id}'),
                                    splashRadius: 16,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                  if (!isPromoted && !isRejected) ...[
                                    if (canPromote) ...[
                                      const SizedBox(width: 6),
                                      IconButton(
                                        tooltip: 'Promote to Staff',
                                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 18, color: Color(0xFF16A34A)),
                                        onPressed: () => _showQuickPromoteDialog(context, controller, applicant),
                                        splashRadius: 16,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                    if (canReject) ...[
                                      const SizedBox(width: 6),
                                      IconButton(
                                        tooltip: 'Reject Application',
                                        icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFDC2626)),
                                        onPressed: () => _showQuickRejectDialog(context, controller, applicant),
                                        splashRadius: 16,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ],
                                  if (canDelete) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      tooltip: 'Delete Applicant',
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                      onPressed: () => _showDeleteConfirmDialog(context, controller, applicant),
                                      splashRadius: 16,
                                      padding: const EdgeInsets.all(4),
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
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuickPromoteDialog(BuildContext context, ApplicantsListController controller, StaffModel applicant) {
    bool autoSendOfferLetter = true;
    final defaultRole = applicant.role.isNotEmpty && applicant.role != 'Applicant'
        ? applicant.role
        : (applicant.targetRole?.isNotEmpty == true
            ? applicant.targetRole!
            : (applicant.currentDesignation?.isNotEmpty == true
                ? applicant.currentDesignation!
                : 'Business Development Executive'));

    final defaultJoinDt = applicant.joiningDate ?? DateTime.now().add(const Duration(days: 7));
    final defaultJoinStr = '${defaultJoinDt.day.toString().padLeft(2, '0')}/${defaultJoinDt.month.toString().padLeft(2, '0')}/${defaultJoinDt.year}';

    final roleCtrl = TextEditingController(text: defaultRole);
    final joinDateCtrl = TextEditingController(text: defaultJoinStr);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Icon(Icons.how_to_reg_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Promote ${applicant.name} to Staff',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promote this candidate to an active employee account. Role hierarchy, reporting supervisor, and MPIN can also be updated from the Staff page.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Offer Letter Delivery Card (Automatic vs Manual)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: autoSendOfferLetter ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: autoSendOfferLetter ? const Color(0xFFA5B4FC) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setDialogState(() {
                              autoSendOfferLetter = !autoSendOfferLetter;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            children: [
                              Checkbox(
                                value: autoSendOfferLetter,
                                activeColor: const Color(0xFF4F46E5),
                                onChanged: (v) {
                                  setDialogState(() {
                                    autoSendOfferLetter = v ?? false;
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Automatic: Email Official Offer Letter on Promotion',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 40, right: 8, bottom: 4),
                          child: Text(
                            autoSendOfferLetter
                                ? 'Generates the official SP Researchvia letterhead PDF and emails it to ${applicant.email.isNotEmpty ? applicant.email : "candidate"} upon promotion.'
                                : 'Manual Option: Staff will be promoted without an email. You can preview and send the offer letter manually anytime from the Staff or Applicant page.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: autoSendOfferLetter ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (autoSendOfferLetter) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Offer Designation *',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: roleCtrl,
                                  style: const TextStyle(fontSize: 12.5),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Joining Date (DD/MM/YYYY) *',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: joinDateCtrl,
                                  style: const TextStyle(fontSize: 12.5),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_month_outlined, size: 16),
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        final parts = joinDateCtrl.text.split('/');
                                        DateTime initial = DateTime.now();
                                        if (parts.length == 3) {
                                          try {
                                            initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                                          } catch (_) {}
                                        }
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: (initial.year >= 2000 && initial.year <= 2100) ? initial : DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          joinDateCtrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
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
                await controller.promoteApplicant(
                  applicant.id,
                  autoSendOfferLetter: autoSendOfferLetter,
                  offerDesignation: roleCtrl.text.trim(),
                  offerJoiningDate: joinDateCtrl.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(autoSendOfferLetter ? 'Promote & Send Letter' : 'Promote Staff Only'),
            ),
          ],
        ),
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
