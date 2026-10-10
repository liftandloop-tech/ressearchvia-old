import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicants_list.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/skeleton_loader.widget.dart';
import '../../../config/app.config.dart';
import '../../../models/staff.model.dart';

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
                Column(
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
                const Spacer(),
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
                if (controller.isLoading.value && controller.applicants.isEmpty) {
                  return const TableSkeleton(rowCount: 8, columnCount: 7);
                }
                if (controller.applicants.isEmpty) {
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
                            'No applicants found in this stage.',
                            style: TextStyle(color: Color(0xFF334155), fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try selecting another stage or clearing your search filter.',
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
                      minWidth: 920,
                      columns: const [
                        DataColumn2(label: Text('Candidate'), size: ColumnSize.L),
                        DataColumn2(label: Text('Applied Role')),
                        DataColumn2(label: Text('Contact Details')),
                        DataColumn2(label: Text('Verification')),
                        DataColumn2(label: Text('Pipeline Stage')),
                        DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                      ],
                      rows: controller.applicants.map((applicant) {
                        final contactsVerified = applicant.isEmailVerified && applicant.isMobileVerified;
                        final stage = applicant.stage.toUpperCase();
                        final isPromoted = stage == 'PROMOTED' ||
                            stage == 'OFFER_ACCEPTED' ||
                            stage == 'EMPLOYEE' ||
                            applicant.rawJson?['convertedToStaffId'] != null ||
                            applicant.rawJson?['convertedStaffId'] != null;
                        final isRejected = stage == 'REJECTED';

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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    applicant.role.isNotEmpty ? applicant.role : 'General Applicant',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                                  ),
                                  if (applicant.department.isNotEmpty)
                                    Text(
                                      applicant.department,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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

                            // Verification status
                            DataCell(
                              Row(
                                children: [
                                  Icon(
                                    applicant.isEmailVerified ? Icons.email : Icons.mail_outline,
                                    size: 16,
                                    color: applicant.isEmailVerified ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    applicant.isMobileVerified ? Icons.phone_android : Icons.phone_android_outlined,
                                    size: 16,
                                    color: applicant.isMobileVerified ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    contactsVerified ? 'Verified' : 'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: contactsVerified ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
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

                            // Actions
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'View Profile',
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 19, color: Color(0xFF2563EB)),
                                    onPressed: () => Get.toNamed('/applicant/${applicant.id}'),
                                  ),
                                  if (!isPromoted && !isRejected) ...[
                                    IconButton(
                                      tooltip: 'Promote to Staff',
                                      icon: const Icon(Icons.how_to_reg_rounded, size: 19, color: Color(0xFF16A34A)),
                                      onPressed: () => _showQuickPromoteDialog(context, controller, applicant),
                                    ),
                                    IconButton(
                                      tooltip: 'Reject Application',
                                      icon: const Icon(Icons.cancel_outlined, size: 19, color: Color(0xFFDC2626)),
                                      onPressed: () => _showQuickRejectDialog(context, controller, applicant),
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
}
