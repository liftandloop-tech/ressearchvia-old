import 'package:flutter/material.dart';
import '../../layouts/dashboard_layout.widget.dart';
import 'dashboard_content.screen.dart';

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardLayout(child: Dashboard());
  }
}
