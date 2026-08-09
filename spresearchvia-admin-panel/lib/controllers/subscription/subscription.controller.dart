import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/models/subscription_plan.model.dart';
import 'package:spresearch_web/models/segment.model.dart';
import 'package:spresearch_web/services/subscription.service.dart';

class SubscriptionController extends GetxController {
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();

  final selectedStatus = 'All Status'.obs;
  final searchController = TextEditingController();

  final plansCurrentPage = 1.obs;
  final plansItemsPerPage = 10;
  final segmentsCurrentPage = 1.obs;
  final segmentsItemsPerPage = 10;

  final plans = <SubscriptionPlanModel>[].obs;
  final totalPlansCount = 0.obs;
  final isLoadingPlans = false.obs;

  final segments = <SegmentModel>[].obs;
  final isLoadingSegments = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
    fetchSegments();
  }

  Future<void> fetchPlans() async {
    isLoadingPlans.value = true;
    try {
      final result = await _subscriptionService.getSubscriptionPlans(
        page: plansCurrentPage.value,
        pageSize: plansItemsPerPage,
        search: searchController.text.trim().isNotEmpty
            ? searchController.text.trim()
            : null,
        status: selectedStatus.value != 'All Status'
            ? selectedStatus.value
            : null,
      );

      plans.value = result.plans;
      totalPlansCount.value = result.totalCount;
    } catch (e) {
      debugPrint('Error fetching plans: $e');
      plans.value = [];
      totalPlansCount.value = 0;
    } finally {
      isLoadingPlans.value = false;
    }
  }

  Future<void> fetchSegments() async {
    isLoadingSegments.value = true;
    try {
      final result = await _subscriptionService.getSegments();
      segments.value = result;
    } catch (e) {
      debugPrint('Error fetching segments: $e');
      segments.value = [];
    } finally {
      isLoadingSegments.value = false;
    }
  }

  Future<void> deleteSegment(String segmentId) async {
    try {
      final success = await _subscriptionService.deleteSegment(segmentId);
      if (success) {
        Get.snackbar(
          'Success',
          'Segment deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchSegments();
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete segment',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error deleting segment: $e');
      Get.snackbar(
        'Error',
        'An error occurred while deleting segment',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      final success = await _subscriptionService.deletePlan(planId);
      if (success) {
        Get.snackbar(
          'Success',
          'Plan deleted successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchPlans();
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete plan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error deleting plan: $e');
      Get.snackbar(
        'Error',
        'An error occurred while deleting plan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void updateStatus(String value) {
    selectedStatus.value = value;
  }

  void applyFilters() {
    plansCurrentPage.value = 1; // Reset to first page
    fetchPlans();
  }

  void resetFilters() {
    selectedStatus.value = 'All Status';
    searchController.clear();
    plansCurrentPage.value = 1;
    fetchPlans();
  }

  void setPlansPage(int page) {
    plansCurrentPage.value = page;
    fetchPlans();
  }

  void setSegmentsPage(int page) {
    segmentsCurrentPage.value = page;
  }

  int get plansTotalPages => (totalPlansCount.value / plansItemsPerPage).ceil();

  List<SegmentModel> get paginatedSegments {
    final start = (segmentsCurrentPage.value - 1) * segmentsItemsPerPage;
    final end = start + segmentsItemsPerPage;
    if (start >= segments.length) return [];
    return segments.sublist(
      start,
      end > segments.length ? segments.length : end,
    );
  }

  int get segmentsTotalPages => (segments.length / segmentsItemsPerPage).ceil();

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
