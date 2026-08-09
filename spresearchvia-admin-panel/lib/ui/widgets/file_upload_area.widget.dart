import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';

class FileUploadController extends GetxController {
  var selectedFileName = ''.obs;
  var isDragging = false.obs;
  var isUploading = false.obs;
  var uploadProgress = 0.0.obs;

  void setDragging(bool value) {
    isDragging.value = value;
  }

  void selectFile(String fileName) {
    selectedFileName.value = fileName;
  }

  void clearFile() {
    selectedFileName.value = '';
    uploadProgress.value = 0.0;
  }

  void startUpload() {
    isUploading.value = true;
  }

  void completeUpload() {
    isUploading.value = false;
    uploadProgress.value = 100.0;
  }
}

class FileUploadArea extends StatelessWidget {
  final Function(String) onFileSelected;
  final String? acceptedFormats;
  final String? maxSize;
  final String? selectedFile;

  const FileUploadArea({
    super.key,
    required this.onFileSelected,
    this.acceptedFormats = 'PDF, PNG, JPG, JPEG, GIF, WEBP',
    this.maxSize = '10MB',
    this.selectedFile,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FileUploadController());

    return Obx(
      () => Container(
        height: 240,
        decoration: BoxDecoration(
          color: controller.isDragging.value
              ? AppTheme.lightBlueBg
              : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
          border: Border.all(
            color: controller.isDragging.value
                ? AppTheme.infoButtonBlue
                : AppTheme.gray300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: MouseRegion(
                onEnter: (_) => controller.setDragging(true),
                onExit: (_) => controller.setDragging(false),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.infoButtonBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusDefault,
                        ),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppTheme.infoButtonBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Drag & drop file',
                      style: AppTheme.bodyLargeStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.gray900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'or click to choose files',
                      style: AppTheme.bodySmallStyle,
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        controller.selectFile('document.pdf');
                        onFileSelected('document.pdf');
                      },
                      style: AppTheme.blueButtonStyle,
                      child: const Text('Browse Files'),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Supported formats: $acceptedFormats (Max $maxSize)',
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
              ),
            ),

            if (controller.selectedFileName.value.isNotEmpty)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreenBg,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusDefault,
                    ),
                    border: Border.all(color: AppTheme.successGreen, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_drive_file_outlined,
                        size: 48,
                        color: AppTheme.successGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.selectedFileName.value,
                        style: AppTheme.bodyLargeStyle.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: controller.clearFile,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
