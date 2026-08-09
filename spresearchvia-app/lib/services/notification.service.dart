import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../controllers/report.controller.dart';
import '../core/theme/app_theme.dart';
import '../core/routes/app_routes.dart';
import '../screens/tabs.screen.dart';
import '../services/api_client.service.dart';
import '../core/config/api.config.dart';
import 'secure_storage.service.dart';
import 'snackbar.service.dart';
import 'dart:developer';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('Handling a background message ${message.messageId}');
}


class NotificationService extends GetxService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Map<String, dynamic>? pendingPayload;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Request permissions
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true, // For iOS Critical Alerts (needs entitlement)
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Get.log('User granted permission');
      } else {
        Get.log('User declined or has not accepted permission');
        return;
      }

      // Initialize Local Notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Setup Notification Channels for Android
      // 1. Critical / Trading Calls
      const highChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'Trading Calls',
        description: 'Critical notifications for Buy/Sell calls.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // 2. Standard / Reports
      const defaultChannel = AndroidNotificationChannel(
        'default_channel',
        'Trading Reports',
        description: 'Standard notifications for daily reports.',
        importance: Importance.defaultImportance,
        playSound: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(highChannel);
      await androidPlugin?.createNotificationChannel(defaultChannel);

      // Get FCM Token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _updateToken(token);
      }

      // Listen for Token Refresh
      FirebaseMessaging.instance.onTokenRefresh.listen(_updateToken);

      // Background Message Handler (Top Level)
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        Get.log('Got a message whilst in the foreground!');
        Get.log('Message data: ${message.data}');

        if (message.notification != null) {
          // Requirement: IN-APP REAL-TIME ALERTS (Top banner / toast)
          // No push duplication when app is foregrounded.
          _showInAppNotification(message);
        }
      });

      // Background Message Open Handler
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      // Terminated State Open Handler
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        // Store payload for later consumption after App/Auth init
        pendingPayload = initialMessage.data;
      }

      _isInitialized = true;
      
      // Register Device on Startup
      _blindRegister();
    } catch (e) {
      Get.log('Error initializing NotificationService: $e');
    }
  }

  void consumePendingPayload() {
    if (pendingPayload != null) {
      Get.log('Consuming pending notification payload: $pendingPayload');
      _handleNavigation(pendingPayload!);
      pendingPayload = null;
    }
  }

  final ApiClient _apiClient = ApiClient();

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('device_id', deviceId);
      Get.log('Generated new device ID: $deviceId');
    }
    
    return deviceId;
  }

  Future<void> registerDevice({String? userId}) async {
    try {
      final deviceId = await getOrCreateDeviceId();
      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken == null) return;

      final data = {
        'deviceId': deviceId,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'pushToken': fcmToken,
        if (userId != null) 'userId': userId,
      };

      await _apiClient.post(ApiConfig.registerDevice, data: data);
      Get.log('Device registered successfully: $deviceId');
    } catch (e) {
      Get.log('Error registering device: $e');
    }
  }

  Future<void> unlinkDevice() async {
    try {
      final deviceId = await getOrCreateDeviceId();
      await _apiClient.post(
        ApiConfig.unlinkDevice,
        data: {'deviceId': deviceId},
      );
      Get.log('Device unlinked successfully: $deviceId');
    } catch (e) {
      Get.log('Error unlinking device: $e');
    }
  }

  void _updateToken(String token) {
    Get.log('FCM Token Helper: $token');
    // Register device with new token (anonymous or linked depends on caller, 
    // but here we just refresh token. Ideally we check if logged in to pass ID,
    // but registerDevice handles token upsert primarily. 
    // To be safe, if we have a user in memory, pass it.
    // However, getting user from controller might be safe here.)
    
    // We will call registerDevice without userId for token refresh background events
    // unless we can easily grab it. AuthController/SecureStorage is source of truth.
    // Let's try to get userId from SecureStorage if possible.
    
    _blindRegister();
  }

  Future<void> _blindRegister() async {
     // Helper to register with potential user ID
     String? userId;
     try {
       final storage = SecureStorageService();
       if (await storage.hasAuthToken()) {
         userId = await storage.getUserId();
       }
     } catch (_) {}
     
     await registerDevice(userId: userId);
  }

  // Handle Foreground In-App Alert
  void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    final isTradingCall = data['type'] == 'TRADING_CALL';

    SnackbarService.show(
      notification.body ?? '',
      title: notification.title ?? 'Notification',
      backgroundColor: isTradingCall ? AppTheme.backgroundWhite : Colors.white,
      duration: const Duration(seconds: 4),
      icon: isTradingCall ? Icons.trending_up : Icons.article,
      actionTitle: 'VIEW',
      actionOnTap: () => _handleNavigation(data),
      onTap: () => _handleNavigation(data),
    );
  }



  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      // Parse payload string -> json
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    Get.log('Notification opened app: ${message.data}');
    _handleNavigation(message.data);
  }

  void _handleNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final reportId = data['reportId'];

    if (reportId != null) {
      // 1. Ensure we are on the Tabs Screen
      // Navigate to Tabs Screen with 'Research' tab selected (Index 1 of Main Tabs)
      if (Get.currentRoute != AppRoutes.tabs) {
         Get.offAllNamed(AppRoutes.tabs, arguments: 1);
      } else {
         // Already on Tabs, use TabsController if accessible, or force update
         // Since TabsScreen listens to Get.arguments only on build, direct controller access is preferred
         try {
            final tabsController = Get.find<TabsController>(); // TabsController must be exported/available
            if(true) {
                tabsController.changeTab(1);
            }
         } catch(e) {
            // If controller not found (rare), force reload
            Get.offAllNamed(AppRoutes.tabs, arguments: 1);
         }
      }

      // 2. Select the correct Sub-Tab (Trading Calls vs Reports) in ResearchReportsScreen
      // This is handled via ReportController which ResearchReportsScreen listens to
      final reportController = Get.put(ReportController());
      
      if (type == 'TRADING_CALL') {
        reportController.selectedTabIndex.value = 0; // Trading Calls (Tab 0)
        reportController.fetchTradingCalls(refresh: true);
      } else {
        reportController.selectedTabIndex.value = 1; // Research Reports (Tab 1)
        reportController.fetchReportList(refresh: true);
      }
      
      // Safety delay to ensure UI mounting if navigation occurred
      Future.delayed(const Duration(milliseconds: 300), () {
          if (type == 'TRADING_CALL') {
            reportController.selectedTabIndex.value = 0;
            reportController.fetchTradingCalls(refresh: true);
          } else {
            reportController.selectedTabIndex.value = 1;
            reportController.fetchReportList(refresh: true);
          }
      });
    }
  }
}
