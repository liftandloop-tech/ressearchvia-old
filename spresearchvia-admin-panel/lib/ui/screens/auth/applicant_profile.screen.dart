import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_profile.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';
import '../../../config/app.config.dart';
import '../../../models/staff.model.dart';

class ApplicantProfileScreen extends StatelessWidget {
  const ApplicantProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantProfileController());

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A5F)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Applicant Profile Details',
          style: TextStyle(color: Color(0xFF1E3A5F), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final applicant = controller.applicant.value;
        if (applicant == null) {
          return const Center(
            child: Text(
              'Applicant profile not found or link has expired.',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }

        final isApproved = applicant.stage == 'Employee';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Applicant Details
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gray200),
                      ),
                      child: Row(
                        children: [
                          if (applicant.photoUrl != null)
                            CircleAvatar(
                              backgroundImage: NetworkImage(AppConfig.buildImageUrl(applicant.photoUrl)),
                              radius: 36,
                            )
                          else
                            const CircleAvatar(
                              child: Icon(Icons.person, size: 32),
                              radius: 36,
                            ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  applicant.name,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Applicant ID: ${applicant.staffId}',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isApproved ? Colors.green : Colors.amber).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isApproved ? 'Approved Employee' : applicant.onboardingStatus,
                              style: TextStyle(
                                color: isApproved ? Colors.green : Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Personal & Job Details Section
                    _buildDetailsSection(
                      '1. Personal Information',
                      [
                        _buildInfoRow('Email Address', applicant.email),
                        _buildInfoRow('Mobile Number', applicant.mobile),
                        _buildInfoRow('Date of Birth', applicant.dob ?? 'Not Provided'),
                        _buildInfoRow('Gender', applicant.gender ?? 'Not Provided'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildDetailsSection(
                      '2. Professional Details',
                      [
                        _buildInfoRow('Years of Experience', '${applicant.experienceYears ?? 0} Years'),
                        _buildInfoRow('Previous Employer', applicant.previousCompany ?? 'Not Provided'),
                        _buildInfoRow('Last Drawn CTC', applicant.lastCtc ?? 'Not Provided'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildDetailsSection(
                      '3. Address details',
                      [
                        _buildInfoRow('Local Address', applicant.localAddress ?? 'Not Provided'),
                        _buildInfoRow('Permanent Address', applicant.permanentAddress ?? 'Not Provided'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildDetailsSection(
                      '4. Emergency Contact details',
                      [
                        _buildInfoRow('Contact Name', applicant.emergencyContact?.name ?? 'Not Provided'),
                        _buildInfoRow('Relation', applicant.emergencyContact?.relation ?? 'Not Provided'),
                        _buildInfoRow('Phone Number', applicant.emergencyContact?.phone ?? 'Not Provided'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // Right Column: Documents and Verification Action
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.gray200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Uploaded Documents',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                          ),
                          const SizedBox(height: 20),
                          _buildDocumentRow('PAN Card', applicant.panUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow('Aadhaar Card', applicant.aadhaarUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow('NISM Certificate', applicant.nismUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow('Highest Education', applicant.highestEducationUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow('Resume / CV', applicant.resumeUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow('Verification Video', applicant.kycVideoUrl),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!isApproved)
                      Button(
                        title: 'Approve & Promote to Employee',
                        buttonType: ButtonType.green,
                        onTap: () => _showApproveDialog(context, controller, applicant),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This candidate has already been approved and promoted to an active Employee.',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDetailsSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
          ),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF212529), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, String? url) {
    final hasDoc = url != null && url.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFDEE2E6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (hasDoc)
            TextButton.icon(
              onPressed: () {
                Get.dialog(
                  FilePreviewDialog(
                    fileName: url.split('/').last,
                    fileUrl: url,
                  ),
                );
              },
              icon: const Icon(Icons.visibility, size: 14),
              label: const Text('View File', style: TextStyle(fontSize: 12)),
            )
          else
            const Text(
              'Not Uploaded',
              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, ApplicantProfileController controller, StaffModel applicant) {
    controller.mpinController.clear();
    controller.selectedDepartment.value = '';
    controller.isViewOnly.value = false;
    controller.joiningDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Promote ${applicant.name} to Staff',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
              ),
              const SizedBox(height: 20),
              // Department Selector
              Obx(() => DropdownButtonFormField<String>(
                    value: controller.selectedDepartment.value.isEmpty ? null : controller.selectedDepartment.value,
                    decoration: const InputDecoration(labelText: 'Select Department *', border: OutlineInputBorder()),
                    items: ['Manager', 'Research Analyst', 'Advisory', 'Compliance', 'Sales', 'Support', 'Admin']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) => controller.selectedDepartment.value = val ?? '',
                  )),
              const SizedBox(height: 16),
              // MPIN Input
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
                decoration: const InputDecoration(labelText: 'Joining Date', border: OutlineInputBorder()),
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
                    onTap: () async {
                      final success = await controller.approveApplicant();
                      if (success) {
                        Get.back();
                      }
                    },
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
