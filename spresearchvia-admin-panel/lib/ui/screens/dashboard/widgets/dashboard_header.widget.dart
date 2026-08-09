import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/dashboard/main_dashboard.controller.dart';
import 'dashboard_logo.widget.dart';
import 'dashboard_nav_bar.widget.dart';
import 'dashboard_header_actions.widget.dart';

class DashboardHeader extends StatelessWidget {
  final MainDashboardController controller;

  const DashboardHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.gray200, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.all(24), child: DashboardLogo()),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: DashboardNavBar(controller: controller),
            ),
          ),
          const DashboardHeaderActions(),
        ],
      ),
    );
  }
}
