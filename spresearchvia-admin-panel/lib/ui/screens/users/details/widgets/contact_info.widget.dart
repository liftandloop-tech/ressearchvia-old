import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user_details.controller.dart';
import 'package:spresearch_web/ui/screens/users/details/widgets/info_section.widget.dart';
import 'package:spresearch_web/ui/screens/users/details/widgets/editable_row.widget.dart';
import 'package:spresearch_web/controllers/auth/auth.controller.dart';

class ContactInfo extends StatelessWidget {
  const ContactInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserDetailsController>();

    return Obx(() {
      final userDetails = controller.userDetails.value;
      if (userDetails == null) return SizedBox.shrink();

      final email = userDetails.email;
      final isEditing = controller.isEditingContact.value;

      return InfoSection(
        title: 'Contact Information',
        icon: Icons.phone,
        headerAction: Get.find<AuthController>().user.value?.isDirector == true
            ? null
            : isEditing
            ? Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: AppTheme.statusSuccess),
                    onPressed: controller.saveContactDetails,
                    tooltip: 'Save',
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppTheme.errorRed),
                    onPressed: controller.cancelEditingContact,
                    tooltip: 'Cancel',
                  ),
                ],
              )
            : IconButton(
                icon: Icon(Icons.edit, color: AppTheme.primaryBlue, size: 20),
                onPressed: controller.startEditingContact,
                tooltip: 'Edit',
              ),
        child: Column(
          children: [
            EditableRow(
              label: 'Mobile Number',
              value: userDetails.formattedPhone,
              controller: controller.phoneController,
              isEditing: isEditing,
            ),
            EditableRow(
              label: 'Email Address',
              value: email,
              controller: controller.emailController,
              isEditing: isEditing,
            ),
            EditableRow(
              label: 'Firm Name',
              value: userDetails.firmName ?? 'Not Found',
              controller: controller.firmNameController,
              isEditing: isEditing,
            ),
            EditableRow(
              label: 'GSTIN',
              value: userDetails.gstin ?? 'Not Found',
              controller: controller.gstinController,
              isEditing: isEditing,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                UpperCaseTextFormatter(),
              ],
            ),
            if (!isEditing)
              InfoRow(
                label: 'Residential Address',
                value: userDetails.residentialAddress,
              ),
            if (isEditing) ...[
              EditableRow(
                label: 'Address Line 1',
                value: '', // Value handled by controller
                controller: controller.addressController,
                isEditing: true,
              ),
              EditableRow(
                label: 'City',
                value: '',
                controller: controller.cityController,
                isEditing: true,
              ),
              EditableRow(
                label: 'State',
                value: '',
                controller: controller.stateController,
                isEditing: true,
              ),
              EditableRow(
                label: 'Pincode',
                value: '',
                controller: controller.pincodeController,
                isEditing: true,
              ),
            ],
          ],
        ),
      );
    });
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
