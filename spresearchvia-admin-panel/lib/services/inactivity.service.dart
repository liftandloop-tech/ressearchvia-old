import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth/auth.controller.dart';

class InactivityService extends GetxService {
  static InactivityService get to => Get.find<InactivityService>();

  static void recordIfRegistered({bool forcePersist = false}) {
    if (Get.isRegistered<InactivityService>()) {
      Get.find<InactivityService>().recordActivity(forcePersist: forcePersist);
    }
  }

  static const String _lastActivityKey = 'last_activity_timestamp';
  static const Duration inactivityTimeout = Duration(hours: 1);

  DateTime _lastActivityTime = DateTime.now();
  DateTime _lastPersistedTime = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _inactivityCheckTimer;
  bool _isHandlingTimeout = false;

  bool _keyHandler(KeyEvent event) {
    recordActivity();
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    _startTimer();
    HardwareKeyboard.instance.addHandler(_keyHandler);
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_keyHandler);
    _inactivityCheckTimer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _inactivityCheckTimer?.cancel();
    // Check every 15 seconds
    _inactivityCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkInactivity();
    });
  }

  /// Call whenever user interacts with the app (click, mouse move, scroll, key press)
  void recordActivity({bool forcePersist = false}) {
    _lastActivityTime = DateTime.now();

    // Persist immediately if forced or at least 15 seconds have passed
    if (forcePersist || _lastActivityTime.difference(_lastPersistedTime).inSeconds >= 15) {
      _lastPersistedTime = _lastActivityTime;
      _persistLastActivity(_lastActivityTime);
    }
  }

  Future<void> _persistLastActivity(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActivityKey, time.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[InactivityService] Error persisting activity timestamp: $e');
    }
  }

  /// Resets the timer upon login or session restore
  Future<void> resetTimer() async {
    _lastActivityTime = DateTime.now();
    _lastPersistedTime = _lastActivityTime;
    _isHandlingTimeout = false;
    await _persistLastActivity(_lastActivityTime);
    _startTimer();
  }

  /// Checks if the saved session in storage has exceeded the 1-hour inactivity limit
  Future<bool> isSessionExpiredFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_lastActivityKey);
      if (lastMs == null) return false;

      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final elapsed = DateTime.now().difference(lastTime);
      final expired = elapsed >= inactivityTimeout;
      if (expired) {
        debugPrint(
          '[InactivityService] Session expired from storage: elapsed ${elapsed.inMinutes} minutes (limit: ${inactivityTimeout.inMinutes} mins)',
        );
      }
      return expired;
    } catch (e) {
      debugPrint('[InactivityService] Error checking stored activity: $e');
      return false;
    }
  }

  /// Clear activity record on manual logout
  Future<void> clearActivityRecord() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActivityKey);
      _lastActivityTime = DateTime.now();
    } catch (e) {
      debugPrint('[InactivityService] Error clearing activity record: $e');
    }
  }

  void _checkInactivity() {
    if (_isHandlingTimeout) return;

    if (!Get.isRegistered<AuthController>()) return;
    final authController = Get.find<AuthController>();
    if (!authController.isAuthenticated.value) return;

    final elapsed = DateTime.now().difference(_lastActivityTime);
    if (elapsed >= inactivityTimeout) {
      _isHandlingTimeout = true;
      debugPrint(
        '[InactivityService] Auto-logout triggered: Inactive for ${elapsed.inMinutes} minutes.',
      );
      authController.handleInactivityLogout();
    }
  }
}
