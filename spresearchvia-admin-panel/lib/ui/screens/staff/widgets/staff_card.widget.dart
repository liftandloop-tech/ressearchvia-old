import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import '../../../../models/staff.model.dart';
import 'staff_digital_id_dialog.widget.dart';

class StaffCard extends StatelessWidget {
  final StaffModel staff;

  const StaffCard({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary,
            child: Text(
              staff.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Get.toNamed('/staff/${staff.id}'),
                  child: Text(
                    staff.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.email,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                staff.mobile,
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: staff.status == 'Active'
                      ? AppTheme.statusSuccessLight
                      : AppTheme.statusErrorLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  staff.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: staff.status == 'Active'
                        ? AppTheme.statusSuccess
                        : AppTheme.statusError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.badge_outlined, size: 20),
                onPressed: () {
                  Get.dialog(
                    StaffDigitalIdDialog(staff: staff),
                  );
                },
                color: const Color(0xFF0F172A),
                tooltip: 'Digital ID Card',
              ),
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18),
                onPressed: () => Get.toNamed('/staff/${staff.id}'),
                color: AppTheme.textSecondary,
                tooltip: 'View Staff',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
