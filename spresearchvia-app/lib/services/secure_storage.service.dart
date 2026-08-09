import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import '../core/config/app.config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _secureStorage = const FlutterSecureStorage(
    // ignore: deprecated_member_use
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked, 
      synchronizable: false,
    ),
  );

  final _regularStorage = GetStorage();

  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _pendingPaymentIdKey = 'pending_payment_id';
  static const String _pendingOrderIdKey = 'pending_order_id';
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _subscriptionCacheTimeKey = 'subscription_cache_time';
  static const String _loginTimestampKey = 'login_timestamp';

  bool get _useSecureStorage => AppConfig.useSecureStorage;

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  Future<void> removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  Future<bool> hasAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_authTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    if (_useSecureStorage) {
      await _secureStorage.write(key: _userDataKey, value: jsonString);
    } else {
      await _regularStorage.write(_userDataKey, userData);
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_useSecureStorage) {
      final jsonString = await _secureStorage.read(key: _userDataKey);
      if (jsonString != null) {
        try {
          final decoded = jsonDecode(jsonString);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (_) {}
      }
      return null;
    } else {
      return _regularStorage.read(_userDataKey);
    }
  }

  Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> savePendingPayment({
    required String paymentId,
    required String orderId,
  }) async {
    if (_useSecureStorage) {
      await _secureStorage.write(key: _pendingPaymentIdKey, value: paymentId);
      await _secureStorage.write(key: _pendingOrderIdKey, value: orderId);
    } else {
      await _regularStorage.write(_pendingPaymentIdKey, paymentId);
      await _regularStorage.write(_pendingOrderIdKey, orderId);
    }
  }

  Future<Map<String, String>?> getPendingPayment() async {
    String? paymentId;
    String? orderId;

    if (_useSecureStorage) {
      paymentId = await _secureStorage.read(key: _pendingPaymentIdKey);
      orderId = await _secureStorage.read(key: _pendingOrderIdKey);
    } else {
      paymentId = _regularStorage.read(_pendingPaymentIdKey);
      orderId = _regularStorage.read(_pendingOrderIdKey);
    }

    if (paymentId != null && orderId != null) {
      return {'paymentId': paymentId, 'orderId': orderId};
    }
    return null;
  }

  Future<void> clearPendingPayment() async {
    if (_useSecureStorage) {
      await _secureStorage.delete(key: _pendingPaymentIdKey);
      await _secureStorage.delete(key: _pendingOrderIdKey);
    } else {
      await _regularStorage.remove(_pendingPaymentIdKey);
      await _regularStorage.remove(_pendingOrderIdKey);
    }
  }

  Future<void> cacheSubscriptionStatus(bool hasSubscription) async {
    await _regularStorage.write(_subscriptionStatusKey, hasSubscription);
    await _regularStorage.write(
      _subscriptionCacheTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<bool?> getCachedSubscriptionStatus() async {
    final cacheTime = _regularStorage.read(_subscriptionCacheTimeKey);
    if (cacheTime == null) return null;

    final cacheAge = DateTime.now().millisecondsSinceEpoch - (cacheTime as int);
    const maxCacheAge = 24 * 60 * 60 * 1000;

    if (cacheAge > maxCacheAge) {
      await _regularStorage.remove(_subscriptionStatusKey);
      await _regularStorage.remove(_subscriptionCacheTimeKey);
      return null;
    }

    return _regularStorage.read(_subscriptionStatusKey);
  }

  Future<void> clearSubscriptionCache() async {
    await _regularStorage.remove(_subscriptionStatusKey);
    await _regularStorage.remove(_subscriptionCacheTimeKey);
  }

  Future<void> saveLoginTimestamp() async {
    final timestamp = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginTimestampKey, timestamp);
  }

  Future<DateTime?> getLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_loginTimestampKey);
    
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }

  static const String _refreshTokenKey = 'refresh_token';

  Future<void> saveRefreshToken(String token) async {
    // Refresh Token is sensitive, prefer secure storage if available/enabled
    // But for consistency with AuthToken (if not secure), we might use SharedPreferences
    // The previous AuthToken uses SharedPreferences.
    // If we want "Secure Storage", we should use FlutterSecureStorage.
    // Given the prompt emphasized "Secure Storage" for refresh token, let's use FlutterSecureStorage if possible.
    // BUT checking `_useSecureStorage` flag: `AppConfig.useSecureStorage`.
    
    if (_useSecureStorage) {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    } else {
      // Fallback to SharedPrefs for robustness if SecureStorage disabled/failed in past
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshTokenKey, token);
    }
  }

  Future<String?> getRefreshToken() async {
    if (_useSecureStorage) {
      final token = await _secureStorage.read(key: _refreshTokenKey);
      if (token != null) return token;
      
      // Fallback: Check SharedPreferences even if we are supposed to use SecureStorage
      // This handles cases where data was saved in previous versions or different modes
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
  }

  Future<void> removeRefreshToken() async {
     if (_useSecureStorage) {
      await _secureStorage.delete(key: _refreshTokenKey);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_refreshTokenKey);
    }
  }

  Future<void> clearAuthData() async {
    await removeAuthToken();
    await removeRefreshToken();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_loginTimestampKey);
    
    // Clear legacy/other storage
    await _regularStorage.remove(_userIdKey); // In case it was here
    await _regularStorage.remove(_userDataKey);

    await clearPendingPayment();
    await clearSubscriptionCache();

    if (_useSecureStorage) {
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _userDataKey);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI HINT: Registration Skipped Flag
  // ──────────────────────────────────────────────────────────────────────────
  // ⚠️  UI DISPLAY ONLY. NEVER use this flag for navigation or access control.
  // ⚠️  Navigation is EXCLUSIVELY controlled by the backend's `state`/`nextStep`
  //     and `canSkipRegistration` fields returned from the API.
  //
  // Renamed from 'reg_skipped' → 'ui_registration_hint' (v2) to make intent clear.
  // If you find yourself reading this flag for routing, you are doing it wrong.
  // ──────────────────────────────────────────────────────────────────────────
  static const String _registrationSkippedKey = 'ui_registration_hint';
  // TOMBSTONED KEY (old name — kept here as a reference, cleaned up in migration):
  // static const String _OLD_registrationSkippedKey = 'reg_skipped';

  /// ⚠️ UI ONLY — Persists the "user chose to skip registration" hint for display.
  /// DO NOT use this for navigation decisions. Backend decides navigation.
  Future<void> setRegistrationSkipped(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_registrationSkippedKey, value);
  }

  /// ⚠️ UI ONLY — Reads the "user chose to skip registration" hint.
  /// DO NOT use this for navigation decisions. Backend decides navigation.
  Future<bool> isRegistrationSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_registrationSkippedKey) ?? false;
  }

  static Future<void> init() async {
    await GetStorage.init();
    await SecureStorageService().checkAndMigrate();
  }

  static const String _storageVersionKey = 'storage_version';

  /// Checks if the local storage needs migration or clearing due to a version mismatch.
  /// This ensures that old flags (like skip registration) don't persist across major app updates.
  Future<void> checkAndMigrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_storageVersionKey) ?? 0;

      if (currentVersion < AppConfig.storageVersion) {
        Get.log('SecureStorage: Version mismatch ($currentVersion < ${AppConfig.storageVersion}). Migrating...');
        
        // 1. Remove stale navigation flags (both old and new key names)
        //    Old key 'reg_skipped' is tombstoned — ensure complete removal.
        //    New key 'ui_registration_hint' is UI-only and should also reset.
        await prefs.remove('reg_skipped');            // TOMBSTONED: old key
        await prefs.remove(_registrationSkippedKey);  // new key 'ui_registration_hint'
        
        // 2. Clear cached user data to force a fresh fetch from backend
        // (We keep the auth token so the user stays logged in)
        if (_useSecureStorage) {
          await _secureStorage.delete(key: _userDataKey);
        } else {
          await _regularStorage.remove(_userDataKey);
        }

        // 3. Clear subscription caches
        await clearSubscriptionCache();

        // 4. Clear pending payment flows to avoid stuck states
        await clearPendingPayment();

        // 5. Update the stored version
        await prefs.setInt(_storageVersionKey, AppConfig.storageVersion);
        
        Get.log('SecureStorage: Migration to version ${AppConfig.storageVersion} complete.');
      }
    } catch (e) {
      Get.log('SecureStorage: Migration error: $e');
    }
  }
}

