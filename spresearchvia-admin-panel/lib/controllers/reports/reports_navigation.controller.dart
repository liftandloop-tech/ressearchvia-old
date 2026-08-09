import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/ui/screens/reports/upload_report.screen.dart';
import 'package:spresearch_web/ui/screens/reports/report_details.screen.dart';
import 'package:spresearch_web/models/report.model.dart';
import 'package:spresearch_web/controllers/reports/report.controller.dart';

class ReportsNavigationController extends GetxController {
  var navigationStack = <Widget>[].obs;

  Widget? get currentScreen =>
      navigationStack.isEmpty ? null : navigationStack.last;

  void showUploadReport({ReportModel? reportToEdit}) {
    if (reportToEdit != null) {
      // We need to access the controller of the new screen to load data.
      // But Get.put happens inside build.
      // So we can pass arguments to the screen or use Get.arguments.
      // Or we can find the controller after pushing? No, controller is created on build.
      // Better way: Pass report to screen constructor.
      navigationStack.add(UploadReportScreen(reportToEdit: reportToEdit));
    } else {
      navigationStack.add(UploadReportScreen());
    }
  }

  void showReportDetails(ReportModel report) {
    navigationStack.add(ReportDetailsScreen(report: report));
  }

  void goBack() {
    if (navigationStack.isNotEmpty) {
      navigationStack.removeLast();
      if (navigationStack.isEmpty) {
        if (Get.isRegistered<ReportController>()) {
          Get.find<ReportController>().fetchReports();
        }
      }
    } else {
      Get.back();
    }
  }
}
