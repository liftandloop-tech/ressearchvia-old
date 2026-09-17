import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/research_activity.model.dart';
import '../../services/api.service.dart';
import '../../config/routes.config.dart';
import '../../config/theme.config.dart';
import '../auth/auth.controller.dart';

class ResearchNotificationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  final isProceeding = false.obs;
  final recentActivities = <ResearchActivityModel>[].obs;
  final latestProceedingActivity = Rxn<ResearchActivityModel>();
  final unreadCount = 0.obs;

  Timer? _pollingTimer;
  int _lastSeenTimestamp = 0;
  bool _isInitialFetch = true;

  @override
  void onInit() {
    super.onInit();
    fetchLiveActivities(initial: true);
    _startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Check every 5 seconds for live research activities
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchLiveActivities();
    });
  }

  Future<void> fetchLiveActivities({bool initial = false}) async {
    try {
      // Only proceed if staff/user is authenticated
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        if (!authController.isAuthenticated.value) return;
      }

      final response = await _apiService.get(
        '/reports/live-activities',
        forceRefresh: true,
      );

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body['data'];
        if (data == null) return;

        final proceedingFlag = data['isProceeding'] == true;
        isProceeding.value = proceedingFlag;

        final rawList = (data['activities'] as List<dynamic>?) ?? [];
        final parsed = rawList
            .map((item) => ResearchActivityModel.fromJson(item as Map<String, dynamic>))
            .toList();

        recentActivities.assignAll(parsed);

        final latestTimestamp = data['latestTimestamp'] is int
            ? data['latestTimestamp'] as int
            : int.tryParse(data['latestTimestamp']?.toString() ?? '0') ?? 0;

        if (initial || _isInitialFetch) {
          _lastSeenTimestamp = latestTimestamp;
          _isInitialFetch = false;
          return;
        }

        // Automatic trigger: the exact moment any research is created or updated
        if (latestTimestamp > _lastSeenTimestamp && parsed.isNotEmpty) {
          _lastSeenTimestamp = latestTimestamp;
          final latest = parsed.firstWhere(
            (a) => a.timestamp == latestTimestamp,
            orElse: () => parsed.first,
          );
          latestProceedingActivity.value = latest;
          unreadCount.value++;
          debugPrint('ResearchNotificationController: Triggering live notification for ${latest.title} (timestamp: $latestTimestamp)');

          // AUTOMATICALLY display notification popup on staff panel
          _showAutomaticPopup(latest);
        }
      }
    } catch (e) {
      debugPrint('Error fetching live research activities: $e');
    }
  }

  void markAllAsRead() {
    unreadCount.value = 0;
  }

  void _showAutomaticPopup(ResearchActivityModel activity) {
    final isUpdate = activity.latestUpdate != null && activity.latestUpdate!.isNotEmpty;

    // Dismiss any previously open snackbar so notifications don't overlap
    Get.closeCurrentSnackbar();

    Get.rawSnackbar(
      titleText: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUpdate ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isUpdate ? 'RESEARCH UPDATED' : 'NEW RESEARCH CALL',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (activity.segmentName.isNotEmpty) ...[
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(maxWidth: 120),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                activity.segmentName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          const SizedBox(width: 8),
          // Top-right explicit manual close button
          InkWell(
            onTap: () {
              Get.closeCurrentSnackbar();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Research Description Section
          if (activity.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESEARCH DESCRIPTION:',
                    style: TextStyle(
                      color: Color(0xFF93C5FD), // Light blue label
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],

          // 2. What Has Updated Section
          if (isUpdate) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_rounded, size: 16, color: Color(0xFFFBBF24)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WHAT WAS UPDATED:',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity.latestUpdate!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Type: ${activity.reportType}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Explicit Dismiss Button for Staff
                  InkWell(
                    onTap: () {
                      Get.closeCurrentSnackbar();
                    },
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 12, color: Colors.white70),
                          SizedBox(width: 4),
                          Text(
                            'Dismiss',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Primary View in Reports Button
                  InkWell(
                    onTap: () {
                      Get.closeCurrentSnackbar();
                      Get.toNamed(AppRoutes.reports);
                    },
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View in Reports',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0F172A),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.only(top: 16, right: 24, left: 280),
      borderRadius: 12,
      duration: null, // null = NO auto-close timer. Persists indefinitely until staff manually closes it
      isDismissible: false,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeIn,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isUpdate
              ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
              : const Color(0xFF10B981).withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isUpdate ? Icons.update_rounded : Icons.candlestick_chart_rounded,
          color: isUpdate ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          size: 26,
        ),
      ),
    );
  }
}
