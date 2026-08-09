import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../controllers/auth.controller.dart';
import '../../widgets/button.dart';
import '../../controllers/digio.controller.dart';
import '../../controllers/user.controller.dart';
import '../../services/snackbar.service.dart';
import '../../services/secure_storage.service.dart';
import '../../core/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'digio_webview_screen.dart';
import 'kyc_fallback_form_screen.dart';
import 'video_kyc_intro.screen.dart';

class DigioConnectScreen extends StatelessWidget {
  const DigioConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final digioController = Get.isRegistered<DigioController>() 
        ? Get.find<DigioController>() 
        : Get.put(DigioController());
    final userController = Get.find<UserController>();



    Future<void> onConnect() async {
      var user = userController.currentUser.value;
      var uid = await userController.userId;

      final storage = SecureStorageService();

      if (user == null || uid == null) {
        final storedUserData = await storage.getUserData();
        final storedUid = await storage.getUserId();

        if (user == null &&
            storedUserData != null &&
            storedUserData.isNotEmpty) {
          final merged = Map<String, dynamic>.from(storedUserData);
          if ((merged['_id'] == null && merged['id'] == null) &&
              merged['userId'] != null) {
            merged['_id'] = merged['userId'];
          }
          try {
            user = User.fromJson(merged);
          } catch (e) {
            if (kDebugMode) debugPrint('Failed to parse stored userData: $e');
          }
        }
        uid ??= storedUid;
      }

      // Check KRA Response Validity
      final userObject = user?.userObject;
      bool isKraValid = false;

      if (userObject != null) {
        final hasError = userObject.containsKey('error_code') ||
            userObject.containsKey('error_message');

        final hasResDtls = userObject['resdtls'] != null &&
            userObject['resdtls'].toString().isNotEmpty;

        final startPan = userObject['APP_PAN_NO']?.toString();
        // Fallback checks for essential fields that KRA is supposed to return
        // Ideally, Digio needs at least Name and Address to generate the document
        // But our fallback form is precisely for when these are missing.
        
        final hasName = (userObject['APP_NAME']?.toString().isNotEmpty ?? false);
        final hasAddress = (userObject['APP_COR_ADD1']?.toString().isNotEmpty ?? false);
        
        // Revised Logic:
        // Valid ONLY if: No Error AND Has Name AND Has Address.
        // Previously we just checked Name OR ResDtls. That's too loose.
        
        if (!hasError && hasName && hasAddress) {
          isKraValid = true;
        }
      }

      if (!isKraValid) {
        Get.to(() => const KycFallbackFormScreen());
        return;
      }

      if (user == null || uid == null) {
        SnackbarService.showWarning('User not logged in');
        return;
      }

      final name = user.fullName ?? user.name;

      var email = user.email;
      if (email == null || email.isEmpty) {
        final storedUserData = await storage.getUserData();
        email = storedUserData?['email'] as String?;
      }

      debugPrint('DEBUG: DigioConnectScreen - Found email: $email');

      if (email == null || email.isEmpty) {
        SnackbarService.showWarning('Email not available');
        return;
      }

      if (name.isEmpty) {
        SnackbarService.showWarning('Name not available');
        return;
      }

      final response = await digioController.connectDigio(
        email: email,
        name: name,
        userId: uid,
      );

      if (response != null) {
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
          // Structure can be: { data: { sdkResponse: { ... }, digio: { ... } } }
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
                  identifier: email!,
                  token: tokenId!,
                  environment: "production", // Reverting to Production as per .env keys
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

    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xff111827),
            size: 18,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'SEBI Verification',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffE5E7EB)),
                  boxShadow: const [
                    BoxShadow(
                      offset: Offset(0, 6),
                      blurRadius: 20,
                      color: Color.fromARGB(25, 17, 65, 107),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xffF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/digio.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connect Digio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        color: Color(0xff0B2B4A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect Digio for secure\nverification of your identity\ndocuments',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Color(0xff6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _point(
                      icon: Icons.check_circle,
                      color: const Color(0xff10B981),
                      text: 'Instant document verification',
                    ),
                    _point(
                      icon: Icons.check_circle,
                      color: const Color(0xff10B981),
                      text: 'Government-verified documents',
                    ),
                    _point(
                      icon: Icons.check_circle,
                      color: const Color(0xff10B981),
                      text: 'No physical document upload\nneeded',
                      multiline: true,
                    ),

                    const SizedBox(height: 16),

                    Obx(
                      () => Button(
                        title: 'Continue',
                        icon: Icons.arrow_forward,
                        buttonType: ButtonType.green,
                        onTap: digioController.connecting.value
                            ? null
                            : onConnect,
                        showLoading: digioController.connecting.value,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield, color: Color(0xff9CA3AF)),
                  SizedBox(width: 10),
                  Text(
                    'Your data is encrypted & safe',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xff9CA3AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Protected by 256-bit SSL encryption',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xff9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _point({
    required IconData icon,
    required Color color,
    required String text,
    bool multiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xff374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
