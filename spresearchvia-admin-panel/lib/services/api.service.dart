import 'dart:convert';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app.config.dart';

class ApiService extends GetConnect {
  static final Map<String, Future<dynamic>> _inflightRequests = {};
  static final Map<String, Response> _responseCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const int _cacheTtlSeconds = 15;

  ApiService() {
    httpClient.baseUrl = AppConfig.apiBaseUrl;
    httpClient.timeout = const Duration(seconds: 30);
    _initializeModifiers();
  }

  @override
  void onInit() {
    super.onInit();
    // Fallback if needed
    if (httpClient.baseUrl == null) {
      httpClient.baseUrl = AppConfig.apiBaseUrl;
      httpClient.timeout = const Duration(seconds: 30);
    }
  }

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    bool forceRefresh = false,
  }) async {
    final key = _generateFingerprint('GET', url, query);

    // 1. Check Cache (TTL)
    if (!forceRefresh && _responseCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null &&
          DateTime.now().difference(timestamp).inSeconds < _cacheTtlSeconds) {
        debugPrint('ApiService: CACHE HIT: $url');
        return _responseCache[key]! as Response<T>;
      }
    }

    // 2. Check In-flight (Deduplication)
    if (_inflightRequests.containsKey(key)) {
      debugPrint('ApiService: DEDUPLICATING GET: $url');
      return _inflightRequests[key]! as Future<Response<T>>;
    }

    final future = super.get<T>(
      url,
      headers: headers,
      contentType: contentType,
      query: query,
      decoder: decoder,
    );

    _inflightRequests[key] = future;

    try {
      final response = await future;

      // 3. Store in Cache on Success
      if (!response.status.hasError) {
        _responseCache[key] = response;
        _cacheTimestamps[key] = DateTime.now();
      }

      return response;
    } catch (e) {
      rethrow;
    } finally {
      _inflightRequests.remove(key);
    }
  }

  String _generateFingerprint(
    String method,
    String path,
    Map<String, dynamic>? params,
  ) {
    try {
      // Sort keys for consistent hashing
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
    debugPrint('ApiService: Cache cleared');
  }

  void _initializeModifiers() {
    // Add auth headers
    httpClient.addRequestModifier<dynamic>((request) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null && token.isNotEmpty) {
          // Backend expects raw token without "Bearer " prefix
          request.headers['Authorization'] = token;
          debugPrint('Added auth header for ${request.url}');
        } else {
          debugPrint('No auth token found for ${request.url}');
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

        if (isTokenError) {
          print(
            'Auth Token Invalid or Expired (Status: ${response.statusCode}). Redirecting to login.',
          );

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            await prefs.remove('user_data');
            clearCache();

            // Redirect to login if not already there to prevent loops if login API itself returns 400
            if (Get.currentRoute != '/') {
              Get.offAllNamed('/');
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
