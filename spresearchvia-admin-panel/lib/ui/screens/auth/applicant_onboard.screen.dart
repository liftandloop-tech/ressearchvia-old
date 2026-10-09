import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_profile.controller.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';
import '../../../config/app.config.dart';

class ApplicantOnboardScreen extends StatelessWidget {
  const ApplicantOnboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantProfileController());

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 20 : 60,
                horizontal: isMobile ? 10 : 16,
              ),
              child: Container(
                width: 750,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                  border: Border.all(color: AppTheme.gray200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 40,
                  vertical: isMobile ? 24 : 40,
                ),
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Header
                      isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (applicant.photoUrl != null)
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(AppConfig.buildImageUrl(applicant.photoUrl)),
                                        radius: 30,
                                      )
                                    else
                                      const CircleAvatar(
                                        radius: 30,
                                        child: Icon(Icons.person, size: 28),
                                      ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            applicant.name,
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Applicant ID: ${(applicant.applicantId != null && applicant.applicantId!.isNotEmpty) ? applicant.applicantId! : applicant.staffId}',
                                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (applicant.onboardingStatus == 'VERIFIED' ? Colors.green : Colors.amber).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
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
                              ],
                            )
                          : Row(
                              children: [
                                if (applicant.photoUrl != null)
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(AppConfig.buildImageUrl(applicant.photoUrl)),
                                    radius: 36,
                                  )
                                else
                                  const CircleAvatar(
                                    radius: 36,
                                    child: Icon(Icons.person, size: 32),
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
                                        'Applicant ID: ${(applicant.applicantId != null && applicant.applicantId!.isNotEmpty) ? applicant.applicantId! : applicant.staffId}',
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
                      const Divider(height: 36),

                      // Documents Upload Stepper
                      Text(
                        'Onboarding Document Checklist',
                        style: TextStyle(fontSize: isMobile ? 15 : 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Upload required files to complete your registration.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: isMobile ? 12 : 13),
                      ),
                      const SizedBox(height: 20),

                      _buildUploadRow(context, 'Profile Photo', 'photo', applicant.photoUrl, controller, isMobile: isMobile),
                      const SizedBox(height: 12),
                      _buildUploadRow(context, 'Resume / CV', 'resume', applicant.resumeUrl, controller, isMobile: isMobile),
                      const SizedBox(height: 12),
                      _buildUploadRow(context, 'PAN Card', 'pan', applicant.panUrl, controller, isMobile: isMobile),
                      const SizedBox(height: 12),
                      _buildUploadRow(context, 'Aadhaar Card', 'aadhaar', applicant.aadhaarUrl, controller, isMobile: isMobile),
                      const SizedBox(height: 12),
                      _buildUploadRow(context, 'NISM Certificate', 'nism', applicant.nismUrl, controller, isMobile: isMobile),
                      const SizedBox(height: 12),
                      _buildUploadRow(context, 'Highest Education Certificate', 'education', applicant.highestEducationUrl, controller, isMobile: isMobile),
                      const SizedBox(height: 12),
                      _buildUploadRow(context, 'KYC Verification Video', 'video', applicant.kycVideoUrl, controller, isMobile: isMobile),

                      if (applicant.onboardingStatus == 'VERIFIED') ...[
                        const SizedBox(height: 28),
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
          );
        },
      ),
    );
  }

  Widget _buildUploadRow(
    BuildContext context,
    String title,
    String type,
    String? fileUrl,
    ApplicantProfileController controller, {
    bool isMobile = false,
  }) {
    final hasFile = fileUrl != null && fileUrl.isNotEmpty;
    final isVideo = type == 'video';
    final isUploading = controller.uploadingDocType.value == type;
    final cleanFileName = hasFile ? fileUrl.split('/').last : '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasFile ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(color: hasFile ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasFile ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: hasFile ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(
                        isVideo ? Icons.videocam_outlined : Icons.description_outlined,
                        color: hasFile ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasFile ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: hasFile ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasFile) ...[
                                      const Icon(Icons.check_circle, size: 11, color: Color(0xFF059669)),
                                      const SizedBox(width: 3),
                                    ],
                                    Text(
                                      hasFile ? 'Uploaded' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: hasFile ? const Color(0xFF059669) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasFile ? cleanFileName : (isVideo ? 'Supports MP4, MOV' : 'Supports PDF, JPG, PNG'),
                            style: TextStyle(fontSize: 11, color: hasFile ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (hasFile) ...[
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
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: const Text('Preview', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: !isUploading ? () => (isVideo ? controller.handleVideoKyc(context) : controller.uploadDoc(type)) : null,
                      icon: isUploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                            )
                          : Icon(isVideo ? (hasFile ? Icons.videocam : Icons.videocam_outlined) : (hasFile ? Icons.swap_horiz : Icons.file_upload_outlined), size: 14),
                      label: Text(isUploading ? 'Uploading...' : (isVideo ? (hasFile ? 'Re-record / Replace' : 'Record / Upload') : (hasFile ? 'Replace' : 'Upload')), style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasFile ? const Color(0xFFF1F5F9) : const Color(0xFF1E3A5F),
                        foregroundColor: hasFile ? const Color(0xFF334155) : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: hasFile ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: hasFile ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam_outlined : Icons.description_outlined,
                    color: hasFile ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasFile ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: hasFile ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasFile) ...[
                                  const Icon(Icons.check_circle, size: 11, color: Color(0xFF059669)),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  hasFile ? 'Uploaded' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: hasFile ? const Color(0xFF059669) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasFile ? cleanFileName : (isVideo ? 'Supports MP4, MOV, AVI' : 'Supports PDF, JPG, PNG'),
                        style: TextStyle(fontSize: 11.5, color: hasFile ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                          fileName: '$title$ext',
                          fileUrl: fullUrl,
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Preview', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: !isUploading ? () => (isVideo ? controller.handleVideoKyc(context) : controller.uploadDoc(type)) : null,
                  icon: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                        )
                      : Icon(isVideo ? (hasFile ? Icons.videocam : Icons.videocam_outlined) : (hasFile ? Icons.swap_horiz : Icons.file_upload_outlined), size: 14),
                  label: Text(isUploading ? 'Uploading...' : (isVideo ? (hasFile ? 'Re-record / Replace' : 'Record / Upload') : (hasFile ? 'Replace' : 'Upload')), style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasFile ? const Color(0xFFF1F5F9) : const Color(0xFF1E3A5F),
                    foregroundColor: hasFile ? const Color(0xFF334155) : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                )
              ],
            ),
    );
  }
}
