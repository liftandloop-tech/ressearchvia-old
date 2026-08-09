import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/main_dashboard.controller.dart';
import '../screens/dashboard/widgets/dashboard_header.widget.dart';
import '../widgets/footer.widget.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    final controller = Get.put(MainDashboardController());

    return SelectionArea(
      child: Scaffold(
        backgroundColor: AppTheme.gray50,
        body: Row(
          children: [
            DashboardHeader(controller: controller),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: child),
                  const Footer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
