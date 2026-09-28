import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class InAppUpdateService {
  /// Checks for in-app update and initiates immediate or flexible update if available.
  /// Safely catches errors (e.g. non-Play-Store builds, debug mode, or network issues).
  static Future<void> checkForUpdate({bool immediateOnly = false}) async {
    // In-app updates via Google Play Core are only supported on Android devices
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (!immediateOnly && updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('InAppUpdateService: Check for update skipped or failed ($e)');
    }
  }
}
