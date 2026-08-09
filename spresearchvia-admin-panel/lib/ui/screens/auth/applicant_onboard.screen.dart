import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_profile.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import '../../../config/app.config.dart';

class ApplicantOnboardScreen extends StatelessWidget {
  const ApplicantOnboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantProfileController());

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
          child: Container(
            width: 750,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.gray200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(40),
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final applicant = controller.applicant.value;
              if (applicant == null) {
                return const Center(
                  child: Text(
                    'Application profile not found or link has expired.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                );
              }

              final contactsVerified = applicant.isEmailVerified && applicant.isMobileVerified;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  Row(
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
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
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
                          color: (applicant.onboardingStatus == 'VERIFIED' ? Colors.green : Colors.amber).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          applicant.onboardingStatus,
                          style: TextStyle(
                            color: applicant.onboardingStatus == 'VERIFIED' ? Colors.green : Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // Contact Verification Block
                  if (!contactsVerified) ...[
                    const Text(
                      'Verify Your Contact Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enter the verification codes sent to your registered phone and email.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.mobileOtpController,
                            decoration: const InputDecoration(labelText: 'Mobile OTP *', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: controller.emailOtpController,
                            decoration: const InputDecoration(labelText: 'Email OTP *', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Button(
                      title: 'Verify Details',
                      buttonType: ButtonType.blue,
                      onTap: () => controller.verifyOtps(),
                    ),
                    const Divider(height: 48),
                  ],

                  // Documents Upload Stepper
                  const Text(
                    'Onboarding Document Checklist',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    contactsVerified
                        ? 'Upload required files to complete your registration.'
                        : 'Verify email & mobile numbers above to unlock document uploads.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  _buildUploadRow(context, 'Profile Photo', 'photo', applicant.photoUrl, contactsVerified, controller),
                  const SizedBox(height: 12),
                  _buildUploadRow(context, 'Resume / CV', 'resume', applicant.resumeUrl, contactsVerified, controller),
                  const SizedBox(height: 12),
                  _buildUploadRow(context, 'PAN Card', 'pan', applicant.panUrl, contactsVerified, controller),
                  const SizedBox(height: 12),
                  _buildUploadRow(context, 'Aadhaar Card', 'aadhaar', applicant.aadhaarUrl, contactsVerified, controller),
                  const SizedBox(height: 12),
                  _buildUploadRow(context, 'NISM Certificate', 'nism', applicant.nismUrl, contactsVerified, controller),
                  const SizedBox(height: 12),
                  _buildUploadRow(context, 'Highest Education Certificate', 'education', applicant.highestEducationUrl, contactsVerified, controller),
                  const SizedBox(height: 12),
                  _buildUploadRow(context, 'KYC Verification Video', 'video', applicant.kycVideoUrl, contactsVerified, controller),

                  if (applicant.onboardingStatus == 'VERIFIED') ...[
                    const SizedBox(height: 32),
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
                              'Thank you! Your documents are successfully uploaded. Our HR team will review your application and assign your credentials shortly.',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          )
                        ],
                      ),
                    ),
                  ]
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadRow(BuildContext context, String title, String type, String? fileUrl, bool verified, ApplicantProfileController controller) {
    final hasFile = fileUrl != null && fileUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFDEE2E6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            type == 'video' ? Icons.video_library : Icons.description,
            color: hasFile ? Colors.green : const Color(0xFF6C757D),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (hasFile)
                  Text(
                    'Uploaded: $fileUrl',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  const Text(
                    'Pending upload',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: verified ? () => controller.uploadDoc(type) : null,
            icon: const Icon(Icons.upload, size: 14),
            label: Text(hasFile ? 'Re-upload' : 'Upload'),
            style: ElevatedButton.styleFrom(elevation: 0),
          )
        ],
      ),
    );
  }
}
