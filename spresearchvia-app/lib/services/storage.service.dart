import 'package:get_storage/get_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = GetStorage();

  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _rememberMeKey = 'remember_me';

  static Future<void> init() async {
    await GetStorage.init();
  }

  Future<void> saveAuthToken(String token) async {
    await _storage.write(_authTokenKey, token);
  }

  String? getAuthToken() {
    return _storage.read(_authTokenKey);
  }

  Future<void> removeAuthToken() async {
    await _storage.remove(_authTokenKey);
  }

  bool hasAuthToken() {
    return _storage.hasData(_authTokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(_userIdKey, userId);
  }

  String? getUserId() {
    return _storage.read(_userIdKey);
  }

  Future<void> removeUserId() async {
    await _storage.remove(_userIdKey);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(_userDataKey, userData);
  }

  Map<String, dynamic>? getUserData() {
    return _storage.read(_userDataKey);
  }

  Future<void> removeUserData() async {
    await _storage.remove(_userDataKey);
  }

  Future<void> setLoggedIn(bool value) async {
    await _storage.write(_isLoggedInKey, value);
  }

  bool isLoggedIn() {
    return _storage.read(_isLoggedInKey) ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    await _storage.write(_rememberMeKey, value);
  }

  bool getRememberMe() {
    return _storage.read(_rememberMeKey) ?? false;
  }

  Future<void> clearAll() async {
    await _storage.erase();
  }

  Future<void> clearAuthData() async {
    await removeAuthToken();
    await removeUserId();
    await removeUserData();
    await setLoggedIn(false);
  }
}
