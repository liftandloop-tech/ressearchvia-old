import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/main_dashboard.controller.dart';
import '../../layouts/dashboard_layout.widget.dart';
import 'dashboard_content.screen.dart';
import '../users/users.screen.dart';
import '../subscription/subscription_tab.screen.dart';
import '../reports/reports.screen.dart';
import '../staff/staff.screen.dart';
import '../notifications/notifications.screen.dart';
import 'widgets/dashboard_header.widget.dart';
import '../../widgets/footer.widget.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardLayout(child: Dashboard());
  }
}
