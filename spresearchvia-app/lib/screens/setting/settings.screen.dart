import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import 'setting.tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xff11416B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          children: [
            SettingTile(
              title: 'Automated Trading',
              subtitle: 'Link broker & authorize daily session',
              icon: Icons.auto_graph_outlined,
              onTap: () => Get.toNamed(AppRoutes.automatedTrading),
            ),
            const SizedBox(height: 10),
            SettingTile(
              title: 'Static Proxy IP',
              subtitle: 'Purchase & manage static proxy IP',
              icon: Icons.settings_ethernet_outlined,
              onTap: () => Get.toNamed(AppRoutes.proxySetup),
            ),
            const SizedBox(height: 10),
            SettingTile(
              title: 'Trading Consent',
              subtitle: 'Review & grant daily execution consent',
              icon: Icons.gpp_good_outlined,
              onTap: () => Get.toNamed(AppRoutes.consent),
            ),
          ],
        ),
      ),
    );
  }
}
