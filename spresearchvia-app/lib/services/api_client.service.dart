import 'dart:convert';
import 'dart:collection';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:async';
import 'package:get/get.dart' as getx;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../core/config/api.config.dart';
import 'secure_storage.service.dart';
import 'snackbar.service.dart';
import '../core/routes/app_routes.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl.endsWith('/')
            ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
            : ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  late Dio _dio;
  final _storage = SecureStorageService();
  static final Map<String, Future<Response>> _inflightRequests = {};
  static final Map<String, Response> _responseCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const int _cacheTtlSeconds = 15;

  Dio get dio => _dio;

  void _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['authorization'] = token;
    }

    // Inject Device ID Header for Single Device Enforcement
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id');
    if (deviceId != null) {
      options.headers['device-id'] = deviceId;
    }

    // Inject Platform Header for Logic Enforcement
    try {
      if (Platform.isIOS) {
        options.headers['x-platform'] = 'ios';
      } else if (Platform.isAndroid) {
        options.headers['x-platform'] = 'android';
      }
    } catch (_) {
      // Ignore platform check errors (e.g. web)
    }

    debugPrint('AUTH HEADER => ${options.headers['authorization']}');

    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  void _finishRefresh({Object? error}) {
    _isRefreshing = false;
    if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
      if (error == null) {
        _refreshCompleter!.complete();
      } else {
        _refreshCompleter!.completeError(error);
      }
    }
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401 || error.response?.statusCode == 404 || error.response?.statusCode == 403) {
      final RequestOptions options = error.requestOptions;
      
      final responseData = error.response?.data;
      final bool isUserNotFound = error.response?.statusCode == 404 && 
          responseData is Map && 
          (responseData['message']?.toString().toLowerCase().contains('user not found') ?? false);
          
      final bool isSuspended = error.response?.statusCode == 403 &&
          responseData is Map &&
          (responseData['errorCode'] == 'USER_SUSPENDED' ||
           (responseData['message']?.toString().toLowerCase().contains('suspended') ?? false));

      final bool isNoActivePlan = error.response?.statusCode == 403 &&
          responseData is Map &&
          responseData['errorCode'] == 'NO_ACTIVE_PLAN';

      if (isNoActivePlan) {
        // Business logic error: User does not have an active plan.
        // DO NOT attempt to refresh token. Just reject and let the controller handle it.
        handler.reject(error);
        return;
      }


      // Avoid looping if error comes from refresh token endpoint or login itself
      // Also force logout if user is strictly not found in DB or suspended
      if (options.path.contains(ApiConfig.refreshToken) || 
          options.path.contains(ApiConfig.login) || 
          isUserNotFound || 
          isSuspended) {
        
        await _forceLogout(error);
        handler.reject(error);
        return;
      }

      // OPTIMIZATION: If token was already updated by another thread, retry immediately
      final currentToken = await _storage.getAuthToken();
      final usedToken = options.headers['authorization'];
      
      if (currentToken != null && usedToken != null && currentToken != usedToken) {
         options.headers['authorization'] = currentToken;
         
         final cloneReq = await _dio.request(
            options.path,
            options: Options(
              method: options.method,
              headers: options.headers,
              responseType: options.responseType,
              contentType: options.contentType,
              validateStatus: options.validateStatus,
              receiveTimeout: options.receiveTimeout,
              sendTimeout: options.sendTimeout,
            ),
            data: options.data,
            queryParameters: options.queryParameters,
         );
         handler.resolve(cloneReq);
         return;
      }

      // MUTEX LOGIC: If a refresh is already in progress, wait for it
      if (_isRefreshing) {
        try {
          await _refreshCompleter?.future;
          
          // Once refreshed, update token and retry
          final newToken = await _storage.getAuthToken();
          if (newToken != null) {
            options.headers['authorization'] = newToken;
            
            final cloneReq = await _dio.request(
              options.path,
              options: Options(
                method: options.method,
                headers: options.headers,
                responseType: options.responseType,
                contentType: options.contentType,
                validateStatus: options.validateStatus,
                receiveTimeout: options.receiveTimeout,
                sendTimeout: options.sendTimeout,
              ),
              data: options.data,
              queryParameters: options.queryParameters,
            );
            handler.resolve(cloneReq);
            return;
          }
        } catch (e) {
          // If the primary refresh failed, these pending requests also fail
          handler.reject(error);
          return;
        }
      }

      // START REFRESH
      _isRefreshing = true;
      _refreshCompleter = Completer<void>();

      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
           try {
           final prefs = await SharedPreferences.getInstance();
           final deviceId = prefs.getString('device_id');
           String platform = 'android';
           try {
             if (Platform.isIOS) platform = 'ios';
           } catch (_) {}

           final refreshHeaders = {'Content-Type': 'application/json'};
           if (deviceId != null) {
              refreshHeaders['device-id'] = deviceId;
           }

           final refreshDio = Dio(
             BaseOptions(
               baseUrl: _dio.options.baseUrl,
               headers: refreshHeaders,
             )
           );
           // Ensure no circular interceptors
           refreshDio.interceptors.clear(); 
           
           final refreshResponse = await refreshDio.post(
             ApiConfig.refreshToken,
             data: {
                'refreshToken': refreshToken, 
                'platform': platform
             },
           );
           
           if (refreshResponse.statusCode == 200) {
              final newAccessToken = refreshResponse.data['data']['accessToken'];
              final newRefreshToken = refreshResponse.data['data']['refreshToken'];
              
              if (newAccessToken != null && newRefreshToken != null) {
                 // ATOMIC STORAGE: Write new tokens immediately
                 await _storage.saveAuthToken(newAccessToken);
                 await _storage.saveRefreshToken(newRefreshToken);
                 
                 _finishRefresh(); // SUCCESS
                 
                 // Retry original request
                 options.headers['authorization'] = newAccessToken;
                 
                 final cloneReq = await _dio.request(
                    options.path,
                    options: Options(
                      method: options.method,
                      headers: options.headers,
                      responseType: options.responseType,
                      contentType: options.contentType,
                      validateStatus: options.validateStatus,
                      receiveTimeout: options.receiveTimeout,
                      sendTimeout: options.sendTimeout,
                    ),
                    data: options.data,
                    queryParameters: options.queryParameters,
                 );
                 
                 handler.resolve(cloneReq);
                 return;
              }
           }
           } catch (e) {
            // Refresh failed naturally
            getx.Get.log('Refresh Token Failed: $e');
            _finishRefresh(error: e); // FAILURE
            
            // Analyze failure reason
            bool shouldLogout = true;
            if (e is DioException) {
              final status = e.response?.statusCode;
              // If it's a network error (no response) or server error (5xx), do not logs out
              // Only logout if explicit 4xx error from refresh endpoint
              if (e.type != DioExceptionType.badResponse || (status != null && status >= 500)) {
                shouldLogout = false;
              }
            }

            if (shouldLogout) {
               await _forceLogout(error);
            }
            // If not logging out, we just reject the request. The user stays logged in locally.
            // Future requests will try to refresh again.
            handler.reject(error);
            return;
         }
      }

      // If we fall through here, it means no refresh token was found
      _finishRefresh(error: 'No refresh token'); 
      
      await _forceLogout(error);
      handler.reject(error);
      return;
    }

    // Handle 400 Token Invalid errors (Backend environment mismatch)
    if (error.response?.statusCode == 400) {
      final data = error.response?.data;
      if (data != null && data.toString().toLowerCase().contains('token')) {
         getx.Get.log('Auth Token 400 Error detected: $data');
         await _forceLogout(error);
         handler.reject(error);
         return;
      }
    }

    // -----------------------------------------------------------------------
    // GLOBAL ERROR LOG: Show any remaining unhandled API errors as a snackbar
    // -----------------------------------------------------------------------
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Determine a human-readable message from the server response
    String? serverMessage;
    if (responseData is Map) {
      serverMessage = responseData['message']?.toString() ??
          responseData['error']?.toString() ??
          responseData['msg']?.toString();
    } else if (responseData is String && responseData.isNotEmpty &&
        !responseData.toLowerCase().contains('<!doctype')) {
      serverMessage = responseData;
    }

    // Only show snackbar for errors we care about (skip silent retries & non-HTTP errors)
    final bool isSilentNetworkError =
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.cancel;

    if (!isSilentNetworkError) {
      final String displayMessage = serverMessage ??
          (statusCode != null ? 'Server Error ($statusCode)' : 'Network Error');
      SnackbarService.showError(displayMessage);
    }

    handler.next(error);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _generateFingerprint('GET', path, queryParameters);

    // 1. Check Cache (TTL)
    if (!forceRefresh && _responseCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp).inSeconds < _cacheTtlSeconds) {
        debugPrint('ApiClient: CACHE HIT: $path');
        return _responseCache[cacheKey]!;
      }
    }

    // 2. Check In-flight (Deduplication)
    if (_inflightRequests.containsKey(cacheKey)) {
      debugPrint('ApiClient: DEDUPLICATING CALL: $path');
      return _inflightRequests[cacheKey]!;
    }

    final future = _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );

    _inflightRequests[cacheKey] = future;

    try {
      final response = await future;
      
      // 3. Store in Cache on Success
      if (response.statusCode == 200) {
        _responseCache[cacheKey] = response;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
      
      return response;
    } catch (e) {
      rethrow;
    } finally {
      // Keep in-flight slightly longer for race conditions, 
      // but remove immediately to avoid blocking fresh attempts if needed.
      _inflightRequests.remove(cacheKey);
    }
  }

  String _generateFingerprint(
    String method,
    String path,
    Map<String, dynamic>? params,
  ) {
    try {
      final sortedParams = params == null
          ? {}
          : SplayTreeMap<String, dynamic>.from(params);
      return '$method:$path:${jsonEncode(sortedParams)}';
    } catch (_) {
      return '$method:$path:${params?.toString() ?? ""}';
    }
  }

  void clearCache() {
    _responseCache.clear();
    _cacheTimestamps.clear();
    debugPrint('ApiClient: Cache cleared');
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: onSendProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _forceLogout(DioException error) async {
      await _storage.clearAuthData();
      clearCache();

      // Show error why it was force logged out
      SnackbarService.showErrorFromException(error);

      final currentRoute = getx.Get.currentRoute;
      // Silently redirect — no snackbar or dialog shown to the user.
      // If another device logs in, the current session is simply ended.
      if (currentRoute != AppRoutes.login &&
          currentRoute != AppRoutes.signup &&
          currentRoute != AppRoutes.createAccount &&
          currentRoute != AppRoutes.getStarted &&
          currentRoute != AppRoutes.splash &&
          currentRoute != AppRoutes.otpVerification &&
          currentRoute != AppRoutes.forgotMpin) {
        getx.Get.offAllNamed(AppRoutes.getStarted);
      }
  }
}
