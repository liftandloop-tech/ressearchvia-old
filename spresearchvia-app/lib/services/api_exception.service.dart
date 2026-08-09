import 'package:dio/dio.dart';
import '../core/utils/error_message_handler.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiErrorHandler {
  static ApiException handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiException(message: 'Response Timeout', statusCode: null);

        case DioExceptionType.badResponse:
          return _handleBadResponse(error.response);

        case DioExceptionType.cancel:
          return ApiException(message: 'Request Cancelled', statusCode: null);

        case DioExceptionType.connectionError:
          return ApiException(
            message: 'No Internet Connection',
            statusCode: null,
          );

        case DioExceptionType.unknown:
          ErrorMessageHandler.logError('Unknown Dio Error', error.error, error.stackTrace);
          return ApiException(message: 'Network Error: ${error.message}', statusCode: null);

        default:
          ErrorMessageHandler.logError('Unhandled Dio Error', error);
          return ApiException(
            message: 'Something Went Wrong: ${error.message}',
            statusCode: null,
          );
      }
    } else {
      ErrorMessageHandler.logError('API Error', error);
      return ApiException(
        message: ErrorMessageHandler.getUserFriendlyMessage(error),
        statusCode: null,
      );
    }
  }

  static ApiException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;
    
    // Log the bad response details for debugging
    // ignore: avoid_print
    print('Bad Response: Status Code: $statusCode');
    // ignore: avoid_print
    print('Bad Response: Data: $data');

    String message = 'Error Occurred';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? data['error'] ?? data['msg'] ?? message;
    } else if (data is String) {
      if (data.isNotEmpty) {
        if (data.toLowerCase().contains('<!doctype html>') || data.toLowerCase().contains('<html>')) {
          message = 'Server Error (404/500)';
        } else {
          message = data;
        }
      }
    }

    if (message.length > 200) { // Increased length limit slightly
      message = ErrorMessageHandler.getUserFriendlyMessage(message);
    }

    switch (statusCode) {
      // ... existing cases ...
      case 400:
        final lowerMsg = message.toLowerCase();
        if (lowerMsg.contains('pan card') || lowerMsg.contains('pancard')) {
             if (lowerMsg.contains('already') || lowerMsg.contains('registered')) {
                return ApiException(
                  message: 'This PAN card is already registered with another account.',
                  statusCode: statusCode,
                  data: data,
                );
             }
        }
        if (lowerMsg.contains('phone') || lowerMsg.contains('mobile')) {
             if (lowerMsg.contains('already') || lowerMsg.contains('registered')) {
                return ApiException(
                  message: 'This phone number is already registered.',
                  statusCode: statusCode,
                  data: data,
                );
             }
        }
        if (lowerMsg.contains('already exists') || lowerMsg.contains('duplicate')) {
          return ApiException(
            message: 'Account Already Exists',
            statusCode: statusCode,
            data: data,
          );
        }
        return ApiException(
          message: message.isNotEmpty ? message : 'Invalid Request',
          statusCode: statusCode,
          data: data,
        );

      case 401:
        return ApiException(
          message: message.isNotEmpty ? message : 'Unauthorized',
          statusCode: statusCode,
          data: data,
        );

      case 403:
        return ApiException(
          message: message.isNotEmpty ? message : 'Access Denied',
          statusCode: statusCode,
          data: data,
        );

      case 404:
        return ApiException(
          message: message.isNotEmpty ? message : 'Not Found',
          statusCode: statusCode,
          data: data,
        );

      case 409:
        return ApiException(
          message: 'Already Exists',
          statusCode: statusCode,
          data: data,
        );

      case 422:
        return ApiException(
          message: message.isNotEmpty ? message : 'Validation Error',
          statusCode: statusCode,
          data: data,
        );

      case 429:
        return ApiException(
          message: 'Too Many Requests',
          statusCode: statusCode,
          data: data,
        );

      case 500:
        return ApiException(
          message: 'Server Error',
          statusCode: statusCode,
          data: data,
        );

      case 502:
        return ApiException(
          message: 'Service Unavailable',
          statusCode: statusCode,
          data: data,
        );

      case 503:
        return ApiException(
          message: 'Service Unavailable',
          statusCode: statusCode,
          data: data,
        );

      default:
        // Return the actual message if captured, otherwise fallback
        return ApiException(
          message: message != 'Error Occurred' ? message : 'Something Went Wrong (Status: $statusCode)',
          statusCode: statusCode,
          data: data,
        );
    }
  }
}
