import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../core/config/api.config.dart';
import '../core/models/user.dart';
import '../core/routes/app_routes.dart';
import '../services/api_client.service.dart';
import '../services/api_exception.service.dart';
import '../services/secure_storage.service.dart';
import '../services/snackbar.service.dart';
import '../services/notification.service.dart';
import 'user.controller.dart';
import 'segment_plan.controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/validators.dart';
import '../services/cache.service.dart';

class AuthController extends GetxController {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthController({ApiClient? apiClient, SecureStorageService? storage})
    : _apiClient = apiClient ?? ApiClient(),
      _storage = storage ?? SecureStorageService();

  final isFetchingPhoneNumber = false.obs;
  final isLoading = false.obs;
  final isOtpSent = false.obs;
  final currentUser = Rxn<User>();
  final signUpError = RxnString();

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      if (await _storage.isLoggedIn() && await _storage.hasAuthToken()) {
        var userData = await _storage.getUserData();
        
        // Check for 24-hour Session Expiry
        // Check for 24-hour Session Expiry - DISABLED
        // final loginTime = await _storage.getLoginTimestamp();
        // if (loginTime != null) {
        //    final difference = DateTime.now().difference(loginTime);
        //    if (difference.inHours >= 24) {
        //      await _storage.clearAuthData();
        //      SnackbarService.showInfo('Session expired. Please login again.');
        //      Get.offAllNamed(AppRoutes.getStarted); // Or Login depending on flow
        //      return;
        //    }
        // }
        
        // Fallback: If userData is null (GetStorage issue), try to get userId from SharedPreferences
        String? userId;
        if (userData != null) {
           userId = userData['id'] ?? userData['_id'];
        } else {
           userId = await _storage.getUserId();
        }

        if (userId != null) {
           try {
             if (userData != null) {
               currentUser.value = User.fromJson(userData);
             }
             
             // Validate session with backend and get next step
             final response = await _apiClient.get(ApiConfig.getUserDetails(userId));
             if (response.statusCode == 200) {
               final data = response.data['data'];
               final freshUser = data['userDetails'];
               final nextStep = data['nextStep'];
               
               // Update local user data
               await _storage.saveUserData(freshUser);
               // Ensure userId is synced to SharedPreferences
               await _storage.saveUserId(userId); 
               
               currentUser.value = User.fromJson(freshUser);

               // CRITICAL FIX: Sync data to UserController for Profile Screen
               final userController = Get.isRegistered<UserController>()
                   ? Get.find<UserController>()
                   : Get.put(UserController());
               await userController.updateUserFromBackend(freshUser);
               
              
               // Handle Navigation or Offline Fallback
               // CRITICAL: Pass state, nextStep and canSkipRegistration from backend (source of truth)
               final canSkip = data['canSkipRegistration'] as bool? ?? true;
               final state = data['state'] as String?;
               await handlePostLoginNavigation(nextStep, rejectionReason: data['rejectionReason'], canSkipRegistration: canSkip, state: state);

               
               // CRITICAL: Clean Cache on Session Start/Login
               CacheService.to.clearAllCache();

               // Check if there is a pending notification payload to consume
               WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    final notificationService = Get.find<NotificationService>(); // Ensure NotificationService is registered
                    if(notificationService.pendingPayload != null) {
                       notificationService.consumePendingPayload(); 
                    }
                  } catch(e) { /* Ignore if service not found */ }
               });

               return;
             }
           } catch (e) {
             // Only force logout if specifically 401 or Critical Auth Error
             if (e is DioException && e.response?.statusCode == 401) {
               SnackbarService.showError('Session expired. Please login again.');
               await _storage.clearAuthData();
               _safeRedirectToGetStarted();
             } else {
               // Show the error (e.g. User Suspended, Network Error)
               if (e is DioException && e.response?.statusCode == 403) {
                  SnackbarService.showErrorFromException(e);
                  await _storage.clearAuthData();
                  _safeRedirectToGetStarted();
                  return;
               }

               // Don't show error if we are going to fallback to offline dashboard, to avoid noise
               // But if we are stuck, show it.
               if (currentUser.value == null) {
                  SnackbarService.showErrorFromException(e);
               }
               
               // Network Error / Server Error -> Allow Offline Access / Dashboard
               // Don't clear auth data.
               
               if (currentUser.value != null && 
                   (currentUser.value!.registrationStatus == 'ACTIVE' || 
                   currentUser.value!.registrationStatus == 'COMPLETE')) {
                   
                    Get.offAllNamed(AppRoutes.tabs);
                    
                    // Check pending payload for offline cold start
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                       try {
                         final notificationService = Get.find<NotificationService>();
                         notificationService.consumePendingPayload();
                       } catch(e) { 
                         // Ignored
                       }
                    });
               } else {
                   // If we don't have user data and api failed, we can't do much but go to login or tabs
                   Get.offAllNamed(AppRoutes.tabs);
               }
             }
             return;
           }
        }
      }
      _safeRedirectToGetStarted();
    } catch (e) {
      Get.log('Error checking auth status: $e');
      _safeRedirectToGetStarted();
    }
  }

  void _safeRedirectToGetStarted() {
    final currentRoute = Get.currentRoute;
    if (currentRoute != AppRoutes.login &&
        currentRoute != AppRoutes.signup &&
        currentRoute != AppRoutes.createAccount &&
        currentRoute != AppRoutes.getStarted &&
        currentRoute != AppRoutes.otpVerification &&
        currentRoute != AppRoutes.forgotMpin &&
        currentRoute != AppRoutes.kycDocumentUpload &&
        currentRoute != AppRoutes.setMpin) {
       Get.offAllNamed(AppRoutes.getStarted);
    }
  }

  Future<bool> sendOtp(String phone) async {
    try {
      isLoading.value = true;

      final response = await _apiClient.post(
        ApiConfig.sendOtp,
        data: {'phone': '+91$phone'},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['message'] == 'User not exist') {
          SnackbarService.showError('User not found. Please sign up first.');
          return false;
        }
        isOtpSent.value = true;
        SnackbarService.showSuccess('OTP sent to your phone');
        return true;
      }
      return false;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    try {
      isLoading.value = true;

      final response = await _apiClient.post(
        ApiConfig.verifyOtp,
        data: {'otp': int.tryParse(otp) ?? otp},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['message'] == 'User not exist' ||
            data['message'] == 'OTP Invalid') {
          SnackbarService.showError(data['message']);
          return false;
        }
        final phone = data['data']?['phone'];
        if (phone != null) {
          final existingData = await _storage.getUserData();
          await _storage.saveUserData({...?existingData, 'phone': phone});
        }
        SnackbarService.showSuccess('OTP verified successfully');
        return true;
      }
      return false;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createUser({
    required String fullName,
    required String phone,
    String? email,
  }) async {
    try {
      debugPrint(
        'DEBUG: createUser called with name: $fullName, phone: $phone, email: $email',
      );
      isLoading.value = true;
      final response = await _apiClient.post(
        ApiConfig.createUser,
        data: {
          'fullName': fullName,
          'phone': '+91$phone',
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      debugPrint('DEBUG: createUser response status: ${response.statusCode}');
      debugPrint('DEBUG: createUser response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final message = data['message'] ?? '';

        if (message.contains('already exist')) {
          SnackbarService.showWarning(
            'User already exists. Please login to continue',
          );
          return false;
        }

        final userData = data['data']?['user'];
        if (userData != null) {
          final userId = userData['_id'];
          await _storage.saveUserData({
            'userId': userId,
            'fullName': fullName,
            'phone': phone,
            if (email != null && email.isNotEmpty) 'email': email,
          });
          if (userId != null) {
             await _storage.saveUserId(userId);
          }
          SnackbarService.showSuccess('OTP sent successfully!');
          return true;
        }

        SnackbarService.showError(
          'Failed to create account. Please try again.',
        );
        return false;
      } else {
        SnackbarService.showError('Server error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signUp({
    required String userId,
    required String pan,
    required String dob,
    required String aadhaarNumber,
    String userType = 'user',
  }) async {
    try {
      isLoading.value = true;
      signUpError.value = null;

      int? aadhaarInt;
      if (aadhaarNumber.isNotEmpty) {
        aadhaarInt = int.tryParse(Validators.cleanAadhar(aadhaarNumber));
        if (aadhaarInt == null) {
          SnackbarService.showError('Invalid Aadhaar number');
          return false;
        }
      }

      final body = <String, dynamic>{
        'pan': Validators.formatPAN(pan),
        'dob': Validators.normalizeDob(dob),
        'userType': userType,
      };

      if (aadhaarInt != null) {
        body['aadhaarNumber'] = aadhaarInt;
      }

      final response = await _apiClient.put(
        ApiConfig.signUp(userId),
        data: body,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final message = data['message'] ?? '';

        if (message.contains('signed up successfully')) {
          final userData = data['data']?['existUser'];
          if (userData != null) {
            // Save the full user object and update UserController
            final userController = Get.isRegistered<UserController>()
                ? Get.find<UserController>()
                : Get.put(UserController());
            await userController.updateUserFromBackend(userData);
            
            // Ensure userId is saved
            final uid = userData['_id'] ?? userData['id'];
            if(uid != null) await _storage.saveUserId(uid);

            SnackbarService.showSuccess('KYC completed successfully');
            return true;
          }
        }

        SnackbarService.showError('Signup failed');
        return false;
      }
      return false;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      final msg = error.message.toLowerCase();

      if (msg.contains('invalid pan') || msg.contains('invalid dob')) {
        signUpError.value = 'Invalid PAN or Date of Birth. Please check and try again.';
        SnackbarService.showError(signUpError.value!);
      } else if (msg.contains('no phone number')) {
        signUpError.value = 'No phone number found in KYC records. Please contact support.';
        SnackbarService.showError(signUpError.value!);
      } else if (msg.contains('already registered') || msg.contains('pan card is already')) {
        signUpError.value = error.message;
        SnackbarService.showError(error.message);
      } else {
        signUpError.value = error.message;
        SnackbarService.showError(error.message);
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({
    String? email,
    String? phone,
    required String mPin,
  }) async {
    try {
      isLoading.value = true;

      final requestData = {'mPin': mPin.toString()};
      if (email != null) requestData['email'] = email;
      if (phone != null) requestData['phone'] = '+91$phone';

      try {
        if (Platform.isIOS) {
          requestData['platform'] = 'ios';
        } else if (Platform.isAndroid) {
          requestData['platform'] = 'android';
        }
      } catch (_) {}

      // Add device ID to request body for single-device enforcement
      try {
        final notificationService = Get.isRegistered<NotificationService>()
            ? Get.find<NotificationService>()
            : null;
        if (notificationService != null) {
          final deviceId = await notificationService.getOrCreateDeviceId();
          requestData['deviceId'] = deviceId;
        }
      } catch (e) {
        Get.log('Error getting device ID for login: $e');
      }

      final response = await _apiClient.post(
        ApiConfig.login,
        data: requestData,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['message'] == 'Invalid credentials') {
          SnackbarService.showError('Invalid credentials');
          return false;
        }
        final token = data['data']?['token'];
        final refreshToken = data['data']?['refreshToken']; // New Field
        final userData = data['data']?['user'];

        if (token != null && userData != null) {
          await _storage.saveAuthToken(token);
          if (refreshToken != null) {
            await _storage.saveRefreshToken(refreshToken);
          }
          await _storage.setLoggedIn(true);
          await _storage.saveLoginTimestamp();
          
          final userController = Get.isRegistered<UserController>()
              ? Get.find<UserController>()
              : Get.put(UserController());
          await userController.updateUserFromBackend(userData);

          // Save UserID explicitly to SharedPreferences for robust restoration
          final userId = userData['_id'] ?? userData['id'];
          if (userId != null) {
             await _storage.saveUserId(userId);
          }
          
          // Sync AuthController's user with UserController
          currentUser.value = userController.currentUser.value;

          // REGISTER DEVICE (Link device to user)
          if(Get.isRegistered<NotificationService>() && currentUser.value != null) {
              await Get.find<NotificationService>().registerDevice(userId: currentUser.value!.id);
          }

          if (Get.isRegistered<SegmentPlanController>()) {
            Get.find<SegmentPlanController>().fetchActiveSegment();
          }

           // Handle Dynamic Navigation
           final nextStep = data['data']?['nextStep'];
           final state = data['data']?['state'];
           final rejectionReason = data['data']?['rejectionReason'];
           // CRITICAL: Use backend's canSkipRegistration, not local flag
           final canSkip = data['data']?['canSkipRegistration'] as bool? ?? true;
           await handlePostLoginNavigation(nextStep, rejectionReason: rejectionReason, canSkipRegistration: canSkip, state: state);


           // CRITICAL: Clean Cache on successful login
           CacheService.to.clearAllCache();

           return true; // Navigation handled
        }
        return true;
      }
      return false;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handlePostLoginNavigation(String? nextStep, {String? rejectionReason, bool canSkipRegistration = true, String? state}) async {


    void showKycRejectionDialog(String title, String message, String route) {
      Get.defaultDialog(
        title: title,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        middleText: message,
        middleTextStyle: const TextStyle(fontSize: 14),
        barrierDismissible: false,
        onConfirm: () {
          Get.back(); // close dialog
          Get.offAllNamed(route);
        },
        textConfirm: 'Update Now',
        confirmTextColor: Colors.white,
        buttonColor: Get.theme.primaryColor,
      );
    }


    void navigateToTabs() {
       // Prevent unexpected redirects if we are already deep in the application
       // caused by AuthController re-initialization (fenix: true).
       final currentRoute = Get.currentRoute;
       final isSafeToRedirect = 
          currentRoute == AppRoutes.splash ||
          currentRoute == AppRoutes.getStarted ||
          currentRoute == AppRoutes.login ||
          currentRoute == AppRoutes.signup ||
          currentRoute == AppRoutes.createAccount ||
          currentRoute == AppRoutes.otpVerification ||
          currentRoute == AppRoutes.forgotMpin ||
          currentRoute == AppRoutes.setMpin ||
          currentRoute == AppRoutes.kycDocumentUpload ||
          currentRoute == AppRoutes.digioConnect ||
          currentRoute == AppRoutes.videoKycIntro ||
          currentRoute == AppRoutes.registrationScreen ||
          currentRoute == AppRoutes.bankTransferUpload ||
          currentRoute == AppRoutes.sebiCompilanceCheck;

      if (!isSafeToRedirect) {
        Get.log('Already on authenticated route ($currentRoute). Skipping redirect to Tabs.');
        return;
      }

      Get.offAllNamed(AppRoutes.tabs);
      // Requirement: Deferred Navigation.
      // If we are landing on Dashboard (authenticated), check if we have a pending notification click 
      // that initiated this flow (e.g. from a cold start with expired session).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (Get.isRegistered<NotificationService>()) {
             Get.find<NotificationService>().consumePendingPayload();
          }
        } catch (_) {}
      });
    }

    // Determine the primary router code (favoring 'state' if present)
    final routerCode = state ?? nextStep;

    if (routerCode == null) {
      navigateToTabs();
      return;
    }

    switch (routerCode) {
      case 'RESET_MPIN':
        Get.offAllNamed(AppRoutes.setMpin);
        break;
      
      case 'SET_MPIN':
        Get.offAllNamed(AppRoutes.setMpin);
        break;

      case 'KYC_DETAILS':
         Get.offAllNamed(AppRoutes.signup);
         break;

      case 'KYC_DOCUMENT_UPLOAD':
         Get.offAllNamed(AppRoutes.kycDocumentUpload);
         break;

      case 'SEBI_COMPLIANCE_CHECK':
        Get.offAllNamed(AppRoutes.sebiCompilanceCheck);
        break;

      case 'DIGIO_ESIGN_FLOW':
        Get.offAllNamed(AppRoutes.digioConnect); 
        break;

      case 'KYC_IN_REVIEW':
        // Allow access but UI should show "Pending" status
        navigateToTabs();

        break;
      
      case 'KYC_DOCUMENT_REJECTED':
        if (Get.currentRoute != AppRoutes.kycDocumentUpload && Get.currentRoute != AppRoutes.signup) {
          showKycRejectionDialog(
            'Documents Rejected',
            rejectionReason ?? 'Your KYC documents were rejected. Please re-upload.',
            AppRoutes.kycDocumentUpload,
          );
        }
        break;

      case 'DIGIO_ESIGN_REJECTED':
        if (Get.currentRoute != AppRoutes.digioConnect) {
          showKycRejectionDialog(
            'E-Sign Rejected',
            rejectionReason ?? 'Your service agreement was rejected. Please re-sign.',
            AppRoutes.digioConnect,
          );
        }
        break;

      case 'VIDEO_KYC_REJECTED':
        if (Get.currentRoute != AppRoutes.videoKycIntro && Get.currentRoute != AppRoutes.videoRecorder) {
          showKycRejectionDialog(
            'Video KYC Rejected',
            rejectionReason ?? 'Your Video KYC was rejected. Please re-record.',
            AppRoutes.videoKycIntro,
          );
        }
        break;

      case 'KYC_RETRY':
      case 'KYC_REJECTED':
        // Legacy generic fallback
        Get.offAllNamed(AppRoutes.signup); // Redirect to signup to re-enter details if rejected
        SnackbarService.showError(rejectionReason ?? 'Your KYC was rejected. Please review and resubmit.');
        break;

      case 'VIDEO_RECORDER':
        // Route through the intro screen (permission gatekeeper) instead of
        // jumping directly to the recorder. This ensures mic/camera are always
        // validated before recording starts, regardless of how this state is reached.
        if (Get.currentRoute != AppRoutes.videoKycIntro && Get.currentRoute != AppRoutes.videoRecorder) {
          Get.offAllNamed(AppRoutes.videoKycIntro);
        }
        break;

      case 'VIDEO_KYC_INTRO':
      case 'VIDEO_KYC_DISCLAIMER': // Legacy support
        Get.offAllNamed(AppRoutes.videoKycIntro);
        break;

      case 'REGISTRATION_REQUIRED': // New unified state
      case 'REGISTRATION_PAYMENT':
      case 'REGISTRATION_FEES':
        if (Platform.isIOS) {
          navigateToTabs();
        } else {
          // BACKEND IS THE SOURCE OF TRUTH.
          // However, if the user explicitly tapped "Skip for now" locally, we must
          // respect their session choice so they aren't trapped in a redirect loop.
          bool isSkippedLocally = await _storage.isRegistrationSkipped();
          if (!isSkippedLocally) {
             try {
                isSkippedLocally = Get.isRegistered<UserController>() 
                   ? Get.find<UserController>().isRegistrationSkipped.value 
                   : false;
             } catch (_) {}
          }

          if (canSkipRegistration || isSkippedLocally) {
            Get.log('Auth: Allowed registration skip (backend: $canSkipRegistration, local: $isSkippedLocally). Going to Dashboard.');
            navigateToTabs();
          } else {
            // Backend says: User MUST register, and they haven't skipped yet. Send them to the registration screen.
            // We also check for pending partial payments (bank transfer in progress).
            bool hasPending = false;
            if (Get.isRegistered<SegmentPlanController>()) {
               final segCtrl = Get.find<SegmentPlanController>();
               if (segCtrl.activePartialInfo.value != null &&
                   (segCtrl.activePartialInfo.value!['purchaseType'] == 'REGISTRATION' ||
                    segCtrl.activePartialInfo.value!['purchase_type'] == 'REGISTRATION')) {
                  hasPending = true;
               }
            }

            if (hasPending) {
              Get.log('Auth: Pending registration payment detected. Allowing Dashboard entry.');
              navigateToTabs();
            } else if (Get.currentRoute != AppRoutes.bankTransferUpload) {
              Get.offAllNamed(AppRoutes.registrationScreen);
            }
          }
        }
        break;
      case 'HOME':           // New unified state
      case 'HOME_LIMITED':   // New unified state
      case 'HOME_SUSPENDED': // New unified state
      case 'DASHBOARD_LIMITED': // iOS Access Only Mode
      case 'DASHBOARD':
      default:
        navigateToTabs();
        break;
    }
  }


  Future<bool> hasActiveSubscription({bool forceRefresh = false}) async {
    try {
      final cached = forceRefresh
          ? null
          : await _storage.getCachedSubscriptionStatus();

      if (cached == true && !forceRefresh) {
        return true;
      }

      final userId = await _storage.getUserId();

      if (userId == null) {
        if (currentUser.value?.id != null && currentUser.value!.id.isNotEmpty) {
        } else {
          return false;
        }
      }

      final idToUse = userId ?? currentUser.value!.id;
      final response = await _apiClient.get(ApiConfig.getUserPlan(idToUse));

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final planData = data?['activePlan'];

        bool planIsActive(Map<String, dynamic>? planJson) {
          if (planJson == null) {
            return false;
          }

          final rawStatus = planJson['status'].toString().toLowerCase();
          final isActiveFlag = rawStatus == 'active';
          final endDateValue = planJson['endDate'] ?? planJson['expiryDate'];

          final expiry = endDateValue != null
              ? DateTime.tryParse(endDateValue.toString())
              : null;

          final isNotExpired = expiry == null || expiry.isAfter(DateTime.now());

          return isActiveFlag && isNotExpired;
        }

        if (planIsActive(planData)) {
          await _storage.cacheSubscriptionStatus(true);
          return true;
        }

        await _storage.cacheSubscriptionStatus(false);
        return false;
      }

      return cached ?? false;
    } catch (e) {
      final cached = await _storage.getCachedSubscriptionStatus();
      return cached ?? false;
    }
  }

  Future<String?> setMpin(String phone, String mPin) async {
    try {
      isLoading.value = true;
      final response = await _apiClient.post(
        ApiConfig.setMpin,
        data: {'phone': '+91$phone', 'mPin': mPin.toString()},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['message'] == 'User not exist') {
          SnackbarService.showError('User not found');
          return null;
        }
        final token = data['data']?['token'];
        final refreshToken = data['data']?['refreshToken'];
        final userData = data['data']?['user'];
        final nextStep = data['data']?['nextStep'];

        if (token != null && userData != null) {
          await _storage.saveAuthToken(token);
          if (refreshToken != null) {
             await _storage.saveRefreshToken(refreshToken);
          }
          await _storage.setLoggedIn(true);
          await _storage.saveLoginTimestamp();

          final userController = Get.isRegistered<UserController>()
              ? Get.find<UserController>()
              : Get.put(UserController());
          await userController.updateUserFromBackend(userData);

          if (Get.isRegistered<SegmentPlanController>()) {
            Get.find<SegmentPlanController>().fetchActiveSegment();
          }
        }
        SnackbarService.showSuccess('MPIN set successfully');
        return nextStep;
      }
      return null;
    } catch (e) {
      final error = ApiErrorHandler.handleError(e);
      SnackbarService.showError(error.message);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout({String? redirectTo}) async {
    try {
      isLoading.value = true;
      
      // UNLINK DEVICE (Remove user association but keep anonymous token)
      if(Get.isRegistered<NotificationService>()) {
         await Get.find<NotificationService>().unlinkDevice();
      }

      await _apiClient.post(ApiConfig.logout);
      await _storage.clearAuthData();
      currentUser.value = null;
      isOtpSent.value = false;

      // Clean Cache on Logout
      CacheService.to.clearAllCache();

      if (Get.isRegistered<UserController>()) {
        Get.find<UserController>().currentUser.value = null;
      }
      SnackbarService.showSuccess('Logged out successfully');
      Get.offAllNamed(redirectTo ?? AppRoutes.getStarted);
    } catch (e) {
      await _storage.clearAuthData();
      currentUser.value = null;
      Get.offAllNamed(redirectTo ?? AppRoutes.getStarted);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> acceptTradingDisclaimer(String version) async {
    try {
      isLoading.value = true;
      final response = await _apiClient.post(
        ApiConfig.acceptDisclaimer,
        data: {
          'version': version,
          // 'ip': '...', // Ideally pass device IP if needed 
        },
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
       final error = ApiErrorHandler.handleError(e);
       SnackbarService.showError(error.message);
       return false;
    } finally {
      isLoading.value = false;
    }
  }

  void resetOtpState() {
    isOtpSent.value = false;
  }

  void showSuspensionDialog() {
    final user = currentUser.value;
    if (user == null || user.userStatus != 'SUSPENDED') return;

    final reason = user.suspensionReason ?? 'No reason provided.';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Account Suspended',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your account has been suspended. Please contact admin for assistance.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suspension Reason:',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Text(
                reason,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppTheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can continue to surf the app, but subscription and call features are restricted.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'DISMISS',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
