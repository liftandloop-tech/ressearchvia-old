import 'dart:io';

class FileValidator {
  static const int maxImageSize = 5 * 1024 * 1024;
  static const int maxDocumentSize = 10 * 1024 * 1024;

  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
  ];

  static const List<String> allowedDocumentExtensions = [
    '.pdf',
    '.doc',
    '.docx',
    '.jpg',
    '.jpeg',
    '.png',
  ];

  static String? validateImageFile(File file) {
    final fileSize = file.lengthSync();
    final fileName = file.path.toLowerCase();

    if (fileSize > maxImageSize) {
      return 'Image size must be less than ${_formatBytes(maxImageSize)}';
    }

    final hasValidExtension = allowedImageExtensions.any(
      (ext) => fileName.endsWith(ext),
    );

    if (!hasValidExtension) {
      return 'Only ${allowedImageExtensions.join(", ")} files are allowed';
    }

    return null;
  }

  static String? validateDocumentFile(File file) {
    final fileSize = file.lengthSync();
    final fileName = file.path.toLowerCase();

    if (fileSize > maxDocumentSize) {
      return 'Document size must be less than ${_formatBytes(maxDocumentSize)}';
    }

    final hasValidExtension = allowedDocumentExtensions.any(
      (ext) => fileName.endsWith(ext),
    );

    if (!hasValidExtension) {
      return 'Only ${allowedDocumentExtensions.join(", ")} files are allowed';
    }

    return null;
  }

  static bool isImageFile(String path) {
    final fileName = path.toLowerCase();
    return allowedImageExtensions.any((ext) => fileName.endsWith(ext));
  }

  static bool isPDFFile(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String formatFileSize(int bytes) {
    return _formatBytes(bytes);
  }
}
