import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/input_formatters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_styles.dart';
import 'package:flutter/services.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/button.dart';
import '../../widgets/title_field.dart';
import '../../controllers/login.controller.dart';
import '../../core/routes/app_routes.dart';

part 'widgets/data_protection_footer.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final responsive = Responsive.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Padding(
          padding: responsive.padding(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.primaryBlue,
                        size: responsive.spacing(AppDimensions.iconLarge),
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(AppDimensions.spacing20)),
                SizedBox(
                  height: responsive.spacing(AppDimensions.logoHeight),
                  width: double.maxFinite,
                  child: const AppLogo(),
                ),
                SizedBox(height: responsive.spacing(AppDimensions.spacing20)),
                Text(
                  AppStrings.welcomeBack,
                  style: AppStyles.welcomeText.copyWith(
                    fontSize: responsive.sp(24),
                  ),
                ),
                Text(
                  AppStrings.signInToAccess,
                  style: AppStyles.bodyLarge.copyWith(
                    fontSize: responsive.sp(16),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppDimensions.spacing40)),
                TitleField(
                  title: AppStrings.emailOrPhone,
                  hint: AppStrings.enterEmailOrPhone,
                  controller: controller.phoneOrMailController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [PhoneInputFormatter()],
                ),
                SizedBox(height: responsive.spacing(AppDimensions.spacing20)),
                TitleField(
                  title: AppStrings.mpin,
                  hint: AppStrings.enterMpin,
                  controller: controller.mpinController,
                  icon: Icons.lock_outline,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                SizedBox(height: responsive.spacing(AppDimensions.spacing10)),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.forgotMpin);
                    },
                    child: Text(
                      AppStrings.forgotMpin,
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: responsive.sp(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(AppDimensions.spacing40)),
                Obx(
                  () => Button(
                    title: controller.isLoading.value
                        ? 'Logging in...'
                        : AppStrings.login,
                    buttonType: ButtonType.blue,
                    onTap: controller.isLoading.value
                        ? null
                        : controller.handleLogin,
                    showLoading: controller.isLoading.value,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppDimensions.spacing10)),
                Button(
                  title: AppStrings.back,
                  buttonType: ButtonType.greyBorder,
                  onTap: () => Get.back(),
                ),
                SizedBox(height: responsive.spacing(AppDimensions.spacing20)),
                const DataProtection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
