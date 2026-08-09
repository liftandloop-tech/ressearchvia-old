import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';
import 'package:spresearch_web/controllers/kyc/kyc_manager.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'widgets/kyc_filters.widget.dart';
import 'widgets/kyc_table.widget.dart';

class KycManager extends StatelessWidget {
  const KycManager({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(KycManagerController());
    return DashboardLayout(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.getResponsivePadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.kycManagement,
                  style: AppTheme.sectionTitleStyle.copyWith(
                    fontSize: 24,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.kycManagementDesc,
              style: AppTheme.cardTitleStyle.copyWith(fontFamily: 'Poppins'),
            ),

            const SizedBox(height: 32),

            const KycFilters(),

            const SizedBox(height: 24),

            const KycTable(),
          ],
        ),
      ),
    );
  }
}
