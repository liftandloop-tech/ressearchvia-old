import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicants_list.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app.config.dart';

class ApplicantsListScreen extends StatelessWidget {
  const ApplicantsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantsListController());

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
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.applicants.isEmpty) {
                  return Center(
                    child: Text(
                      'No pending applicants at this time.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
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

  Widget _buildDocItem(String label, String? url) {
    final hasDoc = url != null && url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          if (hasDoc)
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(AppConfig.buildImageUrl(url))),
              icon: const Icon(Icons.download, size: 14),
              label: const Text('View File'),
            )
          else
            const Text('Not Uploaded', style: TextStyle(color: Colors.red, fontSize: 13)),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, ApplicantsListController controller, StaffModel applicant) {
    controller.mpinController.clear();
    controller.joiningDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    controller.selectedDepartment.value = '';
    controller.isViewOnly.value = false;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Approve & Setup ${applicant.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Department selection
              Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedDepartment.value.isEmpty ? null : controller.selectedDepartment.value,
                  hint: const Text('Select Role'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: controller.availableDepartments
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (val) => controller.selectedDepartment.value = val ?? '',
                ),
              ),
              const SizedBox(height: 16),
              // MPIN setting
              TextField(
                controller: controller.mpinController,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Set Employee MPIN *',
                  hintText: 'Enter 4-digit numeric code',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              // Joining Date
              TextField(
                controller: controller.joiningDateController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    controller.joiningDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Joining Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),
              // View Only toggle
              Row(
                children: [
                  const Text('View Only Access'),
                  const Spacer(),
                  Obx(() => Switch(
                        value: controller.isViewOnly.value,
                        onChanged: (val) => controller.isViewOnly.value = val,
                      ))
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  Button(
                    title: 'Approve',
                    buttonType: ButtonType.green,
                    onTap: () => controller.approveApplicant(applicant.id),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
