import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user_details.controller.dart';
import 'package:spresearch_web/ui/screens/users/details/widgets/info_section.widget.dart';
import 'package:spresearch_web/ui/screens/users/details/widgets/editable_row.widget.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';

class PersonalInfo extends StatelessWidget {
  const PersonalInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserDetailsController>();

    return Obx(() {
      final userDetails = controller.userDetails.value;
      if (userDetails == null) return SizedBox.shrink();

      final displayName = userDetails.userObject?.appName.isNotEmpty == true
          ? userDetails.userObject!.appName
          : userDetails.fullName;

      final fatherName = userDetails.userObject?.appFName ?? 'Not Found';
      final dob = userDetails.userObject?.appDobDt ?? 'Not Found';
      final isEditing = controller.isEditingPersonal.value;

      return InfoSection(
        title: 'Personal Information',
        icon: Icons.person,
        headerAction: Get.find<AuthController>().user.value?.isDirector == true
            ? null
            : isEditing
            ? Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: AppTheme.statusSuccess),
                    onPressed: controller.savePersonalDetails,
                    tooltip: 'Save',
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.errorRed),
                    onPressed: controller.cancelEditingPersonal,
                    tooltip: 'Cancel',
                  ),
                ],
              )
            : IconButton(
                icon: Icon(Icons.edit, color: AppTheme.primaryBlue, size: 20),
                onPressed: controller.startEditingPersonal,
                tooltip: 'Edit',
              ),
        child: Column(
          children: [
            EditableRow(
              label: 'User Full Name',
              value: displayName,
              controller: controller.firstNameController,
              isEditing: isEditing,
            ),
            EditableRow(
              label: 'Father\'s Name',
              value: fatherName,
              controller: controller.fatherNameController,
              isEditing: isEditing,
            ),
            EditableRow(
              label: 'Date of Birth',
              value: dob,
              controller: controller.dobController,
              isEditing: isEditing,
            ),
            EditableRow(
              label: 'Gender',
              value: userDetails.gender,
              controller: controller.genderController,
              isEditing: isEditing,
            ),
          ],
        ),
      );
    });
  }
}
