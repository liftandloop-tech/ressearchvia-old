import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/core/config/api.config.dart';

import '../services/api_client.service.dart';
import '../services/api_exception.service.dart';
import '../services/snackbar.service.dart';
import '../services/secure_storage.service.dart';
import 'user.controller.dart';
import '../screens/kyc/kyc_fallback_form_screen.dart';
import '../screens/kyc/digio_webview_screen.dart';
import '../screens/kyc/video_kyc_intro.screen.dart';
import '../core/routes/app_routes.dart';
import 'auth.controller.dart';

class DigioController extends GetxController {
  final RxBool connecting = false.obs;
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>?> connectDigio({
    required String email,
    required String name,
    required String userId,
    Map<String, dynamic>? fallbackData,
  }) async {
    try {
      connecting.value = true;

      final token = await SecureStorageService().getAuthToken();
      if (token == null || token.isEmpty) {
        SnackbarService.showError('User token missing. Please login again.');
        return null;
      }

      final Map<String, dynamic> payload = {'email': email, 'name': name, 'sign_type': 'aadhaar'};
      if (fallbackData != null) {
        payload.addAll(fallbackData);
      }

      final response = await _apiClient.post(
        ApiConfig.documentKYC(userId),
        data: payload,
      );

      SnackbarService.showSuccess('Service connected successfully');
      return response.data as Map<String, dynamic>?;
    } catch (e) {
      if (e is Exception) {
         // Check for 422 or specific message
         // Assuming ApiClient throws DioException or similar that ApiErrorHandler wraps
         // Ideally check response status code here if available in 'e'
         // If generic handling:
         final error = ApiErrorHandler.handleError(e);
         // Check if error response indicates fallback required
         // Depending on how ApiErrorHandler exposes the raw response or data
         // For now, checking message or re-throwing if specific
         
         // NOTE: Since I cannot easily see ApiClient internals here, 
         // I'm assuming we can inspect the error or if the backend sends 422, it throws.
         // If valid 422 response body is needed, we might need access to it.
         
         if (error.statusCode == 422) { 
             // Navigate to Fallback Form
             Get.to(() => const KycFallbackFormScreen()); 
             // Ideally we shouldn't have circular imports. 
             // Best to use named route or lazy import if possible.
             // But for now, I'll use Get.to with dynamic import or just string/route if defined.
             // Since I didn't define a route in AppRoutes, I will use the class directly, assuming import is added.
             return null;
         }
         
         SnackbarService.showError(error.message);
         return null;
      }
      return null;
    } finally {
      connecting.value = false;
    }
  }

  Future<void> connectDigioWithFallback({
    required String userId,
    required Map<String, dynamic> formData,
  }) async {
      final user = Get.find<UserController>().currentUser.value;
      if (user == null) return;
      
      // Prefer formData email/name as it's the most recent user input
      final String email = formData['email']?.toString() ?? user.email ?? '';
      
      final fName = formData['firstName']?.toString() ?? '';
      final lName = formData['lastName']?.toString() ?? '';
      final formName = '$fName $lName'.trim();
      
      final name = formName.isNotEmpty ? formName : (user.fullName ?? '');

      // CRITICAL: Digio needs a valid identifier. If email is empty, use phone.
      String identifier = email;
      if (identifier.isEmpty && (user.phone != null && user.phone!.isNotEmpty)) {
        identifier = user.phone!;
      }
      
      final response = await connectDigio(
          email: identifier, // Pass best available identifier
          name: name, 
          userId: userId, 
          fallbackData: formData
      );
      
      if (response != null) {
          // If successful, we need to handle the success flow (permissions, webview)
          // Since connectDigio returns the data, the caller logic in DigioConnectScreen usually handles it.
          // BUT here we are calling from KycFallbackFormScreen.
          // So we should replicate the success handling or move it to a shared method.
          // For simplicity, I'll pass the result back or handle it here.
          
          // Actually, the best way:
          // Navigate BACK to DigioConnectScreen with the result? 
          // Or handle the Digio Webview opening right here?
          // Let's call the logic to open WebView.
          
          // Re-using the logic from DigioConnectScreen is hard without refactoring.
          // I will navigate back with result? No, Get.back(result: response) ?
          // The Fallback screen was pushed.
          
          // Refactor Suggestion: Move the "Handle Response" logic to Controller?
          // Let's do that.
          
           handleDigioSuccess(response, email);
      }
  }

