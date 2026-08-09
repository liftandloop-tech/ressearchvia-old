import 'package:flutter/material.dart';
import '../dashboard.controller.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'renewals_filters.widget.dart';
import 'renewals_table.widget.dart';

class RenewalsSection extends StatelessWidget {
  final DashboardController controller;

  const RenewalsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          RenewalsFilters(controller: controller),
          const SizedBox(height: 24),
          const RenewalsTable(),
        ],
      ),
    );
  }
}
