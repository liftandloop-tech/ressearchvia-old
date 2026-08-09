import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/services/subscription.service.dart';
import 'package:spresearch_web/models/subscription_plan.model.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'package:spresearch_web/controllers/subscription/subscription_navigation.controller.dart';

class CreatePlanController extends GetxController {
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();

  final formKey = GlobalKey<FormState>();
  final planNameController = TextEditingController();
  final durationController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final planFeaturesController = TextEditingController();

  var isLoading = false.obs;
  var selectedDurationType = 'days'.obs;
  var isActive = true.obs;
  var isHni = false.obs;
  SubscriptionPlanModel? planToEdit;
  bool get isEditing => planToEdit != null;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> init(SubscriptionPlanModel? plan) async {
    // 1. Use passed plan (highest priority)
    if (plan != null) {
      _setFields(plan);
      return;
    }

    // 2. Check arguments
    if (Get.arguments is SubscriptionPlanModel) {
      _setFields(Get.arguments as SubscriptionPlanModel);
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

        if (subController.plans.isEmpty) {
          await subController.fetchPlans();
        }

        try {
          final foundPlan = subController.plans.firstWhere((p) => p.id == id);
          _setFields(foundPlan);
        } catch (e) {
          // Plan not found
          resetForm();
        }
      } finally {
        isLoading.value = false;
      }
      return;
    }

    // 4. Default to Create Mode
    resetForm();
  }

  void _setFields(SubscriptionPlanModel plan) {
    planToEdit = plan;
    planNameController.text = plan.planName;
    durationController.text = plan.duration.toString();
    priceController.text = plan.price.toString();
    descriptionController.text = plan.description;
    planFeaturesController.text = plan.planFeatures;
    selectedDurationType.value = plan.day;
    isActive.value = plan.planStatus.toLowerCase() == 'active';
    isHni.value = plan.isHni;
  }

  Future<void> savePlan() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    try {
      bool success;
      if (isEditing) {
        success = await _subscriptionService.updatePlan(
          planId: planToEdit!.id,
          name: planNameController.text,
          duration: int.tryParse(durationController.text) ?? 0,
          day: 'days',
          price: double.tryParse(priceController.text) ?? 0,
          description: descriptionController.text,
          planFeatures: planFeaturesController.text,
          planStatus: isActive.value ? "active" : "inactive",
          isHni: isHni.value,
        );
      } else {
        final data = {
          "planName": planNameController.text,
          "duration": int.tryParse(durationController.text) ?? 0,
          "day": 'days',
          "price": double.tryParse(priceController.text) ?? 0,
          "discription": descriptionController.text,
          "planFeatures": planFeaturesController.text,
          "planStatus": isActive.value ? "active" : "inactive",
          "isHni": isHni.value,
        };
        success = await _subscriptionService.createPlan(data);
      }

      if (success) {
        Get.find<SubscriptionController>().fetchPlans(); // Refresh list
        Get.find<SubscriptionNavigationController>().goBack();
        Get.snackbar(
          'Success',
          isEditing ? 'Plan updated successfully' : 'Plan created successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          isEditing ? 'Failed to update plan' : 'Failed to create plan',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
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
    planNameController.clear();
    durationController.clear();
    priceController.clear();
    descriptionController.clear();
    planFeaturesController.clear();
    selectedDurationType.value = 'days';
    isActive.value = true;
    isHni.value = false;
    planToEdit = null;
  }

  @override
  void onClose() {
    planNameController.dispose();
    durationController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    planFeaturesController.dispose();
    super.onClose();
  }
}
