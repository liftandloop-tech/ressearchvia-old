import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicants_list.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/skeleton_loader.widget.dart';
import '../../../config/app.config.dart';

class ApplicantsListScreen extends StatelessWidget {
  const ApplicantsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ApplicantsListController>()
        ? Get.find<ApplicantsListController>()
        : Get.put(ApplicantsListController(), permanent: true);

    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Pending Job Applicants',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => controller.fetchApplicants(),
                  icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
                  tooltip: 'Refresh Applicants',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Table of Applicants
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.applicants.isEmpty) {
                  return const TableSkeleton(rowCount: 8, columnCount: 7);
                }
                if (controller.applicants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 56, color: AppTheme.gray400),
                        const SizedBox(height: 12),
                        Text(
                          'No pending applicants at this time.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppTheme.gray200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      minWidth: 800,
                      columns: const [
                        DataColumn2(label: Text('Applicant Name'), size: ColumnSize.L),
                        DataColumn2(label: Text('Email')),
                        DataColumn2(label: Text('Mobile')),
                        DataColumn2(label: Text('Contacts Verified')),
                        DataColumn2(label: Text('Onboarding Stage')),
                        DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                      ],
                      rows: controller.applicants.map((applicant) {
                        final contactsVerified = applicant.isEmailVerified && applicant.isMobileVerified;

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  if (applicant.photoUrl != null)
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(AppConfig.buildImageUrl(applicant.photoUrl)),
                                      radius: 16,
                                    )
                                  else
                                    const CircleAvatar(
                                      child: Icon(Icons.person, size: 16),
                                      radius: 16,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(applicant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            DataCell(Text(applicant.email)),
                            DataCell(Text(applicant.mobile)),
                            DataCell(
                              Icon(
                                contactsVerified ? Icons.verified : Icons.pending_actions,
                                color: contactsVerified ? Colors.green : Colors.amber,
                                size: 20,
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (applicant.onboardingStatus == 'VERIFIED' ? Colors.green : Colors.amber).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  applicant.onboardingStatus,
                                  style: TextStyle(
                                    color: applicant.onboardingStatus == 'VERIFIED' ? Colors.green : Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                             DataCell(
                               IconButton(
                                 icon: Icon(Icons.remove_red_eye, color: AppTheme.primaryBlue),
                                 onPressed: () => Get.toNamed('/applicant/${applicant.id}'),
                               ),
                             ),
                           ],
                         );
                       }).toList(),
                     ),
                   ),
                 );
               }),
             )
           ],
         ),
       ),
     );
    }
}

