import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/staff/staff_details.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';
import '../../../config/app.config.dart';
import '../../../models/staff.model.dart';

class StaffDetailsScreen extends StatelessWidget {
  const StaffDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StaffDetailsController());

    return DashboardLayout(
      child: Container(
        color: AppTheme.gray50,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final staff = controller.staff.value;
          if (staff == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Staff member not found.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation / Header Row
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Staff Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/staff/edit/${staff.id}'),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit Staff'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Content Cards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Profile Card & Personal Info
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Profile Header Card
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.gray200),
                            ),
                            child: Row(
                              children: [
                                if (staff.photoUrl != null && staff.photoUrl!.isNotEmpty)
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(AppConfig.buildImageUrl(staff.photoUrl)),
                                    radius: 40,
                                  )
                                else
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                                    child: Icon(Icons.person, size: 40, color: AppTheme.primaryBlue),
                                  ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        staff.name,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Staff ID: ${staff.staffId}',
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          staff.department.isNotEmpty ? staff.department : staff.role,
                                          style: TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (staff.status == 'Active')
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: staff.status == 'Active' ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        staff.status,
                                        style: TextStyle(
                                          color: staff.status == 'Active' ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Personal & Professional Details Card
                          Container(
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
                                  'Personal & Contact Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                const Divider(height: 24),
                                Wrap(
                                  runSpacing: 16,
                                  spacing: 32,
                                  children: [
                                    _buildDetailItem('Mobile Number', staff.mobile, icon: Icons.phone),
                                    _buildDetailItem('Email Address', staff.email, icon: Icons.email),
                                    _buildDetailItem('Department / Role', staff.department.isNotEmpty ? staff.department : staff.role, icon: Icons.work),
                                    _buildDetailItem('Joining Date', staff.joiningDate != null ? "${staff.joiningDate!.day}/${staff.joiningDate!.month}/${staff.joiningDate!.year}" : 'N/A', icon: Icons.calendar_today),
                                    _buildDetailItem('Gender', staff.gender ?? 'N/A', icon: Icons.person_outline),
                                    _buildDetailItem('Date of Birth', staff.dob ?? 'N/A', icon: Icons.cake),
                                    _buildDetailItem('Experience', staff.experienceYears != null ? '${staff.experienceYears} Years' : 'N/A', icon: Icons.badge),
                                    _buildDetailItem('Previous Company', staff.previousCompany ?? 'N/A', icon: Icons.business),
                                    _buildDetailItem('Last CTC', staff.lastCtc != null ? '₹${staff.lastCtc}' : 'N/A', icon: Icons.currency_rupee),
                                    _buildDetailItem('Assigned Director', staff.assignedDirectorName ?? 'Unassigned', icon: Icons.supervisor_account),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Emergency Contact Card
                          if (staff.emergencyContact != null)
                            Container(
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
                                    'Emergency Contact',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  Wrap(
                                    runSpacing: 16,
                                    spacing: 32,
                                    children: [
                                      _buildDetailItem('Name', staff.emergencyContact!.name ?? 'N/A', icon: Icons.person),
                                      _buildDetailItem('Relation', staff.emergencyContact!.relation ?? 'N/A', icon: Icons.family_restroom),
                                      _buildDetailItem('Phone', staff.emergencyContact!.phone ?? 'N/A', icon: Icons.phone_forwarded),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Side: Verification Files & Documents
                    Expanded(
                      flex: 2,
                      child: Container(
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
                              'Uploaded Verification Documents',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const Divider(height: 24),
                            _buildDocumentTile(context, 'Resume', staff.resumeUrl, Icons.description),
                            _buildDocumentTile(context, 'PAN Card', staff.panUrl, Icons.credit_card),
                            _buildDocumentTile(context, 'Aadhaar Card', staff.aadhaarUrl, Icons.badge),
                            _buildDocumentTile(context, 'NISM Certificate', staff.nismUrl, Icons.verified_user),
                            _buildDocumentTile(context, 'Highest Education', staff.highestEducationUrl, Icons.school),
                            _buildDocumentTile(context, 'KYC Verification Video', staff.kycVideoUrl, Icons.video_library, isVideo: true),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, {IconData? icon}) {
    return SizedBox(
      width: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, String title, String? url, IconData icon, {bool isVideo = false}) {
    final bool hasFile = url != null && url.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasFile ? AppTheme.gray50 : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasFile ? AppTheme.gray200 : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: hasFile ? AppTheme.primaryBlue : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: hasFile ? AppTheme.textPrimary : Colors.grey,
                  ),
                ),
                Text(
                  hasFile ? (isVideo ? 'Video Uploaded' : 'Document Uploaded') : 'Not Uploaded',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasFile ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (hasFile)
            TextButton.icon(
              onPressed: () {
                final fullUrl = AppConfig.buildImageUrl(url);
                final ext = isVideo ? '.mp4' : (url.toLowerCase().endsWith('.pdf') ? '.pdf' : '.png');
                showDialog(
                  context: context,
                  builder: (context) => FilePreviewDialog(
                    fileName: '$title$ext',
                    fileUrl: fullUrl,
                  ),
                );
              },
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View'),
            ),
        ],
      ),
    );
  }
}
