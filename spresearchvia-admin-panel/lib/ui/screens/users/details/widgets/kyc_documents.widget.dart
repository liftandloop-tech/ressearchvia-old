import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/controllers/users/user_details.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:spresearch_web/ui/widgets/video_player.widget.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';
import 'kyc_doc_placeholder.widget.dart';

class KYCDocuments extends StatelessWidget {
  final UserDetailsController controller;

  const KYCDocuments({super.key, required this.controller});

  String? _buildUrl(String? filename, String type) {
    if (filename == null || filename.isEmpty) return null;
    if (filename.startsWith('http')) return filename;

    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');

    // Handle legacy data where full path is stored (e.g., "app/uploads/kycimg/file.png")
    if (filename.startsWith('app/uploads/')) {
      // Remove 'app/' prefix and prepend base URL
      // "app/uploads/kycimg/file.png" -> "http://localhost:8080/uploads/kycimg/file.png"
      return '$baseUrl/${filename.substring(4)}';
    }

    // Handle new data where only filename is stored (e.g., "file.png")
    // type: 'kycimg' or 'kycvid'

    // Special handling for video: use streaming endpoint
    if (type == 'kycvid') {
      return '${AppConfig.apiBaseUrl}/user/kyc/stream-video/$filename';
    }

    // Special handling for image: use image serving endpoint
    if (type == 'kycimg') {
      return '${AppConfig.apiBaseUrl}/user/kyc/image/$filename';
    }

    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$cleanBaseUrl/uploads/$type/$filename';
  }