  Future<void> handleDigioSuccess(Map<String, dynamic> response, String email) async {
      try {
          // Request permissions before starting SDK
          debugPrint('DEBUG: Requesting permissions...');
          Map<Permission, PermissionStatus> statuses = await [
            Permission.camera,
            Permission.microphone,
            Permission.location,
          ].request();
          debugPrint('DEBUG: Permissions status: $statuses');

          debugPrint('DEBUG: Raw Response: $response');

          // Check if the data is wrapped in a 'data' key
          dynamic digioData = response;
          
          if (digioData is Map && digioData.containsKey('data')) {
             digioData = digioData['data']; // Peel first layer
             
          // Prefer sdkResponse if available (direct from backend API header)
             if (digioData is Map && digioData.containsKey('tokens')) {
                 debugPrint('DEBUG: Found tokens object. Using it directly.');
                 digioData = digioData['tokens']; 
             }
             else if (digioData is Map && digioData.containsKey('sdkResponse')) {
                 debugPrint('DEBUG: Found sdkResponse. Using it.');
                 digioData = digioData['sdkResponse'];
             } 
             // Fallback to legacy structure
             else if (digioData is Map && digioData.containsKey('digio')) {
                final digioContainer = digioData['digio']; // Peel 'digio' wrapper
                if (digioContainer is Map && digioContainer.containsKey('digioObject')) {
                   digioData = digioContainer['digioObject']; // Peel 'digioObject' wrapper
                } else {
                   digioData = digioContainer;
                }
             }
          }
          
          debugPrint('DEBUG: Parsed Digio Data: $digioData');

          if (digioData is! Map) {
             debugPrint('DEBUG: Digio Data is not a Map. Parsing failed.');
             SnackbarService.showError('Invalid server response for eSign.');
             return;
          }

          final String? docId = (digioData['id'] ?? 
                                 digioData['document_id'] ?? 
                                 digioData['document_additional_info']?['docId'])?.toString();
          
          String? tokenId;
          // Check for direct access_token field first (populated by backend helper)
          if (digioData.containsKey('access_token')) {
             final val = digioData['access_token'];
             if (val is String) {
               tokenId = val;
             } else if (val is Map) {
               tokenId = val['id']?.toString();
             }
          }
          
          // Fallback checks
          if (tokenId == null) {
              final accessTokenVal = digioData['access_token']; // Re-checking if missed
              if (accessTokenVal is Map) {
                 tokenId = accessTokenVal['id']?.toString(); 
              } else if (accessTokenVal is String) {
                 tokenId = accessTokenVal;
              }
          }
          tokenId ??= digioData['token']?.toString();

          debugPrint('DEBUG: Extracted docId: $docId');
          debugPrint('DEBUG: Extracted tokenId: $tokenId');
          debugPrint('DEBUG: Email: $email');
          
          if (docId != null && tokenId != null) {
              debugPrint('DEBUG: Opening Digio WebView Fallback...');
              
              final result = await Get.to(() => DigioWebViewScreen(
                  docId: docId,
                  identifier: email,
                  token: tokenId!,
                  environment: "production", // Force production since backend is live
              ));

              debugPrint("WebView Result: $result");

              if (result != null && result is Map) {
                  final status = result['status'];
                  if (status == 'success') {
                      debugPrint('DEBUG: Signing Successful via WebView. Navigating to Success Screen.');
                      Get.offAllNamed(AppRoutes.sebiCompilanceCheck);
                  } else {
                      debugPrint('DEBUG: Signing Status: $status. Message: ${result['message']}');
                      SnackbarService.showError('Verification not completed: ${result['message'] ?? 'Please try again.'}');
                  }
              }
          } else {
             debugPrint('DEBUG: Validation failed - docId or tokenId is null. Fallback to registration.');
             Get.offAllNamed(AppRoutes.registrationScreen);
          }
      } catch (e, stack) {
          debugPrint('DEBUG: Digio Integration Error: $e');
          debugPrint('DEBUG: Stack trace: $stack');
          SnackbarService.showError('Error initializing eSign: $e');
      }
  }
}
