import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/view_profile.controller.dart';
import '../../core/config/app.config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_styles.dart';
import '../../core/routes/app_routes.dart';
import 'widgets/profile.image.dart';
import '../../widgets/state_selector.dart';
import '../../widgets/title_field.dart';
import '../../widgets/button.dart';
import '../../services/cache.service.dart';
import '../../services/snackbar.service.dart';

class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ViewProfileController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        title: const Text('View Profile', style: AppStyles.appBarTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      Obx(() {
                        final user =
                            controller.userController.currentUser.value;
                        return ProfileImageAvatar(
                          imagePath:
                              user?.profileImage ??
                              'assets/images/profile_placeholder.jpg',
                        );
                      }),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () =>
                              _showImageSourceDialog(context, controller),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: AppTheme.backgroundWhite,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppTheme.backgroundWhite,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
              TitleField(
                title: 'First Name',
                controller: controller.firstNameController,
                hint: 'Not available',
                readOnly: true,
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Middle Name',
                controller: controller.middleNameController,
                hint: 'Not available',
                readOnly: true,
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Last Name',
                controller: controller.lastNameController,
                hint: 'Not available',
                readOnly: true,
              ),
              const SizedBox(height: 5),
              TitleField(
                title: "Father's Name",
                controller: controller.fatherNameController,
                hint: 'Not available',
                readOnly: true,
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'House No',
                controller: controller.houseNoController,
                hint: 'Enter House No',
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Street Address',
                controller: controller.streetAddressController,
                hint: 'Enter Street Address',
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Area',
                controller: controller.areaController,
                hint: 'Enter Area',
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Landmark',
                controller: controller.landmarkController,
                hint: 'Enter Landmark',
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Pincode',
                controller: controller.pincodeController,
                hint: 'Enter Pincode',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 5),
              Obx(
                () => StateSelector(
                  label: 'State',
                  value: controller.selectedState.value,
                  onChanged: (val) {
                    if (val != null) controller.selectedState.value = val;
                  },
                ),
              ),

              const SizedBox(height: 20),
              TitleField(
                title: 'Mobile Number',
                controller: controller.phoneController,
                hint: 'Not available',
                readOnly: true,
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Email',
                controller: controller.emailController,
                hint: 'Not available',
                readOnly: true,
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'PAN Number',
                controller: controller.panController,
                hint: 'Not available',
                readOnly: true,
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Date of Birth',
                controller: controller.dobController,
                hint: 'Not available',
                readOnly: true,
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'Firm Name',
                controller: controller.firmNameController,
                hint: 'Enter Firm Name',
              ),
              const SizedBox(height: 5),
              TitleField(
                title: 'GSTIN',
                controller: controller.gstinController,
                hint: 'Enter GSTIN',
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                  UpperCaseTextFormatter(),
                ],
              ),
              const SizedBox(height: 20),
              Button(
                title: 'Update Profile',
                buttonType: ButtonType.blue,
                onTap: controller.saveChanges,
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: () {
                  Get.toNamed(AppRoutes.setMpin, arguments: {'flow': 'profile'});
                },
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderGrey),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.key, size: 20, color: AppTheme.iconGrey),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Change MPin',
                          style: AppStyles.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 20,
                        color: AppTheme.iconGrey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  if (await canLaunchUrl(AppConfig.policyURL)) {
                    await launchUrl(
                      AppConfig.policyURL,
                      mode: LaunchMode.inAppBrowserView,
                    );
                  }
                },
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderGrey),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: AppTheme.iconGrey,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Privacy Settings',
                          style: AppStyles.bodyMedium,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 20,
                        color: AppTheme.iconGrey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Button(
                title: 'Delete Account',
                buttonType: ButtonType.red,
                onTap: () async {
                  if (await canLaunchUrl(AppConfig.deleteURL)) {
                    await launchUrl(
                      AppConfig.deleteURL,
                      mode: LaunchMode.inAppBrowserView,
                    );
                  }
                },
              ),
              const SizedBox(height: 15),
              Obx(() => Button(
                title: 'Clean App Cache (${CacheService.to.currentCacheSize.value})',
                buttonType: ButtonType.greyBorder,
                icon: Icons.cleaning_services_outlined,
                onTap: () {
                    Get.defaultDialog(
                      title: 'Clear Cache',
                      middleText: 'Are you sure you want to clear the application cache? This will remove temporary files and image history.',
                      textConfirm: 'Yes, Clear',
                      textCancel: 'Cancel',
                      confirmTextColor: Colors.white,
                      buttonColor: AppTheme.error,
                      onConfirm: () async {
                        Get.back();
                        await CacheService.to.clearAllCache();
                        SnackbarService.showSuccess('Cache cleared successfully!');
                      },
                    );
                },
              )),
              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(
    BuildContext context,
    ViewProfileController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Change Profile Picture', style: AppStyles.heading4),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickImageFromSource(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    controller.pickImageFromSource(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
