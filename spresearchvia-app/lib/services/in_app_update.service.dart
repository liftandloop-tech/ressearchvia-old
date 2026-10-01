import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import '../core/config/app.config.dart';
import '../core/theme/app_theme.dart';
import 'snackbar.service.dart';

class InAppUpdateService {
  static bool _isChecking = false;

  /// Checks for Google Play In-App Updates and initiates the appropriate update flow.
  /// 
  /// - [immediateOnly]: Force an immediate full-screen update if allowed.
  /// - [isManualCheck]: Set to true when triggered manually by user (e.g. from Settings screen)
  ///   to display explicit feedback toast/snackbar when app is up-to-date or if check fails.
  static Future<void> checkForUpdate({
    bool immediateOnly = false,
    bool isManualCheck = false,
  }) async {
    // In-app updates via Google Play Core are strictly Android-only
    if (kIsWeb || !Platform.isAndroid) {
      if (isManualCheck) {
        SnackbarService.show(
          'Google Play In-App Updates are only available on Android devices.',
          title: 'Not Supported',
          icon: Icons.info_outline,
        );
      }
      return;
    }

    if (_isChecking) return;
    _isChecking = true;

    try {
      debugPrint('InAppUpdateService: Querying Google Play for update availability...');
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      
      debugPrint('InAppUpdateService: Availability=${updateInfo.updateAvailability}, '
          'InstallStatus=${updateInfo.installStatus}, '
          'ImmediateAllowed=${updateInfo.immediateUpdateAllowed}, '
          'FlexibleAllowed=${updateInfo.flexibleUpdateAllowed}, '
          'AvailableVersionCode=${updateInfo.availableVersionCode}');

      // 1. If an update was already downloaded in background, prompt user to complete installation
      if (updateInfo.installStatus == InstallStatus.downloaded) {
        _showUpdateDownloadedNotification();
        return;
      }

      // 2. If an immediate update was already triggered and interrupted, resume it
      if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        debugPrint('InAppUpdateService: Resuming developer-triggered update in progress');
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      // 3. New update is available on Google Play Store
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // High priority updates (>= 4) or forced immediate
        final isHighPriority = updateInfo.updatePriority >= 4;
        
        if (immediateOnly || (isHighPriority && updateInfo.immediateUpdateAllowed)) {
          debugPrint('InAppUpdateService: Performing immediate update flow');
          final AppUpdateResult result =
              await InAppUpdate.performImmediateUpdate();
          if (result == AppUpdateResult.userDeniedUpdate && isManualCheck) {
            SnackbarService.show(
              'Update was cancelled. You can update later from the Play Store or Settings.',
              title: 'Update Cancelled',
              icon: Icons.cancel_outlined,
            );
          }
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Flexible background update — downloads while user continues using app
          debugPrint('InAppUpdateService: Starting flexible update in background');
          final AppUpdateResult result =
              await InAppUpdate.startFlexibleUpdate();
          
          if (result == AppUpdateResult.success) {
            // Flexible download finished! Prompt user to restart app to apply
            _showUpdateDownloadedNotification();
          }
        } else if (updateInfo.immediateUpdateAllowed) {
          // Fallback to immediate update if flexible is not allowed
          debugPrint('InAppUpdateService: Flexible update not allowed, falling back to immediate');
          await InAppUpdate.performImmediateUpdate();
        }
      } else if (updateInfo.updateAvailability ==
          UpdateAvailability.updateNotAvailable) {
        if (isManualCheck) {
          SnackbarService.show(
            'You are on the latest version of SP ResearchVia (v${AppConfig.appVersion}).',
            title: 'App Up to Date',
            icon: Icons.check_circle_outline,
            backgroundColor: AppTheme.success,
          );
        }
      } else if (isManualCheck) {
        SnackbarService.show(
          'No updates currently available on Google Play Store.',
          title: 'Up to Date',
          icon: Icons.info_outline,
        );
      }
    } catch (e) {
      debugPrint('InAppUpdateService: Check for update skipped or failed ($e)');
      if (isManualCheck) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('error(-3)') ||
            errStr.contains('error(-10)') ||
            kDebugMode) {
          SnackbarService.show(
            'Play Store In-App Updates require the app to be installed from Google Play Store.',
            title: 'Play Store Required',
            icon: Icons.info_outline,
          );
        } else {
          SnackbarService.show(
            'Unable to check for updates right now. Please check Google Play Store.',
            title: 'Check Failed',
            icon: Icons.error_outline,
            backgroundColor: AppTheme.error,
          );
        }
      }
    } finally {
      _isChecking = false;
    }
  }

  /// Checks if an update was downloaded in background and is waiting to be installed.
  /// Typically called when the app lifecycle resumes from background.
  static Future<void> checkUpdateOnResume() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.installStatus == InstallStatus.downloaded) {
        _showUpdateDownloadedNotification();
      } else if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('InAppUpdateService: checkUpdateOnResume skipped ($e)');
    }
  }

  /// Prompts the user with a top notification / action bar to restart the app and complete installation.
  static void _showUpdateDownloadedNotification() {
    SnackbarService.show(
      'A new version has been downloaded. Restart the app to apply the update.',
      title: 'Update Ready to Install',
      icon: Icons.system_update_rounded,
      backgroundColor: AppTheme.primaryBlueDark,
      duration: const Duration(days: 1), // Persistent until actioned
      actionTitle: 'RESTART NOW',
      actionOnTap: () async {
        try {
          await InAppUpdate.completeFlexibleUpdate();
        } catch (e) {
          debugPrint('InAppUpdateService: completeFlexibleUpdate error: $e');
        }
      },
    );
  }
}
