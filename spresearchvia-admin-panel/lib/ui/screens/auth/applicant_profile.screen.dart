import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
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

    return SelectionArea(
      child: Scaffold(
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
        final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
        final currentUser = authController?.user.value;
        final canApproveApplicant = currentUser?.isAdmin == true || (currentUser?.has('staff.approve_applicant') ?? false);

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
                          _buildDocumentRow(context, controller, 'PAN Card', 'pan', applicant.panUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow(context, controller, 'Aadhaar Card', 'aadhaar', applicant.aadhaarUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow(context, controller, 'NISM Certificate', 'nism', applicant.nismUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow(context, controller, 'Highest Education', 'education', applicant.highestEducationUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow(context, controller, 'Resume / CV', 'resume', applicant.resumeUrl),
                          const SizedBox(height: 12),
                          _buildDocumentRow(context, controller, 'Verification Video', 'video', applicant.kycVideoUrl),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!isApproved) ...[
                      if (canApproveApplicant)
                        Button(
                          title: 'Approve & Promote to Employee',
                          buttonType: ButtonType.green,
                          onTap: () => _showApproveDialog(context, controller, applicant),
                        ),
                    ] else
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
      ),
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

  Widget _buildDocumentRow(
    BuildContext context,
    ApplicantProfileController controller,
    String label,
    String type,
    String? url,
  ) {
    final hasDoc = url != null && url.isNotEmpty;
    final isVideo = type == 'video';

    return Obx(() {
      final isUploading = controller.uploadingDocType.value == type;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: hasDoc ? const Color(0xFFF8FAFC) : Colors.white,
          border: Border.all(color: hasDoc ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: hasDoc ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hasDoc ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
              ),
              child: Icon(
                isVideo ? Icons.videocam_outlined : Icons.description_outlined,
                size: 16,
                color: hasDoc ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasDoc ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: hasDoc ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasDoc) ...[
                              const Icon(Icons.check_circle, size: 10, color: Color(0xFF059669)),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              hasDoc ? 'Uploaded' : 'Pending',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: hasDoc ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasDoc) ...[
                    const SizedBox(height: 2),
                    Text(
                      url.split('/').last,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (hasDoc) ...[
              OutlinedButton.icon(
                onPressed: () {
                  final fullUrl = AppConfig.buildImageUrl(url);
                  showDialog(
                    context: context,
                    builder: (ctx) => FilePreviewDialog(
                      fileName: url.split('/').last,
                      fileUrl: fullUrl,
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 13),
                label: const Text('Preview', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
            ],
            ElevatedButton.icon(
              onPressed: isUploading ? null : () => controller.uploadDoc(type),
              icon: isUploading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    )
                  : Icon(hasDoc ? Icons.swap_horiz : Icons.file_upload_outlined, size: 13),
              label: Text(
                isUploading ? 'Uploading...' : (hasDoc ? 'Replace' : 'Upload'),
                style: const TextStyle(fontSize: 11.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasDoc ? const Color(0xFFF1F5F9) : const Color(0xFF1E3A5F),
                foregroundColor: hasDoc ? const Color(0xFF334155) : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    });
  }

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
            width: 460,
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
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
                            title: controller.isApproving.value ? 'Approving...' : 'Approve',
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
                                        'Success',
                                        '${applicant.name} approved and promoted to Staff member',
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
