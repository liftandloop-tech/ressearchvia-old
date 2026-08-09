import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import 'plan.row.dart';
import 'setting.tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> planDetails = [
      877,
      'Feb 15, 2024',
      'VISA',
      '**** 4532',
    ];

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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(width: 1, color: const Color(0xffE5E7EB)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Premium Plan',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffeaf3ec),
                        ),
                        child: const Text('Active'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text('data'),
                  const SizedBox(height: 5),
                  PlanRow(title: 'Monthly Price', value: '₹${planDetails[0]}'),
                  PlanRow(title: 'Next Billing', value: planDetails[1]),
                  PlanRow(
                    title: 'Payment Method',
                    value: '[${planDetails[2]}] ${planDetails[3]}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // SettingTile(
            //   title: 'Billing History',
            //   subtitle: 'View past transactions',
            //   icon: Icons.list_alt_outlined,
            //   onTap: () {},
            // ),
            // const SizedBox(height: 10),
            SettingTile(
              title: 'Automated Trading',
              subtitle: 'Link broker & authorize daily session',
              icon: Icons.auto_graph_outlined,
              onTap: () => Get.toNamed(AppRoutes.automatedTrading),
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
