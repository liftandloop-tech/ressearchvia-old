import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app.config.dart';
import '../config/routes.config.dart';
import '../controllers/auth/auth.controller.dart';
import 'inactivity.service.dart';

class ApiService extends GetConnect {
  ApiService() {
    httpClient.baseUrl = AppConfig.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 15);
    _initializeModifiers();
  }

  @override
  void onInit() {
    super.onInit();
    if (httpClient.baseUrl == null) {
      httpClient.baseUrl = AppConfig.apiBaseUrl;
      httpClient.timeout = const Duration(seconds: 15);
    }
  }

  static final Map<String, _CacheEntry> _cache = {};

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    bool forceRefresh = false,
    int cacheTtlSeconds = 0,
  }) async {
    final queryString = query != null && query.isNotEmpty
        ? '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';
    final cacheKey = '$url$queryString';

    // Auto-cache static configuration endpoints like roles and departments (60s TTL)
    final isStaticConfig = url.contains('/role/list') ||
        url.contains('/role/all') ||
        url.contains('/department/list') ||
        url.contains('/applicant/roles');

    final effectiveTtl = cacheTtlSeconds > 0
        ? cacheTtlSeconds
        : (isStaticConfig ? 60 : 0);

    if (!forceRefresh && effectiveTtl > 0 && _cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().isBefore(entry.expiresAt)) {
        return entry.response as Response<T>;
      } else {
        _cache.remove(cacheKey);
      }
    }

    final res = await super.get<T>(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
    );

    if (effectiveTtl > 0 && res.isOk && res.body != null) {
      _cache[cacheKey] = _CacheEntry(
        response: res,
        expiresAt: DateTime.now().add(Duration(seconds: effectiveTtl)),
      );
    }

    return res;
  }

  static void clearAllCache() {
    _cache.clear();
  }

  void clearCache() => clearAllCache();

  void _initializeModifiers() {
    // Add auth headers
    httpClient.addRequestModifier<dynamic>((request) async {
      InactivityService.recordIfRegistered();
      try {
        final urlStr = request.url.toString();
        // Admin applicant management endpoints REQUIRE staff auth tokens!
        final isAdminApplicantEndpoint = urlStr.contains('/staff/applicant/approve') ||
            urlStr.contains('/staff/applicant/promote') ||
            urlStr.contains('/staff/applicant/stage') ||
            urlStr.contains('/staff/applicant/reject') ||
            urlStr.contains('/staff/applicant/evaluation-remarks') ||
            urlStr.contains('/staff/applicants');

        // Public applicant routes do not use staff auth tokens
        final isApplicantPublicEndpoint = !isAdminApplicantEndpoint && (
            urlStr.contains('/applicant/create-account') ||
            urlStr.contains('/applicant/verify-account-email') ||
            urlStr.contains('/applicant/resend-email-otp') ||
            urlStr.contains('/applicant/continue-login') ||
            urlStr.contains('/applicant/send-mobile-otp') ||
            urlStr.contains('/applicant/verify-mobile-otp') ||
            urlStr.contains('/applicant/save-step') ||
            urlStr.contains('/applicant/finalize-application') ||
            urlStr.contains('/applicant/register') ||
            urlStr.contains('/applicant/update-contact') ||
            urlStr.contains('/applicant/verify') ||
            urlStr.contains('/applicant/upload-doc') ||
            urlStr.contains('/applicant/upload-video') ||
            urlStr.contains('/applicant/continue-init') ||
            urlStr.contains('/applicant/continue-verify') ||
            urlStr.contains('/applicant/roles')
        );

        if (!isApplicantPublicEndpoint) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null && token.isNotEmpty) {
            // Backend expects raw token without "Bearer " prefix
            request.headers['Authorization'] = token;
            debugPrint('Added auth header for ${request.url}');
          } else {
            debugPrint('No auth token found for ${request.url}');
          }
        }
        
        // Remove content-length to avoid "Refused to set unsafe header" in browser/web
        request.headers.remove('content-length');
      } catch (e) {
        debugPrint('Error attaching auth token: $e');
      }
      return request;
    });

    // Response modifier for logging
    httpClient.addResponseModifier((request, response) async {
      // Early exit for binary downloads to prevent UTF-8 decoding errors
      if (request.url.toString().contains('download')) {
        return response;
      }

      if (response.status.hasError) {
        debugPrint(
          'API Error: ${request.method} ${request.url} -> ${response.statusCode} ${response.statusText}',
        );

        final urlStr = request.url.toString();
        final isAdminApplicantEndpoint = urlStr.contains('/staff/applicant/approve') ||
            urlStr.contains('/staff/applicant/promote') ||
            urlStr.contains('/staff/applicant/stage') ||
            urlStr.contains('/staff/applicant/reject') ||
            urlStr.contains('/staff/applicant/evaluation-remarks') ||
            urlStr.contains('/staff/applicants');

        final isApplicantPublicRequest = !isAdminApplicantEndpoint && (
            urlStr.contains('/applicant/create-account') ||
            urlStr.contains('/applicant/verify-account-email') ||
            urlStr.contains('/applicant/resend-email-otp') ||
            urlStr.contains('/applicant/continue-login') ||
            urlStr.contains('/applicant/send-mobile-otp') ||
            urlStr.contains('/applicant/verify-mobile-otp') ||
            urlStr.contains('/applicant/save-step') ||
            urlStr.contains('/applicant/finalize-application') ||
            urlStr.contains('/applicant/register') ||
            urlStr.contains('/applicant/update-contact') ||
            urlStr.contains('/applicant/verify') ||
            urlStr.contains('/applicant/upload-doc') ||
            urlStr.contains('/applicant/upload-video') ||
            urlStr.contains('/applicant/continue-init') ||
            urlStr.contains('/applicant/continue-verify') ||
            urlStr.contains('/applicant/roles')
        );
        final isPublicPage = AppRoutes.isPublicRoute(Get.currentRoute);

        // Guard: NEVER trigger staff logout or redirect to login screen for public applicant endpoints or when applicant is on public pages
        if (isApplicantPublicRequest || isPublicPage) {
          debugPrint('Bypassing auth guard for applicant endpoint or public route: $urlStr');
          return response;
        }

        // Handle "Token not valid" (400) or Unauthorized (401)
        // The backend returns 400 for jwt verification failure with message "Token not valid"
        bool isTokenError = response.statusCode == 401;

        // Only check body if it's potentially text content
        String contentType = '';
        try {
          contentType = response.headers?['content-type'] ?? '';
        } catch (e) {
          debugPrint('Web Headers access bypass: $e');
        }

        if (!isTokenError &&
            response.statusCode == 400 &&
            !contentType.contains('pdf')) {
          try {
            final bodyStr =
                response.bodyString ?? response.body?.toString() ?? '';
            if (bodyStr.contains('Token not valid')) {
              isTokenError = true;
            }
          } catch (_) {
            // Ignore decoding errors in the interceptor
          }
        }

        final reqAuth = request.headers['Authorization'] ?? request.headers['authorization'];
        final hadAuthToken = reqAuth != null && reqAuth.trim().isNotEmpty;

        // Only clear storage and redirect if the request actually sent an auth token that was rejected.
        // Unauthenticated initial requests before auth check finishes must not wipe stored tokens.
        if (isTokenError && hadAuthToken) {
          debugPrint(
            'Auth Token Invalid or Expired (Status: ${response.statusCode}). Redirecting to login.',
          );

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            await prefs.remove('user_data');
            clearCache();

            if (Get.isRegistered<AuthController>()) {
              final auth = Get.find<AuthController>();
              auth.user.value = null;
              auth.authToken.value = '';
              auth.isAuthenticated.value = false;
            }

            if (Get.currentRoute != AppRoutes.login &&
                Get.currentRoute != '/' &&
                !AppRoutes.isPublicRoute(Get.currentRoute)) {
              Get.offAllNamed(AppRoutes.login);
            }
          } catch (e) {
            debugPrint('Error handling auth clearing: $e');
          }
        }
      }
      return response;
    });
  }
}

class _CacheEntry {
  final dynamic response;
  final DateTime expiresAt;

  _CacheEntry({required this.response, required this.expiresAt});
}
