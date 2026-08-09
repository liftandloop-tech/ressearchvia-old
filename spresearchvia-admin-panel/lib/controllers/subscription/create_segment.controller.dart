import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/models/segment.model.dart';
import 'package:spresearch_web/services/subscription.service.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'package:spresearch_web/controllers/subscription/subscription_navigation.controller.dart';

class CreateSegmentController extends GetxController {
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();

  final formKey = GlobalKey<FormState>();
  final segmentNameController = TextEditingController();
  final descriptionController = TextEditingController();

  var isLoading = false.obs;
  var isActive = true.obs;
  SegmentModel? segmentToEdit;
  bool get isEditing => segmentToEdit != null;

  Future<void> init(SegmentModel? segment) async {
    // 1. Use passed segment
    if (segment != null) {
      _setFields(segment);
      return;
    }

    // 2. Check arguments
    if (Get.arguments is SegmentModel) {
      _setFields(Get.arguments as SegmentModel);
      return;
    }

    // 3. Check parameters
    final id = Get.parameters['id'];
    if (id != null) {
      isLoading.value = true;
      try {
        SubscriptionController subController;
        if (Get.isRegistered<SubscriptionController>()) {
          subController = Get.find<SubscriptionController>();
        } else {
          subController = Get.put(SubscriptionController());
        }

        if (subController.segments.isEmpty) {
          await subController.fetchSegments();
        }

        try {
          final foundSegment = subController.segments.firstWhere(
            (s) => s.id == id,
          );
          _setFields(foundSegment);
        } catch (e) {
          resetForm();
        }
      } finally {
        isLoading.value = false;
      }
      return;
    }

    // 4. Default
    resetForm();
  }

  void _setFields(SegmentModel segment) {
    segmentToEdit = segment;
    segmentNameController.text = segment.segmentName;
    descriptionController.text = segment.segmentDescription;
    isActive.value = segment.segmentStatus == 'active';
  }

  Future<void> saveSegment() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      bool success;
      if (isEditing) {
        success = await _subscriptionService.updateSegment(
          segmentId: segmentToEdit!.id,
          name: segmentNameController.text,
          description: descriptionController.text,
          status: isActive.value ? 'active' : 'inactive',
        );
      } else {
        success = await _subscriptionService.createSegment(
          name: segmentNameController.text,
          description: descriptionController.text,
          status: isActive.value ? 'active' : 'inactive',
        );
      }

      if (success) {
        Get.find<SubscriptionController>().fetchSegments(); // Refresh list
        Get.find<SubscriptionNavigationController>().goBack();
        Get.snackbar(
          'Success',
          isEditing
              ? 'Segment updated successfully'
              : 'Segment created successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          isEditing ? 'Failed to update segment' : 'Failed to create segment',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error saving segment: $e');
      Get.snackbar(
        'Error',
        'An error occurred',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void resetForm() {
    segmentNameController.clear();
    descriptionController.clear();
    isActive.value = true;
    segmentToEdit = null;
  }

  @override
  void onClose() {
    segmentNameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
