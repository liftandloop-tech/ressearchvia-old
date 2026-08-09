import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'api_client.service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CacheService extends GetxService {
  static CacheService get to => Get.find();

  final RxString currentCacheSize = '0 KB'.obs;

  @override
  void onInit() {
    super.onInit();
    updateCacheSize();
  }

  /// Clears all application-level caches
  /// 1. API Response Cache
  /// 2. Flutter Image Cache
  /// 3. System Temporary Directory (Reports, temporary images, etc.)
  /// 4. WebView Cookies
  Future<void> clearAllCache() async {
    try {
      debugPrint('CacheService: Starting global cache cleanup...');

      // 1. Clear API Client Response Cache
      ApiClient().clearCache();

      // 2. Clear Flutter Image Cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 3. Clear System Temporary Directory
      await _clearTemporaryDirectory();

      // 4. Clear WebView Cookies/Cache
      try {
        final cookieManager = WebViewCookieManager();
        await cookieManager.clearCookies();
      } catch (e) {
        debugPrint('CacheService: WebView Cookie clearing skipped or failed: $e');
      }

      await updateCacheSize();
      debugPrint('CacheService: Cache cleanup completed successfully.');
    } catch (e) {
      debugPrint('CacheService: Error during cache cleanup: $e');
    }
  }

  /// Updates the observable cache size
  Future<void> updateCacheSize() async {
    final size = await _getTotalCacheSize();
    currentCacheSize.value = size;
  }

  /// Deletes all files and directories in the system's temporary directory
  Future<void> _clearTemporaryDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        final List<FileSystemEntity> entities = tempDir.listSync();
        for (final entity in entities) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            // Some files might be in use (like active logs or temporary system files), skip those
            debugPrint('CacheService: Could not delete ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('CacheService: Error clearing temporary directory: $e');
    }
  }

  /// Get the approximate total size of the cache for display in UI
  Future<String> _getTotalCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;

      if (tempDir.existsSync()) {
        totalSize += _getDirectorySize(tempDir);
      }
      
      return _formatBytes(totalSize);
    } catch (e) {
      return '0 KB';
    }
  }

  int _getDirectorySize(Directory directory) {
    int totalSize = 0;
    try {
      if (directory.existsSync()) {
        directory.listSync(recursive: true, followLinks: false).forEach((entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      debugPrint('CacheService: Error calculating directory size: $e');
    }
    return totalSize;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes.toString().length - 1) ~/ 3;
    var value = bytes / (1 << (i * 10));
    return "${value.toStringAsFixed(2)} ${suffixes[i]}";
  }
}