  Widget _buildGateDropdown({
    required String title,
    required String? status,
    required String? rejectionReason,
    required Function(String) onChanged,
  }) {
    final currentStatus = status?.toUpperCase() ?? 'PENDING';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$title Gate Status",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      [
                        'PENDING',
                        'VERIFIED',
                        'REJECTED',
                      ].contains(currentStatus)
                      ? currentStatus
                      : 'PENDING',
                  icon: (Get.find<AuthController>().user.value?.hasPermission('KYC', 'update') ?? false)
                      ? Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade600,
                        )
                      : const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: 'PENDING',
                      child: Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'VERIFIED',
                      child: Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'REJECTED',
                      child: Text(
                        'Rejected',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (Get.find<AuthController>().user.value?.hasPermission('KYC', 'update') ?? false)
                      ? (val) {
                          if (val != null && val != currentStatus)
                            onChanged(val);
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
        if (currentStatus == 'REJECTED' && rejectionReason != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Reason: $rejectionReason",
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final authController = Get.find<AuthController>();
      final isDirector = authController.user.value?.isDirector == true;
      final userDetails = controller.userDetails.value;
      if (userDetails == null || userDetails.id.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final aadhaarFrontUrl = _buildUrl(
        userDetails.kycDocs?.aadhaarFront,
        'kycimg',
      );
      final aadhaarBackUrl = _buildUrl(
        userDetails.kycDocs?.aadhaarBack,
        'kycimg',
      );
      final panUrl = _buildUrl(userDetails.kycDocs?.panImage, 'kycimg');
      final videoUrl = _buildUrl(
        userDetails.kycDocs?.video ?? userDetails.kycVideo,
        'kycvid',
      );

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Color(0xFF0F172A),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "KYC Documents",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (userDetails.kycStatus ?? '').toLowerCase() ==
                            'verified'
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (userDetails.effectiveKycStatus ?? 'PENDING').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          (userDetails.effectiveKycStatus ?? '').toLowerCase() ==
                              'verified'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Aadhaar Card",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (userDetails.aadhaarNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "Aadhaar: ${userDetails.aadhaarNumber}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      KycDocPlaceholder(
                        label: "Front Side",
                        imageUrl: aadhaarFrontUrl,
                      ),
                      if (authController.user.value?.hasPermission('KYC', 'update') ?? false)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  controller.updateDocument('aadhaarFront'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Stack(
                    children: [
                      KycDocPlaceholder(
                        label: "Back Side",
                        imageUrl: aadhaarBackUrl,
                      ),
                      if (authController.user.value?.hasPermission('KYC', 'update') ?? false)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  controller.updateDocument('aadhaarBack'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "PAN Card",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (userDetails.userObject?.appPanNo != null &&
                userDetails.userObject!.appPanNo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "PAN: ${userDetails.userObject!.appPanNo}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            SizedBox(
              width: (MediaQuery.of(context).size.width - 96) / 2,
              child: Stack(
                children: [
                  KycDocPlaceholder(label: "PAN Card", imageUrl: panUrl),
                  if (authController.user.value?.hasPermission('KYC', 'update') ?? false)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.8),
                        radius: 16,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.blue,
                          ),
                          onPressed: () => controller.updateDocument('pan'),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _buildGateDropdown(
              title: "Documents",
              status: userDetails.kycDocStatus,
              rejectionReason: userDetails.kycDocRejectionReason,
              onChanged: (val) => controller.updateDocumentGateStatus(val),
            ),

            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Video KYC",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (authController.user.value?.hasPermission('KYC', 'update') ?? false)
                  TextButton.icon(
                    onPressed: () => controller.updateDocument('video'),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Update Video"),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (videoUrl != null)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: VideoPlayerWidget(videoUrl: videoUrl),
                ),
              )
            else
              const Text(
                "No Video KYC uploaded",
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 16),
            _buildGateDropdown(
              title: "Video KYC",
              status: userDetails.kycVideoStatus,
              rejectionReason: userDetails.kycVideoRejectionReason,
              onChanged: (val) => controller.updateVideoGateStatus(val),
            ),

            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Service Agreement",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Download Signed E-Agreement from Digio",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (userDetails.digioDocumentId != null)
                  ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.viewServiceAgreement(),
                    icon: controller.isLoading.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      controller.isLoading.value
                          ? "Downloading..."
                          : "Download Agreement",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF163174), // Brand Blue
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  )
                else
                  Text(
                    "Agreement not found",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (userDetails.digioDocumentId != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Signed ID: ${userDetails.digioDocumentId}",
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            _buildGateDropdown(
              title: "E-Sign",
              status: userDetails.kycEsignStatus,
              rejectionReason: userDetails.kycEsignRejectionReason,
              onChanged: (val) => controller.updateEsignGateStatus(val),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Overall KYC Status",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (userDetails.effectiveKycStatus).toUpperCase() ==
                                'VERIFIED'
                            ? Colors.green.shade50
                            : ((userDetails.effectiveKycStatus).toUpperCase() ==
                                      'REJECTED'
                                  ? Colors.red.shade50
                                  : Colors.blue.shade50),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          (userDetails.effectiveKycStatus).toUpperCase() ==
                                  'VERIFIED'
                              ? Colors.green.shade200
                              : ((userDetails.effectiveKycStatus).toUpperCase() ==
                                        'REJECTED'
                                    ? Colors.red.shade200
                                    : Colors.blue.shade200),
                    ),
                  ),
                  child: Text(
                    (userDetails.effectiveKycStatus).toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          (userDetails.effectiveKycStatus).toUpperCase() ==
                                  'VERIFIED'
                              ? Colors.green.shade700
                              : ((userDetails.effectiveKycStatus).toUpperCase() ==
                                        'REJECTED'
                                    ? Colors.red.shade700
                                    : Colors.blue.shade700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (userDetails.effectiveKycStatus.toUpperCase() ==
                'WAITING_FOR_REVIEW')
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ready for review. All gates have submissions.',
                      style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                    ),
                  ),
                ],
              )
            else if (userDetails.effectiveKycStatus.toUpperCase() == 'PENDING')
              Row(
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 14, color: Colors.orange[800]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Incomplete: User has not yet uploaded all required documents.',
                      style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              "Note: Overall status is computed automatically from the 3 gates above and cannot be set manually.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    });
  }
}
