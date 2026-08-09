import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/edit_profile.controller.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';
import '../../widgets/button.widget.dart';
import '../../widgets/edit_profile_text_field.widget.dart';
import '../../widgets/edit_profile_dropdown.widget.dart';

class EditUserProfile extends StatelessWidget {
  final String userId;
  const EditUserProfile({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController());

    // Fetch user details
    controller.fetchUserDetails(userId);

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Obx(() {
          if (controller.isLoadingDetails.value) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing32),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0, top: 4),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              color: AppTheme.primaryBlue,
                              onPressed: () {
                                Get.find<UsersNavigationController>().goBack();
                              },
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit User Profile',
                                style: AppTheme.h2Style.copyWith(
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update user information and preferences',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                child: Obx(
                                  () => Center(
                                    child: Text(
                                      controller.fullNameDisplay.value,
                                      style: AppTheme.h2Style.copyWith(
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Change Photo',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 24),
                            EditProfileTextField(
                              label: 'User Full Name',
                              controller: controller.fullNameController,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 16),
                            EditProfileTextField(
                              label: 'Father\'s Name',
                              controller: controller.fatherNameController,
                              enabled: true,
                            ),
                            const SizedBox(height: 16),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: EditProfileTextField(
                                      label: 'Date of Birth',
                                      controller: controller.dobController,
                                      enabled: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Obx(
                                      () => EditProfileDropdown(
                                        label: 'Gender',
                                        value: controller.selectedGender.value,
                                        items: ['Male', 'Female'],
                                        onChanged: (val) {
                                          if (val != null)
                                            controller.selectedGender.value =
                                                val;
                                        },
                                        enabled: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 24),
                            EditProfileTextField(
                              label: 'Mobile No.',
                              controller: controller.mobileController,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Mobile number is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            EditProfileTextField(
                              label: 'Email Address',
                              controller: controller.emailController,
                              required: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return 'Enter valid email';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Address Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: EditProfileTextField(
                            label: 'Reseidential Address',
                            controller: controller.addressController,
                            enabled: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: EditProfileTextField(
                            label: 'Pincode',
                            controller: controller.pincodeController,
                            enabled: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Obx(
                            () => EditProfileDropdown(
                              label: 'State',
                              value: controller.selectedState.value,
                              items: [
                                'Andhra Pradesh',
                                'Arunachal Pradesh',
                                'Assam',
                                'Bihar',
                                'Chhattisgarh',
                                'Goa',
                                'Gujarat',
                                'Haryana',
                                'Himachal Pradesh',
                                'Jharkhand',
                                'Karnataka',
                                'Kerala',
                                'Madhya Pradesh',
                                'Maharashtra',
                                'Manipur',
                                'Meghalaya',
                                'Mizoram',
                                'Nagaland',
                                'Odisha',
                                'Punjab',
                                'Rajasthan',
                                'Sikkim',
                                'Tamil Nadu',
                                'Telangana',
                                'Tripura',
                                'Uttar Pradesh',
                                'Uttarakhand',
                                'West Bengal',
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  controller.selectedState.value = val;
                              },
                              enabled: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Button(
                        title: 'Cancel',
                        buttonType: ButtonType.grey,
                        onTap: () =>
                            Get.find<UsersNavigationController>().goBack(),
                      ),
                      const SizedBox(width: 12),
                      Obx(
                        () => Button(
                          title: 'Save Changes',
                          buttonType: ButtonType.green,
                          icon: Icons.save,
                          onTap: controller.isSaving.value
                              ? null
                              : () => controller.saveProfile(userId),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
