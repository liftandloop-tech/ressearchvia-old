import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/models/subscription_plan.model.dart';
import 'package:spresearch_web/models/segment.model.dart';
import 'package:spresearch_web/controllers/subscription/subscription.controller.dart';
import 'package:spresearch_web/ui/screens/subscription/create_plan.screen.dart';
import 'package:spresearch_web/ui/screens/subscription/create_segment.screen.dart';

class SubscriptionNavigationController extends GetxController {
  var navigationStack = <Widget>[].obs;

  Widget? get currentScreen =>
      navigationStack.isEmpty ? null : navigationStack.last;

  void showCreatePlan({SubscriptionPlanModel? planToEdit}) {
    navigationStack.add(CreatePlanScreen(planToEdit: planToEdit));
  }

  void showCreateSegment({SegmentModel? segmentToEdit}) {
    navigationStack.add(CreateSegmentScreen(segmentToEdit: segmentToEdit));
  }

  void showHniRequests() {
    Get.toNamed('/subscriptions/hni-requests');
  }

  void goBack() {
    if (navigationStack.isNotEmpty) {
      navigationStack.removeLast();
      if (navigationStack.isEmpty) {
        if (Get.isRegistered<SubscriptionController>()) {
          Get.find<SubscriptionController>().fetchPlans();
          Get.find<SubscriptionController>().fetchSegments();
        }
      }
    } else {
      Get.back();
    }
  }
}
