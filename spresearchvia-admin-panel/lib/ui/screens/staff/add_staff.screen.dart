import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'widgets/add_staff_dialog.widget.dart';

class AddStaffScreen extends StatelessWidget {
  const AddStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuse the existing controller registered by StaffScreen
    final controller = Get.isRegistered<StaffController>()
        ? Get.find<StaffController>()
        : Get.put(StaffController());

    // Handle deep linking for edit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = Get.parameters['id'];
      if (id != null && !controller.isEditing.value) {
        // If we have an ID but not currently editing (avoid loop if already set)
        // We might need to fetch list first.
        if (controller.staffList.isEmpty) {
          controller.fetchStaffList().then((_) {
            _findAndPopulate(controller, id);
          });
        } else {
          _findAndPopulate(controller, id);
        }
      } else if (id == null) {
        // Create mode
        controller.resetForm();
      }
    });

    return DashboardLayout(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Text(
                    controller.isEditing.value
                        ? 'Update Staff'
                        : 'Add New Staff',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AddStaffDialog(controller: controller),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _findAndPopulate(StaffController controller, String id) {
    final staff = controller.staffList.firstWhereOrNull((s) => s.id == id);
    if (staff != null) {
      controller.populateForEdit(staff);
    }
  }
}
